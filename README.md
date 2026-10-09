# WinRise OS

Um sistema operacional **feito do zero em Rust** para PCs x86_64 modernos (Intel e AMD).

O objetivo de longo prazo é uma área de trabalho **parecida com o Windows 10** —
barra de tarefas embaixo com botão Iniciar, menu Iniciar, janelas com barra de
título e ícones na área de trabalho — porém **leve e limpa**: sem notícias,
clima, widgets, anúncios nem aplicativos pré-instalados que você não pediu.

![WinRise OS rodando no QEMU](docs/screenshot.png)

## Estado atual (marco 0.1)

- Boot pelo **Limine** em **UEFI** e **BIOS legado**, a partir de uma única ISO híbrida
- Kernel `no_std` em Rust, carregado na metade superior da memória (higher-half)
- **Framebuffer** gráfico com fonte antialiasing e um protótipo da área de trabalho
  (fundo azul, ícones, janela, barra de tarefas com botão Iniciar e relógio)
- **Console de texto** dentro da janela "Informações do sistema"
- **Porta serial** (COM1) para depuração
- **GDT + TSS** (pilha separada para *double fault*) e **IDT** com tratadores de exceções
- Leitura do **mapa de memória** (RAM usável), CPU (CPUID), firmware e bootloader

## Requisitos de hardware

- Processador x86_64 (Intel ou AMD) razoavelmente moderno
- Pelo menos **8 GB de RAM** (recomendado)
- Firmware UEFI ou BIOS legado

## Requisitos para compilar

Em Debian/Ubuntu:

```bash
sudo apt install build-essential git make xorriso qemu-system-x86 ovmf socat imagemagick
curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh
```

O arquivo `kernel/rust-toolchain.toml` seleciona automaticamente o Rust **nightly**
com `rust-src` e `llvm-tools`. O Limine é baixado e compilado pelo próprio `Makefile`.

## Compilar e executar

```bash
make iso        # gera winrise-os.iso (BIOS + UEFI)
make run        # roda no QEMU com BIOS legado
make run-uefi   # roda no QEMU com UEFI (OVMF)
make test       # teste automático sem janela, BIOS e UEFI, com captura de tela
make clean      # limpa os artefatos
```

A saída serial do kernel aparece no terminal (`-serial stdio`).

## Rodar em um computador de verdade

> ⚠️ Gravar a ISO **apaga todo o conteúdo do pendrive**. Confira o dispositivo duas vezes.

**Linux:**

```bash
lsblk                                   # descubra o pendrive (ex.: /dev/sdX)
sudo dd if=winrise-os.iso of=/dev/sdX bs=4M status=progress conv=fsync
```

**Windows:** use o [Rufus](https://rufus.ie) (modo "DD Image") ou o
[balenaEtcher](https://etcher.balena.io).

Depois, reinicie o PC, abra o menu de boot (geralmente F12, F8, F11 ou Esc) e
escolha o pendrive. Em máquinas UEFI pode ser necessário **desativar o Secure Boot**.

## Estrutura do projeto

```
kernel/
  src/main.rs         ponto de entrada (kmain), área de trabalho e informações
  src/boot.rs         requisições ao bootloader Limine
  src/framebuffer.rs  desenho de pixels, retângulos, degradê e texto
  src/console.rs      console de texto sobre o framebuffer (kprintln!)
  src/serial.rs       driver da porta serial COM1 (serial_println!)
  src/gdt.rs          GDT e TSS
  src/interrupts.rs   IDT e tratadores de exceções
  src/memory.rs       leitura do mapa de memória
  src/cpu.rs          identificação da CPU (CPUID)
  linker.ld           layout do kernel na memória
limine.conf           configuração do menu de boot
scripts/test-boot.sh  teste automatizado no QEMU
Makefile
```

## Roadmap

**Núcleo do sistema**
- [x] Boot UEFI + BIOS, framebuffer, serial, GDT/IDT
- [ ] Gerenciamento de memória: alocador de quadros físicos e paginação própria
- [ ] Alocador de heap (`alloc`: `Vec`, `String`, `Box`)
- [ ] APIC/IOAPIC, timer e interrupções de hardware
- [ ] Teclado e mouse (PS/2 e depois USB)
- [ ] Multitarefa (agendador preemptivo, threads, multiprocessador)
- [ ] Modo usuário e chamadas de sistema
- [ ] Sistema de arquivos (FAT32 primeiro, depois um próprio)
- [ ] Drivers: AHCI/NVMe, USB (xHCI), rede, ACPI (desligar/reiniciar)
- [ ] Shell de linha de comando

**Interface gráfica estilo Windows 10 — leve e sem bloatware**
- [x] Protótipo estático: área de trabalho azul, ícones, janela e barra de tarefas
- [ ] Compositor de janelas com double buffering
- [ ] Barra de tarefas funcional: botão Iniciar, janelas abertas, relógio real
- [ ] Menu Iniciar com busca de aplicativos
- [ ] Janelas móveis/redimensionáveis com barra de título (minimizar, maximizar, fechar)
- [ ] Ícones na área de trabalho e explorador de arquivos
- [ ] Apenas o essencial: terminal, explorador de arquivos, editor de texto e configurações
- [ ] **Sem** notícias, clima, widgets, anúncios, telemetria ou apps pré-instalados indesejados

## Licença

[MIT](LICENSE)
