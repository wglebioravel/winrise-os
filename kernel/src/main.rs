//! WinRise OS — kernel x86_64 escrito em Rust.
//!
//! Ponto de entrada `kmain`, chamado pelo bootloader Limine (BIOS ou UEFI)
//! já em modo longo de 64 bits, com paginação ativa e o kernel mapeado na
//! metade superior do espaço de endereçamento.

#![no_std]
#![no_main]
#![feature(abi_x86_interrupt)]

mod boot;
mod console;
mod cpu;
mod framebuffer;
mod gdt;
mod interrupts;
mod memory;
mod serial;

use core::panic::PanicInfo;
use noto_sans_mono_bitmap::{FontWeight, RasterHeight};

use framebuffer::{Color, Framebuffer};
use memory::Size;

pub const VERSION: &str = env!("CARGO_PKG_VERSION");

// Paleta (inspirada no Windows 10, sem copiar sua identidade visual)
const DESK_TOP: Color = Color::rgb(0x00, 0x4e, 0x9a);
const DESK_BOTTOM: Color = Color::rgb(0x00, 0x2a, 0x5c);
const TASKBAR: Color = Color::rgb(0x1a, 0x1c, 0x22);
const START_BTN: Color = Color::rgb(0x2b, 0x2e, 0x38);
const TITLEBAR: Color = Color::rgb(0xf3, 0xf3, 0xf3);
const TITLE_TEXT: Color = Color::rgb(0x20, 0x20, 0x20);
const PANEL: Color = Color::rgb(0x12, 0x16, 0x26);
const ACCENT: Color = Color::rgb(0xff, 0x9f, 0x1c);
const TEXT: Color = Color::rgb(0xe8, 0xea, 0xf6);
const WHITE: Color = Color::rgb(0xff, 0xff, 0xff);
const OK: Color = Color::rgb(0x5e, 0xe0, 0x8f);

const TASKBAR_H: usize = 40;
const TITLEBAR_H: usize = 30;

#[unsafe(no_mangle)]
unsafe extern "C" fn kmain() -> ! {
    serial::init();
    serial_println!();
    serial_println!("==> WinRise OS v{} iniciando...", VERSION);

    if !boot::BASE_REVISION.is_supported() {
        serial_println!("ERRO: revisao base do protocolo Limine nao suportada");
        halt_forever();
    }

    gdt::init();
    interrupts::init();
    serial_println!("[ok] GDT, TSS e IDT carregadas");

    let fb_response = boot::FRAMEBUFFER.response();
    let Some(lfb) = fb_response.and_then(|r| r.framebuffers().first().copied()) else {
        serial_println!("ERRO: nenhum framebuffer disponivel");
        halt_forever();
    };
    let mut fb = Framebuffer::from_limine(lfb);
    serial_println!("[ok] framebuffer {}x{} @ {} bpp", fb.width, fb.height, fb.bpp());

    let (w, h) = (fb.width, fb.height);
    draw_desktop(&mut fb);

    // Janela "Informações do sistema", cujo conteúdo é o console de texto.
    let win_w = w.saturating_sub(260).min(900);
    let win_h = h.saturating_sub(TASKBAR_H + 120).min(440);
    let win_x = 140 + (w.saturating_sub(140) - win_w) / 2;
    let win_y = (h - TASKBAR_H - win_h) / 2;
    draw_window_frame(&mut fb, win_x, win_y, win_w, win_h, "Informações do sistema");
    let pad = 12;
    console::init(
        fb,
        win_x + pad,
        win_y + TITLEBAR_H + pad,
        win_w - 2 * pad,
        win_h - TITLEBAR_H - 2 * pad,
        TEXT,
        PANEL,
    );
    print_system_info(w, h);

    // Testa o tratamento de exceções: o breakpoint deve voltar normalmente.
    x86_64::instructions::interrupts::int3();

    console::set_color(OK);
    kprintln!();
    kprintln!("Sistema pronto. CPU em espera (hlt).");
    serial_println!("WINRISE_BOOT_OK");

    halt_forever();
}

