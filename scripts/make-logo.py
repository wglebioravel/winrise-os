#!/usr/bin/env python3
"""Vetoriza o logo oficial do WinRise (JPG fundo branco) em SVG por camadas de cor.
Uso: scripts/make-logo.py artwork/winrise-logo-original.jpg artwork
Gera winrise-logo.svg (cores originais), winrise-logo-light.svg (W branco p/ fundos escuros)
e winrise-logo-mono-white.svg (tudo branco)."""
import sys, os, subprocess, tempfile, re
import numpy as np
from PIL import Image
src, out = sys.argv[1], sys.argv[2]
PAL = {"w": (0x11,0x11,0x0F), "r": (0x72,0x75,0x65), "a": (0xFF,0xB5,0x4B)}
img = np.asarray(Image.open(src).convert("RGB")).astype(float)
d = 255.0 - img                                   # "tinta" sobre o branco
vs = [255.0 - np.array(c, float) for c in PAL.values()]
fits = []
for v in vs:
    au = np.clip((d @ v) / (v @ v), 0, 1.35)       # sem corte em 1: tolera "ringing" do JPEG
    fits.append((np.clip(au, 0, 1), ((d - au[...,None]*v)**2).sum(-1)))
A = np.stack([f[0] for f in fits]); R = np.stack([f[1] for f in fits])
# 1) Núcleo: pixels sólidos (alfa alto) classificados pela cor
cls = np.full(img.shape[:2], -1)
best = R.argmin(0)
core = (np.take_along_axis(A, best[None], 0)[0] > 0.85) & (R.min(0) < 900)
cls[core] = best[core]
# 2) Bordas anti-aliased herdam a classe do núcleo vizinho mais próximo
ink = A.max(0) > 0.03
for _ in range(12):
    todo = ink & (cls < 0)
    if not todo.any(): break
    for dy in (-1,0,1):
        for dx in (-1,0,1):
            sh = np.roll(np.roll(cls, dy, 0), dx, 1)
            m = todo & (cls < 0) & (sh >= 0)
            cls[m] = sh[m]
alpha = np.where(cls >= 0, np.take_along_axis(A, np.clip(cls,0,None)[None], 0)[0], 0.0)
alpha[alpha < 0.04] = 0
ys, xs = np.where(alpha > 0.04)
x0, y0, x1, y1 = xs.min(), ys.min(), xs.max()+1, ys.max()+1
UP = 8
paths = {}
with tempfile.TemporaryDirectory() as t:
    for i,k in enumerate(PAL):
        m = np.where(cls == i, alpha, 0)[y0:y1, x0:x1]
        im = Image.fromarray((m*255).astype(np.uint8)).resize(((x1-x0)*UP, (y1-y0)*UP), Image.LANCZOS)
        bw = Image.fromarray(np.where(np.asarray(im) > 127, 0, 255).astype(np.uint8)).convert("1")
        bmp = os.path.join(t, k+".pbm"); bw.save(bmp)
        svg = os.path.join(t, k+".svg")
        subprocess.run(["potrace", "-s", "--flat", "-t", "40", "-a", "1.0", "-O", "0.4", "-u", "10", "-o", svg, bmp], check=True)
        s = open(svg).read()
        tr = re.search(r'<g transform="([^"]+)"', s).group(1)
        ds = re.findall(r'<path d="([^"]+)"', s)
        paths[k] = (tr, ds)
W, H = (x1-x0)*UP, (y1-y0)*UP
pad = int(max(W, H)*0.08); side = max(W, H) + 2*pad
ox, oy = (side-W)/2, (side-H)/2
def write(name, colors):
    with open(os.path.join(out, name), "w") as f:
        f.write(f'<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 {side} {side}" width="512" height="512">\n')
        f.write('  <title>WinRise OS</title>\n')
        for k in ("w", "r", "a"):
            tr, ds = paths[k]
            f.write(f'  <g transform="translate({ox:.1f},{oy:.1f}) {tr}" fill="{colors[k]}">\n')
            for dd in ds: f.write(f'    <path d="{dd}"/>\n')
            f.write('  </g>\n')
        f.write('</svg>\n')
write("winrise-logo.svg", {"w":"#11110f","r":"#727565","a":"#ffb54b"})
write("winrise-logo-light.svg", {"w":"#ffffff","r":"#a3a796","a":"#ffb54b"})
write("winrise-logo-mono-white.svg", {"w":"#ffffff","r":"#ffffff","a":"#ffffff"})
print("ok", side, "bbox", x0, y0, x1, y1)
