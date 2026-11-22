#!/usr/bin/env python3
"""NEXORA Upgrade Assistant: read-only preflight for future release upgrades.

This prototype deliberately does not change APT sources, install/remove packages,
or migrate Debian/NEXORA releases. It only inspects the current system and runs
an APT simulation when available.
"""
from __future__ import annotations

import argparse
import platform
import shutil
import subprocess
import sys
from pathlib import Path


def read_os_release() -> dict[str, str]:
    data: dict[str, str] = {}
    path = Path("/etc/os-release")
    if not path.exists():
        return data
    for line in path.read_text(encoding="utf-8", errors="replace").splitlines():
        if "=" not in line or line.startswith("#"):
            continue
        key, value = line.split("=", 1)
        data[key] = value.strip().strip('"')
    return data


def read_nexora_version() -> str:
    path = Path("/etc/nexora-release")
    if not path.exists():
        return "No detectada (esta instalación puede ser una versión antigua)"
    return path.read_text(encoding="utf-8", errors="replace").strip() or "No detectada"


def run_simulation() -> tuple[int, str]:
    if not shutil.which("apt-get"):
        return 127, "apt-get no está disponible."
    try:
        result = subprocess.run(
            ["apt-get", "--simulate", "dist-upgrade"],
            text=True,
            stdout=subprocess.PIPE,
            stderr=subprocess.STDOUT,
            timeout=90,
            check=False,
        )
        return result.returncode, result.stdout
    except subprocess.TimeoutExpired:
        return 124, "La simulación de APT superó los 90 segundos."
    except OSError as exc:
        return 1, str(exc)


def main() -> int:
    parser = argparse.ArgumentParser(
        description="Evalúa el estado del sistema antes de una futura migración NEXORA."
    )
    parser.add_argument(
        "--no-apt-simulation",
        action="store_true",
        help="No ejecutar la simulación de paquetes APT.",
    )
    args = parser.parse_args()

    os_info = read_os_release()
    print("NEXORA OS — Upgrade Assistant")
    print("=" * 36)
    print(f"Versión NEXORA: {read_nexora_version()}")
    print(f"Sistema base: {os_info.get('PRETTY_NAME', 'Desconocido')}")
    print(f"Codename Debian: {os_info.get('VERSION_CODENAME', 'Desconocido')}")
    print(f"Arquitectura: {platform.machine()}")
    print()

    blockers: list[str] = []
    if os_info.get("ID") != "debian":
        blockers.append("La base detectada no es Debian; no hay ruta de migración definida.")
    if os_info.get("VERSION_CODENAME") != "trixie":
        blockers.append("Esta versión de Debian no tiene una ruta de migración validada.")
    if platform.machine() not in {"x86_64", "amd64"}:
        blockers.append("Esta compilación solo tiene como objetivo amd64.")

    if args.no_apt_simulation:
        print("APT: simulación omitida por solicitud.")
    else:
        print("Comprobando cambios de paquetes (solo simulación APT)...")
        code, output = run_simulation()
        if code == 0:
            print("APT: simulación completada; no se instaló ni eliminó nada.")
            interesting = [
                line for line in output.splitlines()
                if line.startswith(("Inst ", "Remv ", "Conf "))
            ]
            if interesting:
                print(f"Operaciones previstas: {len(interesting)}")
                for line in interesting[:20]:
                    print("  " + line)
                if len(interesting) > 20:
                    print(f"  ... y {len(interesting) - 20} operaciones más.")
            else:
                print("No se detectaron operaciones pendientes en la simulación.")
        else:
            print(f"APT: no se pudo completar la simulación (código {code}).")
            print(output[-2500:])
            blockers.append("No se pudo verificar el estado de paquetes APT.")

    print()
    print("ESTADO DE MIGRACIÓN")
    print("-" * 36)
    if blockers:
        for item in blockers:
            print(f"[BLOQUEO] {item}")
    print("[INFORMACIÓN] La migración entre versiones de NEXORA todavía no está habilitada.")
    print("[INFORMACIÓN] Esta herramienta no cambia repositorios ni actualiza la distribución.")
    print("[INFORMACIÓN] Para actualizaciones normales, utiliza el gestor de paquetes de Debian.")
    print()
    print("Resultado: diagnóstico completado; no se modificó el sistema.")
    return 0


if __name__ == "__main__":
    sys.exit(main())
