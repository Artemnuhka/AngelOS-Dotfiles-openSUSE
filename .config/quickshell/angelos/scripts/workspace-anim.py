#!/usr/bin/env python3
"""Read or set niri's workspace-switch animation (cfg/animation.kdl).

  workspace-anim.py            -> {"preset": "soft" | "slide" | "bounce" | "instant" | "custom"}
  workspace-anim.py <preset>   -> write it: staged copy validated with `niri validate`,
                                  backup under ~/.local/state/angelos/backups/anim-*,
                                  rollback if the final validation fails.
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
    "soft": "spring damping-ratio=0.82 stiffness=650 epsilon=0.0001",
    "slide": "spring damping-ratio=1.0 stiffness=900 epsilon=0.0001",
    "bounce": "spring damping-ratio=0.42 stiffness=520 epsilon=0.0001",
    "instant": "off",
}
CONFIG = Path.home() / ".config/niri/config.kdl"
ANIMATIONS = CONFIG.parent / "cfg/animation.kdl"
BACKUPS = Path.home() / ".local/state/angelos/backups"
BLOCK = re.compile(r"(?m)^([ \t]*)workspace-switch\s*\{([^{}]*)\}")


def normalize(body):
    return re.sub(r"\s+", " ", body).strip()


def current(text):
    match = BLOCK.search(text)
    if not match:
        return "soft"   # niri's own default spring is closest to "soft"
    body = normalize(match.group(2))
    return next((name for name, value in PRESETS.items() if normalize(value) == body), "custom")


def update(text, preset):
    body = PRESETS[preset]
    match = BLOCK.search(text)
    if match:
        indent = match.group(1)
        block = f"{indent}workspace-switch {{\n{indent}    {body}\n{indent}}}"
        return text[:match.start()] + block + text[match.end():]
    opening = re.search(r"(?m)^([ \t]*)animations\s*\{", text)
    if not opening:
        raise ValueError("animations block not found in cfg/animation.kdl")
    indent = opening.group(1) + "    "
    insert = f"\n{indent}workspace-switch {{\n{indent}    {body}\n{indent}}}"
    return text[:opening.end()] + insert + text[opening.end():]


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


def save(preset):
    if preset not in PRESETS:
        raise ValueError("unknown preset: " + preset)
    BACKUPS.mkdir(parents=True, exist_ok=True)
    with (BACKUPS / ".anim.lock").open("w") as lock:
        fcntl.flock(lock, fcntl.LOCK_EX)
        text = ANIMATIONS.read_text()
        updated = update(text, preset)
        if updated == text:
            return "Unchanged"
        with tempfile.TemporaryDirectory(prefix="angelos-anim-") as tmp:
            staged = Path(tmp) / "niri"
            shutil.copytree(CONFIG.parent, staged)
            (staged / "cfg/animation.kdl").write_text(updated)
            validate(staged / CONFIG.name)
        backup = Path(tempfile.mkdtemp(prefix="anim-", dir=BACKUPS))
        shutil.copy2(ANIMATIONS, backup / ANIMATIONS.name)
        if ANIMATIONS.read_text() != text:
            raise RuntimeError("animation.kdl changed during validation; try again")
        atomic_write(ANIMATIONS, updated)
        try:
            validate(CONFIG)
        except Exception:
            if ANIMATIONS.read_text() == updated:
                atomic_write(ANIMATIONS, text)
            raise
        return "Saved · " + str(backup)


def main():
    try:
        if len(sys.argv) == 1:
            print(json.dumps({"preset": current(ANIMATIONS.read_text())}))
        else:
            print(json.dumps({"ok": save(sys.argv[1])}))
    except (OSError, ValueError, RuntimeError) as error:
        print(json.dumps({"error": str(error)}))
        return 1
    return 0


if __name__ == "__main__":
    sys.exit(main())
