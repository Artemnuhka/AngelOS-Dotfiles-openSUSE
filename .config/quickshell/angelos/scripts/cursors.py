#!/usr/bin/env python3
"""Pixel cursor themes for angelOS, and one cursor everywhere.

  cursors.py list                      -> JSON: catalog, installed themes, what is applied where
  cursors.py install <id> [--accent #rrggbb --edge #rrggbb --light #rrggbb]
  cursors.py apply <theme> <size> [--no-flatpak]
  cursors.py preview <theme>           -> PNG strip in ~/.cache/angelos/cursors/<theme>.png

Themes are downloaded from pinned archives (SHA-256 checked) or built from the
pixel-cursors assets (mikaeladev, GPL-3.0) recoloured with the angelOS palette.
`apply` sets the theme for niri (Wayland + XWayland via xwayland-satellite),
GTK 3/4 (settings.ini, gsettings, xsettingsd), plain X11 clients and Steam
(~/.icons/default, ~/.icons/<theme>), the systemd/D-Bus activation environment
and Flatpak apps. niri's config is validated before it is written.
"""
import io
import json
import os
from pathlib import Path
import re
import shutil
import struct
import subprocess
import sys
import tarfile
import tempfile
import tomllib
import urllib.error
import urllib.request

HOME = Path.home()
ICONS = HOME / ".local/share/icons"
LEGACY_ICONS = HOME / ".icons"
CACHE = HOME / ".cache/angelos/cursors"
NIRI = HOME / ".config/niri"
BACKUPS = HOME / ".local/state/angelos/backups"

PIXEL_SRC = ("https://codeload.github.com/mikaeladev/pixel-cursors/tar.gz/736814216bcd5558ec904287b18deeabd0b91f78",
             "679a2df495b1333208a61f01fff3fe7bfba28fd81a28e61b6508d4a2ac9d5dfb")
CATALOG = [
    {"id": "angelos", "theme": "angelOS-Pixel", "name": "angelOS Pixel",
     "about": "pixel-cursors in the angelOS colours (accent, edge, light)", "license": "GPL-3.0 (mikaeladev/pixel-cursors)",
     "build": "pixel", "palette": None},
    {"id": "pixel-amethyst", "theme": "Pixel-Amethyst", "name": "Pixel Amethyst",
     "about": "lavender 8-bit set", "license": "GPL-3.0 (mikaeladev/pixel-cursors)",
     "build": "pixel", "palette": {"primary": "#fad6ff", "secondary": "#9c8bdb", "border": "#7864c6"}},
    {"id": "pixel-golden", "theme": "Pixel-Golden", "name": "Pixel Golden",
     "about": "warm retro set", "license": "GPL-3.0 (mikaeladev/pixel-cursors)",
     "build": "pixel", "palette": {"primary": "#eceabe", "secondary": "#c07b67", "border": "#5e2f44"}},
    {"id": "pink-hearts", "theme": "pink-heart-cursors", "name": "Pink Hearts",
     "about": "pink cursors with little hearts", "license": "not stated by the author (SimonCantCode)",
     "url": "https://codeload.github.com/SimonCantCode/pink-heart-cursors/tar.gz/36f3910044ffe8305bcf16242d70e8e43378e721",
     "sha256": "a3583953b485b0170c05d1cf8af1bc7da8af82cd5fd97c6b61f4201310e8b070"},
    {"id": "modern-xp", "theme": "ModernXP", "name": "Modern XP",
     "about": "pixel-perfect Windows XP set, HiDPI sizes", "license": "GPL-3.0 (na0miluv/modernXP-cursor-theme)",
     "url": "https://github.com/na0miluv/modernXP-cursor-theme/releases/download/final/ModernXP.tar.gz",
     "sha256": "5b439d1b838f19b667d565f9bc7c5e435118a7ef60cb2975f4695ce216b6be03"},
    {"id": "pixel-linux", "theme": "Pixel-Linux-Cursor", "name": "Pixel Linux",
     "about": "black-and-white pixel set with a skull", "license": "BSD-3-Clause (da0ab/Pixel-Linux-Cursor)",
     "url": "https://codeload.github.com/da0ab/Pixel-Linux-Cursor/tar.gz/fdef33f8c87bff22812048c6060d6f36a12f1aaa",
     "sha256": "6039f887cec4d32de0b5cea9b87a55c009a9e2975fde1e87211ee57b57dbe55a"},
]
NAME_RE = re.compile(r"[A-Za-z0-9][A-Za-z0-9_.+-]{0,63}\Z")
HEX_RE = re.compile(r"#[0-9a-fA-F]{6}\Z")
# names apps ask for that pixel-cursors does not list
EXTRA_ALIASES = {"default": ["progress-fallback"], "wait": ["progress", "left_ptr_watch", "half-busy", "watch",
                 "3ecb610c1bf2410f44200f48c40d3599", "00000000000000020006000e7e9ffc3f", "08e8e1c95fe2fc01f976f1e063a24ccd"]}


