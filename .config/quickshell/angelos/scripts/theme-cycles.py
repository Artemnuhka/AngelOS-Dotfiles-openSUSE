#!/usr/bin/env python3
"""Heaven → hell → heaven, many times, and the apps must end up in heaven's colours.

  angelos debug cycles [N] [PATTERN]     (developer mode, the live shell: a dev instance
                                         exports no theme, so there is nothing to compare)

Takes heaven's files as they are now (the shell settled in heaven first), then runs N cycles
through the debug panel's IPC and after each one waits until the theme export has settled,
then compares every recipient with heaven's: niri's window borders (~/.config/niri/angelos.kdl),
the palette, kitty, foot, Alacritty, GTK 3/4 (and the angelOS-a/b theme in use), Qt (qt6ct),
Telegram, Steam, Helium, the terminal's realm — and the cursor niri shows against the one the
shell wants (heaven's changes with the angel's mood: a throw cools her, Frost). PATTERN letters, one
per cycle in turn (default "fmscfgtfmc"):
  f  in and straight out (0.2 s: inside the export's debounce)
  m  out after 1.5 s (while hell's render runs)
  s  out after 6 s (hell settled first)
  c  in, the circle switched, out right after it
  g  out "as in the game" (the show and the widgets' burn: the realm turns midway)
  t  in "as in the game" (thrown down), out as soon as she is the demon
A switch within a minute of the last show is a quiet one (story/game.json → pace.quickSwitch),
so g and t wait out that minute: each of them gets the whole show.
Exit 1 if any cycle ends with anything not heaven's. The game's save changes as in play
(returns, falls): take a snapshot in the debug panel first, put it back after.
"""
import hashlib
import json
import os
import re
import subprocess
import sys
import time
from pathlib import Path

H = Path.home()
CIRCLES = ["limbo", "lust", "gluttony", "greed", "wrath", "heresy", "violence", "fraud", "treachery"]
FILES = {
    "palette": H / ".cache/angelos/palette.json",
    "niri": H / ".config/niri/angelos.kdl",
    "kitty": H / ".config/kitty/themes/angelos.conf",
    "foot": H / ".config/foot/themes/angelos",
    "alacritty": H / ".config/alacritty/themes/angelos.toml",
    "gtk3": H / ".config/gtk-3.0/angelos.css",
    "gtk4": H / ".config/gtk-4.0/angelos.css",
    "gtk4-decor": H / ".config/gtk-4.0/angelos-decor.css",
    "qt": H / ".config/qt6ct/colors/angelos.conf",
    "qss": H / ".config/qt6ct/qss/angelos.qss",
    "telegram": H / ".local/share/angelos/telegram/angelOS.tdesktop-theme",
    "steam": H / ".local/share/angelos/steam/angelOS/colors.json",
    "helium": H / ".local/share/angelos/helium/theme/manifest.json",
    "terminal": H / ".local/share/angelos/terminal/realm",
}
RU = os.environ.get("LANG", "").startswith("ru")


def t(ru, en):
    return ru if RU else en


def qs():
    for c in ("qs", os.path.expanduser("~/.local/bin/qs")):
        if subprocess.run(["sh", "-c", f"command -v {c}"], capture_output=True).returncode == 0:
            return c
    return "qs"


QS = qs()


def ipc(fn, arg=""):
    r = subprocess.run([QS, "-c", "angelos", "ipc", "call", "angelos", fn, arg], capture_output=True, text=True, timeout=15)
    return r.stdout.strip()


def theme():
    try:
        return json.loads(ipc("debug", "theme"))
    except ValueError:
        return {}


def gtk_theme():
    r = subprocess.run(["gsettings", "get", "org.gnome.desktop.interface", "gtk-theme"], capture_output=True, text=True)
    return r.stdout.strip().strip("'")


def cursor():
    for p in [H / ".config/niri/config.kdl"] + sorted((H / ".config/niri/cfg").glob("*.kdl")):
        m = re.search(r'xcursor-theme\s+"([^"]*)"', p.read_text()) if p.is_file() else None
        if m:
            return m.group(1)
    return ""


def state():
    """every recipient's file as a short digest, plus the GTK theme in use and the cursor"""
    s = {}
    for k, p in FILES.items():
        try:
            s[k] = hashlib.sha1(p.read_bytes()).hexdigest()[:12]
        except OSError:
            s[k] = "-"
    g = gtk_theme()
    css = H / ".local/share/themes" / g / "gtk-3.0/gtk.css"
    s["gtk-theme"] = (g if not g.startswith("angelOS-") else "angelOS") + ":" + (hashlib.sha1(css.read_bytes()).hexdigest()[:12] if css.is_file() else "-")
    return s


def borders():
    m = re.findall(r'(?:active|inactive)-color\s+"(#[0-9a-fA-F]{6})"', FILES["niri"].read_text())
    return ",".join(m[:2])


