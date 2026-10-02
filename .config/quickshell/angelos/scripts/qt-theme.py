#!/usr/bin/env python3
"""Qt apps in angelOS's look (Settings → Appearance → Qt apps), run by render-templates.py.

usage: qt-theme.py PALETTE.json
       qt-theme.py --status        JSON: {"on", "platformTheme", "niri", "qt6ct"}

On (palette key qtStyle): qt6ct carries the look — a colour scheme from the palette
(~/.config/qt6ct/colors/angelos.conf: heaven's, or hell's while the demon rules, the
palette's "apps" overrides), a pixel stylesheet (~/.config/qt6ct/qss/angelos.qss: square
corners, bevelled buttons and fields, the accent for selections) and Fusion underneath.
qt6ct watches its folder, so running Qt apps change on the fly, heaven ↔ hell included.
Apps only use qt6ct with QT_QPA_PLATFORMTHEME=qt6ct: this sets it in niri's environment
block (cfg/misc.kdl, the old value kept in a comment), in systemd's user manager and
D-Bus activation; the shell itself stays on its own (bin/angelos), apps started from
angelOS get qt6ct right away (Shell.childEnv). Off: everything back as it was.
The first change of qt6ct.conf keeps a copy in ~/.local/state/angelos/backups/.
"""
import configparser
import json
import os
import re
import subprocess
import sys
import time
from pathlib import Path

HOME = Path.home()
QT6CT = HOME / ".config/qt6ct"
CONF = QT6CT / "qt6ct.conf"
SCHEME = QT6CT / "colors/angelos.conf"
QSS = QT6CT / "qss/angelos.qss"
NIRI = HOME / ".config/niri/cfg/misc.kdl"
MARK = "// angelOS qt: was "
BACKUPS = HOME / ".local/state/angelos/backups"


def write(path, text):
    path.parent.mkdir(parents=True, exist_ok=True)
    if path.exists() and path.read_text() == text:
        return False
    tmp = path.with_name(path.name + ".angelos-tmp")
    tmp.write_text(text)
    tmp.replace(path)
    return True


def mix(a, b, t):
    a, b = a.lstrip("#"), b.lstrip("#")
    ca = [int(a[i:i + 2], 16) for i in (0, 2, 4)]
    cb = [int(b[i:i + 2], 16) for i in (0, 2, 4)]
    return "#%02x%02x%02x" % tuple(round(x + (y - x) * t) for x, y in zip(ca, cb))


def colours(p):
    fg, bg, alt = p["fg"], p["bg"], p.get("bgAlt", p["bg"])
    face = p.get("face", alt)
    acc, sel = p.get("select", p["accent"]), p.get("selectText", "#ffffff")
    dim = p.get("textDim", mix(fg, bg, 0.45))
    hi, lo = p.get("hi", mix(face, "#ffffff", 0.3)), p.get("lo", mix(face, "#000000", 0.4))
    # windowText, button, light, midlight, dark, mid, text, brightText, buttonText, base,
    # window, shadow, highlight, highlightedText, link, linkVisited, alternateBase,
    # noRole, toolTipBase, toolTipText, placeholderText, accent
    active = [fg, face, hi, mix(face, hi, 0.5), lo, mix(face, lo, 0.5), fg, "#ffffff", fg, p.get("sunken", bg) if p.get("mode") == "dark" else bg,
              bg, p.get("edge", "#000000"), acc, sel, p.get("accent2", acc), mix(p.get("accent2", acc), fg, 0.3), mix(bg, alt, 0.5),
              bg, face, fg, dim, p["accent"]]
    disabled = list(active)
    for i in (0, 6, 8):
        disabled[i] = dim
    disabled[12] = mix(acc, bg, 0.5)
    inactive = list(active)
    return "[ColorScheme]\n# angelOS %s (scripts/qt-theme.py) — generated, edits are overwritten\nactive_colors=%s\ndisabled_colors=%s\ninactive_colors=%s\n" % (
        p.get("appsRealm", "heaven"), ", ".join(active), ", ".join(disabled), ", ".join(inactive))


