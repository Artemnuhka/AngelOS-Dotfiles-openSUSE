#!/usr/bin/env python3
"""Read or set niri's workspace-switch animation (cfg/animation.kdl) and whether
the workspace keys go through angelOS (cfg/keybinds.kdl).

  workspace-anim.py                          -> {"preset": "soft|dash|instant|custom", "routed": bool}
  workspace-anim.py <preset> [--route|--native]
      write it: a staged copy is validated with `niri validate`, the old files are
      backed up under ~/.local/state/angelos/backups/anim-*, and restored if the
      final validation fails.

--route turns `focus-workspace N / -up / -down / -previous` binds into
`spawn-sh "exec …/bin/angelos ws N"` (the shell captures the screen for its
transition, then asks niri to switch; niri is called directly if the shell is
not running). --native turns them back.
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

PRESETS = {
    # ease-out-quint: starts right away, settles softly
    "soft": 'duration-ms 380\ncurve "cubic-bezier" 0.22 1 0.36 1',
    # slow start, a dash, a tidy stop
    "dash": 'duration-ms 460\ncurve "cubic-bezier" 0.8 0 0.12 1',
    "instant": "off",
}
CONFIG = Path.home() / ".config/niri/config.kdl"
ANIMATIONS = CONFIG.parent / "cfg/animation.kdl"
KEYBINDS = CONFIG.parent / "cfg/keybinds.kdl"
BACKUPS = Path.home() / ".local/state/angelos/backups"
BLOCK = re.compile(r"(?m)^([ \t]*)workspace-switch\s*\{([^{}]*)\}")
ANGELOS = "exec ~/.config/quickshell/angelos/bin/angelos ws "
NATIVE_ACTIONS = {"up": "focus-workspace-up", "down": "focus-workspace-down", "prev": "focus-workspace-previous"}
NATIVE_RE = re.compile(r"\{\s*(focus-workspace(?:-up|-down|-previous)?)(?:\s+(\d{1,2}))?\s*;\s*\}")
ROUTED_RE = re.compile(r'\{\s*spawn-sh\s+"' + re.escape(ANGELOS) + r'(\d{1,2}|up|down|prev)"\s*;\s*\}')


def normalize(body):
    return re.sub(r"\s+", " ", body).strip()


def current(text):
    match = BLOCK.search(text)
    if not match:
        return "soft"
    body = normalize(match.group(2))
    return next((name for name, value in PRESETS.items() if normalize(value) == body), "custom")


def update(text, preset):
    body = PRESETS[preset]
    match = BLOCK.search(text)
    indent = match.group(1) if match else None
    if indent is None:
        opening = re.search(r"(?m)^([ \t]*)animations\s*\{", text)
        if not opening:
            raise ValueError("animations block not found in cfg/animation.kdl")
        indent = opening.group(1) + "    "
    lines = "\n".join(f"{indent}    {line}" for line in body.splitlines())
    block = f"{indent}workspace-switch {{\n{lines}\n{indent}}}"
    if match:
        return text[:match.start()] + block + text[match.end():]
    return text[:opening.end()] + "\n" + block + text[opening.end():]


def routed(text):
    return bool(ROUTED_RE.search(text))


def route(text, on):
    def to_angelos(m):
        action, num = m.group(1), m.group(2)
        target = num if action == "focus-workspace" and num else {v: k for k, v in NATIVE_ACTIONS.items()}.get(action)
        if not target:
            return m.group(0)
        return '{ spawn-sh "' + ANGELOS + target + '"; }'

    def to_niri(m):
        target = m.group(1)
        return "{ " + (f"focus-workspace {target}" if target.isdigit() else NATIVE_ACTIONS[target]) + "; }"

    out = []
    for line in text.splitlines(keepends=True):
        # only plain Mod+<key> workspace binds; move-column/move-window binds stay as they are
        if on and NATIVE_RE.search(line) and not line.lstrip().startswith("//"):
            line = NATIVE_RE.sub(to_angelos, line)
        elif not on and ROUTED_RE.search(line):
            line = ROUTED_RE.sub(to_niri, line)
        out.append(line)
    return "".join(out)


def validate(config):
    result = subprocess.run(["niri", "validate", "-c", str(config)], capture_output=True, text=True)
    if result.returncode:
        raise ValueError((result.stderr or result.stdout).strip()[-400:])


def atomic_write(path, content):
    fd, name = tempfile.mkstemp(prefix=".anim-", dir=path.parent)
    try:
        with os.fdopen(fd, "w") as stream:
            stream.write(content)
        os.chmod(name, path.stat().st_mode & 0o777)
        os.replace(name, path)
    finally:
        if os.path.exists(name):
            os.unlink(name)


def save(preset, route_mode):
    if preset not in PRESETS:
        raise ValueError("unknown preset: " + preset)
    BACKUPS.mkdir(parents=True, exist_ok=True)
    with (BACKUPS / ".anim.lock").open("w") as lock:
        fcntl.flock(lock, fcntl.LOCK_EX)
        old = {ANIMATIONS: ANIMATIONS.read_text(), KEYBINDS: KEYBINDS.read_text()}
        new = {ANIMATIONS: update(old[ANIMATIONS], preset), KEYBINDS: old[KEYBINDS]}
        if route_mode is not None:
            new[KEYBINDS] = route(old[KEYBINDS], route_mode)
        changed = [p for p in new if new[p] != old[p]]
        if not changed:
            return "Unchanged"
        with tempfile.TemporaryDirectory(prefix="angelos-anim-") as tmp:
            staged = Path(tmp) / "niri"
            shutil.copytree(CONFIG.parent, staged)
            for path in changed:
                (staged / path.relative_to(CONFIG.parent)).write_text(new[path])
            validate(staged / CONFIG.name)
        backup = Path(tempfile.mkdtemp(prefix="anim-", dir=BACKUPS))
        for path in changed:
            shutil.copy2(path, backup / path.name)
            if path.read_text() != old[path]:
                raise RuntimeError(path.name + " changed during validation; try again")
        for path in changed:
            atomic_write(path, new[path])
        try:
            validate(CONFIG)
        except Exception:
            for path in changed:
                if path.read_text() == new[path]:
                    atomic_write(path, old[path])
            raise
        return "Saved · " + str(backup)


def main():
    try:
        if len(sys.argv) == 1:
            print(json.dumps({"preset": current(ANIMATIONS.read_text()), "routed": routed(KEYBINDS.read_text())}))
        else:
            mode = True if "--route" in sys.argv else False if "--native" in sys.argv else None
            print(json.dumps({"ok": save(sys.argv[1], mode)}))
    except (OSError, ValueError, RuntimeError) as error:
        print(json.dumps({"error": str(error)}))
        return 1
    return 0


if __name__ == "__main__":
    sys.exit(main())
