# WinRise OS: no login gráfico, cria as pastas do usuário no idioma do sistema
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
        if [ ! -e "$_wr_places" ]; then
            _wr_url="file://$(printf '%s' "$HOME/.local/share/winrise/Este Computador" | sed 's/ /%20/g')"
            cat > "$_wr_places" <<XBEL
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE xbel>
<xbel xmlns:bookmark="http://www.freedesktop.org/standards/desktop-bookmarks" xmlns:mime="http://www.freedesktop.org/standards/shared-mime-info" xmlns:kdepriv="http://www.kde.org/kdepriv">
 <bookmark href="$_wr_url">
  <title>Este Computador</title>
  <info>
   <metadata owner="http://freedesktop.org">
    <bookmark:icon name="computer"/>
   </metadata>
   <metadata owner="http://www.kde.org">
    <ID>winrise-este-computador</ID>
   </metadata>
  </info>
 </bookmark>
</xbel>
XBEL
        fi
        unset _wr_places _wr_url
    fi
    unset _wr_desk _wr_f
fi
