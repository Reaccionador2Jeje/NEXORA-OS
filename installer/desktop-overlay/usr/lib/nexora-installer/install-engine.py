#!/usr/bin/python3
"""NEXORA OS disk installation engine. Destructive operations require explicit GUI confirmation."""
import atexit
import os
import re
import shutil
import subprocess
import sys
import time
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

def main():
    if os.geteuid() != 0:
        fail("El motor debe ejecutarse con permisos administrativos.")
    if len(sys.argv) != 5:
        fail("Uso interno incorrecto.")
    disk, username, hostname, secret_file = sys.argv[1:]
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
    (target / "etc/default/locale").write_text('LANG="es_CL.UTF-8"\n', encoding="utf-8")
    (target / "etc/default/keyboard").write_text(
        'XKBMODEL="pc105"\nXKBLAYOUT="latam"\nXKBVARIANT=""\nXKBOPTIONS=""\nBACKSPACE="guess"\n',
        encoding="utf-8",
    )
    (target / "etc/timezone").write_text("America/Santiago\n", encoding="utf-8")
    hosts = target / "etc/hosts"
    hosts.write_text("127.0.0.1 localhost\n127.0.1.1 " + hostname + "\n\n::1 localhost ip6-localhost ip6-loopback\n", encoding="utf-8")

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
    run(chroot + ["locale-gen", "es_CL.UTF-8"], check=False)
    run(chroot + ["ln", "-sf", "/usr/share/zoneinfo/America/Santiago", "/etc/localtime"], check=False)
    run(chroot + ["chpasswd"], input_text=username + ":" + password + "\n")
    password = ""
    # Remove the temporary Live-session account when the user chose another name.
    if username != "nexora" and run(chroot + ["id", "-u", "nexora"], check=False).returncode == 0:
        run(chroot + ["userdel", "-r", "nexora"], check=False)
    # The Live image machine-id must not be cloned to installed systems.
    (target / "etc/machine-id").write_text("", encoding="utf-8")
    run(chroot + ["passwd", "-l", "root"], check=False)
    run(chroot + ["systemctl", "enable", "NetworkManager", "lightdm"], check=False)
    run(chroot + ["systemctl", "set-default", "graphical.target"], check=False)
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