class Fail(Exception):
    pass


# ---------- downloads ----------
def fetch(url, sha):
    req = urllib.request.Request(url, headers={"User-Agent": "angelOS-cursors/1"})
    with urllib.request.urlopen(req, timeout=60) as r:
        data = r.read(64 * 1024 * 1024 + 1)
    if len(data) > 64 * 1024 * 1024:
        raise Fail("download too large")
    import hashlib
    if hashlib.sha256(data).hexdigest() != sha:
        raise Fail("checksum mismatch for " + url)
    return data


def safe_members(tar):
    for m in tar.getmembers():
        p = Path(m.name)
        if p.is_absolute() or ".." in p.parts or m.isdev():
            raise Fail("unsafe path in archive: " + m.name)
        if m.issym() or m.islnk():
            target = Path(m.linkname)
            if target.is_absolute() or ".." in target.parts:
                raise Fail("unsafe link in archive: " + m.name)
        yield m


def install_archive(entry):
    data = fetch(entry["url"], entry["sha256"])
    with tempfile.TemporaryDirectory(prefix="angelos-cursor-") as tmp:
        with tarfile.open(fileobj=io.BytesIO(data)) as tar:
            tar.extractall(tmp, members=list(safe_members(tar)), filter="data")
        # the theme root is the directory holding cursors/
        roots = [p.parent for p in Path(tmp).rglob("cursors") if p.is_dir()]
        if not roots:
            raise Fail("no cursors/ directory in the archive")
        root = min(roots, key=lambda p: len(p.parts))
        index = root / "index.theme"
        if not index.exists():
            index.write_text(f"[Icon Theme]\nName={entry['name']}\nComment={entry['about']}\n")
        place(root, entry["theme"])


def place(src, theme):
    ICONS.mkdir(parents=True, exist_ok=True)
    dest = ICONS / theme
    tmp = ICONS / f".{theme}.new"
    shutil.rmtree(tmp, ignore_errors=True)
    shutil.copytree(src, tmp, symlinks=True)
    if dest.exists() or dest.is_symlink():
        old = ICONS / f".{theme}.old"
        shutil.rmtree(old, ignore_errors=True)
        dest.rename(old)
        tmp.rename(dest)
        shutil.rmtree(old, ignore_errors=True)
    else:
        tmp.rename(dest)
    legacy_link(theme)


def legacy_link(theme):
    # Steam's runtime and old X11 clients only look in ~/.icons
    LEGACY_ICONS.mkdir(parents=True, exist_ok=True)
    link = LEGACY_ICONS / theme
    if (ICONS / theme).is_dir() and not link.exists() and not link.is_symlink():
        link.symlink_to(ICONS / theme)


