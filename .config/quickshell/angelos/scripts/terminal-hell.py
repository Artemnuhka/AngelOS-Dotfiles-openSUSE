#!/usr/bin/env python3
"""The terminal in hell (Settings → Y2K → Terminal in hell), run by render-templates.py.

usage: terminal-hell.py PALETTE.json

The terminals' colours come from their templates (kitty.conf, foot.ini, alacritty.toml
with "terminal": true — the palette's "term" overrides them with hell's while the demon
rules). This writes what the templates can't:
  ~/.local/share/angelos/terminal/realm          heaven | hell
  ~/.local/share/angelos/terminal/hell-lines.txt  her lines for a new terminal, one a line
  ~/.local/share/angelos/terminal/hell.png        kitty's charred background (painted once)
  ~/.config/fish/conf.d/angelos-realm.fish        in hell: fiery command colours for the
                                                  session and one of her lines before the
                                                  first prompt (only if fish is set up)
"""
import json
import random
import sys
from pathlib import Path

HOME = Path.home()
OUT = HOME / ".local/share/angelos/terminal"
FISH = HOME / ".config/fish/conf.d/angelos-realm.fish"
PAINT_VERSION = "1"

FISH_SNIPPET = r"""# angelOS: the terminal in hell (Settings → Y2K → Terminal in hell).
# Written by angelOS (scripts/terminal-hell.py) — edits here are overwritten.
status is-interactive; or return
set -l __angelos_dir (set -q XDG_DATA_HOME; and echo $XDG_DATA_HOME; or echo $HOME/.local/share)/angelos/terminal
test -f $__angelos_dir/realm; or return
test (string trim < $__angelos_dir/realm) = hell; or return
# fire for the command line — this session only, the universal colours stay yours
set -g fish_color_command ff6a1a
set -g fish_color_keyword ffb02e
set -g fish_color_param f3d9c0
set -g fish_color_quote d9a441
set -g fish_color_redirection e8404f
set -g fish_color_end b3142b
set -g fish_color_operator ffb02e
set -g fish_color_escape ff4f8b
set -g fish_color_error ff2a3d --bold
set -g fish_color_autosuggestion 6e3a3f
set -g fish_color_comment 8a5a50
set -g fish_color_selection --background=6e1a21
set -g fish_color_search_match --background=3d1016
# one of her lines before the first prompt (after fastfetch)
function __angelos_hell_line --on-event fish_prompt
    functions -e __angelos_hell_line
    set -l file (set -q XDG_DATA_HOME; and echo $XDG_DATA_HOME; or echo $HOME/.local/share)/angelos/terminal/hell-lines.txt
    test -s $file; or return
    set -l lines (string match -v -r '^\s*$' < $file)
    test (count $lines) -gt 0; or return
    set_color ff6a1a; printf '⛧ '
    set_color f3d9c0; printf '%s' $lines[(random 1 (count $lines))]
    set_color normal; echo
end
"""


def write(path, text):
    path.parent.mkdir(parents=True, exist_ok=True)
    if path.exists() and path.read_text() == text:
        return False
    tmp = path.with_suffix(path.suffix + ".angelos-tmp")
    tmp.write_text(text)
    tmp.replace(path)
    return True


def paint(path):
    """a charred pixel background: dark obsidian, embers rising from a glow along the
    foot, a faint pentagram in the corner. Drawn at 1/4 size and scaled up crisp."""
    try:
        from PIL import Image, ImageDraw
    except ImportError:
        return False
    import math
    w, h = 400, 250
    img = Image.new("RGB", (w, h))
    px = img.load()
    for y in range(h):
        t = y / (h - 1)
        glow = max(0.0, (t - 0.62) / 0.38) ** 1.8          # the fire below the edge
        r = int(11 + 9 * t + 58 * glow)
        g = int(2 + 2 * t + 10 * glow)
        b = int(4 + 3 * t + 6 * glow)
        for x in range(w):
            px[x, y] = (r, g, b)
    rnd = random.Random(666)
    d = ImageDraw.Draw(img)
    # charred cracks: short dark random walks
    for _ in range(26):
        x, y = rnd.randrange(w), rnd.randrange(h // 3, h)
        for _ in range(rnd.randrange(6, 18)):
            px[x % w, min(h - 1, y)] = (5, 1, 2)
            x += rnd.choice((-1, 0, 1, 1))
            y += rnd.choice((-1, 0, 0, 1))
    # embers: denser and hotter low down
    for _ in range(180):
        y = int(h - (rnd.random() ** 2.2) * h * 0.9) - 1
        x = rnd.randrange(w)
        heat = 1 - y / h
        c = (int(70 + 70 * (1 - heat)), int(18 + 22 * (1 - heat)), 8) if rnd.random() < 0.8 else (120, 60, 16)
        px[x, max(0, y)] = c
        if rnd.random() < 0.25 and y > 0:
            px[x, y - 1] = (c[0] // 2, c[1] // 2, 4)
    # the pentagram, barely there
    cx, cy, rad = w - 62, h - 64, 44
    col = (34, 8, 11)
    pts = [(cx + rad * math.cos(-math.pi / 2 + i * 2 * math.pi / 5), cy + rad * math.sin(-math.pi / 2 + i * 2 * math.pi / 5)) for i in range(5)]
    for i in range(5):
        d.line([pts[i], pts[(i + 2) % 5]], fill=col, width=1)
    d.ellipse([cx - rad - 5, cy - rad - 5, cx + rad + 5, cy + rad + 5], outline=col, width=1)
    d.ellipse([cx - rad - 9, cy - rad - 9, cx + rad + 9, cy + rad + 9], outline=(26, 6, 9), width=1)
    path.parent.mkdir(parents=True, exist_ok=True)
    img.resize((w * 4, h * 4), Image.NEAREST).save(path)
    (path.parent / ".paint-version").write_text(PAINT_VERSION)
    return True


def main():
    pal = json.loads(Path(sys.argv[1]).read_text())
    realm = pal.get("termRealm", "heaven")
    write(OUT / "realm", realm + "\n")
    lines = [str(l).replace("\n", " ") for l in pal.get("hellLines") or []]
    if lines:
        write(OUT / "hell-lines.txt", "\n".join(lines) + "\n")
    bg = OUT / "hell.png"
    ver = OUT / ".paint-version"
    if realm == "hell" and (not bg.exists() or not ver.exists() or ver.read_text().strip() != PAINT_VERSION):
        paint(bg)
    # fish: only where fish is the user's shell (its config dir exists)
    if FISH.parent.parent.is_dir():
        write(FISH, FISH_SNIPPET)


if __name__ == "__main__":
    main()
