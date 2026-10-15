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
W, H, S = 630, 500, 2
img = bytearray(b"\x10\x10\x10" * (W * H))
tmp = tempfile.mkdtemp()
fp = os.path.join(tmp, "f.ppm")
frame(42, "12,4,4,2,4,4,2,2,4,4,4,2,2,4", fp)
w, h, px = read_ppm(fp)
ox, oy = (W - w * 2) // 2, 40
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