def wait_heaven(limit=90):
    """the angel back, no show or burn going on, the export settled; then the cursor and the files still"""
    t0 = time.time()
    while time.time() - t0 < limit:
        th = theme()
        if th.get("settled") and not th.get("demon") and not th.get("transition") and th.get("realm") == "heaven" and not th.get("cursorBusy"):
            break
        time.sleep(0.3)
    else:
        return None
    # the cursor follows on its own (scripts/cursors.py), and a last write may land: wait for 3 s of quiet
    last, quiet = None, 0
    while time.time() - t0 < limit:
        now = state()
        quiet = quiet + 1 if now == last else 0
        last = now
        if quiet >= 6 and cursor() == theme().get("cursor"):
            th = theme()
            pal = hashlib.md5(FILES["palette"].read_bytes()).hexdigest()
            return now, th, pal == th.get("palette")
        time.sleep(0.5)
    return None


def wait(pred, limit=40):
    t0 = time.time()
    while time.time() - t0 < limit:
        th = theme()
        if pred(th):
            return True
        time.sleep(0.2)
    return False


LAST_SHOW = [0.0]
QUICK = 65          # pace.quickSwitch (60 s), and the throw lands a moment after the call


def cycle(kind, i):
    c = CIRCLES[i % len(CIRCLES)]
    if kind in "gt":
        left = LAST_SHOW[0] + QUICK - time.time()
        if left > 0:
            print(t(f"   (жду {left:.0f} с: показ, а не тихий переход)", f"   (waiting {left:.0f} s: the show, not a quiet switch)"), flush=True)
            time.sleep(left)
    if kind == "t":
        ipc("helper", "throw")
        LAST_SHOW[0] = time.time()
        if not wait(lambda th: th.get("demon") and not th.get("transition"), 60):
            return t("не дождалась демоницы", "the demon never came")
    else:
        out = ipc("debug", "hell " + c)
        if "уже" in out or "already" in out:
            return out
    if kind == "f":
        time.sleep(0.2)
    elif kind == "m":
        time.sleep(1.5)
    elif kind == "s":
        time.sleep(6)
    elif kind == "c":
        time.sleep(1.2)
        ipc("debug", "circle " + CIRCLES[(i + 4) % len(CIRCLES)])
        time.sleep(0.1)
    elif kind == "g":
        time.sleep(2)
    if kind == "g":
        ipc("helper", "ascend")
        LAST_SHOW[0] = time.time()
    else:
        if not wait(lambda th: not th.get("transition"), 30):
            return t("переход не кончился", "the switch never ended")
        ipc("debug", "heaven")
    return ""


def main(argv):
    n = int(argv[0]) if argv and argv[0].isdigit() else 30
    pattern = argv[1] if len(argv) > 1 else "fmscfgtfmc"
    th = theme()
    if not th:
        print(t("Оболочка не отвечает на `debug theme` (нужен режим разработчика и живая, не dev, оболочка).",
                "The shell doesn't answer `debug theme` (developer mode and the live, not dev, shell needed)."), file=sys.stderr)
        return 2
    if th.get("demon"):
        ipc("debug", "heaven")
    got = wait_heaven()
    if not got:
        print(t("Рай так и не успокоился — проверять не с чем.", "Heaven never settled — nothing to compare with."), file=sys.stderr)
        return 2
    base, _, _ = got
    print(t("Рай сейчас: рамки ", "Heaven now: borders ") + borders() + t(", курсор ", ", cursor ") + cursor())
    bad = 0
    for i in range(n):
        kind = pattern[i % len(pattern)]
        t0 = time.time()
        err = cycle(kind, i)
        got = wait_heaven() if not err else None
        if not got:
            bad += 1
            print(f"{i + 1:2} {kind}  ✕ {err or t('не успокоилось за 90 с', 'never settled in 90 s')} " + t("курсор ", "cursor ") + cursor() + " / " + str(theme().get("cursor")), flush=True)
            continue
        now, th, pal_ok = got
        diff = [k for k in base if now.get(k) != base[k]]
        if cursor() != th.get("cursor"):
            diff.append("cursor " + cursor() + "≠" + str(th.get("cursor")))
        ok = not diff and pal_ok
        bad += not ok
        print(f"{i + 1:2} {kind}  {'✓' if ok else '✕'} {time.time() - t0:5.1f} s  " + t("рамки ", "borders ") + borders() + t(", курсор ", ", cursor ") + cursor()
              + ("" if ok else "  " + t("не райское: ", "not heaven's: ") + ", ".join(diff + ([] if pal_ok else ["palette≠state"]))), flush=True)
    print(t(f"Циклов: {n}, не в раю: {bad}", f"Cycles: {n}, not heaven: {bad}"))
    return 1 if bad else 0


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