# ---------- xcursor ----------
def xcursor_bytes(images):
    """images: [(nominal, w, h, xhot, yhot, delay, rgba bytes)] -> .xcursor file"""
    toc, chunks = [], []
    pos = 16 + 12 * len(images)
    for nominal, w, h, xh, yh, delay, rgba in images:
        px = bytearray()
        for i in range(0, len(rgba), 4):
            r, g, b, a = rgba[i:i + 4]
            px += bytes((b * a // 255, g * a // 255, r * a // 255, a))    # premultiplied BGRA (LE ARGB)
        chunk = struct.pack("<9I", 36, 0xFFFD0002, nominal, 1, w, h, xh, yh, delay) + bytes(px)
        toc.append(struct.pack("<3I", 0xFFFD0002, nominal, pos))
        chunks.append(chunk)
        pos += len(chunk)
    return struct.pack("<4s3I", b"Xcur", 16, 0x10000, len(images)) + b"".join(toc) + b"".join(chunks)


def xcursor_first_image(path, want=32):
    data = path.read_bytes()
    if data[:4] != b"Xcur":
        raise Fail("not an xcursor file")
    _, hsize, _, ntoc = struct.unpack("<4s3I", data[:16])
    entries = [struct.unpack("<3I", data[hsize + 12 * i:hsize + 12 * i + 12]) for i in range(ntoc)]
    images = [e for e in entries if e[0] == 0xFFFD0002]
    if not images:
        raise Fail("no images")
    best = min(images, key=lambda e: abs(e[1] - want))
    pos = best[2]
    _, _, _, _, w, h, xh, yh, _ = struct.unpack("<9I", data[pos:pos + 36])
    raw = data[pos + 36:pos + 36 + w * h * 4]
    rgba = bytearray()
    for i in range(0, len(raw), 4):
        b, g, r, a = raw[i:i + 4]
        if a:
            r, g, b = min(255, r * 255 // a), min(255, g * 255 // a), min(255, b * 255 // a)
        rgba += bytes((r, g, b, a))
    return w, h, bytes(rgba)


# ---------- pixel-cursors build ----------
def hex_rgb(h):
    return tuple(int(h[i:i + 2], 16) for i in (1, 3, 5))


def build_pixel(entry, accent=None, edge=None, light=None):
    from PIL import Image
    data = fetch(*PIXEL_SRC)
    with tempfile.TemporaryDirectory(prefix="angelos-pixel-") as tmp:
        with tarfile.open(fileobj=io.BytesIO(data)) as tar:
            tar.extractall(tmp, members=list(safe_members(tar)), filter="data")
        src = next(Path(tmp).iterdir())
        cfg = tomllib.loads((src / "config.toml").read_text())
        default = cfg["themes"]["default"]
        palette = entry["palette"] or {"primary": light or "#fff4fb", "secondary": accent or "#ff77c8",
                                       "border": edge or "#2b1d33"}
        recolor = {hex_rgb(default[k]): hex_rgb(palette[k]) for k in ("primary", "secondary", "border")}
        out = Path(tmp) / "theme"
        (out / "cursors").mkdir(parents=True)
        scales = (2, 3, 4)
        for name, spec in cfg["cursors"].items():
            asset = spec.get("asset", name)
            opts = asset if isinstance(asset, dict) else {"name": asset}
            img = Image.open(src / "assets" / (opts["name"] + ".png")).convert("RGBA")
            px = img.load()
            for y in range(img.height):
                for x in range(img.width):
                    r, g, b, a = px[x, y]
                    if a and (r, g, b) in recolor:
                        px[x, y] = recolor[(r, g, b)] + (a,)
            if opts.get("flop"):
                img = img.transpose(Image.FLIP_LEFT_RIGHT)
            frames = [img]
            delay = 0
            if "frames" in opts:
                tile = img.width
                cut = [img.crop((0, i * tile, tile, (i + 1) * tile)) for i in range(img.height // tile)]
                frames = [cut[i] for i in opts["frames"]]
                delay = int(opts.get("delay", 200))
            if opts.get("rotate"):
                frames = [f.rotate(-int(opts["rotate"]), expand=True) for f in frames]
            hx, hy = int(spec.get("hot_x", 0)), int(spec.get("hot_y", 0))
            images = []
            for s in scales:
                for f in frames:
                    big = f.resize((f.width * s, f.height * s), Image.NEAREST)
                    images.append((12 * s, big.width, big.height, hx * s + s // 2, hy * s + s // 2, delay, big.tobytes()))
            (out / "cursors" / name).write_bytes(xcursor_bytes(images))
            for alias in list(spec.get("aliases", [])) + EXTRA_ALIASES.get(name, []):
                link = out / "cursors" / alias
                if NAME_RE.fullmatch(alias) and not link.exists():
                    link.symlink_to(name)
        (out / "index.theme").write_text(f"[Icon Theme]\nName={entry['name']}\nComment={entry['about']}\n")
        place(out, entry["theme"])


# ---------- previews ----------
def preview(theme):
    from PIL import Image
    root = theme_dir(theme)
    if not root:
        raise Fail("theme not installed: " + theme)
    names = [("left_ptr", "default"), ("hand2", "pointer"), ("xterm", "text"), ("watch", "wait"), ("grabbing", "closedhand"), ("not-allowed", "crossed_circle")]
    tiles = []
    for pair in names:
        f = next((root / "cursors" / n for n in pair if (root / "cursors" / n).exists()), None)
        if not f:
            continue
        try:
            w, h, rgba = xcursor_first_image(f.resolve())
        except (Fail, OSError, struct.error):
            continue
        tiles.append(Image.frombytes("RGBA", (w, h), rgba))
    if not tiles:
        raise Fail("no previewable cursors")
    cell = 40
    strip = Image.new("RGBA", (cell * len(tiles), cell), (0, 0, 0, 0))
    for i, t in enumerate(tiles):
        t.thumbnail((cell, cell), Image.NEAREST)
        strip.alpha_composite(t, (i * cell + (cell - t.width) // 2, (cell - t.height) // 2))
    CACHE.mkdir(parents=True, exist_ok=True)
    out = CACHE / f"{theme}.png"
    strip.save(out)
    return str(out)


# ---------- where themes live ----------
def theme_dirs():
    found = {}
    for base in (Path("/usr/share/icons"), LEGACY_ICONS, ICONS):
        if base.is_dir():
            for d in base.iterdir():
                if d.name != "default" and (d / "cursors").is_dir():
                    found[d.name] = d
    return found


def theme_dir(theme):
    return theme_dirs().get(theme)


# ---------- apply everywhere ----------
def set_ini(path, pairs):
    text = path.read_text() if path.exists() else ""
    if "[Settings]" not in text:
        text = "[Settings]\n" + text
    for key, value in pairs.items():
        line = f"{key}={value}"
        if re.search(rf"(?m)^{re.escape(key)}\s*=", text):
            text = re.sub(rf"(?m)^{re.escape(key)}\s*=.*$", line, text)
        else:
            text = text.replace("[Settings]\n", f"[Settings]\n{line}\n", 1)
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text(text)


def niri_cursor(theme, size):
    """Rewrite niri's `cursor { }` block (validated, backed up, rolled back on failure)."""
    files = [p for p in [NIRI / "config.kdl"] + sorted((NIRI / "cfg").glob("*.kdl")) if p.is_file()]
    block = re.compile(r"(?ms)^([ \t]*)cursor\s*\{(.*?)^\1\}")
    target = next((p for p in files if block.search(p.read_text())), NIRI / "cfg/misc.kdl")
    old = target.read_text() if target.exists() else ""
    m = block.search(old)
    body = m.group(2) if m else ""
    indent = m.group(1) if m else "    "
    body = re.sub(r'(?m)^\s*xcursor-theme\s+"[^"]*"\s*\n?', "", body)
    body = re.sub(r"(?m)^\s*xcursor-size\s+\d+\s*\n?", "", body)
    inner = f'{indent}    xcursor-theme "{theme}"\n{indent}    xcursor-size {size}\n' + body.lstrip("\n")
    new_block = f"{indent}cursor {{\n{inner.rstrip()}\n{indent}}}"
    new = old[:m.start()] + new_block + old[m.end():] if m else old.rstrip() + f"\n\ncursor {{\n{inner.rstrip()}\n}}\n"
    if new == old:
        return
    with tempfile.TemporaryDirectory(prefix="angelos-cursor-niri-") as tmp:
        staged = Path(tmp) / "niri"
        shutil.copytree(NIRI, staged, symlinks=True)
        (staged / target.relative_to(NIRI)).write_text(new)
        r = subprocess.run(["niri", "validate", "-c", str(staged / "config.kdl")], capture_output=True, text=True)
        if r.returncode:
            raise Fail("niri validate: " + (r.stderr or r.stdout).strip()[-300:])
    BACKUPS.mkdir(parents=True, exist_ok=True)
    backup = Path(tempfile.mkdtemp(prefix="cursor-", dir=BACKUPS))
    if target.exists():
        shutil.copy2(target, backup / target.name)
    fd, name = tempfile.mkstemp(prefix=".cursor-", dir=target.parent)
    with os.fdopen(fd, "w") as f:
        f.write(new)
    os.replace(name, target)


def run(argv):
    try:
        return subprocess.run(argv, capture_output=True, text=True, timeout=20).returncode == 0
    except (OSError, subprocess.TimeoutExpired):
        return False


def apply(theme, size, flatpak=True):
    if not NAME_RE.fullmatch(theme):
        raise Fail("bad theme name")
    if not theme_dir(theme):
        raise Fail("theme not installed: " + theme)
    size = max(16, min(96, int(size)))
    done = []
    legacy_link(theme)
    niri_cursor(theme, size)
    done.append("niri")
    for d in (LEGACY_ICONS / "default", ICONS / "default"):
        d.mkdir(parents=True, exist_ok=True)
        (d / "index.theme").write_text(f"[Icon Theme]\nName=Default\nComment=Default cursor (angelOS)\nInherits={theme}\n")
    done.append("x11")
    for g in ("gtk-3.0", "gtk-4.0"):
        set_ini(HOME / f".config/{g}/settings.ini", {"gtk-cursor-theme-name": theme, "gtk-cursor-theme-size": size})
    done.append("gtk")
    if shutil.which("gsettings"):
        run(["gsettings", "set", "org.gnome.desktop.interface", "cursor-theme", theme])
        run(["gsettings", "set", "org.gnome.desktop.interface", "cursor-size", str(size)])
        done.append("gsettings")
    xs = HOME / ".config/xsettingsd/xsettingsd.conf"
    if xs.exists():
        text = xs.read_text()
        for key, value in (("Gtk/CursorThemeName", f'"{theme}"'), ("Gtk/CursorThemeSize", str(size))):
            if re.search(rf"(?m)^{re.escape(key)}\s", text):
                text = re.sub(rf"(?m)^{re.escape(key)}\s.*$", f"{key} {value}", text)
            else:
                text = text.rstrip("\n") + f"\n{key} {value}\n"
        xs.write_text(text)
        run(["pkill", "-HUP", "-x", "xsettingsd"])
        done.append("xsettingsd")
    env = dict(os.environ, XCURSOR_THEME=theme, XCURSOR_SIZE=str(size))
    if shutil.which("systemctl"):
        run(["systemctl", "--user", "set-environment", f"XCURSOR_THEME={theme}", f"XCURSOR_SIZE={size}"])
        done.append("systemd")
    if shutil.which("dbus-update-activation-environment"):
        subprocess.run(["dbus-update-activation-environment", "XCURSOR_THEME", "XCURSOR_SIZE"], env=env,
                       capture_output=True, timeout=20)
        done.append("dbus")
    if flatpak and shutil.which("flatpak"):
        # read-only access to ~/.local/share/icons only (where angelOS puts the themes)
        ok = run(["flatpak", "override", "--user", "--filesystem=xdg-data/icons:ro", "--nofilesystem=~/.icons",
                  f"--env=XCURSOR_THEME={theme}", f"--env=XCURSOR_SIZE={size}",
                  f"--env=XCURSOR_PATH={ICONS}:/run/host/user-share/icons:/run/host/share/icons:/usr/share/icons"])
        if ok:
            done.append("flatpak")
    return done


def status():
    out = {}
    for p in [NIRI / "config.kdl"] + sorted((NIRI / "cfg").glob("*.kdl")):
        m = re.search(r'xcursor-theme\s+"([^"]*)"', p.read_text()) if p.is_file() else None
        if m:
            s = re.search(r"xcursor-size\s+(\d+)", p.read_text())
            out["niri"] = [m.group(1), int(s.group(1)) if s else None]
    for g in ("gtk-3.0", "gtk-4.0"):
        p = HOME / f".config/{g}/settings.ini"
        if p.exists():
            m = re.search(r"(?m)^gtk-cursor-theme-name\s*=\s*(.*)$", p.read_text())
            out[g] = m.group(1).strip() if m else None
    idx = LEGACY_ICONS / "default/index.theme"
    if idx.exists():
        m = re.search(r"(?m)^Inherits\s*=\s*(.*)$", idx.read_text())
        out["x11"] = m.group(1).strip() if m else None
    if shutil.which("gsettings"):
        r = subprocess.run(["gsettings", "get", "org.gnome.desktop.interface", "cursor-theme"], capture_output=True, text=True)
        out["gsettings"] = r.stdout.strip().strip("'") or None
    return out


def listing():
    dirs = theme_dirs()
    catalog = []
    for e in CATALOG:
        item = {k: e[k] for k in ("id", "theme", "name", "about", "license")}
        item["installed"] = e["theme"] in dirs
        prev = CACHE / f"{e['theme']}.png"
        item["preview"] = str(prev) if prev.exists() else ""
        catalog.append(item)
    known = {e["theme"] for e in CATALOG}
    other = sorted(n for n in dirs if n not in known)
    return {"catalog": catalog, "other": other, "status": status()}


def main():
    args = sys.argv[1:]
    try:
        cmd = args[0] if args else "list"
        if cmd == "list":
            print(json.dumps(listing()))
        elif cmd == "install":
            entry = next((e for e in CATALOG if e["id"] == args[1]), None)
            if not entry:
                raise Fail("unknown theme id")
            opts = {k: args[args.index("--" + k) + 1] for k in ("accent", "edge", "light") if "--" + k in args}
            if any(not HEX_RE.fullmatch(v) for v in opts.values()):
                raise Fail("colours must be #rrggbb")
            if entry.get("build") == "pixel":
                build_pixel(entry, **opts)
            else:
                install_archive(entry)
            try:
                preview(entry["theme"])
            except Exception:
                pass
            print(json.dumps({"ok": True, "theme": entry["theme"]}))
        elif cmd == "apply":
            done = apply(args[1], args[2], "--no-flatpak" not in args)
            print(json.dumps({"ok": True, "done": done}))
        elif cmd == "preview":
            if not NAME_RE.fullmatch(args[1]):
                raise Fail("bad theme name")
            print(json.dumps({"ok": True, "preview": preview(args[1])}))
        else:
            raise Fail("unknown command")
    except (Fail, OSError, ValueError, IndexError, KeyError, tarfile.TarError, urllib.error.URLError) as error:
        print(json.dumps({"error": str(error)}))
        return 1
    return 0


if __name__ == "__main__":
    sys.exit(main())