/// Desenha a área de trabalho: fundo, ícones e barra de tarefas.
fn draw_desktop(fb: &mut Framebuffer) {
    let (w, h) = (fb.width, fb.height);
    fb.fill_vertical_gradient(DESK_TOP, DESK_BOTTOM);

    // Marca d'água "WinRise OS" no canto superior direito.
    let title = "WinRise OS";
    let tw = Framebuffer::text_width(title, FontWeight::Bold, RasterHeight::Size32);
    let ty = 24;
    let bg = Color::lerp(DESK_TOP, DESK_BOTTOM, (ty * 255 / h) as u32);
    fb.draw_text(w - tw - 32, ty, title, FontWeight::Bold, RasterHeight::Size32, WHITE, bg);

    // Ícones da área de trabalho.
    draw_icon(fb, 28, 24, "Computador", Color::rgb(0x6c, 0xc4, 0xff));
    draw_icon(fb, 28, 124, "Documentos", Color::rgb(0xff, 0xc8, 0x4a));
    draw_icon(fb, 28, 224, "Lixeira", Color::rgb(0xc8, 0xd0, 0xdc));

    // Barra de tarefas.
    let ty = h - TASKBAR_H;
    fb.fill_rect(0, ty, w, TASKBAR_H, TASKBAR);
    fb.fill_rect(0, ty, w, 1, Color::rgb(0x33, 0x36, 0x40));

    // Botão Iniciar com o logotipo do WinRise (seta para cima = "rise").
    fb.fill_rect(0, ty, 48, TASKBAR_H, START_BTN);
    draw_logo(fb, 24, ty + TASKBAR_H / 2, ACCENT);

    // Caixa de pesquisa.
    let sx = 56;
    fb.fill_rect(sx, ty + 6, 240.min(w / 4), TASKBAR_H - 12, Color::rgb(0x3a, 0x3d, 0x48));
    fb.draw_text(
        sx + 10,
        ty + 12,
        "Pesquisar",
        FontWeight::Regular,
        RasterHeight::Size16,
        Color::rgb(0xb0, 0xb4, 0xc0),
        Color::rgb(0x3a, 0x3d, 0x48),
    );

    // Janela ativa na barra de tarefas (indicador sublinhado).
    let bx = sx + 240.min(w / 4) + 12;
    fb.fill_rect(bx, ty, 48, TASKBAR_H, Color::rgb(0x2b, 0x2e, 0x38));
    fb.fill_rect(bx + 14, ty + 12, 20, 16, Color::rgb(0x6c, 0xc4, 0xff));
    fb.fill_rect(bx + 4, ty + TASKBAR_H - 3, 40, 3, ACCENT);

    // Relógio (hora UTC informada pelo bootloader, ou marcador).
    let mut buf = [0u8; 16];
    let clock = clock_text(&mut buf);
    let cw = Framebuffer::text_width(clock, FontWeight::Regular, RasterHeight::Size16);
    fb.draw_text(w - cw - 16, ty + 12, clock, FontWeight::Regular, RasterHeight::Size16, WHITE, TASKBAR);
}

/// Ícone simples da área de trabalho: um "cartão" colorido com rótulo.
fn draw_icon(fb: &mut Framebuffer, x: usize, y: usize, label: &str, color: Color) {
    fb.fill_rect(x + 16, y, 48, 40, color);
    fb.fill_rect(x + 16, y, 48, 8, Color::lerp(color, WHITE, 120));
    let lw = Framebuffer::text_width(label, FontWeight::Regular, RasterHeight::Size16);
    let lx = (x + 40).saturating_sub(lw / 2);
    let bg = Color::lerp(DESK_TOP, DESK_BOTTOM, ((y + 48) * 255 / fb.height) as u32);
    fb.draw_text(lx, y + 48, label, FontWeight::Regular, RasterHeight::Size16, WHITE, bg);
}

/// Logotipo do WinRise: uma seta/chevron apontando para cima.
fn draw_logo(fb: &mut Framebuffer, cx: usize, cy: usize, c: Color) {
    for i in 0..10 {
        // dois chevrons empilhados
        for (dy, thick) in [(0usize, 3usize), (8, 3)] {
            let y = cy - 8 + dy + i;
            fb.fill_rect(cx - 1 - i, y, thick, 1, c);
            fb.fill_rect(cx + i - 1, y, thick, 1, c);
        }
    }
}

