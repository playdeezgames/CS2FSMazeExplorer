#!/usr/bin/env python3
"""630x500 itch.io cover from real wasm frames (needs build/web; run tools/build_web.sh first).
Usage: tools/make_cover.py OUT.png   (writes ppm frames via tools/wasm_node.js, upscales by 2, no deps)"""
import subprocess, sys, zlib, struct, os, tempfile
out = sys.argv[1] if len(sys.argv) > 1 else "assets/cover.png"
here = os.path.dirname(os.path.abspath(__file__))
def frame(seed, keys, path):
    subprocess.run(["node", os.path.join(here, "wasm_node.js"), "dump", str(seed), keys, path], check=True,
                   stdout=subprocess.DEVNULL)
def read_ppm(path):
    d = open(path, "rb").read()
    parts = d.split(b"\n", 3)
    w, h = map(int, parts[1].split())
    return w, h, parts[3]
W, H = 630, 500
img = bytearray(b"\x18\x18\x20" * (W * H))
src = open(os.path.join(here, "..", "odin", "ui", "patterns_gen.odin")).read()
font = [[int(x, 16) for x in row.split(",")] for row in
        __import__("re").findall(r"\{((?:0x[0-9a-f]{2},? ?){8})\}, // \d+", src.split("FONT_PATTERNS")[1])]
def text(s, x, y, k, rgb):
    for ch in s:
        pat = font[ord(ch)]
        for r in range(8):
            for c in range(8):
                if pat[r] & (0x80 >> c):
                    for dy in range(k):
                        for dx in range(k):
                            o = ((y + r * k + dy) * W + x + c * k + dx) * 3
                            img[o:o + 3] = bytes(rgb)
        x += 8 * k
def centred(s, y, k, rgb): text(s, (W - len(s) * 8 * k) // 2, y, k, rgb)
centred("MAZE EXPLORER", 24, 5, (0xf0, 0xc0, 0x30))
centred("of SPLORR!!", 76, 4, (0xc0, 0xc0, 0xd0))
tmp = tempfile.mkdtemp()
fp = os.path.join(tmp, "f.ppm")
frame(7, "12,4,2,1,3,4,1,3,2,2,3,4,1,2,4,1,4,1,4,3,1,3,2,3,3,3,3,1,1,4,4,3,3,4,2,4,4,3,4,1,4,1,2,1,3,3,4,2,2,4,1,2,2,4,2,4,3,2,3,3,3,3,1,4,1,2,1,1,1,2,1,1,3,1,3,4,2,4,3,2,2,4,3,2,2,4,1,1,2,4,2,2,3,2,4,2,4,2,4,3,2,3,4,3,3,1,2,1,1,4,2,4,3,1,3,1,1,3,2,4,3,3,1,2,3,1,2,3,1,1,4,3,3,3,3,3,2,3,4,4,3,1,3,2,1,3,3,2,3,2,3,4,2,2,2,1,4,2,4,3,4,4,2,3,1,3,4,2,4,3,4,2,2,4,2,1,2,3,3,2,2,3,3,4,2,3,4,2,1,3,1,4,4,1,4,3,3,3,4,3,1,3,4,3,1,3,2,2,3,3,4,1,1,3,2,1,2,4,4,2,1,2,1,4,1,2,2,1,4,2,4,2,4,2,3,1,1,2,3,3,3,1,3,4,3,2,2,1,1,2,2,3,2,1,1,1,4,3,4,3,1", fp)
w, h, px = read_ppm(fp)
ox, oy = (W - w * 2) // 2, 130
for y in range(h * 2):
    for x in range(w * 2):
        i = ((y // 2) * w + x // 2) * 3
        o = ((oy + y) * W + ox + x) * 3
        img[o:o + 3] = px[i:i + 3]
raw = b"".join(b"\0" + bytes(img[y * W * 3:(y + 1) * W * 3]) for y in range(H))
def chunk(t, d): c = struct.pack(">I", len(d)) + t + d; return c + struct.pack(">I", zlib.crc32(t + d))
png = b"\x89PNG\r\n\x1a\n" + chunk(b"IHDR", struct.pack(">IIBBBBB", W, H, 8, 2, 0, 0, 0)) + chunk(b"IDAT", zlib.compress(raw)) + chunk(b"IEND", b"")
os.makedirs(os.path.dirname(os.path.abspath(out)), exist_ok=True)
open(out, "wb").write(png)
print("wrote", out)
