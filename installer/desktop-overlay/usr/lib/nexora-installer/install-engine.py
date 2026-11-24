#!/usr/bin/python3
"""NEXORA OS disk installation engine. Destructive operations require explicit GUI confirmation."""
import atexit
import os
import re
import shutil
import subprocess
import sys
import time
import urllib.request
from pathlib import Path

MOUNTS = []
def cleanup():
    for mountpoint in reversed(MOUNTS):
        subprocess.run(["umount", "-lf", mountpoint], stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
    MOUNTS.clear()

atexit.register(cleanup)

def run(args, *, check=True, input_text=None):
    return subprocess.run(args, check=check, text=True, input=input_text,
                          stdout=subprocess.PIPE, stderr=subprocess.STDOUT)

def fail(message):
    print("ERROR: " + message, flush=True)
    raise SystemExit(1)

def part_path(disk, number):
    return disk + ("p" if disk[-1].isdigit() else "") + str(number)

def validate_manual_partition_plan(disk, root_part, efi_part, inventory):
    """Validate a manual partition plan using an lsblk JSON inventory.

    This helper is deliberately read-only. It never formats, mounts, or edits
    partition tables; the installer can use it before enabling manual installs.
    Return an explanatory error string, or None when the plan is structurally safe.
    """
    def clean_device(value):
        return isinstance(value, str) and re.fullmatch(r"/dev/[A-Za-z0-9_-]+", value)

    if not clean_device(disk) or not clean_device(root_part):
        return "La ruta del disco o de la partición raíz no es válida."
    if efi_part and not clean_device(efi_part):
        return "La ruta de la partición EFI no es válida."
    devices = inventory.get("blockdevices", []) if isinstance(inventory, dict) else []
    selected_disk = None
    partitions = {}

    def walk(nodes, parent=None):
        nonlocal selected_disk
        for node in nodes or []:
            name = node.get("name") or ""
            path = "/dev/" + name
            kind = node.get("type")
            if path == disk and kind == "disk":
                selected_disk = node
            if kind == "part":
                partitions[path] = (node, parent)
            walk(node.get("children") or [], node if kind == "disk" else parent)

    walk(devices)
    if selected_disk is None:
        return "El disco seleccionado ya no está disponible."
    root = partitions.get(root_part)
    if root is None or root[1] is not selected_disk:
        return "La partición raíz debe pertenecer al disco seleccionado."
    root_node = root[0]
    root_size = int(root_node.get("size") or 0)
    if root_size < 8 * 1024**3:
        return "La partición raíz debe tener al menos 8 GB."
    if any(point for point in (root_node.get("mountpoints") or []) if point):
        return "La partición raíz está montada y no se puede seleccionar."
    if efi_part:
        efi = partitions.get(efi_part)
        if efi is None or efi[1] is not selected_disk:
            return "La partición EFI debe pertenecer al mismo disco seleccionado."
        efi_node = efi[0]
        if efi_part == root_part:
            return "La partición raíz y la EFI deben ser distintas."
        if int(efi_node.get("size") or 0) < 100 * 1024**2:
            return "La partición EFI debe tener al menos 100 MB."
        if any(point for point in (efi_node.get("mountpoints") or []) if point):
            return "La partición EFI está montada y no se puede seleccionar."
        fs = (efi_node.get("fstype") or "").lower()
        if fs and fs not in ("vfat", "fat", "fat16", "fat32"):
            return "La partición EFI debe usar FAT32 o estar sin formato."
    return None

def main():
    if os.geteuid() != 0:
        fail("El motor debe ejecutarse con permisos administrativos.")
    if len(sys.argv) != 12:
        fail("Uso interno incorrecto.")
    (disk, username, hostname, locale_code, timezone, keyboard_layout,
     root_enabled, root_secret_file, secret_file, desktop_profile, apt_mirror) = sys.argv[1:]
    if desktop_profile not in {"xfce", "minimal"}:
        fail("El perfil de escritorio no es válido.")
    if not re.fullmatch(r"https://[A-Za-z0-9.-]+(?::[0-9]{1,5})?(?:/[A-Za-z0-9._~:/-]*)?", apt_mirror):
        fail("El servidor APT debe ser una URL HTTPS válida.")
    if root_enabled not in {"yes", "no"}:
        fail("La opción de superusuario no es válida.")
    allowed_locales = {"es_CL.UTF-8", "es_ES.UTF-8", "en_US.UTF-8", "en_GB.UTF-8", "pt_BR.UTF-8"}
    allowed_timezones = {
        "America/Santiago", "America/Punta_Arenas", "America/Easter",
        "America/Argentina/Buenos_Aires", "America/Lima", "America/Bogota",
        "America/Mexico_City", "Europe/Madrid", "UTC",
    }
    allowed_keyboards = {"latam", "us", "es", "br"}
    if locale_code not in allowed_locales or timezone not in allowed_timezones:
        fail("La configuración regional seleccionada no está permitida.")
    if keyboard_layout not in allowed_keyboards:
        fail("La distribución de teclado seleccionada no está permitida.")
    if not Path("/usr/share/zoneinfo", timezone).is_file():
        fail("La zona horaria seleccionada no está instalada en el medio Live.")
    if not re.fullmatch(r"/dev/[A-Za-z0-9_./-]+", disk) or not Path(disk).exists():
        fail("Disco de destino no válido.")
    if not re.fullmatch(r"[a-z_][a-z0-9_-]{0,31}", username):
        fail("Nombre de usuario no válido.")
    if not re.fullmatch(r"[a-z0-9][a-z0-9-]{0,62}", hostname):
        fail("Nombre de equipo no válido.")
    secret = Path(secret_file)
    try:
        password = secret.read_text(encoding="utf-8")
    finally:
        try: secret.unlink()
        except OSError: pass
    if len(password) < 8 or "\n" in password or ":" in password:
        fail("La contraseña no cumple los requisitos mínimos.")
    root_password = ""
    if root_enabled == "yes":
        root_secret = Path(root_secret_file)
        try:
            root_password = root_secret.read_text(encoding="utf-8")
        finally:
            try: root_secret.unlink()
            except OSError: pass
        if len(root_password) < 12 or "\n" in root_password or ":" in root_password:
            fail("La contraseña de root no cumple los requisitos mínimos.")
    elif root_secret_file != "-":
        fail("No se esperaba un archivo de contraseña root.")

    # Validar la red antes de modificar el disco: APT necesitará Internet.
    network_state = run(["nmcli", "-t", "-f", "STATE", "general"], check=False)
    if network_state.returncode != 0 or network_state.stdout.strip() != "connected":
        fail("No hay conexión activa. Conecta Ethernet o Wi-Fi desde NetworkManager.")
    try:
        request = urllib.request.Request(apt_mirror + "/dists/bookworm/InRelease")
        with urllib.request.urlopen(request, timeout=12) as response:
            if response.status != 200:
                fail("El repositorio APT no respondió correctamente.")
    except Exception as error:
        fail("No se pudo acceder al repositorio APT: " + str(error))

    # Validate capacity and refuse disks currently mounted by the Live session.
    size_result = run(["lsblk", "-b", "-ndo", "SIZE", disk], check=False)
    try:
        if int(size_result.stdout.strip() or "0") < 12 * 1024**3:
            fail("El disco debe tener al menos 12 GB.")
    except ValueError:
        fail("No se pudo comprobar el tamaño del disco.")
    tree = run(["lsblk", "-J", "-o", "NAME,TYPE,MOUNTPOINTS"], check=False)
    if tree.returncode == 0:
        import json
        data = json.loads(tree.stdout)
        def find_disk(nodes):
            for node in nodes:
                if node.get("name") == Path(disk).name:
                    return node
                found = find_disk(node.get("children") or [])
                if found:
                    return found
            return None
        selected = find_disk(data.get("blockdevices", []))
        def has_mount(node):
            if any(point for point in (node.get("mountpoints") or []) if point):
                return True
            return any(has_mount(child) for child in (node.get("children") or []))
        if selected and has_mount(selected):
            fail("El disco de destino tiene particiones montadas. Desmonta el disco o selecciona otro.")
    # Protect the medium currently running NEXORA Live.
    for medium in ("/run/live/medium", "/lib/live/mount/medium"):
        source = run(["findmnt", "-nro", "SOURCE", "--target", medium], check=False).stdout.strip()
        if source.startswith("/dev/"):
            source_name = Path(source).name
            parent = run(["lsblk", "-no", "PKNAME", source], check=False).stdout.strip()
            if source_name == Path(disk).name or parent == Path(disk).name:
                fail("No se puede instalar sobre el medio desde el que arrancó NEXORA Live.")
    efi = Path("/sys/firmware/efi").exists()
    print("Preparando el disco seleccionado…", flush=True)
    # La GUI solicita confirmación explícita antes de invocar este motor.
    run(["parted", "-s", disk, "mklabel", "gpt"])
    if efi:
        run(["parted", "-s", disk, "mkpart", "ESP", "fat32", "1MiB", "513MiB"])
        run(["parted", "-s", disk, "set", "1", "esp", "on"])
        root_num = 2
        root_start = "513MiB"
    else:
        run(["parted", "-s", disk, "mkpart", "BIOS-GRUB", "1MiB", "3MiB"])
        run(["parted", "-s", disk, "set", "1", "bios_grub", "on"])
        root_num = 2
        root_start = "3MiB"
    run(["parted", "-s", disk, "mkpart", "NEXORA-ROOT", "ext4", root_start, "100%"])
    run(["partprobe", disk], check=False)
    run(["udevadm", "settle"], check=False)
    root_part = part_path(disk, root_num)
    efi_part = part_path(disk, 1)
    print("Formateando la partición del sistema…", flush=True)
    run(["mkfs.ext4", "-F", "-L", "NEXORA", root_part])
    if efi:
        run(["mkfs.fat", "-F", "32", "-n", "NEXORA_EFI", efi_part])

    target = Path("/mnt/nexora-install")
    target.mkdir(parents=True, exist_ok=True)
    run(["mount", root_part, str(target)])
    MOUNTS.append(str(target))
    if efi:
        (target / "boot/efi").mkdir(parents=True, exist_ok=True)
        run(["mount", efi_part, str(target / "boot/efi")])
        MOUNTS.append(str(target / "boot/efi"))

    print("Copiando el sistema NEXORA al disco…", flush=True)
    rsync = shutil.which("rsync")
    if not rsync:
        fail("No se encontró rsync en el sistema Live.")
    excludes = [
        "--exclude=/dev/***", "--exclude=/proc/***", "--exclude=/sys/***",
        "--exclude=/run/***", "--exclude=/tmp/***", "--exclude=/mnt/***",
        "--exclude=/media/***", "--exclude=/lost+found",
        "--exclude=/var/cache/apt/archives/*.deb",
    ]
    run([rsync, "-aHAXx", "--numeric-ids", *excludes, "/", str(target) + "/"])

    root_uuid = run(["blkid", "-s", "UUID", "-o", "value", root_part]).stdout.strip()
    fstab = [f"UUID={root_uuid} / ext4 defaults,errors=remount-ro 0 1"]
    if efi:
        efi_uuid = run(["blkid", "-s", "UUID", "-o", "value", efi_part]).stdout.strip()
        fstab.append(f"UUID={efi_uuid} /boot/efi vfat umask=0077 0 1")
    (target / "etc/fstab").write_text("\n".join(fstab) + "\n", encoding="utf-8")
    (target / "etc/hostname").write_text(hostname + "\n", encoding="utf-8")
    (target / "etc/default/locale").write_text(
        'LANG="' + locale_code + '"\n', encoding="utf-8"
    )
    (target / "etc/default/keyboard").write_text(
        'XKBMODEL="pc105"\nXKBLAYOUT="' + keyboard_layout +
        '"\nXKBVARIANT=""\nXKBOPTIONS=""\nBACKSPACE="guess"\n',
        encoding="utf-8",
    )
    (target / "etc/timezone").write_text(timezone + "\n", encoding="utf-8")
    hosts = target / "etc/hosts"
    hosts.write_text("127.0.0.1 localhost\n127.0.1.1 " + hostname + "\n\n::1 localhost ip6-localhost ip6-loopback\n", encoding="utf-8")

    # Aplicar el mirror Debian en sources.list y archivos deb822.
    print("Configurando repositorios APT…", flush=True)
    apt_sources = target / "etc/apt/sources.list.d"
    if apt_sources.exists():
        for source_file in apt_sources.glob("*.sources"):
            content = source_file.read_text(encoding="utf-8")
            content = re.sub(r"(?m)^URIs:.*$", "URIs: " + apt_mirror, content)
            source_file.write_text(content, encoding="utf-8")
    legacy_sources = target / "etc/apt/sources.list"
    if legacy_sources.exists():
        content = legacy_sources.read_text(encoding="utf-8")
        content = re.sub(r"(?m)^(deb(?:-src)?\s+)\S+", lambda match: match.group(1) + apt_mirror, content)
        legacy_sources.write_text(content, encoding="utf-8")

    print("Configurando la cuenta y el arranque…", flush=True)
    for mount in ("dev", "dev/pts", "proc", "sys", "run"):
        (target / mount).mkdir(parents=True, exist_ok=True)
        run(["mount", "--bind", "/" + mount, str(target / mount)])
        MOUNTS.append(str(target / mount))
    chroot = ["chroot", str(target)]
    if run(chroot + ["id", "-u", username], check=False).returncode != 0:
        run(chroot + ["useradd", "-m", "-s", "/bin/bash", "-G", "sudo", username])
    else:
        run(chroot + ["usermod", "-aG", "sudo", username])
    locale_gen = target / "etc/locale.gen"
    locale_lines = locale_gen.read_text(encoding="utf-8").splitlines() if locale_gen.exists() else []
    supported_locales = (
        "es_CL.UTF-8", "es_ES.UTF-8", "en_US.UTF-8",
        "en_GB.UTF-8", "pt_BR.UTF-8",
    )
    for supported in supported_locales:
        locale_lines = [
            line for line in locale_lines
            if not line.lstrip().startswith(supported + " ")
        ]
        locale_lines.append(supported + " UTF-8")
    locale_gen.write_text("\n".join(locale_lines) + "\n", encoding="utf-8")
    run(chroot + ["locale-gen"], check=False)
    run(chroot + ["ln", "-sf", "/usr/share/zoneinfo/" + timezone, "/etc/localtime"], check=False)
    run(chroot + ["chpasswd"], input_text=username + ":" + password + "\n")
    password = ""
    # Remove the temporary Live-session account when the user chose another name.
    if username != "nexora" and run(chroot + ["id", "-u", "nexora"], check=False).returncode == 0:
        run(chroot + ["userdel", "-r", "nexora"], check=False)
    # The Live image machine-id must not be cloned to installed systems.
    (target / "etc/machine-id").write_text("", encoding="utf-8")
    if root_enabled == "yes":
        run(chroot + ["chpasswd"], input_text="root:" + root_password + "\n")
        root_password = ""
        print("Cuenta root activada con contraseña propia.", flush=True)
    else:
        run(chroot + ["passwd", "-l", "root"], check=False)
        print("Cuenta root bloqueada; el usuario principal administra mediante sudo.", flush=True)
    print("Actualizando índices APT en el sistema instalado…", flush=True)
    run(chroot + ["apt-get", "update"])
    if desktop_profile == "xfce":
        print("Instalando el escritorio XFCE4…", flush=True)
        run(chroot + ["apt-get", "install", "-y", "task-xfce-desktop", "lightdm", "network-manager-gnome"])
        run(chroot + ["systemctl", "enable", "lightdm"])
        run(chroot + ["systemctl", "set-default", "graphical.target"])
    else:
        print("Preparando NEXORA Minimal sin entorno gráfico…", flush=True)
        run(chroot + ["apt-get", "purge", "-y", "task-xfce-desktop", "xfce4", "xfce4-goodies", "xfce4-panel", "xfce4-session", "xfce4-settings", "xfdesktop4", "xfwm4", "lightdm", "lightdm-gtk-greeter"], check=False)
        run(chroot + ["apt-get", "autoremove", "-y"], check=False)
        run(chroot + ["systemctl", "set-default", "multi-user.target"])
    run(chroot + ["systemctl", "enable", "NetworkManager"])
    if efi:
        run(chroot + ["grub-install", "--target=x86_64-efi", "--efi-directory=/boot/efi",
                      "--bootloader-id=NEXORA", "--recheck", "--no-nvram", "--removable"])
    else:
        run(chroot + ["grub-install", "--target=i386-pc", disk])
    run(chroot + ["update-grub"])
    print("Instalación terminada. Puedes reiniciar y retirar el medio Live.", flush=True)
    # Desmontar en orden inverso (también se ejecuta si el proceso falla).
    cleanup()

if __name__ == "__main__":
    main()
