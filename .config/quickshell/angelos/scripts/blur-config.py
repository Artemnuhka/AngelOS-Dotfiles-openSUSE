#!/usr/bin/env python3
"""Adjust niri's existing blur block, validating a staged config before writing."""
import argparse
import fcntl
import json
import math
import os
from pathlib import Path
import re
import shutil
import subprocess
import tempfile

DEFAULTS = {"passes": 3, "offset": 3.0, "noise": 0.018, "saturation": 1.0}
LIMITS = {"passes": (1, 6), "offset": (0.5, 10), "noise": (0, 0.1), "saturation": (0, 2)}


def block(text):
    match = re.search(r"(?m)^\s*blur\s*\{[^{}]*\}", text)
    if not match:
        raise ValueError("Blur block not found in cfg/misc.kdl")
    return match


def read(text):
    content = block(text).group()
    result = dict(DEFAULTS)
    for key in result:
        match = re.search(r"(?m)^\s*" + key + r"\s+([0-9.]+)", content)
        if match:
            result[key] = float(match[1])
    result["passes"] = int(result["passes"])
    return result


def update(text, changes):
    if not changes or set(changes) - DEFAULTS.keys():
        raise ValueError("Unknown or empty blur preference")
    match = block(text)
    content = match.group()
    for key, raw in changes.items():
        value = float(raw)
        lo, hi = LIMITS[key]
        if not math.isfinite(value) or not lo <= value <= hi:
            raise ValueError("Blur value out of range: " + key)
        if key == "passes" and value != int(value):
            raise ValueError("Passes must be an integer")
        number = str(int(value)) if key == "passes" else str(value)
        pattern = r"(?m)^([ \t]*" + key + r"\s+)[0-9.]+"
        content, count = re.subn(pattern, lambda m: m[1] + number, content, count=1)
        if not count:
            content = content[:-1] + "    " + key + " " + number + "\n}"
    return text[:match.start()] + content + text[match.end():]


def atomic_write(path, content):
    fd, name = tempfile.mkstemp(prefix=".blur-", dir=path.parent)
    try:
        with os.fdopen(fd, "w") as stream:
            stream.write(content)
        os.chmod(name, path.stat().st_mode & 0o777)
        os.replace(name, path)
    finally:
        if os.path.exists(name):
            os.unlink(name)


def save(config, changes, backup_root):
    path = config.parent / "cfg/misc.kdl"
    backup_root.mkdir(parents=True, exist_ok=True)
    with (backup_root / ".blur.lock").open("w") as lock:
        fcntl.flock(lock, fcntl.LOCK_EX)
        text = path.read_text()
        updated = update(text, changes)
        if updated == text:
            return "Unchanged"
        with tempfile.TemporaryDirectory(prefix="angelos-blur-") as tmp:
            staged = Path(tmp) / "niri"
            shutil.copytree(config.parent, staged)
            (staged / "cfg/misc.kdl").write_text(updated)
            result = subprocess.run(["niri", "validate", "-c", str(staged / config.name)],
                                    capture_output=True, text=True)
            if result.returncode:
                raise ValueError(result.stderr or result.stdout)
        backup = Path(tempfile.mkdtemp(prefix="blur-", dir=backup_root))
        shutil.copy2(path, backup / path.name)
        (backup / "validate.log").write_text(result.stdout + result.stderr)
        if path.read_text() != text:
            raise RuntimeError("Configuration changed during validation; try again")
        atomic_write(path, updated)
        try:
            result = subprocess.run(["niri", "validate", "-c", str(config)],
                                    capture_output=True, text=True)
            if result.returncode:
                raise ValueError(result.stderr or result.stdout)
        except Exception:
            if path.read_text() == updated:
                atomic_write(path, text)
            raise
        return "Saved · " + str(backup)


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("changes", nargs="?")
    parser.add_argument("--config", type=Path, default=Path.home() / ".config/niri/config.kdl")
    parser.add_argument("--backup-root", type=Path, default=Path.home() / ".local/state/angelos/backups")
    args = parser.parse_args()
    if args.changes is None:
        print(json.dumps(read((args.config.parent / "cfg/misc.kdl").read_text())))
    else:
        print(save(args.config, json.loads(args.changes), args.backup_root))


if __name__ == "__main__":
    main()
