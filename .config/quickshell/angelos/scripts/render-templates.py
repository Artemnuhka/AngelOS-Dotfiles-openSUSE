#!/usr/bin/env python3
"""Render angelOS theme templates.

usage: render-templates.py PALETTE.json [DISABLED_IDS_COMMA_SEPARATED]

Templates are listed in <shell>/templates/templates.json and in
~/.config/angelos/templates/*.json (user entries override by id).
Placeholders: {{key}} -> "#rrggbb", {{key.strip}} -> "rrggbb", plus
{{mode}} (light|dark), {{flavor}}, {{gtkSuffix}} ("-dark" or "").
"""
import json
import os
import re
import shlex
import subprocess
import sys
from pathlib import Path

SHELL = Path(__file__).resolve().parent.parent
USER = Path.home() / ".config/angelos/templates"


def load_entries():
    entries = {}
    sources = [(SHELL / "templates/templates.json", SHELL / "templates")]
    if USER.is_dir():
        sources += [(p, USER) for p in sorted(USER.glob("*.json"))]
    for path, base in sources:
        try:
            data = json.loads(path.read_text())
        except (OSError, ValueError) as e:
            print(f"skip {path}: {e}", file=sys.stderr)
            continue
        for e in data if isinstance(data, list) else [data]:
            e["_base"] = str(base)
            entries[e["id"]] = e
    return list(entries.values())


def render(text, pal, quote=None):
    def sub(m):
        key, _, mod = m.group(1).partition(".")
        val = str(pal.get(key, m.group(0)))
        val = val.lstrip("#") if mod == "strip" else val
        # values that reach `sh -c` must stay single words (the flavor comes from settings.json)
        return quote(val) if quote and not re.fullmatch(r"[\w#.-]*", val) else val
    return re.sub(r"\{\{\s*([\w.]+)\s*\}\}", sub, text)


def main():
    pal = json.loads(Path(sys.argv[1]).read_text())
    pal["gtkSuffix"] = "-dark" if pal.get("mode") == "dark" else ""
    disabled = set(filter(None, (sys.argv[2] if len(sys.argv) > 2 else "").split(",")))
    for e in load_entries():
        if e["id"] in disabled:
            continue
        try:
            if e.get("template"):
                src = Path(e["_base"]) / e["template"]
                dst = Path(os.path.expanduser(e["target"]))
                dst.parent.mkdir(parents=True, exist_ok=True)
                out = render(src.read_text(), pal)
                if not dst.exists() or dst.read_text() != out:
                    tmp = dst.with_suffix(dst.suffix + ".angelos-tmp")
                    tmp.write_text(out)
                    tmp.replace(dst)
                    print(f"wrote {dst}")
            for key in ("command", "reload"):
                if e.get(key):
                    subprocess.run(["sh", "-c", render(e[key], pal, shlex.quote)], stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL, timeout=10)
        except Exception as ex:  # keep going with the other templates
            print(f"{e['id']}: {ex}", file=sys.stderr)


if __name__ == "__main__":
    main()
