# WinRise Connect OS: no login gráfico, cria as pastas do usuário no idioma do sistema
# (Área de trabalho, Documentos, Downloads, Imagens, Músicas, Vídeos...) e coloca os
# ícones "Este Computador", "Pasta pessoal" e "Lixeira" na área de trabalho, como no Windows.
# Obs.: não colocamos pastas com acento no /etc/skel porque a cópia na criação do
# usuário live corrompe nomes não-ASCII; o xdg-user-dirs-update cria em UTF-8 correto.
if [ -n "${HOME:-}" ] && [ "$(id -u)" -ne 0 ] && command -v xdg-user-dirs-update >/dev/null 2>&1; then
    xdg-user-dirs-update >/dev/null 2>&1 || true
    _wr_desk="$(xdg-user-dir DESKTOP 2>/dev/null)"
    if [ -n "$_wr_desk" ] && [ "$_wr_desk" != "$HOME" ] && [ ! -e "$HOME/.config/winrise/desktop-icons-done" ]; then
        mkdir -p "$_wr_desk" "$HOME/.config/winrise"
        for _wr_f in /usr/share/winrise/desktop/*.desktop; do
            [ -e "$_wr_f" ] || continue
            cp "$_wr_f" "$_wr_desk/" && chmod +x "$_wr_desk/${_wr_f##*/}"
        done
        # Sessão live: atalho do instalador
        if [ -d /run/live/medium ] && [ -f /usr/share/applications/calamares-install-debian.desktop ]; then
            cp /usr/share/applications/calamares-install-debian.desktop "$_wr_desk/instalar-winrise.desktop" \
              && chmod +x "$_wr_desk/instalar-winrise.desktop"
        fi
        : > "$HOME/.config/winrise/desktop-icons-done"
    fi
    # "Este Computador" na barra lateral do Dolphin (o KIO completa os outros locais padrão)
    if [ -x /usr/local/bin/winrise-este-computador ]; then
        /usr/local/bin/winrise-este-computador --refresh >/dev/null 2>&1 || true
        _wr_places="$HOME/.local/share/user-places.xbel"
        if [ ! -e "$_wr_places" ] && command -v python3 >/dev/null 2>&1; then
            # Lista completa, na ordem do Windows e com os nomes iguais aos das pastas
            # (ex.: "Músicas"). O KIO não duplica locais cujas URLs já estão no arquivo.
            mkdir -p "${_wr_places%/*}"
            WR_PC="$HOME/.local/share/winrise/Este Computador" python3 - "$_wr_places" <<'PY' || true
import os, sys
from urllib.parse import quote
from xml.sax.saxutils import escape
home = os.path.expanduser("~")
dirs = {}
try:
    for ln in open(os.path.join(home, ".config/user-dirs.dirs"), encoding="utf-8"):
        if ln.startswith("XDG_") and "=" in ln:
            k, v = ln.strip().split("=", 1)
            dirs[k[4:-4]] = v.strip('"').replace("$HOME", home)
except OSError:
    pass
def xdg(k):
    return dirs.get(k, "")
items = [(os.environ["WR_PC"], "Este Computador", "computer", "winrise-este-computador"),
         (home, "Pasta pessoal", "user-home", None)]
for k, icon in (("DESKTOP","user-desktop"), ("DOCUMENTS","folder-documents"), ("DOWNLOAD","folder-downloads"),
                ("PICTURES","folder-pictures"), ("MUSIC","folder-music"), ("VIDEOS","folder-videos")):
    d = xdg(k)
    if d and d != home and os.path.isdir(d):
        items.append((d, os.path.basename(d), icon, None))
out = ['<?xml version="1.0" encoding="UTF-8"?>', '<!DOCTYPE xbel>',
       '<xbel xmlns:bookmark="http://www.freedesktop.org/standards/desktop-bookmarks" '
       'xmlns:mime="http://www.freedesktop.org/standards/shared-mime-info" xmlns:kdepriv="http://www.kde.org/kdepriv">']
def bm(href, title, icon, ident=None):
    out.append(f' <bookmark href="{escape(href)}">\n  <title>{escape(title)}</title>\n  <info>\n'
               f'   <metadata owner="http://freedesktop.org">\n    <bookmark:icon name="{icon}"/>\n   </metadata>\n'
               f'   <metadata owner="http://www.kde.org">\n    <ID>{ident or "winrise-" + icon}</ID>\n   </metadata>\n'
               '  </info>\n </bookmark>')
for path, title, icon, ident in items:
    bm("file://" + quote(path), title, icon, ident)
bm("trash:/", "Lixeira", "user-trash"); bm("remote:/", "Rede", "folder-network")
out.append('</xbel>')
open(sys.argv[1], "w", encoding="utf-8").write("\n".join(out) + "\n")
PY
        fi
        unset _wr_places _wr_url
    fi
    unset _wr_desk _wr_f
fi
