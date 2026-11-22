#!/usr/bin/env python3
"""Create the 800x75 NEXORA GTK installer banner without external libraries."""
import struct
import sys
import zlib

W, H = 800, 75
FONT = {
    "A": ("01110","10001","10001","11111","10001","10001","10001"),
    "E": ("11111","10000","10000","11110","10000","10000","11111"),
    "I": ("11111","00100","00100","00100","00100","00100","11111"),
    "L": ("10000","10000","10000","10000","10000","10000","11111"),
    "M": ("10001","11011","10101","10101","10001","10001","10001"),
    "N": ("10001","11001","10101","10011","10001","10001","10001"),
    "O": ("01110","10001","10001","10001","10001","10001","01110"),
    "R": ("11110","10001","10001","11110","10100","10010","10001"),
    "S": ("01111","10000","10000","01110","00001","00001","11110"),
    "T": ("11111","00100","00100","00100","00100","00100","00100"),
    "X": ("10001","10001","01010","00100","01010","10001","10001"),
    "Y": ("10001","10001","01010","00100","00100","00100","00100"),
    " ": ("00000",)*7,
}

def chunk(kind, data):
    body = kind + data
    return struct.pack(">I", len(data)) + body + struct.pack(">I", zlib.crc32(body) & 0xffffffff)

def render(path, dark):
    pixels = bytearray(W * H * 4)
    def dot(x, y, color):
        if 0 <= x < W and 0 <= y < H:
            p = (y * W + x) * 4
            pixels[p:p+4] = bytes((*color, 255))
    def rect(x, y, w, h, color):
        for yy in range(y, y+h):
            for xx in range(x, x+w):
                dot(xx, yy, color)
    # Thin cyan/violet accent rail and angular N mark.
    cyan = (94, 220, 255) if dark else (0, 132, 184)
    white = (242, 248, 255) if dark else (13, 27, 48)
    muted = (154, 190, 211) if dark else (57, 83, 111)
    rect(28, 15, 3, 45, cyan)
    for n in range(25):
        rect(43+n, 20+n, 3, 3, cyan)
        rect(43+n, 48-n, 3, 3, cyan)
    rect(43, 20, 3, 29, cyan)
    rect(68, 20, 3, 29, cyan)
    # Wordmark, large 5x7 bitmap font.
    x0, y0, scale = 94, 13, 6
    for ch in "NEXORA":
        glyph = FONT[ch]
        for gy, row in enumerate(glyph):
            for gx, bit in enumerate(row):
                if bit == "1":
                    rect(x0 + gx*scale, y0 + gy*scale, scale-1, scale-1, white)
        x0 += 38
    # Secondary OS marker.
    x0 = 340
    for ch in "OS":
        glyph = FONT[ch]
        for gy, row in enumerate(glyph):
            for gx, bit in enumerate(row):
                if bit == "1":
                    rect(x0 + gx*3, 29 + gy*3, 2, 2, cyan)
        x0 += 19
    # Tagline.
    x0, y0, scale = 96, 59, 2
    for ch in "SYSTEM INSTALLER":
        glyph = FONT[ch]
        for gy, row in enumerate(glyph):
            for gx, bit in enumerate(row):
                if bit == "1":
                    rect(x0 + gx*scale, y0 + gy*scale, scale, scale, muted)
        x0 += 12
    # Right edge decorative status bars.
    rect(690, 27, 4, 21, cyan)
    rect(701, 34, 4, 14, muted)
    rect(712, 40, 4, 8, muted)
    raw = b"".join(b"\0" + pixels[y*W*4:(y+1)*W*4] for y in range(H))
    png = (b"\x89PNG\r\n\x1a\n" +
           chunk(b"IHDR", struct.pack(">2I5B", W, H, 8, 6, 0, 0, 0)) +
           chunk(b"IDAT", zlib.compress(raw, 9)) +
           chunk(b"IEND", b""))
    with open(path, "wb") as f:
        f.write(png)
    print(f"Created {'dark' if dark else 'light'} NEXORA GTK logo: {path}")

if len(sys.argv) != 3:
    raise SystemExit("Usage: create-installer-logo.py LIGHT.png DARK.png")
render(sys.argv[1], False)
render(sys.argv[2], True)