def stylesheet(p):
    c = {
        "fg": p["fg"], "bg": p["bg"], "face": p.get("face", p.get("bgAlt", p["bg"])),
        "faceAlt": p.get("faceAlt", p.get("bgAlt", p["bg"])), "sunken": p.get("sunken", p["bg"]),
        "hi": p.get("hi", "#ffffff"), "lo": p.get("lo", "#000000"), "edge": p.get("edge", "#000000"),
        "accent": p.get("select", p["accent"]), "sel": p.get("selectText", "#ffffff"), "dim": p.get("textDim", p["fg"]),
    }
    c["hover"] = mix(c["face"], c["accent"], 0.18)
    css = """/* angelOS pixel style for Qt (scripts/qt-theme.py, %(realm)s) — generated */
QPushButton, QToolButton[popupMode="1"], QComboBox, QAbstractSpinBox::up-button, QAbstractSpinBox::down-button {
    background: %(face)s; color: %(fg)s;
    border: 2px solid; border-color: %(hi)s %(lo)s %(lo)s %(hi)s;
    border-radius: 0px;
}
QPushButton { padding: 4px 12px; min-height: 18px; }
QPushButton:hover, QComboBox:hover { background: %(hover)s; }
QPushButton:pressed, QPushButton:checked, QComboBox:on {
    background: %(sunken)s; border-color: %(lo)s %(hi)s %(hi)s %(lo)s;
}
QPushButton:default { border: 2px solid %(accent)s; }
QPushButton:disabled { color: %(dim)s; }
QComboBox { padding: 3px 8px; }
QComboBox QAbstractItemView { background: %(face)s; border: 2px solid %(edge)s; selection-background-color: %(accent)s; selection-color: %(sel)s; }
QLineEdit, QTextEdit, QPlainTextEdit, QAbstractSpinBox {
    background: %(sunken)s; color: %(fg)s;
    border: 2px solid; border-color: %(lo)s %(hi)s %(hi)s %(lo)s;
    border-radius: 0px; padding: 3px;
    selection-background-color: %(accent)s; selection-color: %(sel)s;
}
QLineEdit:focus, QTextEdit:focus, QPlainTextEdit:focus, QAbstractSpinBox:focus { border-color: %(accent)s; }
QMenu { background: %(face)s; color: %(fg)s; border: 2px solid %(edge)s; padding: 2px; }
QMenu::item { padding: 4px 22px 4px 22px; }
QMenu::item:selected, QMenuBar::item:selected { background: %(accent)s; color: %(sel)s; }
QMenu::separator { height: 2px; background: %(lo)s; margin: 3px 6px; }
QToolTip { background: %(face)s; color: %(fg)s; border: 2px solid %(edge)s; padding: 3px; }
QTabBar::tab {
    background: %(faceAlt)s; color: %(dim)s; padding: 4px 12px; margin-right: 2px;
    border: 2px solid; border-color: %(hi)s %(lo)s %(faceAlt)s %(hi)s; border-radius: 0px;
}
QTabBar::tab:selected { background: %(face)s; color: %(fg)s; border-top: 2px solid %(accent)s; }
QProgressBar { background: %(sunken)s; color: %(fg)s; text-align: center; border: 2px solid; border-color: %(lo)s %(hi)s %(hi)s %(lo)s; border-radius: 0px; }
QProgressBar::chunk { background: %(accent)s; }
QScrollBar:vertical { background: %(sunken)s; width: 14px; margin: 0; }
QScrollBar:horizontal { background: %(sunken)s; height: 14px; margin: 0; }
QScrollBar::handle { background: %(face)s; border: 2px solid; border-color: %(hi)s %(lo)s %(lo)s %(hi)s; }
QScrollBar::handle:vertical { min-height: 24px; }
QScrollBar::handle:horizontal { min-width: 24px; }
QScrollBar::handle:hover { background: %(hover)s; }
QScrollBar::add-line, QScrollBar::sub-line { width: 0px; height: 0px; }
QScrollBar::add-page, QScrollBar::sub-page { background: none; }
QHeaderView::section { background: %(face)s; color: %(fg)s; padding: 3px 6px; border: 0px; border-right: 1px solid %(lo)s; border-bottom: 2px solid %(lo)s; }
QGroupBox { border: 2px solid; border-color: %(lo)s %(hi)s %(hi)s %(lo)s; margin-top: 10px; padding-top: 6px; }
QGroupBox::title { subcontrol-origin: margin; left: 8px; padding: 0 4px; color: %(fg)s; }
QSlider::groove:horizontal { height: 4px; background: %(sunken)s; border: 1px solid %(lo)s; }
QSlider::handle:horizontal { width: 10px; margin: -6px 0; background: %(face)s; border: 2px solid; border-color: %(hi)s %(lo)s %(lo)s %(hi)s; }
QSlider::sub-page:horizontal { background: %(accent)s; }
""" % dict(c, realm=p.get("appsRealm", "heaven"))
    return css


def backup_conf():
    if not CONF.exists():
        return
    flag = QT6CT / ".angelos-backup"
    if flag.exists():
        return
    d = BACKUPS / (time.strftime("%Y%m%d-%H%M%S") + "-qt6ct")
    d.mkdir(parents=True, exist_ok=True)
    (d / "qt6ct.conf").write_bytes(CONF.read_bytes())
    flag.write_text(str(d) + "\n")


