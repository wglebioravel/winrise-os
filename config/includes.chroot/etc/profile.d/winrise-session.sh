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
    unset _wr_desk _wr_f
fi
