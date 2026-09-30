#!/usr/bin/env python3
"""Read or update niri window layout preferences (with backup, validation and rollback).

  window-config.py                 -> JSON with the current values
  window-config.py '<json>'        -> apply changes, keys:
      gaps: int 0..64
      center: never | always | on-overflow
      defaultWidth: "proportion 0.5" | "fixed 1200"
      presets: ["proportion 0.33333", "fixed 900", ...]
      apps: {"kitty": "proportion 0.5", "helium": null (= remove rule)}
      taskmgr: {"appIds": ["angelos.taskmgr", …], "width": "fixed 1200",
                "height": "fixed 760", "place": "center" | "corner"} | null (= no rule)

Per-app rules live in cfg/angelos-windows.kdl, included after rules.kdl so they win.
"""
import json
import os
import re
import shutil
import subprocess
import sys
import tempfile
from pathlib import Path

home = Path.home()
niri = home / ".config/niri"
layout_path = niri / "cfg/layout.kdl"
apps_path = niri / "cfg/angelos-windows.kdl"
config_path = niri / "config.kdl"
WIDTH = re.compile(r"^(proportion\s+(0?\.\d+|1(\.0+)?)|fixed\s+\d{2,5})$")


def value(text, key, default):
    m = re.search(r"^\s*" + re.escape(key) + r"\s+([^\n/{]+)", text, re.M)
    return m.group(1).strip().strip('"') if m else default


def block(text, name):
    """(start, end) of the body of the first `name { ... }` block."""
    m = re.search(r"^\s*" + re.escape(name) + r"\s*\{", text, re.M)
    if not m:
        return None
    depth, i = 0, m.end() - 1
    while i < len(text):
        if text[i] == "{":
            depth += 1
        elif text[i] == "}":
            depth -= 1
            if depth == 0:
                return m.end(), i
        i += 1
    return None


def width_of(body):
    m = re.search(r"(proportion\s+[\d.]+|fixed\s+\d+)", body or "")
    return re.sub(r"\s+", " ", m.group(1)) if m else ""


TM_BEGIN = "// >>> angelOS task manager (Настройки → System → Диспетчер задач)"
TM_END = "// <<< angelOS task manager"
HEIGHT = re.compile(r"^(proportion\s+(0?\.\d+|1(\.0+)?)|fixed\s+\d{2,5})$")


def read_taskmgr(text=None):
    """the task manager block of angelos-windows.kdl as a spec (None when absent)"""
    if text is None:
        text = apps_path.read_text() if apps_path.exists() else ""
    if TM_BEGIN not in text:
        return None
    body = text[text.index(TM_BEGIN):text.index(TM_END) if TM_END in text else len(text)]
    ids = [re.sub(r"\\(.)", r"\1", m) for m in re.findall(r'match app-id=r#"\^(.+?)\$"#', body)]
    w = re.search(r"default-column-width \{ ([^;]+); \}", body)
    h = re.search(r"default-window-height \{ ([^;]+); \}", body)
    return {
        "appIds": ids,
        "width": w.group(1).strip() if w else "",
        "height": h.group(1).strip() if h else "",
        "place": "corner" if "default-floating-position" in body else "center",
    }


def render_taskmgr(spec):
    if not spec:
        return ""
    ids = [a for a in spec.get("appIds") or [] if re.match(r"^[\w.+-]{1,120}$", a)]
    if not ids:
        return ""
    out = [TM_BEGIN, "window-rule {"]
    out += [f'    match app-id=r#"^{re.escape(a)}$"#' for a in ids]
    out.append("    open-floating true")
    if spec.get("width"):
        out.append(f"    default-column-width {{ {check_width(spec['width'])}; }}")
    if spec.get("height"):
        hgt = re.sub(r"\s+", " ", str(spec["height"]).strip())
        if not HEIGHT.match(hgt):
            raise ValueError("bad height: " + hgt)
        out.append(f"    default-window-height {{ {hgt}; }}")
    if spec.get("place") == "corner":
        out.append('    default-floating-position x=16 y=16 relative-to="bottom-right"')
    out += ["}", TM_END, ""]
    return "\n".join(out)


def read_apps():
    rules = {}
    if apps_path.exists():
        text = apps_path.read_text()
        if TM_BEGIN in text:  # the task manager block is not a per-app width
            text = text[:text.index(TM_BEGIN)] + (text[text.index(TM_END) + len(TM_END):] if TM_END in text else "")
        for m in re.finditer(r'match app-id=r#"\^(.+?)\$"#\s*\n\s*default-column-width \{ ([^;]+); \}', text):
            rules[re.sub(r"\\(.)", r"\1", m.group(1))] = m.group(2).strip()
    return rules


def current():
    text = layout_path.read_text()
    presets = []
    b = block(text, "preset-column-widths")
    if b:
        presets = [re.sub(r"\s+", " ", x.strip()) for x in re.findall(r"(proportion\s+[\d.]+|fixed\s+\d+)", text[b[0]:b[1]])]
    d = block(text, "default-column-width")
    return {
        "gaps": float(value(text, "gaps", "16")),
        "center": value(text, "center-focused-column", "never"),
        "defaultWidth": width_of(text[d[0]:d[1]]) if d else "",
        "presets": presets,
        "apps": read_apps(),
        "taskmgr": read_taskmgr(),
    }


