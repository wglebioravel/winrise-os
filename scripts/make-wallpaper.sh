#!/bin/sh
# Gera o papel de parede padrão do WinRise OS (arte própria, sem marcas de terceiros).
# Requer ImageMagick 6/7.  Uso: scripts/make-wallpaper.sh <saida.png> [LARGURAxALTURA]
set -eu
OUT="${1:-artwork/winrise-wallpaper.png}"
SIZE="${2:-3840x2160}"
W="${SIZE%x*}"; H="${SIZE#*x}"
IM=convert; command -v magick >/dev/null 2>&1 && IM=magick
TMP="$(mktemp -d)"; trap 'rm -rf "$TMP"' EXIT
# Fundo: gradiente radial azul profundo -> azul "aurora"
CX=$((W*62/100)); CY=$((H*45/100)); R=$((W*85/100))
$IM -size "$((R*2))x$((R*2))" radial-gradient:'#3a9bff'-'#00102e' \
    -crop "${W}x${H}+$((R-CX))+$((R-CY))" +repage "$TMP/bg.png"
# Feixes de luz diagonais (o "nascer" do WinRise)
$IM -size "${W}x${H}" xc:none -fill 'rgba(255,255,255,0.20)' \
    -draw "polygon $((W*62/100)),$((H*45/100)) $W,$((H*5/100)) $W,$((H*30/100))" \
    -draw "polygon $((W*62/100)),$((H*45/100)) $W,$((H*40/100)) $W,$((H*62/100))" \
    -draw "polygon $((W*62/100)),$((H*45/100)) $((W*80/100)),$H $((W*98/100)),$H" \
    -fill 'rgba(255,255,255,0.10)' \
    -draw "polygon $((W*62/100)),$((H*45/100)) $((W*30/100)),0 $((W*48/100)),0" \
    -blur 0x$((W/160)) "$TMP/rays.png"
# Símbolo WinRise: 3 barras ascendentes em perspectiva
S=$((H/9)); X=$((W*62/100)); Y=$((H*45/100))
$IM -size "${W}x${H}" xc:none -fill 'rgba(220,240,255,0.92)' \
    -draw "roundrectangle $((X-S*3/2)),$((Y)) $((X-S*3/2+S*2/3)),$((Y+S)) 8,8" \
    -draw "roundrectangle $((X-S/3)),$((Y-S/2)) $((X+S/3)),$((Y+S)) 8,8" \
    -draw "roundrectangle $((X+S*3/2-S*2/3)),$((Y-S)) $((X+S*3/2)),$((Y+S)) 8,8" \
    \( +clone -background '#9fd0ff' -shadow 80x$((S/6))+0+0 \) +swap -background none -layers merge +repage \
    -gravity center -extent "${W}x${H}" "$TMP/logo.png"
$IM "$TMP/bg.png" "$TMP/rays.png" -compose screen -composite \
    "$TMP/logo.png" -compose over -composite -depth 8 -quality 95 "$OUT"
echo "ok: $OUT ($SIZE)"
