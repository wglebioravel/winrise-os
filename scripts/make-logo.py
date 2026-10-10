#!/usr/bin/env python3
"""Vetoriza o logo oficial do WinRise Connect OS (JPG em fundo branco) em SVG, por camadas de cor.
Uso: scripts/make-logo.py artwork/winrise-connect-logo-original.jpg artwork
Gera em <saida>:
  winrise-logo.svg            símbolo (W + R + seta), cores oficiais
  winrise-logo-light.svg      símbolo para fundos escuros (W branco)
  winrise-logo-mono-white.svg símbolo todo branco
  winrise-lockup.svg          símbolo + "WinRise" + "Connect"
  winrise-lockup-light.svg    idem, para fundos escuros ("Win" e W brancos)
"""
import sys, os, subprocess, tempfile, re
import numpy as np
from PIL import Image
src, out = sys.argv[1], sys.argv[2]
NAVY, TEAL, GOLD = "#032759", "#01a3b0", "#d4af67"
PAL = {"n": (0x03,0x27,0x59), "t": (0x01,0xA3,0xB0), "g": (0xD4,0xAF,0x67)}
img = np.asarray(Image.open(src).convert("RGB")).astype(float)
d = 255.0 - img
A, R = [], []
for c in PAL.values():
    v = 255.0 - np.array(c, float)
    au = np.clip((d @ v) / (v @ v), 0, 1.35)            # tolera "ringing" do JPEG
    A.append(np.clip(au, 0, 1)); R.append(((d - au[...,None]*v)**2).sum(-1))
A, R = np.stack(A), np.stack(R)
best = R.argmin(0)
cls = np.full(img.shape[:2], -1)
core = (np.take_along_axis(A, best[None], 0)[0] > 0.85) & (R.min(0) < 1200)
cls[core] = best[core]
ink = A.max(0) > 0.03
for _ in range(12):                                     # bordas herdam a cor do núcleo vizinho
    todo = ink & (cls < 0)
    if not todo.any(): break
    for dy in (-1,0,1):
        for dx in (-1,0,1):
            sh = np.roll(np.roll(cls, dy, 0), dx, 1)
            m = todo & (cls < 0) & (sh >= 0); cls[m] = sh[m]
alpha = np.where(cls >= 0, np.take_along_axis(A, np.clip(cls,0,None)[None], 0)[0], 0.0)
alpha[alpha < 0.04] = 0
# Faixas horizontais com tinta: a 1ª é o símbolo; as demais, o texto
rows = np.where((alpha > 0.3).sum(1) > 0)[0]
bands, s, p = [], rows[0], rows[0]
for r in rows[1:]:
    if r > p + 12: bands.append((s, p + 1)); s = r
    p = r
bands.append((s, p + 1))
UP = 6
def trace(y0, y1):
    sub = alpha[y0:y1]; cols = np.where((sub > 0.04).any(0))[0]; x0, x1 = cols.min(), cols.max() + 1
    layers = {}
    with tempfile.TemporaryDirectory() as t:
        for i, k in enumerate(PAL):
            m = np.where(cls[y0:y1, x0:x1] == i, sub[:, x0:x1], 0)
            if m.max() < 0.5: continue
            im = Image.fromarray((m*255).astype(np.uint8)).resize(((x1-x0)*UP, (y1-y0)*UP), Image.LANCZOS)
            Image.fromarray(np.where(np.asarray(im) > 127, 0, 255).astype(np.uint8)).convert("1").save(f"{t}/{k}.pbm")
            subprocess.run(["potrace", "-s", "--flat", "-t", "30", "-a", "1.0", "-O", "0.4", "-u", "10",
                            "-o", f"{t}/{k}.svg", f"{t}/{k}.pbm"], check=True)
            s = open(f"{t}/{k}.svg").read()
            layers[k] = (re.search(r'<g transform="([^"]+)"', s).group(1), re.findall(r'<path d="([^"]+)"', s))
    return x0, x1, layers
def write(name, y0, y1, colors, pad_frac=0.08, square=True):
    x0, x1, layers = trace(y0, y1)
    W, H = (x1-x0)*UP, (y1-y0)*UP
    pad = int(max(W, H)*pad_frac)
    VW, VH = (max(W, H)+2*pad,)*2 if square else (W+2*pad, H+2*pad)
    ox, oy = (VW-W)/2, (VH-H)/2
    with open(os.path.join(out, name), "w") as f:
        f.write(f'<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 {VW} {VH}" width="{round(512*VW/max(VW,VH))}" height="{round(512*VH/max(VW,VH))}">\n  <title>WinRise Connect OS</title>\n')
        for k in ("n", "t", "g"):
            if k not in layers: continue
            tr, ds = layers[k]
            f.write(f'  <g transform="translate({ox:.1f},{oy:.1f}) {tr}" fill="{colors[k]}">\n')
            for dd in ds: f.write(f'    <path d="{dd}"/>\n')
            f.write('  </g>\n')
        f.write('</svg>\n')
mark = bands[0]; full = (bands[0][0], bands[-1][1])
write("winrise-logo.svg", *mark, {"n": NAVY, "t": TEAL, "g": GOLD})
write("winrise-logo-light.svg", *mark, {"n": "#ffffff", "t": TEAL, "g": GOLD})
write("winrise-logo-mono-white.svg", *mark, {"n": "#ffffff", "t": "#ffffff", "g": "#ffffff"})
write("winrise-lockup.svg", *full, {"n": NAVY, "t": TEAL, "g": GOLD}, 0.06, False)
write("winrise-lockup-light.svg", *full, {"n": "#ffffff", "t": TEAL, "g": GOLD}, 0.06, False)
print("ok bands", bands)
