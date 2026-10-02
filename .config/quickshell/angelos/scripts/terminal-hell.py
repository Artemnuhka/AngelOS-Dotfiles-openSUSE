#!/usr/bin/env python3
"""The terminal in hell (Settings → Y2K → Terminal in hell), run by render-templates.py.

usage: terminal-hell.py PALETTE.json

The terminals' colours come from their templates (kitty.conf, foot.ini, alacritty.toml
with "terminal": true — the palette's "term" overrides them with hell's while the demon
rules). This writes what the templates can't:
  ~/.local/share/angelos/terminal/realm          heaven | hell
  ~/.local/share/angelos/terminal/hell-lines.txt  her lines for a new terminal, one a line
  ~/.local/share/angelos/terminal/hell.png        kitty's scorched background (painted once)
  ~/.config/fish/conf.d/angelos-realm.fish        in hell: command colours from the circle's
                                                  palette for the session and one of her
                                                  lines before the first prompt (only if
                                                  fish is set up)
"""
import json
import random
import sys
from pathlib import Path

HOME = Path.home()
OUT = HOME / ".local/share/angelos/terminal"
FISH = HOME / ".config/fish/conf.d/angelos-realm.fish"
PAINT_VERSION = "2"

FISH_SNIPPET = r"""# angelOS: the terminal in hell (Settings → Y2K → Terminal in hell).
# Written by angelOS (scripts/terminal-hell.py) — edits here are overwritten.
status is-interactive; or return
set -l __angelos_dir (set -q XDG_DATA_HOME; and echo $XDG_DATA_HOME; or echo $HOME/.local/share)/angelos/terminal
test -f $__angelos_dir/realm; or return
test (string trim < $__angelos_dir/realm) = hell; or return
# the circle's colours for the command line — this session only, the universal colours stay yours
set -g fish_color_command {accent}
set -g fish_color_keyword {accent2}
set -g fish_color_param {fg}
set -g fish_color_quote {color3}
set -g fish_color_redirection {color1}
set -g fish_color_end {textDim}
set -g fish_color_operator {accent2}
set -g fish_color_escape {color5}
set -g fish_color_error {color9} --bold
set -g fish_color_autosuggestion {textDim}
set -g fish_color_comment {textDim}
set -g fish_color_selection --background={lo}
set -g fish_color_search_match --background={bgAlt}
# one of her lines before the first prompt (after fastfetch)
function __angelos_hell_line --on-event fish_prompt
    functions -e __angelos_hell_line
    set -l file (set -q XDG_DATA_HOME; and echo $XDG_DATA_HOME; or echo $HOME/.local/share)/angelos/terminal/hell-lines.txt
    test -s $file; or return
    set -l lines (string match -v -r '^\s*$' < $file)
    test (count $lines) -gt 0; or return
    set_color {accent}; printf '⛧ '
    set_color {fg}; printf '%s' $lines[(random 1 (count $lines))]
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


# the snippet's colours when the palette has none (heaven: the snippet stays silent anyway)
FISH_DEFAULTS = {"accent": "e2703f", "accent2": "c99a5e", "fg": "d9cbbd", "textDim": "9c8f85",
                 "lo": "1f1716", "bgAlt": "16100f", "color1": "a8473a", "color3": "b08f52",
                 "color5": "8a4a6a", "color8": "3b2a26", "color9": "c4604c"}


def fish_snippet(term):
    cols = dict(FISH_DEFAULTS)
    for k in cols:
        v = str(term.get(k, "")).lstrip("#")
        if len(v) == 6:
            cols[k] = v
    # the snippet has fish's own braces: fill only our names
    out = FISH_SNIPPET
    for k, v in cols.items():
        out = out.replace("{" + k + "}", v)
    return out


def paint(path):
    """a scorched pixel background: near-black, a little lighter low down, a few charred
    cracks and a pentagram barely there. Nothing glows. Drawn at 1/4 size, scaled up crisp."""
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
        r = int(9 + 9 * t)
        g = int(6 + 5 * t)
        b = int(7 + 5 * t)
        for x in range(w):
            px[x, y] = (r, g, b)
    rnd = random.Random(666)
    d = ImageDraw.Draw(img)
    # charred cracks: short dark random walks
    for _ in range(26):
        x, y = rnd.randrange(w), rnd.randrange(h // 3, h)
        for _ in range(rnd.randrange(6, 18)):
            px[x % w, min(h - 1, y)] = (4, 3, 3)
            x += rnd.choice((-1, 0, 1, 1))
            y += rnd.choice((-1, 0, 0, 1))
    # the pentagram, barely there
    cx, cy, rad = w - 62, h - 64, 44
    col = (30, 22, 21)
    pts = [(cx + rad * math.cos(-math.pi / 2 + i * 2 * math.pi / 5), cy + rad * math.sin(-math.pi / 2 + i * 2 * math.pi / 5)) for i in range(5)]
    for i in range(5):
        d.line([pts[i], pts[(i + 2) % 5]], fill=col, width=1)
    d.ellipse([cx - rad - 5, cy - rad - 5, cx + rad + 5, cy + rad + 5], outline=col, width=1)
    d.ellipse([cx - rad - 9, cy - rad - 9, cx + rad + 9, cy + rad + 9], outline=(24, 17, 16), width=1)
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
        write(FISH, fish_snippet(pal.get("term") or {}))


if __name__ == "__main__":
    main()
