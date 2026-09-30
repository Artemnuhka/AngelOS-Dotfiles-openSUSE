#!/usr/bin/env python3
"""The connected keyboard, mouse and microphone worth showing off: popular models
that cost more than the threshold ($100 by default), from data/premium-gear.json.

  gear.py                  -> {"threshold": 100, "devices": [{"kind", "name", "usd", "via"}]}
  gear.py --kind keyboard  -> "NuPhy Air60 HE (~$120)" for fastfetch's command
                              module; nothing (exit 1) if there is none, so
                              fastfetch leaves the line out
  gear.py --threshold N    -> another limit

Sources (read-only, no root, no daemons asked): USB vendor:product and product
strings from /sys (HID interfaces for keyboards and mice, audio interfaces for
microphones), input device names from /proc/bus/input/devices (Bluetooth ones
too) and sound card names from /proc/asound/cards.
"""
import argparse
import json
import re
import sys
from pathlib import Path

HERE = Path(__file__).resolve().parent
DATA = HERE.parent / "data/premium-gear.json"
HID, AUDIO = "03", "01"


def read(path):
    try:
        return Path(path).read_text(errors="replace").strip()
    except OSError:
        return ""


def usb_devices():
    """[(vid:pid, "manufacturer product", {interface classes})]"""
    out = []
    for dev in Path("/sys/bus/usb/devices").glob("*"):
        vid, pid = read(dev / "idVendor"), read(dev / "idProduct")
        if not vid:
            continue
        classes = {read(i / "bInterfaceClass") for i in dev.glob(dev.name + ":*")}
        out.append((f"{vid}:{pid}".lower(), (read(dev / "manufacturer") + " " + read(dev / "product")).strip(), classes))
    return out


def input_names():
    return re.findall(r'^N: Name="(.*)"$', read("/proc/bus/input/devices"), re.M)


def sound_cards():
    # " 3 [Duo            ]: USB-Audio - RODECaster Duo" and its long name on the next line
    return [l.strip() for l in read("/proc/asound/cards").splitlines() if l.strip()]


def things():
    """every device to look at: (label, usb id or "", kinds it may be)"""
    out = []
    for vp, label, classes in usb_devices():
        kinds = (["keyboard", "mouse"] if HID in classes else []) + (["mic"] if AUDIO in classes else [])
        if kinds:
            out.append((label, vp, kinds))
    out += [(n, "", ["keyboard", "mouse"]) for n in input_names()]
    out += [(n, "", ["mic"]) for n in sound_cards()]
    return out


def detect(threshold):
    data = json.loads(DATA.read_text())
    entries = [dict(e, rx=re.compile(e["match"], re.I)) for e in data["devices"]]
    found = {}
    for label, vp, kinds in things():
        # an exact USB id first, else the first pattern in file order (specific ones come first)
        entry = next((e for e in entries if e["kind"] in kinds and vp and vp in [u.lower() for u in e.get("usb", [])]), None)
        if not entry:
            entry = next((e for e in entries if e["kind"] in kinds and e["rx"].search(label)), None)
        if entry and entry["name"] not in found:
            found[entry["name"]] = {"kind": entry["kind"], "name": entry["name"], "usd": entry["usd"], "via": vp or label}
    order = {"keyboard": 0, "mouse": 1, "mic": 2}
    devices = sorted((d for d in found.values() if d["usd"] > threshold), key=lambda d: (order.get(d["kind"], 9), -d["usd"]))
    return threshold, devices


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--kind", choices=["keyboard", "mouse", "mic"])
    parser.add_argument("--threshold", type=float, default=None)
    args = parser.parse_args()
    data_threshold = json.loads(DATA.read_text()).get("threshold", 100)
    threshold, devices = detect(data_threshold if args.threshold is None else args.threshold)
    if args.kind:
        mine = [d for d in devices if d["kind"] == args.kind]
        if not mine:
            return 1
        print(", ".join(f"{d['name']} (~${round(d['usd'])})" for d in mine))
        return 0
    print(json.dumps({"threshold": threshold, "devices": devices}, ensure_ascii=False))
    return 0


if __name__ == "__main__":
    sys.exit(main())
