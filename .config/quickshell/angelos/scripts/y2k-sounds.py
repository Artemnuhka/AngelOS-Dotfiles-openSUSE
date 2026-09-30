#!/usr/bin/env python3
"""The angelOS Y2K sound pack, synthesised on the spot (no samples, no licences).

  y2k-sounds.py <dir>        writes startup/notify/error/click/shutdown/angel .ogg
                             (or .wav when ffmpeg is missing) and prints JSON

Chimes are FM bells and detuned triangle pads with a small echo, levelled to
about -6 dBFS so they sit under music and voice.
"""
import json
import math
import shutil
import subprocess
import sys
import wave
from pathlib import Path

import numpy as np

RATE = 44100


def t_axis(sec):
    return np.arange(int(sec * RATE)) / RATE


def env(n, attack=0.005, release=0.2, sec=None):
    t = np.arange(n) / RATE
    total = n / RATE
    a = np.clip(t / max(attack, 1e-4), 0, 1)
    r = np.clip((total - t) / max(release, 1e-4), 0, 1)
    return a * r


def bell(freq, sec, index=2.0, ratio=3.5, decay=4.0):
    t = t_axis(sec)
    mod = np.sin(2 * np.pi * freq * ratio * t) * index * np.exp(-t * decay * 1.5)
    return np.sin(2 * np.pi * freq * t + mod) * np.exp(-t * decay)


def tri(freq, sec, detune=0.0):
    t = t_axis(sec)
    out = np.zeros_like(t)
    for d in (-detune, 0.0, detune):
        ph = (freq * (1 + d) * t) % 1.0
        out += 2 * np.abs(2 * ph - 1) - 1
    return out / 3


def square(freq, sec):
    t = t_axis(sec)
    return np.sign(np.sin(2 * np.pi * freq * t))


def place(buf, sound, at):
    i = int(at * RATE)
    end = min(len(buf), i + len(sound))
    buf[i:end] += sound[:end - i]


def echo(x, delay=0.18, fb=0.35, taps=4):
    out = x.copy()
    d = int(delay * RATE)
    for k in range(1, taps + 1):
        shifted = np.zeros_like(x)
        shifted[d * k:] = x[:len(x) - d * k] if d * k < len(x) else 0
        out += shifted * fb ** k
    return out


def note(n):
    """MIDI note -> Hz"""
    return 440.0 * 2 ** ((n - 69) / 12)


def level(x, peak_db=-6.0):
    m = np.max(np.abs(x)) or 1.0
    return x / m * 10 ** (peak_db / 20)


def startup():
    # soft pad (Cmaj9 → Fmaj7/C) under a rising bell arpeggio and a sparkle
    sec = 2.6
    buf = np.zeros(int(sec * RATE))
    for n in (48, 55, 64, 67, 71, 74):
        pad = tri(note(n), sec, detune=0.004) * env(int(sec * RATE), attack=0.35, release=1.2)
        buf += pad * 0.16
    for i, n in enumerate((72, 76, 79, 83, 86, 88)):
        place(buf, bell(note(n), 1.4, index=1.6, decay=3.2) * 0.5, 0.12 + i * 0.11)
    for i, n in enumerate((96, 100, 103)):
        place(buf, bell(note(n), 0.5, index=0.8, decay=8) * 0.25, 1.05 + i * 0.07)
    return echo(buf, 0.21, 0.3)


def notify():
    sec = 0.9
    buf = np.zeros(int(sec * RATE))
    place(buf, bell(note(88), 0.7, index=1.2, decay=6), 0.0)
    place(buf, bell(note(83), 0.8, index=1.2, decay=5), 0.13)
    return echo(buf, 0.12, 0.25, 2)


def error():
    sec = 0.45
    t = t_axis(sec)
    f = 220 * np.exp(-t * 3.0)
    ph = np.cumsum(f) / RATE
    x = np.sign(np.sin(2 * np.pi * ph)) * 0.6 + np.sin(2 * np.pi * ph * 0.5) * 0.4
    return x * env(len(t), 0.003, 0.25)


def click():
    sec = 0.035
    t = t_axis(sec)
    return np.sin(2 * np.pi * 2400 * t) * np.exp(-t * 180)


def shutdown():
    sec = 1.8
    buf = np.zeros(int(sec * RATE))
    for i, n in enumerate((88, 84, 79, 76, 72, 67)):
        place(buf, bell(note(n), 1.0, index=1.4, decay=3.8) * 0.55, i * 0.13)
    pad = tri(note(48), sec, detune=0.003) * env(int(sec * RATE), 0.2, 1.3) * 0.2
    return echo(buf + pad, 0.22, 0.28)


def angel():
    sec = 0.8
    buf = np.zeros(int(sec * RATE))
    for i, n in enumerate((91, 95, 98)):
        place(buf, bell(note(n), 0.5, index=0.7, decay=7) * 0.6, i * 0.06)
    return echo(buf, 0.09, 0.3, 3)


SOUNDS = {"startup": startup, "notify": notify, "error": error, "click": click, "shutdown": shutdown, "angel": angel}


def write_wav(path, x):
    pcm = (np.clip(x, -1, 1) * 32767).astype("<i2")
    stereo = np.repeat(pcm[:, None], 2, axis=1)
    with wave.open(str(path), "wb") as w:
        w.setnchannels(2)
        w.setsampwidth(2)
        w.setframerate(RATE)
        w.writeframes(stereo.tobytes())


def main():
    out = Path(sys.argv[1] if len(sys.argv) > 1 else Path.home() / ".local/share/angelos/sounds/y2k")
    out.mkdir(parents=True, exist_ok=True)
    ffmpeg = shutil.which("ffmpeg")
    made = {}
    for name, fn in SOUNDS.items():
        x = level(fn())
        wav = out / (name + ".wav")
        write_wav(wav, x)
        if ffmpeg:
            ogg = out / (name + ".ogg")
            r = subprocess.run([ffmpeg, "-y", "-loglevel", "error", "-i", str(wav), "-c:a", "libvorbis", "-q:a", "5", str(ogg)])
            if r.returncode == 0:
                wav.unlink()
                made[name] = str(ogg)
                continue
        made[name] = str(wav)
    print(json.dumps({"ok": True, "sounds": made}))


if __name__ == "__main__":
    main()
