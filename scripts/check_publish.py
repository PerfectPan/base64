#!/usr/bin/env python3
"""Rehearse publishing, accepting only the known Mooncakes 202 CLI mismatch."""

import argparse
import json
from pathlib import Path
import re
import subprocess
import sys


def _module_identity(root):
    # This is deliberately not a full moon.mod parser: only the repository's
    # canonical, top-level, single-line quoted fields are safe to match here.
    source = (root / "moon.mod").read_text(encoding="utf-8")
    identity = {}
    for key in ("name", "version"):
        lines = re.findall(rf"(?m)^[ \t]*{key}[ \t]*=.*$", source)
        if len(lines) != 1:
            raise ValueError(f"expected exactly one top-level {key} field")
        match = re.fullmatch(rf'{key}[ \t]*=[ \t]*("(?:[^"\\\r\n]|\\.)*")[ \t]*', lines[0])
        if match is None:
            raise ValueError(f"unsupported {key} field format")
        value = json.loads(match[1])
        if not value or any(ord(char) < 32 for char in value):
            raise ValueError(f"invalid {key} field")
        identity[key] = value
    return identity["name"], identity["version"]


def main():
    argparse.ArgumentParser(description=__doc__).parse_args()
    root = Path(__file__).resolve().parent.parent
    try:
        name, version = _module_identity(root)
    except (OSError, UnicodeError, ValueError) as error:
        print(f"Error: cannot read canonical module identity: {error}", file=sys.stderr)
        return 1
    try:
        result = subprocess.run(
            ["moon", "publish", "--dry-run"], cwd=root,
            stdout=subprocess.PIPE, stderr=subprocess.STDOUT, check=False,
        )
    except OSError as error:
        print(f"Error: cannot run moon publish --dry-run: {error}", file=sys.stderr)
        return 1
    sys.stdout.buffer.write(result.stdout)
    sys.stdout.buffer.flush()
    if result.returncode == 0:
        return 0
    receipt = (
        "Server status: 202 Accepted, detail: Dry run completed successfully. "
        "No changes were made. The dry-run was made for package "
        f"{name} version {version}."
    )
    lines = result.stdout.decode("utf-8", errors="replace").splitlines()
    conflict = re.compile(r"\b(?:error|failed|failure)\b|\bserver\s+status\b", re.IGNORECASE)
    if (
        result.returncode == 255
        and lines[-2:] == [receipt, "Error: `moon publish` failed"]
        and not any(conflict.search(line) for line in lines[:-2])
    ):
        if not result.stdout.endswith(b"\n"):
            print()
        print("check_publish: accepted the exact 202 dry-run success receipt "
              "despite CLI exit 255; no release was published.")
        return 0
    return result.returncode if result.returncode > 0 else 128 - result.returncode


if __name__ == "__main__":
    sys.exit(main())
