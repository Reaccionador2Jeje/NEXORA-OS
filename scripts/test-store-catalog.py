#!/usr/bin/env python3
"""Validate the NEXORA Store catalog before building an ISO."""

import json
import re
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
CATALOG = ROOT / "config/includes.chroot/usr/share/nexora-store/catalog.json"
APP_ID = re.compile(r"^[A-Za-z][A-Za-z0-9_-]*(?:\.[A-Za-z][A-Za-z0-9_-]*){2,}$")
CATEGORIES = {
    "Productivity",
    "Graphics",
    "Development",
    "Multimedia",
    "Games",
    "System",
}


def fail(message: str) -> None:
    print(f"[FAIL] {message}", file=sys.stderr)
    raise SystemExit(1)


def main() -> None:
    try:
        data = json.loads(CATALOG.read_text(encoding="utf-8"))
    except (OSError, json.JSONDecodeError) as error:
        fail(f"Cannot read catalog JSON: {error}")

    if data.get("schema") != 1:
        fail("Unsupported or missing catalog schema (expected 1).")

    applications = data.get("applications")
    if not isinstance(applications, list) or not applications:
        fail("Catalog must contain a non-empty applications array.")

    seen = set()
    for index, app in enumerate(applications, start=1):
        if not isinstance(app, dict):
            fail(f"Application #{index} must be a JSON object.")

        app_id = app.get("id")
        name = app.get("name")
        category = app.get("category")
        description = app.get("description", "")

        if not isinstance(app_id, str) or not APP_ID.fullmatch(app_id):
            fail(f"Application #{index} has an invalid Flatpak ID: {app_id!r}")
        if app_id in seen:
            fail(f"Duplicate Flatpak application ID: {app_id}")
        seen.add(app_id)

        if not isinstance(name, str) or not name.strip():
            fail(f"{app_id} has no valid display name.")
        if category not in CATEGORIES:
            fail(f"{app_id} uses an unsupported category: {category!r}")
        if not isinstance(description, str):
            fail(f"{app_id} description must be a string.")

    print(f"[OK] NEXORA Store catalog: {len(applications)} unique applications validated.")


if __name__ == "__main__":
    main()
