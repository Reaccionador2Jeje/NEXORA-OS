#!/usr/bin/python3
"""NEXORA OS disk installation engine. Destructive operations require explicit GUI confirmation."""
import os
import re
import shutil
import subprocess
import sys
import time
from pathlib import Path

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
    if efi:
        (target / "boot/efi").mkdir(parents=True, exist_ok=True)
        run(["mount", efi_part, str(target / "boot/efi")])

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
    hosts = target / "etc/hosts"
    hosts.write_text("127.0.0.1 localhost\n127.0.1.1 " + hostname + "\n\n::1 localhost ip6-localhost ip6-loopback\n", encoding="utf-8")

    print("Configurando la cuenta y el arranque…", flush=True)
    for mount in ("dev", "dev/pts", "proc", "sys", "run"):
        (target / mount).mkdir(parents=True, exist_ok=True)
        run(["mount", "--bind", "/" + mount, str(target / mount)])
    chroot = ["chroot", str(target)]
    if run(chroot + ["id", "-u", username], check=False).returncode != 0:
        run(chroot + ["useradd", "-m", "-s", "/bin/bash", "-G", "sudo,adm,audio,video,plugdev,netdev", username])
    else:
        run(chroot + ["usermod", "-aG", "sudo,adm,audio,video,plugdev,netdev", username])
    run(chroot + ["chpasswd"], input_text=username + ":" + password + "\n")
    password = ""
    run(chroot + ["passwd", "-l", "root"], check=False)
    run(chroot + ["systemctl", "enable", "NetworkManager", "lightdm", "nexora-postinstall.service"], check=False)
    run(chroot + ["systemctl", "set-default", "graphical.target"], check=False)
    if efi:
        run(chroot + ["grub-install", "--target=x86_64-efi", "--efi-directory=/boot/efi",
                      "--bootloader-id=NEXORA", "--recheck"])
    else:
        run(chroot + ["grub-install", "--target=i386-pc", disk])
    run(chroot + ["update-grub"])
    print("Instalación terminada. Puedes reiniciar y retirar el medio Live.", flush=True)
    # Desmontaje en orden inverso.
    for mount in ("run", "sys", "proc", "dev/pts", "dev"):
        run(["umount", "-lf", str(target / mount)], check=False)
    if efi:
        run(["umount", "-lf", str(target / "boot/efi")], check=False)
    run(["umount", "-lf", str(target)], check=False)

if __name__ == "__main__":
    main()
