#!/usr/bin/env python3
"""Generate the NEXORA BIOS/UEFI installer background using only Python stdlib."""
import math
import struct
import sys
import zlib

WIDTH, HEIGHT = 1280, 720
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

def png_chunk(kind, data):
    body = kind + data
    return struct.pack(">I", len(data)) + body + struct.pack(">I", zlib.crc32(body) & 0xffffffff)

pixels = bytearray(WIDTH * HEIGHT * 3)

def pixel(x, y, color):
    if 0 <= x < WIDTH and 0 <= y < HEIGHT:
        offset = (y * WIDTH + x) * 3
        pixels[offset:offset + 3] = bytes(color)

def rect(x, y, width, height, color):
    for yy in range(y, y + height):
        for xx in range(x, x + width):
            pixel(xx, yy, color)

def line(x1, y1, x2, y2, color, thickness=2):
    steps = max(abs(x2 - x1), abs(y2 - y1), 1)
    radius = max(0, thickness // 2)
    for step in range(steps + 1):
        x = round(x1 + (x2 - x1) * step / steps)
        y = round(y1 + (y2 - y1) * step / steps)
        rect(x - radius, y - radius, thickness, thickness, color)

def arc(cx, cy, rx, ry, start, end, color, thickness=3):
    points = max(100, int(abs(end - start) * max(rx, ry) / 90))
    previous = None
    for index in range(points + 1):
        angle = math.radians(start + (end - start) * index / points)
        current = (round(cx + math.cos(angle) * rx), round(cy + math.sin(angle) * ry))
        if previous:
            line(previous[0], previous[1], current[0], current[1], color, thickness)
        previous = current

def text(value, x, y, scale, color, spacing=2):
    cursor = x
    for char in value:
        for row, bits in enumerate(FONT[char]):
            for col, bit in enumerate(bits):
                if bit == "1":
                    rect(cursor + col * scale, y + row * scale, scale, scale, color)
        cursor += (5 + spacing) * scale
    return cursor

# Midnight-blue gradient and cyan/blue aurora glows.
for y in range(HEIGHT):
    ny = y / HEIGHT
    for x in range(WIDTH):
        nx = x / WIDTH
        upper = math.exp(-(((nx - .83) / .38) ** 2 + ((ny - .12) / .42) ** 2) * 2.0)
        lower = math.exp(-(((nx - .18) / .40) ** 2 + ((ny - .91) / .42) ** 2) * 2.0)
        pixel(x, y, (
            min(255, int(3 + 9 * ny + 14 * upper + 10 * lower)),
            min(255, int(7 + 13 * ny + 58 * upper + 18 * lower)),
            min(255, int(20 + 25 * ny + 112 * upper + 66 * lower)),
        ))

# Soft, sweeping aurora ribbons frame the menu area without obscuring its text.
arc(1110, 80, 520, 370, 8, 190, (0, 91, 186), 5)
arc(1110, 80, 490, 340, 8, 190, (0, 188, 238), 2)
arc(90, 760, 600, 430, 190, 350, (0, 95, 220), 7)
arc(90, 760, 570, 400, 190, 350, (0, 208, 255), 3)
arc(650, 930, 780, 210, 205, 335, (24, 66, 202), 4)
arc(650, 930, 760, 190, 205, 335, (0, 190, 255), 2)

# NEXORA wordmark and a restrained large N emblem.
text("NEXORA OS", 112, 104, 13, (239, 248, 255), spacing=2)
text("YOUR TERMINAL YOUR UNIVERSE", 118, 222, 4, (94, 207, 239), spacing=2)
text("NEXORA INSTALLER", 850, 132, 4, (155, 224, 246), spacing=2)

# Oversized geometric N watermark on the right.
line(1000, 340, 1000, 620, (13, 57, 124), 26)
line(1000, 340, 1190, 620, (13, 57, 124), 26)
line(1190, 340, 1190, 620, (13, 57, 124), 26)
line(1000, 340, 1000, 620, (15, 91, 165), 5)
line(1000, 340, 1190, 620, (15, 91, 165), 5)
line(1190, 340, 1190, 620, (15, 91, 165), 5)

# Bottom horizon rail and compact release signature.
arc(640, 850, 900, 180, 205, 335, (0, 83, 195), 5)
arc(640, 850, 875, 158, 205, 335, (0, 190, 255), 2)
rect(48, 680, WIDTH - 96, 2, (0, 93, 153))
rect(48, 680, 230, 2, (0, 213, 255))
text("NEXORA OS", 1030, 682, 3, (151, 199, 226), spacing=2)

raw = b"".join(b"\0" + pixels[y * WIDTH * 3:(y + 1) * WIDTH * 3] for y in range(HEIGHT))
png = (
    b"\x89PNG\r\n\x1a\n"
    + png_chunk(b"IHDR", struct.pack(">2I5B", WIDTH, HEIGHT, 8, 2, 0, 0, 0))
    + png_chunk(b"IDAT", zlib.compress(raw, 9))
    + png_chunk(b"IEND", b"")
)
if len(sys.argv) != 2:
    raise SystemExit("Usage: create-installer-background.py OUTPUT.png")
with open(sys.argv[1], "wb") as output:
    output.write(png)
print(f"Created NEXORA installer background: {sys.argv[1]} ({WIDTH}x{HEIGHT}, {len(png)} bytes)")
