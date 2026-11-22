#!/usr/bin/env python3
"""Generate NEXORA's branded BIOS/UEFI boot splash with only Python stdlib."""
import math
import struct
import sys
import zlib

WIDTH, HEIGHT = 1024, 640
FONT = {
    "A": ("01110","10001","10001","11111","10001","10001","10001"),
    "E": ("11111","10000","10000","11110","10000","10000","11111"),
    "N": ("10001","11001","10101","10011","10001","10001","10001"),
    "O": ("01110","10001","10001","10001","10001","10001","01110"),
    "R": ("11110","10001","10001","11110","10100","10010","10001"),
    "S": ("01111","10000","10000","01110","00001","00001","11110"),
    "I": ("11111","00100","00100","00100","00100","00100","11111"),
    "L": ("10000","10000","10000","10000","10000","10000","11111"),
    "M": ("10001","11011","10101","10101","10001","10001","10001"),
    "T": ("11111","00100","00100","00100","00100","00100","00100"),
    "U": ("10001","10001","10001","10001","10001","10001","01110"),
    "V": ("10001","10001","10001","10001","10001","01010","00100"),
    "Y": ("10001","10001","01010","00100","00100","00100","00100"),
    "X": ("10001","10001","01010","00100","01010","10001","10001"),
    " ": ("00000",)*7,
}

def chunk(kind, data):
    body = kind + data
    return struct.pack(">I", len(data)) + body + struct.pack(">I", zlib.crc32(body) & 0xffffffff)

pixels = bytearray(WIDTH * HEIGHT * 3)

def set_pixel(x, y, color):
    if 0 <= x < WIDTH and 0 <= y < HEIGHT:
        pos = (y * WIDTH + x) * 3
        pixels[pos:pos+3] = bytes(color)

def rect(x, y, w, h, color):
    for yy in range(y, y+h):
        for xx in range(x, x+w):
            set_pixel(xx, yy, color)

# Deep navy gradient with two cyan/blue aurora glows.
for y in range(HEIGHT):
    ny = y / HEIGHT
    for x in range(WIDTH):
        nx = x / WIDTH
        glow1 = math.exp(-(((nx-.78)/.36)**2 + ((ny-.25)/.52)**2)*2.0)
        glow2 = math.exp(-(((nx-.18)/.40)**2 + ((ny-.82)/.48)**2)*2.0)
        set_pixel(x, y, (
            min(255, int(5 + 12*ny + 20*glow1 + 13*glow2)),
            min(255, int(9 + 18*ny + 74*glow1 + 20*glow2)),
            min(255, int(24 + 30*ny + 118*glow1 + 70*glow2)),
        ))

# Subtle technical grid and glowing accent rail.
for x in range(40, WIDTH, 64):
    rect(x, 0, 1, HEIGHT, (13, 28, 53))
for y in range(32, HEIGHT, 64):
    rect(0, y, WIDTH, 1, (13, 28, 53))
rect(78, 112, 5, 416, (58, 203, 246))
rect(90, 112, 1, 416, (28, 101, 148))

def draw_text(text, x, y, scale, color, spacing=2):
    cursor = x
    for ch in text:
        glyph = FONT[ch]
        for gy, row in enumerate(glyph):
            for gx, bit in enumerate(row):
                if bit == "1":
                    rect(cursor + gx*scale, y + gy*scale, scale, scale, color)
        cursor += (5 + spacing) * scale
    return cursor

# Clear wordmark and tagline remain readable on low-resolution boot screens.
draw_text("NEXORA OS", 132, 220, 11, (238, 247, 255), spacing=2)
draw_text("YOUR TERMINAL YOUR UNIVERSE", 136, 322, 4, (112, 199, 231), spacing=2)

# Large angular N emblem at the right, as a soft brand signature.
for y in range(155, 475):
    left = 700
    right = 875
    rect(left, y, 9, 1, (49, 177, 228))
    rect(right, y, 9, 1, (49, 177, 228))
for i in range(0, 320):
    x = 875 - int(i * .55)
    y = 155 + i
    rect(x, y, 7, 1, (42, 139, 204))

# Footer label and progress-like accent.
rect(132, 430, 290, 2, (35, 89, 133))
rect(132, 430, 82, 2, (58, 203, 246))
draw_text("NEXORA LIVE SYSTEM", 132, 458, 3, (119, 161, 190), spacing=2)

raw = b"".join(b"\0" + pixels[y*WIDTH*3:(y+1)*WIDTH*3] for y in range(HEIGHT))
png = (b"\x89PNG\r\n\x1a\n" +
       chunk(b"IHDR", struct.pack(">2I5B", WIDTH, HEIGHT, 8, 2, 0, 0, 0)) +
       chunk(b"IDAT", zlib.compress(raw, 9)) +
       chunk(b"IEND", b""))
if len(sys.argv) != 2:
    raise SystemExit("Usage: create-installer-background.py OUTPUT.png")
with open(sys.argv[1], "wb") as output:
    output.write(png)
print(f"Created NEXORA boot background: {sys.argv[1]} ({len(png)} bytes)")
