#!/usr/bin/env python3
"""Generate an original NEXORA installer background PNG using only stdlib."""
import math
import struct
import sys
import zlib

WIDTH, HEIGHT = 1024, 640
def chunk(kind, data):
    body = kind + data
    return struct.pack(">I", len(data)) + body + struct.pack(">I", zlib.crc32(body) & 0xffffffff)

rows = []
for y in range(HEIGHT):
    row = bytearray([0])
    for x in range(WIDTH):
        nx, ny = x / WIDTH, y / HEIGHT
        glow_a = math.exp(-(((nx - .78) / .36) ** 2 + ((ny - .28) / .55) ** 2) * 2.0)
        glow_b = math.exp(-(((nx - .22) / .34) ** 2 + ((ny - .78) / .42) ** 2) * 2.0)
        base = (int(5 + 10 * ny), int(8 + 13 * ny), int(22 + 28 * ny))
        r = min(255, int(base[0] + 32 * glow_a + 35 * glow_b))
        g = min(255, int(base[1] + 92 * glow_a + 18 * glow_b))
        b = min(255, int(base[2] + 130 * glow_a + 80 * glow_b))
        in_n = (abs(x - (300 + .55 * (y - 245))) < 7 or abs(x - (410 - .55 * (y - 245))) < 7) and 245 <= y <= 395
        if in_n:
            r, g, b = 80, 205, 245
        row.extend((r, g, b))
    rows.append(bytes(row))
raw = b"".join(rows)
png = (b"\x89PNG\r\n\x1a\n" +
       chunk(b"IHDR", struct.pack(">2I5B", WIDTH, HEIGHT, 8, 2, 0, 0, 0)) +
       chunk(b"IDAT", zlib.compress(raw, 9)) +
       chunk(b"IEND", b""))
if len(sys.argv) != 2:
    raise SystemExit("Usage: create-installer-background.py OUTPUT.png")
with open(sys.argv[1], "wb") as output:
    output.write(png)
print(f"Created NEXORA installer background: {sys.argv[1]} ({len(png)} bytes)")