def set_conf(on):
    cp = configparser.RawConfigParser()
    cp.optionxform = str
    if CONF.exists():
        cp.read(CONF)
    keep = QT6CT / ".angelos-before.json"
    for s in ("Appearance", "Interface"):
        if not cp.has_section(s):
            cp.add_section(s)
    want = {("Appearance", "color_scheme_path"): str(SCHEME), ("Appearance", "custom_palette"): "true",
            ("Appearance", "style"): "Fusion", ("Appearance", "standard_dialogs"): "xdgdesktopportal",
            ("Interface", "stylesheets"): str(QSS)}
    if on:
        if not keep.exists():
            before = {"%s/%s" % k: cp.get(*k, fallback=None) for k in want}
            write(keep, json.dumps(before))
        for (s, k), v in want.items():
            cp.set(s, k, v)
    else:
        if not keep.exists():
            return False
        before = json.loads(keep.read_text())
        for sk, v in before.items():
            s, k = sk.split("/", 1)
            if v is None:
                cp.remove_option(s, k)
            else:
                cp.set(s, k, v)
        keep.unlink()
    from io import StringIO
    buf = StringIO()
    cp.write(buf, space_around_delimiters=False)
    text = buf.getvalue().rstrip("\n") + "\n"
    if not CONF.exists() or CONF.read_text() != text:
        backup_conf()
        write(CONF, text)
        return True
    return False


ENV_RE = re.compile(r'^(\s*)QT_QPA_PLATFORMTHEME\s+"([^"]*)"(.*)$', re.M)


def niri_env(on):
    """QT_QPA_PLATFORMTHEME in niri's environment block: qt6ct, or back to what it was"""
    if not NIRI.exists():
        return None
    text = NIRI.read_text()
    m = ENV_RE.search(text)
    if on:
        if m and m.group(2) == "qt6ct":
            return "already"
        if m:
            new = text[:m.start()] + '%sQT_QPA_PLATFORMTHEME "qt6ct" %s"%s"' % (m.group(1), MARK, m.group(2)) + text[m.end():]
        else:
            env = re.search(r"^(\s*)environment\s*\{\s*$", text, re.M)
            if not env:
                return None
            ind = env.group(1) + "    "
            new = text[:env.end()] + '\n%sQT_QPA_PLATFORMTHEME "qt6ct" %s""' % (ind, MARK) + text[env.end():]
    else:
        if not m or MARK not in m.group(3):
            return m.group(2) if m else None
        was = m.group(3).split(MARK, 1)[1].strip().strip('"')
        if was:
            new = text[:m.start()] + '%sQT_QPA_PLATFORMTHEME "%s"' % (m.group(1), was) + text[m.end():]
        else:
            # it was not set at all: drop the line
            end = m.end() + 1 if text[m.end():m.end() + 1] == "\n" else m.end()
            new = text[:m.start()] + text[end:]
    tmp = NIRI.with_name(NIRI.name + ".angelos-tmp")
    tmp.write_text(new)
    tmp.replace(NIRI)
    return "set" if on else "restored"


def session_env(value):
    """systemd's user manager and D-Bus activation: apps started outside niri's spawn"""
    if value:
        cmds = [["systemctl", "--user", "set-environment", "QT_QPA_PLATFORMTHEME=" + value],
                ["dbus-update-activation-environment", "QT_QPA_PLATFORMTHEME=" + value]]
    else:
        cmds = [["systemctl", "--user", "unset-environment", "QT_QPA_PLATFORMTHEME"]]
    for c in cmds:
        try:
            subprocess.run(c, stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL, timeout=5)
        except Exception:
            pass


def original_theme():
    if not NIRI.exists():
        return ""
    m = ENV_RE.search(NIRI.read_text())
    if not m:
        return ""
    return m.group(3).split(MARK, 1)[1].strip().strip('"') if MARK in m.group(3) else m.group(2)


def status():
    m = ENV_RE.search(NIRI.read_text()) if NIRI.exists() else None
    cp = configparser.RawConfigParser()
    if CONF.exists():
        cp.read(CONF)
    print(json.dumps({
        "on": bool(m and m.group(2) == "qt6ct" and MARK in m.group(3)),
        "niri": m.group(2) if m else "",
        "platformTheme": os.environ.get("QT_QPA_PLATFORMTHEME", ""),
        "qt6ct": Path("/usr/lib/qt6/plugins/platformthemes/libqt6ct.so").exists() or Path("/usr/lib64/qt6/plugins/platformthemes/libqt6ct.so").exists(),
        "stylesheet": cp.get("Interface", "stylesheets", fallback="") == str(QSS),
    }))


def main():
    if len(sys.argv) > 1 and sys.argv[1] == "--status":
        return status()
    pal = json.loads(Path(sys.argv[1]).read_text())
    on = bool(pal.get("qtStyle"))
    if not on:
        # back as it was: qt6ct's settings, then the environment
        set_conf(False)
        if niri_env(False) == "restored":
            was = original_theme()
            session_env(was)
        print(json.dumps({"qt": "off"}))
        return
    p = dict(pal, **(pal.get("apps") or {}))
    write(SCHEME, colours(p))
    write(QSS, stylesheet(p))
    set_conf(True)
    if niri_env(True) == "set":
        session_env("qt6ct")
    print(json.dumps({"qt": "on", "realm": p.get("appsRealm", "heaven")}))


if __name__ == "__main__":
    main()
