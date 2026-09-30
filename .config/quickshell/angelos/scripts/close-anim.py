#!/usr/bin/env python3
"""Read or set niri's window-close animation (cfg/animation.kdl).

  close-anim.py            -> {"preset": "<name>|custom"}
  close-anim.py <preset>   -> write it: a staged copy is validated with
                              `niri validate`, the old file is backed up under
                              ~/.local/state/angelos/backups/close-anim-*, and
                              restored if the final validation fails.

Presets: default (niri's fade + shrink), off, and angelOS shaders from
shaders/close/*.glsl (pixel, heart, fall, glitch, crt, minimize). niri compiles
the shader when it loads the config; a broken one only logs a warning and falls
back to the default animation.
"""
import fcntl
import json
import os
from pathlib import Path
import re
import shutil
import subprocess
import sys
import tempfile

HERE = Path(__file__).resolve().parent
SHADERS = HERE.parent / "shaders/close"
CONFIG = Path.home() / ".config/niri/config.kdl"
ANIMATIONS = CONFIG.parent / "cfg/animation.kdl"
BACKUPS = Path.home() / ".local/state/angelos/backups"
MARK = "// angelOS close: "
# curve and length per preset; shader presets ease inside the shader
TIMING = {
    "default": ('duration-ms 220', 'curve "ease-out-quad"'),
    "pixel": ('duration-ms 460', 'curve "linear"'),
    "heart": ('duration-ms 420', 'curve "linear"'),
    "fall": ('duration-ms 520', 'curve "linear"'),
    "glitch": ('duration-ms 380', 'curve "linear"'),
    "crt": ('duration-ms 440', 'curve "linear"'),
    "minimize": ('duration-ms 340', 'curve "linear"'),
}


def presets():
    return ["default", "off"] + sorted(p.stem for p in SHADERS.glob("*.glsl"))


def find_block(text, name):
    """(start of line, end after '}') of `name { … }` — skips KDL strings, so the
    braces of a GLSL shader inside r#"…"# don't count"""
    m = re.search(r"(?m)^([ \t]*)" + re.escape(name) + r"\s*\{", text)
    if not m:
        return None
    i, depth = m.end() - 1, 0
    while i < len(text):
        if text.startswith('r#"', i):
            j = text.find('"#', i + 3)
            i = len(text) if j < 0 else j + 2
            continue
        if text.startswith('r"', i):
            j = text.find('"', i + 2)
            i = len(text) if j < 0 else j + 1
            continue
        c = text[i]
        if c == '"':
            i += 1
            while i < len(text) and text[i] != '"':
                i += 2 if text[i] == "\\" else 1
        elif c == "/" and text.startswith("//", i):
            j = text.find("\n", i)
            i = len(text) if j < 0 else j
            continue
        elif c == "{":
            depth += 1
        elif c == "}":
            depth -= 1
            if depth == 0:
                return m.start(), i + 1, m.group(1)
        i += 1
    return None


def current(text):
    b = find_block(text, "window-close")
    if not b:
        return "default"
    body = text[b[0]:b[1]]
    m = re.search(re.escape(MARK) + r"(\w+)", body)
    if m:
        return m.group(1)
    if re.search(r"\{\s*off\s*;?\s*\}", body) or re.search(r"(?m)^\s*off\s*$", body):
        return "off"
    if "custom-shader" in body:
        return "custom"
    return "default"


def render(preset, indent):
    inner = indent + "    "
    if preset == "off":
        return f"{indent}window-close {{\n{inner}{MARK}off\n{inner}off\n{indent}}}"
    lines = [f"{indent}window-close {{", f"{inner}{MARK}{preset}"]
    lines += [inner + t for t in TIMING.get(preset, TIMING["default"])]
    if preset != "default":
        code = (SHADERS / f"{preset}.glsl").read_text()
        if '"#' in code:
            raise ValueError("shader must not contain \"#")
        lines.append(inner + 'custom-shader r#"')
        lines += [(inner + "    " + l) if l.strip() else "" for l in code.strip("\n").splitlines()]
        lines.append(inner + '"#')
    lines.append(indent + "}")
    return "\n".join(lines)


def update(text, preset):
    b = find_block(text, "window-close")
    if b:
        return text[:b[0]] + render(preset, b[2]) + text[b[1]:]
    opening = re.search(r"(?m)^([ \t]*)animations\s*\{", text)
    if not opening:
        raise ValueError("animations block not found in cfg/animation.kdl")
    return text[:opening.end()] + "\n" + render(preset, opening.group(1) + "    ") + text[opening.end():]


def validate(config):
    result = subprocess.run(["niri", "validate", "-c", str(config)], capture_output=True, text=True)
    if result.returncode:
        raise ValueError((result.stderr or result.stdout).strip()[-400:])


def atomic_write(path, content):
    fd, name = tempfile.mkstemp(prefix=".close-anim-", dir=path.parent)
    try:
        with os.fdopen(fd, "w") as stream:
            stream.write(content)
        os.chmod(name, path.stat().st_mode & 0o777)
        os.replace(name, path)
    finally:
        if os.path.exists(name):
            os.unlink(name)


def save(preset):
    if preset not in presets():
        raise ValueError("unknown preset: " + preset)
    BACKUPS.mkdir(parents=True, exist_ok=True)
    # the same lock as workspace-anim.py: both edit cfg/animation.kdl
    with (BACKUPS / ".anim.lock").open("w") as lock:
        fcntl.flock(lock, fcntl.LOCK_EX)
        old = ANIMATIONS.read_text()
        new = update(old, preset)
        if new == old:
            return "Unchanged"
        with tempfile.TemporaryDirectory(prefix="angelos-close-") as tmp:
            staged = Path(tmp) / "niri"
            shutil.copytree(CONFIG.parent, staged)
            (staged / ANIMATIONS.relative_to(CONFIG.parent)).write_text(new)
            validate(staged / CONFIG.name)
        backup = Path(tempfile.mkdtemp(prefix="close-anim-", dir=BACKUPS))
        shutil.copy2(ANIMATIONS, backup / ANIMATIONS.name)
        if ANIMATIONS.read_text() != old:
            raise RuntimeError("animation.kdl changed during validation; try again")
        atomic_write(ANIMATIONS, new)
        try:
            validate(CONFIG)
        except Exception:
            if ANIMATIONS.read_text() == new:
                atomic_write(ANIMATIONS, old)
            raise
        return "Saved · " + str(backup)


def main():
    try:
        if len(sys.argv) == 1:
            print(json.dumps({"preset": current(ANIMATIONS.read_text()), "presets": presets()}))
        else:
            print(json.dumps({"ok": save(sys.argv[1])}))
    except (OSError, ValueError, RuntimeError) as error:
        print(json.dumps({"error": str(error)}))
        return 1
    return 0


if __name__ == "__main__":
    sys.exit(main())
