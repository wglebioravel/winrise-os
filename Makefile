# WinRise OS — build do kernel e da ISO híbrida (BIOS + UEFI)

ISO        := winrise-os.iso
KERNEL     := kernel/target/x86_64-unknown-none/release/kernel
LIMINE_DIR := limine
LIMINE_BRANCH := v9.x-binary
QEMU       := qemu-system-x86_64
QEMU_MEM   ?= 8G
QEMU_FLAGS ?= -M q35 -m $(QEMU_MEM) -smp 4 -serial stdio
OVMF_CODE  ?= $(firstword $(wildcard /usr/share/OVMF/OVMF_CODE_4M.fd /usr/share/OVMF/OVMF_CODE.fd /usr/share/edk2/x64/OVMF_CODE.4m.fd /usr/share/edk2/ovmf/OVMF_CODE.fd /usr/share/ovmf/OVMF.fd))
OVMF_VARS  ?= $(firstword $(wildcard /usr/share/OVMF/OVMF_VARS_4M.fd /usr/share/OVMF/OVMF_VARS.fd /usr/share/edk2/x64/OVMF_VARS.4m.fd /usr/share/edk2/ovmf/OVMF_VARS.fd))

.PHONY: all kernel iso run run-uefi test clean distclean

all: iso

kernel:
	cd kernel && cargo build --release

$(LIMINE_DIR)/limine:
	rm -rf $(LIMINE_DIR)
	git clone https://codeberg.org/Limine/Limine.git --branch=$(LIMINE_BRANCH) --depth=1 $(LIMINE_DIR)
	$(MAKE) -C $(LIMINE_DIR)

iso: $(ISO)

$(ISO): kernel $(LIMINE_DIR)/limine limine.conf
	rm -rf iso_root
	mkdir -p iso_root/boot/limine iso_root/EFI/BOOT
	cp $(KERNEL) iso_root/boot/kernel
	cp limine.conf $(LIMINE_DIR)/limine-bios.sys $(LIMINE_DIR)/limine-bios-cd.bin \
	   $(LIMINE_DIR)/limine-uefi-cd.bin iso_root/boot/limine/
	cp $(LIMINE_DIR)/BOOTX64.EFI $(LIMINE_DIR)/BOOTIA32.EFI iso_root/EFI/BOOT/
	xorriso -as mkisofs -R -r -J -b boot/limine/limine-bios-cd.bin \
		-no-emul-boot -boot-load-size 4 -boot-info-table -hfsplus \
		-apm-block-size 2048 --efi-boot boot/limine/limine-uefi-cd.bin \
		-efi-boot-part --efi-boot-image --protective-msdos-label \
		iso_root -o $(ISO)
	./$(LIMINE_DIR)/limine bios-install $(ISO)
	rm -rf iso_root
	@echo "ISO pronta: $(ISO)"

# Boot via BIOS legado (SeaBIOS)
run: $(ISO)
	$(QEMU) $(QEMU_FLAGS) -cdrom $(ISO) -boot d

# Boot via UEFI (OVMF)
run-uefi: $(ISO)
	@test -n "$(OVMF_CODE)" || (echo "OVMF não encontrado; instale o pacote ovmf" && exit 1)
	cp $(OVMF_VARS) ovmf-vars.fd 2>/dev/null || true
	$(QEMU) $(QEMU_FLAGS) \
		-drive if=pflash,unit=0,format=raw,file=$(OVMF_CODE),readonly=on \
		$(if $(OVMF_VARS),-drive if=pflash,unit=1,format=raw,file=ovmf-vars.fd) \
		-cdrom $(ISO) -boot d

clean:
	cd kernel && cargo clean
	rm -rf iso_root $(ISO) ovmf-vars.fd

distclean: clean
	rm -rf $(LIMINE_DIR)

# Teste automatizado headless (BIOS e UEFI) com captura de tela
test: $(ISO)
	scripts/test-boot.sh bios docs/boot-bios.png
	scripts/test-boot.sh uefi docs/boot-uefi.png
