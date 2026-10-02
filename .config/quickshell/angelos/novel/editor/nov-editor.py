#!/usr/bin/env python3
"""angelOS novel editor — a small local server for the dialogue editor (novel/editor).

  nov-editor.py [--dir ~/AngelOs-Nov] [--port 0] [--no-open] [--stay]

Serves the editor page on 127.0.0.1 and opens it as an app window (Helium/Chromium
`--app`, else the default browser). The page reads and writes the chapters in
<dir>/story/*.json and shows the sprites in <dir>/sprites/<who>/*.png. Every save keeps
the previous version in <dir>/story/.history/ (the last 50 per chapter). Without --stay
the server quits a minute after the page stopped pinging (the window was closed).

The rules (templates, conditions, checks) come from novel/NovelCore.js — the same file
the shell's engine (services/Novel.qml) uses, served at /core.js without its QML pragma.
Only the standard library: nothing to install.
"""
import argparse
import json
import mimetypes
import os
import re
import shutil
import subprocess
import sys
import threading
import time
import webbrowser
from http.server import BaseHTTPRequestHandler, ThreadingHTTPServer
from pathlib import Path
from urllib.parse import parse_qs, urlparse

HERE = Path(__file__).resolve().parent
CORE = HERE.parent / "NovelCore.js"
SPRITE_EXT = (".png", ".webp", ".gif", ".jpg", ".jpeg")
NAME_RE = re.compile(r"^[\w.-]+\.json$", re.UNICODE)

last_ping = time.time()


def story_dir(base):
    d = base / "story"
    d.mkdir(parents=True, exist_ok=True)
    return d


def list_sprites(base):
    out = {}
    root = base / "sprites"
    if root.is_dir():
        for who in sorted(p for p in root.iterdir() if p.is_dir()):
            out[who.name] = sorted(f.stem for f in who.iterdir() if f.suffix.lower() in SPRITE_EXT)
    return out


def sprite_file(base, who, name):
    d = base / "sprites" / who
    for ext in SPRITE_EXT:
        f = d / (name + ext)
        if f.is_file():
            return f
    return None


TEMPLATE = {
    "id": "", "title": "", "with": "angel", "start": "start",
    "vars": {"trust": 0, "gender": "", "setupGender": ""},
    "nodes": {
        "start": {"type": "event", "trigger": "manual", "next": "hello"},
        "hello": {"type": "say", "who": "angel", "sprite": "neutral", "text": "Привет!", "next": "end"},
        "end": {"type": "end"},
    },
    "pools": {"questions": [], "drops": []},
    "ambient": {"questions": [25, 70], "drops": [30, 90]},
    "layout": {},
}


