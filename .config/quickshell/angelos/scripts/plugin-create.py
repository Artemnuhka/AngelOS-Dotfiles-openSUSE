#!/usr/bin/env python3
"""Scaffold a plugin from plugins/_template (Settings → Plugins → New plugin).

  plugin-create.py <bundled plugins dir> <user plugins dir> <id> <name>

The name goes into JSON and QML string literals escaped for each, never into
a sed script or a shell command. Exit code 3: the id is taken.
"""
import json
from pathlib import Path
import re
import shutil
import sys
import tempfile


def main():
    bundled, user, pid, name = Path(sys.argv[1]), Path(sys.argv[2]), sys.argv[3], sys.argv[4] or sys.argv[3]
    if not re.fullmatch(r"[a-z0-9][a-z0-9_-]{0,47}", pid):
        return 2
    target = user / pid
    if target.exists() or (bundled / pid).exists():
        return 3
    user.mkdir(parents=True, exist_ok=True)
    literal = json.dumps(name[:80], ensure_ascii=False)[1:-1]   # valid inside "…" in JSON and QML
    staging = Path(tempfile.mkdtemp(prefix=".new-", dir=user))
    try:
        for source in (bundled / "_template").iterdir():
            if source.is_file() and not source.is_symlink():
                text = source.read_text().replace("__ID__", pid).replace("__NAME__", literal)
                (staging / source.name).write_text(text)
        json.loads((staging / "manifest.json").read_text())
        staging.chmod(0o755)
        staging.rename(target)
    finally:
        if staging.exists():
            shutil.rmtree(staging)
    return 0


if __name__ == "__main__":
    sys.exit(main())
