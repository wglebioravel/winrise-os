#!/bin/sh
# Gera o papel de parede padrão do WinRise Connect OS: fundo azul-marinho/turquesa estilo
# Windows 10, feixes de luz e o símbolo oficial (W + R + seta, variante clara) CENTRALIZADO.
# Requer ImageMagick 6/7 e rsvg-convert (librsvg2-bin).
# Uso: scripts/make-wallpaper.sh <saida.png> [LARGURAxALTURA]
set -eu
OUT="${1:-artwork/winrise-wallpaper.png}"
SIZE="${2:-3840x2160}"
W="${SIZE%x*}"; H="${SIZE#*x}"
IM=convert; command -v magick >/dev/null 2>&1 && IM=magick
TMP="$(mktemp -d)"; trap 'rm -rf "$TMP"' EXIT
CX=$((W/2)); CY=$((H/2))
# Fundo: gradiente radial a partir do centro (turquesa-azulado -> azul-marinho)
R=$(( (W > H ? W : H) * 75 / 100 ))
$IM -size "$((R*2))x$((R*2))" radial-gradient:'#2a78d0'-'#021634' \
    -crop "${W}x${H}+$((R-CX))+$((R-CY))" +repage "$TMP/bg.png"
# Feixes de luz saindo do centro (o "nascer" do WinRise)
D=$(( W > H ? W : H ))
$IM -size "${W}x${H}" xc:none -fill 'rgba(255,255,255,0.16)' \
    -draw "polygon $CX,$CY $((CX+D)),$((CY-D*45/100)) $((CX+D)),$((CY-D*20/100))" \
    -draw "polygon $CX,$CY $((CX+D)),$((CY-D*5/100)) $((CX+D)),$((CY+D*15/100))" \
    -draw "polygon $CX,$CY $((CX+D*30/100)),$((CY+D)) $((CX+D*55/100)),$((CY+D))" \
    -fill 'rgba(255,255,255,0.08)' \
    -draw "polygon $CX,$CY $((CX-D)),$((CY-D*40/100)) $((CX-D)),$((CY-D*22/100))" \
    -draw "polygon $CX,$CY $((CX-D*45/100)),$((CY-D)) $((CX-D*25/100)),$((CY-D))" \
    -blur 0x$((D/160)) "$TMP/rays.png"
# Símbolo centralizado (só W + R + seta, sem texto); tamanho relativo ao lado menor da tela
LOGO_SVG="$(dirname "$0")/../artwork/winrise-logo-light.svg"
M=$(( W < H ? W : H )); S=$((M*36/100))
rsvg-convert -w "$S" -h "$S" "$LOGO_SVG" -o "$TMP/l.png"
$IM "$TMP/l.png" \( +clone -background '#d6ebff' -shadow 40x$((S/14))+0+0 \) +swap \
    -background none -layers merge +repage "$TMP/lg.png"
$IM "$TMP/bg.png" "$TMP/rays.png" -compose screen -composite \
    "$TMP/lg.png" -gravity center -compose over -composite -depth 8 -quality 95 "$OUT"
echo "ok: $OUT ($SIZE)"
