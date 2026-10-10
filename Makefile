# WinRise Connect OS — build da ISO live (Debian 13 + KDE Plasma estilo Windows 10)
# Uso: make deps && make iso
SHELL := /bin/bash
VERSION ?= 0.2
LBISO := winrise-connect-os-amd64.hybrid.iso
ISO   := winrise-connect-os-$(VERSION)-amd64.iso
SUDO  ?= sudo
# Limita a memória do mksquashfs (evita OOM em máquinas com pouca RAM livre)
SQUASH_OPTS ?= -mem 2G

.PHONY: help deps config iso clean distclean run-uefi run-bios wallpaper branding

help:
	@echo "make deps      - instala live-build e dependências (Debian/Ubuntu)"
	@echo "make branding  - regera logo, ícones, telas de boot/instalador e papel de parede"
	@echo "make iso       - gera $(ISO) (precisa de root, ~20 GB livres e internet)"
	@echo "make run-uefi  - testa a ISO no QEMU com UEFI (OVMF)"
	@echo "make run-bios  - testa a ISO no QEMU com BIOS legado"
	@echo "make clean     - limpa a árvore de build (mantém o cache de pacotes)"
	@echo "make distclean - limpa tudo, inclusive cache"

deps:
	$(SUDO) apt-get update
	$(SUDO) apt-get install -y live-build debootstrap squashfs-tools xorriso mtools dosfstools \
	  grub-efi-amd64-bin grub-pc-bin syslinux isolinux syslinux-utils qemu-system-x86 ovmf imagemagick librsvg2-bin potrace python3-pil python3-numpy

config:
	$(SUDO) lb config

iso: config
	$(SUDO) env MKSQUASHFS_OPTIONS="$(SQUASH_OPTS)" lb build
	$(SUDO) mv -f $(LBISO) $(ISO)
	@ls -lh $(ISO)

clean:
	$(SUDO) lb clean

distclean:
	$(SUDO) lb clean --purge
	$(SUDO) rm -rf cache

WPDIR = config/includes.chroot/usr/share/wallpapers/WinRise/contents/images

# Papel de parede em 16:9, 16:10, 4:3 e 1366x768: o Plasma escolhe o mais próximo da tela
WPSIZES = 1920x1080 2560x1440 3840x2160 1366x768 1920x1200 2560x1600 1280x1024 1600x1200 1024x768

wallpaper:
	for s in $(WPSIZES); do scripts/make-wallpaper.sh $(WPDIR)/$$s.png $$s; done
	cp $(WPDIR)/1920x1080.png artwork/winrise-wallpaper.png

# Regera logo vetorial, ícones, Calamares, tela de boot e papel de parede a partir do logo oficial
branding:
	python3 scripts/make-logo.py artwork/winrise-connect-logo-original.jpg artwork
	python3 scripts/make-branding.py
	$(MAKE) wallpaper

run-uefi:
	cp /usr/share/OVMF/OVMF_VARS_4M.fd /tmp/winrise-vars.fd
	qemu-system-x86_64 -enable-kvm -m 8G -smp 4 -cpu host -vga virtio \
	  -drive if=pflash,format=raw,readonly=on,file=/usr/share/OVMF/OVMF_CODE_4M.fd \
	  -drive if=pflash,format=raw,file=/tmp/winrise-vars.fd \
	  -cdrom $(ISO)

run-bios:
	qemu-system-x86_64 -enable-kvm -m 8G -smp 4 -cpu host -vga virtio -cdrom $(ISO)