/// Moldura de janela no estilo Windows 10: barra de título clara e botões.
fn draw_window_frame(fb: &mut Framebuffer, x: usize, y: usize, w: usize, h: usize, title: &str) {
    // sombra
    fb.fill_rect(x + 6, y + 6, w, h, Color::rgb(0x00, 0x1c, 0x40));
    fb.fill_rect(x, y, w, h, PANEL);
    fb.fill_rect(x, y, w, TITLEBAR_H, TITLEBAR);
    fb.stroke_rect(x, y, w, h, 1, Color::rgb(0x00, 0x7a, 0xcc));
    fb.draw_text(x + 12, y + 7, title, FontWeight::Regular, RasterHeight::Size16, TITLE_TEXT, TITLEBAR);
    // botões minimizar, maximizar, fechar
    let bw = 46;
    let bx = x + w - 3 * bw;
    let my = y + TITLEBAR_H / 2;
    fb.fill_rect(bx + bw / 2 - 5, my, 10, 1, TITLE_TEXT);
    fb.stroke_rect(bx + bw + bw / 2 - 5, my - 5, 10, 10, 1, TITLE_TEXT);
    fb.fill_rect(bx + 2 * bw, y + 1, bw - 1, TITLEBAR_H - 1, Color::rgb(0xe8, 0x11, 0x23));
    let (cx, cy) = (bx + 2 * bw + bw / 2, my);
    for i in 0..10 {
        fb.put_pixel(cx - 5 + i, cy - 5 + i, WHITE);
        fb.put_pixel(cx + 4 - i, cy - 5 + i, WHITE);
    }
}

fn clock_text(buf: &mut [u8; 16]) -> &str {
    let Some(date) = boot::DATE_AT_BOOT.response() else {
        return "--:--";
    };
    let secs = date.timestamp.rem_euclid(86_400) as u32;
    let (hh, mm) = (secs / 3600, secs / 60 % 60);
    let digits = [b'0' + (hh / 10) as u8, b'0' + (hh % 10) as u8, b':', b'0' + (mm / 10) as u8, b'0' + (mm % 10) as u8];
    buf[..5].copy_from_slice(&digits);
    buf[5..9].copy_from_slice(b" UTC");
    core::str::from_utf8(&buf[..9]).unwrap_or("--:--")
}

fn print_system_info(w: usize, h: usize) {
    kprintln!("WinRise OS v{} (x86_64)", VERSION);
    kprintln!("------------------------------------------------------------");

    if let Some(info) = boot::BOOTLOADER_INFO.response() {
        kprintln!("Bootloader : {} {}", info.name(), info.version());
    }
    let firmware = match boot::FIRMWARE_TYPE.response().map(|r| r.firmware_type) {
        Some(limine::firmware::FIRMWARE_TYPE_X86BIOS) => "BIOS (legado)",
        Some(limine::firmware::FIRMWARE_TYPE_EFI64) => "UEFI 64 bits",
        Some(limine::firmware::FIRMWARE_TYPE_EFI32) => "UEFI 32 bits",
        _ => "desconhecido",
    };
    kprintln!("Firmware   : {}", firmware);

    let cpu = cpu::info();
    kprintln!("CPU        : {}", cpu.brand());
    kprintln!("Fabricante : {}", cpu.vendor());
    kprintln!("Vídeo      : {}x{} pixels", w, h);

    if let Some(hhdm) = boot::HHDM.response() {
        kprintln!("HHDM       : {:#x}", hhdm.offset);
    }

    if let Some(mm) = boot::MEMMAP.response() {
        let entries = mm.entries();
        let s = memory::stats(entries);
        kprintln!("RAM usável : {} (+{} recuperável)", Size(s.usable), Size(s.reclaimable));
        kprintln!("Regiões    : {} entradas no mapa de memória", s.regions);
        serial_println!("Mapa de memória:");
        for e in entries {
            serial_println!(
                "  {:#018x} - {:#018x}  {} ({})",
                e.base,
                e.base + e.length,
                Size(e.length),
                memory::type_name(e.type_)
            );
        }
        if s.usable + s.reclaimable < 7 * 1024 * 1024 * 1024 {
            console::set_color(ACCENT);
            kprintln!("Aviso      : recomendado no mínimo 8 GiB de RAM");
            console::set_color(TEXT);
        }
    }
    kprintln!("Interrupções: GDT/TSS/IDT ativas, PIC 8259 mascarado");
}

pub fn halt_forever() -> ! {
    loop {
        x86_64::instructions::interrupts::disable();
        x86_64::instructions::hlt();
    }
}

#[panic_handler]
fn panic(info: &PanicInfo) -> ! {
    x86_64::instructions::interrupts::disable();
    // Evita deadlock caso o pânico ocorra com algum lock segurado.
    unsafe {
        serial::SERIAL1.force_unlock();
        console::CONSOLE.force_unlock();
    }
    console::set_color(Color::rgb(0xff, 0x55, 0x55));
    kprintln!("\n*** KERNEL PANIC ***\n{}", info);
    halt_forever();
}
