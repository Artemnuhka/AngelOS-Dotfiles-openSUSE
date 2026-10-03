#!/usr/bin/env python3
"""The game's snapshot for the debug panel (services/GameDebug): the save and the settings
copied aside, and put back the way they were.

  game-snapshot.py take      ~/.config/angelos/{save,settings}.json → ~/.local/state/angelos/
                             debug-snapshot/ (one snapshot: a new one replaces the old)
  game-snapshot.py restore   the snapshot's files back in place (each written whole, then
                             renamed over the old one: never half a file)
  game-snapshot.py info      what the snapshot there is holds
Prints JSON: {"ok": true, "snapshot": {at, realm, circle, chill, coldRoute, fallen, falls, returns,
sins}} or {"error": "…"}. The shell restarts after a restore (the panel does it).
"""
import json
import os
import shutil
import sys
import tempfile
import time
from pathlib import Path

HOME = Path(os.environ.get("HOME", str(Path.home())))
CONF = HOME / ".config/angelos"
SNAP = HOME / ".local/state/angelos/debug-snapshot"
FILES = ("save.json", "settings.json")


def summary(save, at):
    p, h, v = save.get("player") or {}, save.get("hell") or {}, save.get("vars") or {}
    return {"at": at, "realm": "hell" if p.get("character") == "demon" else "heaven",
            "circle": h.get("circle") or "", "chill": p.get("chill") or 0,
            "coldRoute": bool(p.get("coldRoute")), "fallen": bool(p.get("fallen")),
            "falls": h.get("falls") or 0, "returns": p.get("returns") or 0,
            "sins": sum(x for x in v.values() if isinstance(x, (int, float)))}


def info():
    meta = SNAP / "meta.json"
    if not meta.exists():
        return None
    try:
        return json.loads(meta.read_text())
    except ValueError:
        return None


def put(src, dst):
    """src over dst: a whole new file renamed into place"""
    dst.parent.mkdir(parents=True, exist_ok=True)
    fd, tmp = tempfile.mkstemp(dir=str(dst.parent), prefix="." + dst.name + ".")
    os.close(fd)
    shutil.copyfile(src, tmp)
    os.replace(tmp, dst)


def take():
    if not (CONF / "save.json").exists():
        return {"error": "no save.json in " + str(CONF)}
    SNAP.mkdir(parents=True, exist_ok=True)
    for f in FILES:
        if (CONF / f).exists():
            put(CONF / f, SNAP / f)
        elif (SNAP / f).exists():
            (SNAP / f).unlink()
    try:
        save = json.loads((SNAP / "save.json").read_text())
    except ValueError:
        save = {}
    meta = summary(save, int(time.time() * 1000))
    (SNAP / "meta.json").write_text(json.dumps(meta))
    return {"ok": True, "snapshot": meta}


def restore():
    meta = info()
    if not meta or not (SNAP / "save.json").exists():
        return {"error": "no snapshot"}
    for f in FILES:
        if (SNAP / f).exists():
            put(SNAP / f, CONF / f)
    return {"ok": True, "snapshot": meta}


def main():
    cmd = sys.argv[1] if len(sys.argv) > 1 else "info"
    if cmd == "take":
        out = take()
    elif cmd == "restore":
        out = restore()
    elif cmd == "info":
        out = {"ok": True, "snapshot": info()}
    else:
        print(__doc__)
        return 2
    print(json.dumps(out, ensure_ascii=False))
    return 0 if out.get("ok") else 1


if __name__ == "__main__":
    sys.exit(main())
