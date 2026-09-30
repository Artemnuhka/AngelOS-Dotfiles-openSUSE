#!/usr/bin/env python3
"""Search index of the settings pages, read straight from their QML.

  settings-index.py [pages dir …]  -> JSON list of entries:
      {"page": "appearance", "kind": "page|group|row", "ru": …, "en": …,
       "group": {"ru","en"} (rows), "hint": {"ru","en"}, "words": {"ru","en"}}

Every I18n.t("…", "…") pair is picked up: page headings and subtitles, PxGroup
titles, SettingRow labels and hints, and the texts inside a row or group
(options, buttons) as extra words. New settings become searchable by themselves.
"""
import json
import re
import sys
from pathlib import Path

PAIR = re.compile(r'I18n\.t\(\s*"((?:[^"\\]|\\.)*)"\s*,\s*"((?:[^"\\]|\\.)*)"\s*\)')
PROP = re.compile(r'^\s*"?(heading|subtitle|title|label|hint|text|placeholder)"?\s*:\s*(.*)$')
OPEN = re.compile(r"^\s*([A-Z][\w.]*)\s*\{")


def unescape(s):
    return re.sub(r"\\(.)", r"\1", s)


def page_id(path):
    name = path.stem[:-4] if path.stem.endswith("Page") else path.stem
    return name[:1].lower() + name[1:]


def index_page(path):
    pid = page_id(path)
    out = []
    stack = []  # [(component, depth, entry or None)]
    depth = 0
    page = {"page": pid, "kind": "page", "ru": "", "en": "", "hint": {"ru": "", "en": ""}, "words": {"ru": [], "en": []}}
    out.append(page)

    def owner():
        for comp, _, entry in reversed(stack):
            if entry is not None:
                return entry
        return page

    for line in path.read_text().splitlines():
        code = line.split("//")[0] if "//" in line and '"' not in line.split("//")[0] else line
        m = OPEN.match(code)
        if m:
            comp = m.group(1)
            entry = None
            if comp == "PxGroup":
                entry = {"page": pid, "kind": "group", "ru": "", "en": "", "hint": {"ru": "", "en": ""}, "words": {"ru": [], "en": []}}
            elif comp == "SettingRow":
                grp = next((e for c, _, e in reversed(stack) if c == "PxGroup" and e), None)
                entry = {"page": pid, "kind": "row", "ru": "", "en": "", "hint": {"ru": "", "en": ""}, "words": {"ru": [], "en": []},
                         "group": {"ru": grp["ru"], "en": grp["en"]} if grp else {"ru": "", "en": ""}}
            if entry is not None:
                out.append(entry)
            stack.append((comp, depth, entry))
        p = PROP.match(code)
        pairs = [(unescape(a), unescape(b)) for a, b in PAIR.findall(code)]
        if p and pairs:
            prop = p.group(1)
            e = owner()
            cur = stack[-1][0] if stack else ""
            if prop == "heading" and e is page:
                page["ru"], page["en"] = pairs[0]
            elif prop == "subtitle" and e is page:
                page["hint"] = {"ru": pairs[0][0], "en": pairs[0][1]}
            elif prop == "title" and cur == "PxGroup" and e and e["kind"] == "group" and not e["ru"]:
                e["ru"], e["en"] = pairs[0]
            elif prop == "label" and cur == "SettingRow" and e and e["kind"] == "row" and not e["ru"]:
                e["ru"], e["en"] = pairs[0]
            elif prop == "hint" and cur == "SettingRow" and e and e["kind"] == "row":
                if len(pairs) == 1 and not e["hint"]["ru"]:
                    e["hint"] = {"ru": pairs[0][0], "en": pairs[0][1]}
                else:
                    for ru, en in pairs:
                        e["words"]["ru"].append(ru)
                        e["words"]["en"].append(en)
            else:
                for ru, en in pairs:
                    e["words"]["ru"].append(ru)
                    e["words"]["en"].append(en)
        elif pairs:
            e = owner()
            for ru, en in pairs:
                e["words"]["ru"].append(ru)
                e["words"]["en"].append(en)
        depth += code.count("{") - code.count("}")
        while stack and depth <= stack[-1][1]:
            stack.pop()
    # rows without a literal label (built from a model) are not reachable by name
    return [e for e in out if e["ru"] or e["kind"] == "page"]


def main():
    here = Path(__file__).resolve().parent.parent
    dirs = [Path(a) for a in sys.argv[1:]] or [here / "modules/settings/pages"]
    entries = []
    for d in dirs:
        files = [d] if d.is_file() else sorted(d.glob("*Page.qml"))
        for f in files:
            if f.name == "PluginSettingsPage.qml":
                continue
            try:
                entries += index_page(f)
            except OSError:
                pass
    for e in entries:  # keep the extra words short and unique
        for lang in ("ru", "en"):
            seen, words = set(), []
            for w in e["words"][lang]:
                w = w.strip()
                if w and w not in seen and len(w) < 160:
                    seen.add(w)
                    words.append(w)
            e["words"][lang] = words[:40]
    print(json.dumps(entries, ensure_ascii=False))


if __name__ == "__main__":
    main()
