# WinRise OS — build da ISO live (Debian 13 + KDE Plasma estilo Windows 10)
# Uso: make deps && make iso
SHELL := /bin/bash
ISO   := winrise-os-amd64.hybrid.iso
SUDO  ?= sudo
# Limita a memória do mksquashfs (evita OOM em máquinas com pouca RAM livre)
SQUASH_OPTS ?= -mem 2G

.PHONY: help deps config iso clean distclean run-uefi run-bios wallpaper

help:
	@echo "make deps      - instala live-build e dependências (Debian/Ubuntu)"
	@echo "make iso       - gera $(ISO) (precisa de root, ~20 GB livres e internet)"
	@echo "make run-uefi  - testa a ISO no QEMU com UEFI (OVMF)"
	@echo "make run-bios  - testa a ISO no QEMU com BIOS legado"
	@echo "make clean     - limpa a árvore de build (mantém o cache de pacotes)"
	@echo "make distclean - limpa tudo, inclusive cache"

deps:
	$(SUDO) apt-get update
	$(SUDO) apt-get install -y live-build debootstrap squashfs-tools xorriso mtools dosfstools \
	  grub-efi-amd64-bin grub-pc-bin syslinux isolinux syslinux-utils qemu-system-x86 ovmf imagemagick

config:
	$(SUDO) lb config

iso: config
	$(SUDO) env MKSQUASHFS_OPTIONS="$(SQUASH_OPTS)" lb build
	@ls -lh $(ISO)

clean:
	$(SUDO) lb clean

distclean:
	$(SUDO) lb clean --purge
	$(SUDO) rm -rf cache

wallpaper:
	scripts/make-wallpaper.sh artwork/winrise-wallpaper.png 1920x1080

run-uefi:
	cp /usr/share/OVMF/OVMF_VARS_4M.fd /tmp/winrise-vars.fd
	qemu-system-x86_64 -enable-kvm -m 8G -smp 4 -cpu host -vga virtio \
	  -drive if=pflash,format=raw,readonly=on,file=/usr/share/OVMF/OVMF_CODE_4M.fd \
	  -drive if=pflash,format=raw,file=/tmp/winrise-vars.fd \
	  -cdrom $(ISO)

run-bios:
	qemu-system-x86_64 -enable-kvm -m 8G -smp 4 -cpu host -vga virtio -cdrom $(ISO)