def make_handler(base):
    class H(BaseHTTPRequestHandler):
        def log_message(self, fmt, *args):
            pass

        def send(self, code, body, ctype="application/json; charset=utf-8"):
            data = body if isinstance(body, bytes) else body.encode()
            self.send_response(code)
            self.send_header("Content-Type", ctype)
            self.send_header("Content-Length", str(len(data)))
            self.send_header("Cache-Control", "no-store")
            self.end_headers()
            self.wfile.write(data)

        def json(self, obj, code=200):
            self.send(code, json.dumps(obj, ensure_ascii=False))

        def story_path(self, q):
            name = (q.get("f") or [""])[0]
            if not NAME_RE.match(name):
                return None
            return story_dir(base) / name

        def do_GET(self):
            global last_ping
            u = urlparse(self.path)
            q = parse_qs(u.query)
            p = u.path
            if p == "/" or p == "/index.html":
                return self.send(200, (HERE / "index.html").read_bytes(), "text/html; charset=utf-8")
            if p in ("/editor.js", "/editor.css"):
                return self.send(200, (HERE / p[1:]).read_bytes(), mimetypes.guess_type(p)[0] + "; charset=utf-8")
            if p == "/fonts/caveat.ttf":
                # the grimoire's handwriting, for the notes in the play-test
                return self.send(200, (HERE.parent.parent / "data/fonts/Caveat-Variable.ttf").read_bytes(), "font/ttf")
            if p == "/core.js":
                src = CORE.read_text().replace(".pragma library", "", 1)
                return self.send(200, src, "text/javascript; charset=utf-8")
            if p == "/api/ping":
                last_ping = time.time()
                return self.json({"ok": True})
            if p == "/api/info":
                return self.json({"dir": str(base), "stories": sorted(f.name for f in story_dir(base).glob("*.json")),
                                  "sprites": list_sprites(base)})
            if p == "/api/story":
                f = self.story_path(q)
                if not f or not f.exists():
                    return self.json({"error": "нет такой главы"}, 404)
                return self.send(200, f.read_bytes())
            if p.startswith("/sprites/"):
                parts = p.split("/")
                if len(parts) == 4:
                    f = sprite_file(base, parts[2], re.sub(r"\.[a-z]+$", "", parts[3]))
                    if f:
                        return self.send(200, f.read_bytes(), mimetypes.guess_type(f.name)[0] or "image/png")
                return self.send(404, b"", "text/plain")
            return self.send(404, b"not found", "text/plain")

        def do_PUT(self):
            u = urlparse(self.path)
            q = parse_qs(u.query)
            if u.path != "/api/story":
                return self.json({"error": "?"}, 404)
            f = self.story_path(q)
            if not f:
                return self.json({"error": "имя главы: латиница, цифры, - _ . и .json"}, 400)
            raw = self.rfile.read(int(self.headers.get("Content-Length") or 0))
            try:
                data = json.loads(raw)
            except ValueError as e:
                return self.json({"error": "не JSON: %s" % e}, 400)
            text = json.dumps(data, ensure_ascii=False, indent=2) + "\n"
            if f.exists():
                if f.read_text() == text:
                    return self.json({"ok": True, "same": True})
                hist = f.parent / ".history"
                hist.mkdir(exist_ok=True)
                shutil.copy2(f, hist / ("%s.%s.json" % (f.stem, time.strftime("%Y%m%d-%H%M%S"))))
                old = sorted(hist.glob(f.stem + ".*.json"))
                for o in old[:-50]:
                    o.unlink()
            tmp = f.with_name(f.name + ".tmp")
            tmp.write_text(text)
            tmp.replace(f)
            return self.json({"ok": True})

        def do_POST(self):
            u = urlparse(self.path)
            q = parse_qs(u.query)
            if u.path == "/api/new":
                f = self.story_path(q)
                if not f:
                    return self.json({"error": "имя главы: латиница, цифры, - _ . и .json"}, 400)
                if f.exists():
                    return self.json({"error": "такая глава уже есть"}, 409)
                st = dict(TEMPLATE, id=f.stem, title=f.stem)
                f.write_text(json.dumps(st, ensure_ascii=False, indent=2) + "\n")
                return self.json({"ok": True})
            if u.path == "/api/open":
                # open the novel folder (or a sprites folder) in the file manager
                sub = (q.get("sub") or [""])[0]
                target = (base / sub) if re.match(r"^[\w/.-]*$", sub) and ".." not in sub else base
                target.mkdir(parents=True, exist_ok=True)
                subprocess.Popen(["xdg-open", str(target)], stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL, start_new_session=True)
                return self.json({"ok": True})
            return self.json({"error": "?"}, 404)

    return H


def open_window(url):
    for b in ("helium-browser", "chromium", "google-chrome-stable", "brave"):
        if shutil.which(b):
            subprocess.Popen([b, "--app=" + url, "--new-window"], stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL, start_new_session=True)
            return
    webbrowser.open(url)


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--dir", default=os.environ.get("ANGELOS_NOVEL_DIR") or str(Path.home() / "AngelOs-Nov"))
    ap.add_argument("--port", type=int, default=0)
    ap.add_argument("--no-open", action="store_true")
    ap.add_argument("--stay", action="store_true", help="don't quit when the page is closed")
    a = ap.parse_args()
    base = Path(os.path.expanduser(a.dir))
    story_dir(base)
    (base / "sprites" / "angel").mkdir(parents=True, exist_ok=True)
    (base / "sprites" / "demon").mkdir(parents=True, exist_ok=True)
    srv = ThreadingHTTPServer(("127.0.0.1", a.port), make_handler(base))
    url = "http://127.0.0.1:%d/" % srv.server_address[1]
    print(url, flush=True)
    if not a.no_open:
        open_window(url)
    if not a.stay:
        def watchdog():
            time.sleep(90)
            while time.time() - last_ping < 60:
                time.sleep(5)
            srv.shutdown()
        threading.Thread(target=watchdog, daemon=True).start()
    try:
        srv.serve_forever()
    except KeyboardInterrupt:
        pass


if __name__ == "__main__":
    main()
