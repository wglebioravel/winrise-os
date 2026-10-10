#!/usr/bin/env python3
"""Gera todos os artefatos de marca do WinRise Connect OS a partir de artwork/winrise-logo*.svg.
Requer: python3, rsvg-convert (librsvg2-bin) e ImageMagick.  Uso (na raiz do repo):
    scripts/make-logo.py artwork/winrise-connect-logo-original.jpg artwork   # (re)vetoriza o logo
    scripts/make-branding.py                                         # ícones, Calamares, boot, README
    scripts/make-wallpaper.sh                                        # papel de parede
"""
import os, re, subprocess
ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
A = lambda *p: os.path.join(ROOT, *p)
CH = A("config", "includes.chroot")
def sh(*c): subprocess.run(c, check=True)
def logo(variant, x, y, size, h=None, kind="logo"):
    """Logo como <svg> aninhado (caminhos inline, sem arquivos externos).
    kind="logo": símbolo W+R+seta; kind="lockup": símbolo + "WinRise Connect"."""
    s = open(A("artwork", f"winrise-{kind}{variant}.svg")).read()
    vb = re.search(r'viewBox="([^"]+)"', s).group(1)
    inner = s[s.index(">", s.index("<svg")) + 1 : s.rindex("</svg>")]
    inner = re.sub(r"<title>.*?</title>", "", inner)
    return f'<svg x="{x}" y="{y}" width="{size}" height="{h or size}" viewBox="{vb}">{inner}</svg>'
def write(path, txt):
    os.makedirs(os.path.dirname(path), exist_ok=True); open(path, "w").write(txt)
def png(svg, out, w, h=None):
    os.makedirs(os.path.dirname(out), exist_ok=True)
    sh("rsvg-convert", "-w", str(w), "-h", str(h or w), svg, "-o", out)
# Paleta da marca: azul-marinho (#032759), turquesa (#01a3b0), dourado (#d4af67)
BLUE = ('<radialGradient id="bg" cx="0.62" cy="0.42" r="0.9"><stop offset="0" stop-color="#2a78d0"/>'
        '<stop offset="0.55" stop-color="#0d3f80"/><stop offset="1" stop-color="#021634"/></radialGradient>')

# 1) Ícone do sistema "winrise" (bloco branco arredondado + logo em cores originais):
#    usado em "Instalar o WinRise Connect OS", Calamares (janela), os-release LOGO, Informações do sistema.
icons = A(CH[len(ROOT)+1:], "usr/share/icons/hicolor")
tile = ('<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 256 256" width="256" height="256">'
        '<defs><linearGradient id="t" x1="0" y1="0" x2="0" y2="1"><stop offset="0" stop-color="#ffffff"/>'
        '<stop offset="1" stop-color="#eef1f5"/></linearGradient></defs>'
        '<rect x="8" y="8" width="240" height="240" rx="44" fill="url(#t)" stroke="#c9ced6" stroke-width="3"/>'
        + logo("", 22, 22, 212) + '</svg>\n')
write(f"{icons}/scalable/apps/winrise.svg", tile)
# 2) Botão Iniciar (barra escura): W branco, R cinza, seta laranja, sem fundo.
start = ('<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 256 256" width="256" height="256">'
         + logo("-light", 0, 0, 256) + '</svg>\n')
write(f"{icons}/scalable/apps/winrise-start.svg", start)
for n in (16, 22, 24, 32, 48, 64, 128, 256):
    png(f"{icons}/scalable/apps/winrise.svg", f"{icons}/{n}x{n}/apps/winrise.png", n)
    png(f"{icons}/scalable/apps/winrise-start.svg", f"{icons}/{n}x{n}/apps/winrise-start.png", n)
# Logo "distributor-logo" para KInfoCenter/Sobre o sistema
write(f"{icons}/scalable/apps/distributor-logo-winrise.svg", tile)

# 3) Artefatos para repositório/README/favicon
png(A("artwork", "winrise-logo.svg"), A("artwork", "winrise-logo.png"), 1024)
png(A("artwork", "winrise-logo-light.svg"), A("artwork", "winrise-logo-light.png"), 1024)
png(A("artwork", "winrise-logo.svg"), A("docs", "winrise-logo.png"), 256)
png(A("artwork", "winrise-logo-light.svg"), A("docs", "winrise-logo-light.png"), 256)
def lockup_png(variant, out, h):
    s = open(A("artwork", f"winrise-lockup{variant}.svg")).read()
    vw, vh = map(float, re.search(r'viewBox="0 0 ([\d.]+) ([\d.]+)"', s).groups())
    png(A("artwork", f"winrise-lockup{variant}.svg"), out, round(h * vw / vh), h)
lockup_png("", A("artwork", "winrise-lockup.png"), 1024)
lockup_png("-light", A("artwork", "winrise-lockup-light.png"), 1024)
lockup_png("", A("docs", "winrise-lockup.png"), 300)
lockup_png("-light", A("docs", "winrise-lockup-light.png"), 300)
for n in (16, 32, 48):
    png(f"{icons}/scalable/apps/winrise.svg", f"/tmp/wr-fav-{n}.png", n)
sh("convert", "/tmp/wr-fav-16.png", "/tmp/wr-fav-32.png", "/tmp/wr-fav-48.png", A("artwork", "favicon.ico"))
png(f"{icons}/scalable/apps/winrise.svg", A("artwork", "favicon-32.png"), 32)

# 4) Calamares: logo da barra lateral (fundo azul escuro) e imagem de boas-vindas
cb = A(CH[len(ROOT)+1:], "etc/calamares/branding/winrise")
png(A("artwork", "winrise-logo-light.svg"), f"{cb}/winrise-logo.png", 256)
png(f"{icons}/scalable/apps/winrise.svg", f"{cb}/winrise-icon.png", 256)
welcome = ('<svg xmlns="http://www.w3.org/2000/svg" width="640" height="400" viewBox="0 0 640 400">'
           f'<defs>{BLUE}</defs><rect width="640" height="400" fill="url(#bg)"/>'
           '<path d="M396 168 L640 40 L640 110 Z M396 168 L640 190 L640 260 Z" fill="#ffffff" opacity="0.08"/>'
           + logo("-light", 170, 30, 300, 340, kind="lockup") + '</svg>\n')
write("/tmp/wr-welcome.svg", welcome)
png("/tmp/wr-welcome.svg", f"{cb}/welcome.png", 640, 400)

# 5) Tela do menu de boot (isolinux/GRUB), 800x600; @VARS@ são preenchidas pelo live-build
splash = ('<svg xmlns="http://www.w3.org/2000/svg" width="800" height="600" viewBox="0 0 800 600">'
          f'<defs>{BLUE}</defs><rect width="800" height="600" fill="url(#bg)"/>'
          + logo("-light", 300, 18, 200, 190, kind="lockup") +
          '<text x="400" y="232" font-family="DejaVu Sans, sans-serif" font-size="15" fill="#cfe6ff" '
          'text-anchor="middle">WinRise Connect OS - base Debian @DISTRIBUTION@ - linux @LINUX_VERSIONS@</text>'
          '</svg>\n')
write(A("config", "bootloaders", "splash.svg"), splash)
print("ok: marca gerada")
