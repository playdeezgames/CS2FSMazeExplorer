#!/usr/bin/env python3
"""assets/screenshots/*.png: real frames (4x, nearest neighbour) from the native replay, which draws
what the wasm build draws (tools/parity.sh). Usage: tools/make_screenshots.py"""
import os, re, struct, subprocess, tempfile, zlib
here = os.path.dirname(os.path.abspath(__file__))
root = os.path.join(here, "..")
odin = os.environ.get("ODIN", os.path.expanduser("~/ODIN/odin"))
os.makedirs(os.path.join(root, "build"), exist_ok=True)
subprocess.run([odin, "build", os.path.join(root, "odin", "tools", "replay"), "-out:" + os.path.join(root, "build", "replay")],
               check=True, stdout=subprocess.DEVNULL)
walk = re.search(r'frame\(7, "([0-9,]+)"', open(os.path.join(here, "make_cover.py")).read()).group(1)
# ui.Key numbers: 5 Q, 7 F1, 8 F3, 12 F2 (odin/ui/app.odin)
shots = [("01-title", ""), ("02-help", "7"), ("03-options", "8"), ("04-play", walk), ("05-score", walk + ",5")]
def chunk(t, d): c = struct.pack(">I", len(d)) + t + d; return c + struct.pack(">I", zlib.crc32(t + d))
out = os.path.join(root, "assets", "screenshots")
os.makedirs(out, exist_ok=True)
for name, keys in shots:
    ppm = os.path.join(tempfile.mkdtemp(), "f.ppm")
    subprocess.run([os.path.join(root, "build", "replay"), "7", keys, "900", ppm], check=True, stdout=subprocess.DEVNULL)
    d = open(ppm, "rb").read().split(b"\n", 3)
    w, h = map(int, d[1].split()); px = d[3]; k = 4
    rows = []
    for y in range(h):
        row = b"".join(px[(y * w + x) * 3:(y * w + x) * 3 + 3] * k for x in range(w))
        rows += [b"\0" + row] * k
    png = b"\x89PNG\r\n\x1a\n" + chunk(b"IHDR", struct.pack(">IIBBBBB", w * k, h * k, 8, 2, 0, 0, 0)) + chunk(b"IDAT", zlib.compress(b"".join(rows))) + chunk(b"IEND", b"")
    open(os.path.join(out, name + ".png"), "wb").write(png)
    print("wrote", name)
