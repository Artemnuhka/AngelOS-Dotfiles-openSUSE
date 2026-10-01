#!/usr/bin/env python3
"""Helium (and any Chromium) in angelOS's colours, heaven and hell (Settings → Appearance →
Apps, entry "helium" of templates/templates.json).

  helium-theme.py build PALETTE.json   write the theme for the palette's realm
  helium-theme.py status               what is set up, as JSON

Two ways for Helium to follow angelOS:
  live   Helium's own "GTK" theme (Settings → Appearance → Theme → GTK): it reads GTK's
         colours and draws its title bar buttons with GTK — and angelOS's GTK theme
         (scripts/gtk-live.py) switches live between heaven and hell, buttons included.
  theme  a Chromium theme extension, ~/.local/share/angelos/helium/theme (load it once:
         helium://extensions → Developer mode → Load unpacked). It is rewritten for the
         current palette and realm — the title bar like an angelOS window's, the toolbar
         its face, links in the accent, the new tab the desk; in hell obsidian, blood,
         embers and bone — and Helium reads it when it starts. Chromium keeps one theme at
         a time (enabling a second one uninstalls the first), so a theme can't switch live.
"""
import hashlib
import json
import shutil
import subprocess
import sys
from pathlib import Path

HOME = Path.home()
BASE = HOME / ".local/share/angelos/helium"
PROFILE = HOME / ".config/net.imput.helium"

HELL = {
    "body": "#160609", "face": "#2a0b10", "faceAlt": "#3d1016", "sunken": "#0c0305",
    "edge": "#050102", "hi": "#6e1a21", "blood": "#b3142b", "ember": "#ff6a1a",
    "flame": "#ffb02e", "gold": "#d9a441", "text": "#f3d9c0", "textDim": "#a8857a",
}


def rgb(h):
    h = h.lstrip("#")
    return [int(h[i:i + 2], 16) for i in (0, 2, 4)]


def mix(a, b, t):
    a, b = rgb(a), rgb(b)
    return "#" + "".join("%02x" % round(a[i] + (b[i] - a[i]) * t) for i in range(3))


def theme_colors(p, hell):
    if hell:
        h = HELL
        frame = mix(h["faceAlt"], h["blood"], 0.35)
        return {
            "frame": rgb(frame), "frame_inactive": rgb(h["face"]),
            "frame_incognito": rgb(h["body"]), "frame_incognito_inactive": rgb(h["sunken"]),
            "background_tab": rgb(h["face"]), "background_tab_inactive": rgb(h["sunken"]),
            "toolbar": rgb(h["face"]), "toolbar_text": rgb(h["text"]),
            "toolbar_button_icon": rgb(h["flame"]),
            "tab_text": rgb(h["flame"]), "tab_background_text": rgb(h["textDim"]),
            "tab_background_text_inactive": rgb(h["textDim"]),
            "bookmark_text": rgb(h["text"]),
            "omnibox_background": rgb(h["sunken"]), "omnibox_text": rgb(h["text"]),
            "ntp_background": rgb(h["body"]), "ntp_text": rgb(h["text"]),
            "ntp_link": rgb(h["ember"]), "ntp_header": rgb(h["blood"]),
            "button_background": rgb(h["faceAlt"]) + [1],
        }
    dark = p.get("mode") == "dark"
    header = mix(p["faceAlt"], p["accent"], 0.16 if dark else 0.10)
    return {
        "frame": rgb(header), "frame_inactive": rgb(p["faceAlt"]),
        "frame_incognito": rgb(mix(p["desk"], "#000000", 0.4)),
        "frame_incognito_inactive": rgb(mix(p["desk"], "#000000", 0.5)),
        "background_tab": rgb(p["faceAlt"]), "background_tab_inactive": rgb(p["faceAlt"]),
        "toolbar": rgb(p["face"]), "toolbar_text": rgb(p["text"]),
        "toolbar_button_icon": rgb(p["accent"]),
        "tab_text": rgb(p["text"]), "tab_background_text": rgb(p["textDim"]),
        "tab_background_text_inactive": rgb(p["textDim"]),
        "bookmark_text": rgb(p["text"]),
        "omnibox_background": rgb(p["sunken"]), "omnibox_text": rgb(p["text"]),
        "ntp_background": rgb(p["desk"]), "ntp_text": rgb(p["text"]),
        "ntp_link": rgb(p["accent"]), "ntp_header": rgb(p["accent"]),
        "button_background": rgb(p["face"]) + [1],
    }


def write_json(path, data):
    path.parent.mkdir(parents=True, exist_ok=True)
    tmp = path.with_suffix(path.suffix + ".tmp")
    tmp.write_text(json.dumps(data, indent=2, ensure_ascii=False) + "\n")
    tmp.replace(path)


def write_theme(pal):
    hell = pal.get("realm") == "hell"
    d = BASE / "theme"
    colors = theme_colors(pal, hell)
    manifest = {
        "manifest_version": 3,
        "name": "angelOS",
        "version": "1.%d.%d" % (1 if hell else 0, int(hashlib.sha1(json.dumps(colors, sort_keys=True).encode()).hexdigest()[:6], 16) % 65535),
        "description": "angelOS — " + ("hell, while the demon rules" if hell else "heaven, the angelOS palette") + " (rewritten by angelOS; Helium reads it at start)",
        "theme": {
            "colors": colors,
            "properties": {"ntp_background_alignment": "bottom"},
        },
    }
    old = (d / "manifest.json").read_text() if (d / "manifest.json").exists() else ""
    new = json.dumps(manifest, indent=2, ensure_ascii=False) + "\n"
    if old == new:
        return False
    # Chromium caches a built theme next to an unpacked one: drop it so the new colours count
    for stale in d.glob("Cached Theme*.pak"):
        stale.unlink()
    write_json(d / "manifest.json", manifest)
    return True


def theme_loaded():
    """Is our folder loaded in Helium's profile (as an unpacked extension)?"""
    try:
        prefs = json.loads((PROFILE / "Default/Preferences").read_text())
    except (OSError, ValueError):
        return False
    want = str(BASE / "theme")
    for v in ((prefs.get("extensions") or {}).get("settings") or {}).values():
        if v.get("path") == want:
            return True
    return False


def status():
    try:
        prefs = json.loads((PROFILE / "Default/Preferences").read_text())
    except (OSError, ValueError):
        prefs = {}
    ext = prefs.get("extensions") or {}
    # extensions.theme.system_theme: 1 = GTK (the live way)
    gtk_mode = (ext.get("theme") or {}).get("system_theme") == 1 or ((prefs.get("browser") or {}).get("theme") or {}).get("system_theme") == 1
    print(json.dumps({
        "installed": shutil.which("helium-browser") is not None or Path("/opt/helium-browser-bin/helium").exists(),
        "running": subprocess.run(["pgrep", "-x", "helium"], capture_output=True).returncode == 0,
        "theme": str(BASE / "theme"),
        "themeLoaded": theme_loaded(),
        "gtkMode": bool(gtk_mode),
    }))


def main():
    a = sys.argv[1:]
    if len(a) == 2 and a[0] == "build":
        pal = json.loads(Path(a[1]).read_text())
        changed = write_theme(pal)
        print(json.dumps({"ok": True, "changed": changed, "realm": pal.get("realm", "heaven")}))
    elif a == ["status"]:
        status()
    else:
        print(__doc__, file=sys.stderr)
        sys.exit(1)


if __name__ == "__main__":
    main()
