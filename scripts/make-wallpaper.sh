#!/bin/sh
# Gera o papel de parede padrão do WinRise OS (arte própria, sem marcas de terceiros).
# Requer ImageMagick 6/7 e rsvg-convert (librsvg2-bin).  Uso: scripts/make-wallpaper.sh <saida.png> [LARGURAxALTURA]
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
# Símbolo WinRise: logo oficial (variante clara) com brilho suave, no ponto de onde saem os feixes
LOGO_SVG="$(dirname "$0")/../artwork/winrise-logo-light.svg"
S=$((H*38/100)); X=$((W*62/100)); Y=$((H*45/100))
rsvg-convert -w "$S" -h "$S" "$LOGO_SVG" -o "$TMP/l.png"
$IM "$TMP/l.png" \( +clone -background '#bfe0ff' -shadow 55x$((S/14))+0+0 \) +swap -background none -layers merge +repage "$TMP/lg.png"
LW=$($IM identify -format %w "$TMP/lg.png" 2>/dev/null || identify -format %w "$TMP/lg.png")
LH=$($IM identify -format %h "$TMP/lg.png" 2>/dev/null || identify -format %h "$TMP/lg.png")
$IM -size "${W}x${H}" xc:none "$TMP/lg.png" -geometry +$((X-LW/2))+$((Y-LH/2)) -compose over -composite "$TMP/logo.png"
$IM "$TMP/bg.png" "$TMP/rays.png" -compose screen -composite \
    "$TMP/logo.png" -compose over -composite -depth 8 -quality 95 "$OUT"
echo "ok: $OUT ($SIZE)"
