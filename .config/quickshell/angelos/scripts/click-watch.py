#!/usr/bin/env python3
"""Report mouse clicks for the Y2K "Click" sound (Settings → Y2K → Sounds).

Prints "click" for every left or right button press on any mouse or touchpad,
anywhere on the desktop (the shell only sees clicks on its own windows, so this
reads evdev like meta-tap.py; needs the `input` group). Runs only while the
click sound is on.

  noperm   no pointer device could be opened

Privacy: nothing but "a button went down" is printed — no positions, no keys.
Devices are opened read-only and never grabbed.
"""
import glob
import os
import select
import struct
import sys
import time

EV_KEY, BTN_LEFT, BTN_RIGHT = 1, 272, 273
EVENT = struct.Struct("llHHi")


def has_button(event_dir):
    try:
        words = open(os.path.join(event_dir, "device/capabilities/key")).read().split()
    except OSError:
        return False
    bits = 0
    for word in words:
        bits = (bits << 64) | int(word, 16)
    return bool(bits >> BTN_LEFT & 1)


def main():
    fds = {}
    said_noperm = False
    last_scan = 0.0
    while True:
        now = time.monotonic()
        if now - last_scan > 5:
            last_scan = now
            denied = 0
            seen = set()
            for event_dir in glob.glob("/sys/class/input/event*"):
                path = "/dev/input/" + os.path.basename(event_dir)
                seen.add(path)
                if path in fds or not has_button(event_dir):
                    continue
                try:
                    fds[path] = os.open(path, os.O_RDONLY | os.O_NONBLOCK)
                except PermissionError:
                    denied += 1
                except OSError:
                    pass
            for path in [p for p in fds if p not in seen]:
                os.close(fds.pop(path))
            if denied and not fds and not said_noperm:
                said_noperm = True
                print("noperm", flush=True)
        if not fds:
            time.sleep(1)
            continue
        ready, _, _ = select.select(list(fds.values()), [], [], 1.0)
        for fd in ready:
            try:
                data = os.read(fd, EVENT.size * 64)
            except OSError:
                for path, f in list(fds.items()):
                    if f == fd:
                        os.close(fds.pop(path))
                continue
            for off in range(0, len(data) - EVENT.size + 1, EVENT.size):
                _, _, kind, code, value = EVENT.unpack_from(data, off)
                if kind == EV_KEY and code in (BTN_LEFT, BTN_RIGHT) and value == 1:
                    print("click", flush=True)


if __name__ == "__main__":
    try:
        main()
    except KeyboardInterrupt:
        pass
