#!/usr/bin/env python3
"""gen-wallpapers.py — generate base wallpapers (gradients) as pure PNGs.

No external deps (uses zlib/struct). Renders a few coordinated gradients into
./wallpapers/ so there's something to pick before you drop your own images.

Usage:  python3 gen-wallpapers.py [WIDTH] [HEIGHT]
"""
import struct
import sys
import zlib
from pathlib import Path

OUT = Path(__file__).resolve().parent.parent / "wallpapers"


def chunk(tag: bytes, data: bytes) -> bytes:
    return struct.pack(">I", len(data)) + tag + data + struct.pack(">I", zlib.crc32(tag + data) & 0xFFFFFFFF)


def write_png(path: Path, w: int, h: int, flat: bytes):
    ihdr = struct.pack(">IIBBBBB", w, h, 8, 2, 0, 0, 0)
    stride = w * 3
    raw = b"".join(b"\x00" + flat[y * stride:(y + 1) * stride] for y in range(h))
    idat = zlib.compress(raw, 9)
    png = (b"\x89PNG\r\n\x1a\n"
           + chunk(b"IHDR", ihdr)
           + chunk(b"IDAT", idat)
           + chunk(b"IEND", b""))
    path.write_bytes(png)


def gradient(w: int, h: int, top, bottom) -> bytes:
    rows = bytearray()
    for y in range(h):
        t = y / (h - 1)
        row = bytearray()
        for i in range(3):
            row.append(int(top[i] + (bottom[i] - top[i]) * t))
        rows += row * w
    return bytes(rows)


THEMES = {
    "dusk":     ((26, 27, 38),  (122, 162, 247)),
    "midnight": ((15, 16, 24),  (76, 82, 105)),
    "aurora":   ((10, 30, 30),  (30, 180, 160)),
    "ember":    ((35, 12, 24),  (224, 108, 117)),
    "forest":   ((12, 28, 22),  (84, 140, 110)),
    "violet":   ((30, 20, 45),  (150, 120, 220)),
}


def main():
    w, h = (int(a) for a in sys.argv[1:3]) if len(sys.argv) >= 3 else (2560, 1440)
    OUT.mkdir(exist_ok=True)
    for name, (top, bottom) in THEMES.items():
        path = OUT / f"base-{name}.png"
        write_png(path, w, h, gradient(w, h, top, bottom))
        print(f"wrote {path.relative_to(OUT.parent)} ({w}x{h})")
    print(f"\n{len(THEMES)} base wallpapers in {OUT}")


if __name__ == "__main__":
    main()