def check_width(w):
    w = re.sub(r"\s+", " ", str(w).strip())
    if not WIDTH.match(w):
        raise ValueError("bad width: " + w)
    return w


def set_scalar(text, node, result):
    pattern = r"^(\s*)" + node + r'\s+(?:"[^"]*"|[\d.]+)'
    if re.search(pattern, text, re.M):
        return re.sub(pattern, lambda m: m[1] + node + " " + result, text, count=1, flags=re.M)
    new, n = re.subn(r"(\blayout\s*\{)", lambda m: m[1] + "\n        " + node + " " + result, text, count=1)
    if not n:
        raise ValueError("layout block not found")
    return new


def set_block(text, name, lines):
    body = "".join(f"\n            {l}" for l in lines) + "\n        "
    b = block(text, name)
    if b:
        return text[: b[0]] + body + text[b[1]:]
    new, n = re.subn(r"(\blayout\s*\{)", lambda m: m[1] + f"\n        {name} {{{body}}}", text, count=1)
    if not n:
        raise ValueError("layout block not found")
    return new


def render_apps(rules, taskmgr=None):
    out = ["// Managed by angelOS → Настройки → Окна. Per-app default widths.", ""]
    for app, w in sorted(rules.items()):
        out += ["window-rule {", f'    match app-id=r#"^{re.escape(app)}$"#', f"    default-column-width {{ {w}; }}", "}", ""]
    return "\n".join(out) + render_taskmgr(taskmgr)


def atomic_write(path, content):
    fd, name = tempfile.mkstemp(prefix=".angelos-", dir=path.parent)
    try:
        with os.fdopen(fd, "w") as f:
            f.write(content)
        if path.exists():
            os.chmod(name, path.stat().st_mode & 0o777)
        os.replace(name, path)
    finally:
        if os.path.exists(name):
            os.unlink(name)


def apply(changes):
    unknown = set(changes) - {"gaps", "center", "defaultWidth", "presets", "apps", "taskmgr"}
    if unknown:
        raise ValueError("unknown keys: " + ", ".join(sorted(unknown)))
    layout = layout_path.read_text()
    new_layout = layout
    if "gaps" in changes:
        g = int(changes["gaps"])
        if not 0 <= g <= 64:
            raise ValueError("gap out of range")
        new_layout = set_scalar(new_layout, "gaps", str(g))
    if "center" in changes:
        c = changes["center"]
        if c not in ("never", "always", "on-overflow"):
            raise ValueError("invalid centering")
        new_layout = set_scalar(new_layout, "center-focused-column", json.dumps(c))
    if "defaultWidth" in changes:
        new_layout = set_block(new_layout, "default-column-width", [check_width(changes["defaultWidth"])])
    if "presets" in changes:
        ps = [check_width(p) for p in changes["presets"]]
        if not ps:
            raise ValueError("need at least one preset")
        new_layout = set_block(new_layout, "preset-column-widths", ps)

    files = {layout_path: (layout, new_layout)} if new_layout != layout else {}
    if "apps" in changes or "taskmgr" in changes:
        rules = read_apps()
        for app, w in (changes.get("apps") or {}).items():
            if not re.match(r"^[\w.+-]{1,120}$", app):
                raise ValueError("bad app id: " + app)
            if w in (None, "", "default"):
                rules.pop(app, None)
            else:
                rules[app] = check_width(w)
        taskmgr = changes["taskmgr"] if "taskmgr" in changes else read_taskmgr()
        old_apps = apps_path.read_text() if apps_path.exists() else None
        files[apps_path] = (old_apps, render_apps(rules, taskmgr))
        cfg = config_path.read_text()
        if 'include "./cfg/angelos-windows.kdl"' not in cfg:
            anchor = 'include "./cfg/rules.kdl"'
            new_cfg = cfg.replace(anchor, anchor + '\ninclude "./cfg/angelos-windows.kdl"') if anchor in cfg else cfg + '\ninclude "./cfg/angelos-windows.kdl"\n'
            files[config_path] = (cfg, new_cfg)

    files = {p: v for p, v in files.items() if v[0] != v[1]}
    if not files:
        print("No changes")
        return
    # backup into a fresh folder, write, validate, roll back on failure
    backup_root = home / ".local/state/angelos/backups"
    backup_root.mkdir(parents=True, exist_ok=True)
    backup = Path(tempfile.mkdtemp(prefix="window-layout-", dir=backup_root))
    for path, (old, _new) in files.items():
        if old is not None:
            shutil.copy2(path, backup / path.name)
    # write the included file first so niri never sees a dangling include
    order = sorted(files, key=lambda p: p != apps_path)
    for path in order:
        atomic_write(path, files[path][1])
    p = subprocess.run(["niri", "validate"], capture_output=True, text=True)
    (backup / "validate.log").write_text(p.stdout + p.stderr)
    if p.returncode:
        for path in reversed(order):
            old = files[path][0]
            if old is None:
                path.unlink(missing_ok=True)
            else:
                atomic_write(path, old)
        raise RuntimeError("niri validate failed, rolled back: " + p.stderr.strip()[-300:])
    print("Saved · " + str(backup))


if __name__ == "__main__":
    if len(sys.argv) == 1:
        print(json.dumps(current()))
    else:
        apply(json.loads(sys.argv[1]))
