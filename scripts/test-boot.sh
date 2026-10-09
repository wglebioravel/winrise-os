#!/usr/bin/env bash
# Teste automatizado de boot no QEMU sem janela (headless).
# Uso: scripts/test-boot.sh [bios|uefi] [screenshot.png]
set -euo pipefail

MODE="${1:-bios}"
SHOT="${2:-boot-$MODE.png}"
ISO="${ISO:-winrise-os.iso}"
TIMEOUT="${TIMEOUT:-60}"
WORK="$(mktemp -d)"
trap 'kill "$QPID" 2>/dev/null || true; rm -rf "$WORK"' EXIT

ARGS=(-M q35 -m 8G -smp 4 -cdrom "$ISO" -boot d -display none
      -serial "file:$WORK/serial.log" -monitor "unix:$WORK/mon.sock,server,nowait")
if [ "$MODE" = "uefi" ]; then
    CODE="${OVMF_CODE:-/usr/share/OVMF/OVMF_CODE_4M.fd}"
    VARS="${OVMF_VARS:-/usr/share/OVMF/OVMF_VARS_4M.fd}"
    cp "$VARS" "$WORK/vars.fd"
    ARGS+=(-drive "if=pflash,unit=0,format=raw,file=$CODE,readonly=on"
           -drive "if=pflash,unit=1,format=raw,file=$WORK/vars.fd")
fi

qemu-system-x86_64 "${ARGS[@]}" &
QPID=$!

for _ in $(seq "$TIMEOUT"); do
    grep -q "WINRISE_BOOT_OK" "$WORK/serial.log" 2>/dev/null && break
    sleep 1
done

echo "----- serial ($MODE) -----"
tr -d '\r' < "$WORK/serial.log" || true
echo "--------------------------"

if ! grep -q "WINRISE_BOOT_OK" "$WORK/serial.log"; then
    echo "FALHOU: o kernel não terminou o boot em ${TIMEOUT}s ($MODE)"
    exit 1
fi

sleep 1
echo "screendump $WORK/screen.ppm" | socat - "UNIX-CONNECT:$WORK/mon.sock" >/dev/null
sleep 1
if command -v convert >/dev/null; then
    convert "$WORK/screen.ppm" "$SHOT"
else
    cp "$WORK/screen.ppm" "${SHOT%.png}.ppm"
fi
echo "quit" | socat - "UNIX-CONNECT:$WORK/mon.sock" >/dev/null || true
echo "OK: boot $MODE bem-sucedido; captura em $SHOT"
