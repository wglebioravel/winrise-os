//! Console de texto simples desenhado sobre o framebuffer.
//!
//! Ocupa uma região retangular da tela; quebra linhas automaticamente e
//! recomeça do topo quando a região enche (rolagem virá depois).

use core::fmt;
use noto_sans_mono_bitmap::{FontWeight, RasterHeight, get_raster_width};
use spin::Mutex;

use crate::framebuffer::{Color, Framebuffer};

const SIZE: RasterHeight = RasterHeight::Size16;
const LINE_HEIGHT: usize = 20;

pub struct Console {
    fb: Framebuffer,
    x0: usize,
    y0: usize,
    w: usize,
    h: usize,
    col: usize,
    row: usize,
    pub fg: Color,
    pub bg: Color,
}

impl Console {
    fn char_w() -> usize {
        get_raster_width(FontWeight::Regular, SIZE)
    }

    fn cols(&self) -> usize {
        (self.w / Self::char_w()).max(1)
    }

    fn rows(&self) -> usize {
        (self.h / LINE_HEIGHT).max(1)
    }

    fn newline(&mut self) {
        self.col = 0;
        self.row += 1;
        if self.row >= self.rows() {
            self.row = 0;
            self.fb.fill_rect(self.x0, self.y0, self.w, self.h, self.bg);
        }
    }

    pub fn write_char(&mut self, c: char) {
        match c {
            '\n' => self.newline(),
            '\r' => self.col = 0,
            c => {
                if self.col >= self.cols() {
                    self.newline();
                }
                let x = self.x0 + self.col * Self::char_w();
                let y = self.y0 + self.row * LINE_HEIGHT;
                self.fb.draw_char(x, y, c, FontWeight::Regular, SIZE, self.fg, self.bg);
                self.col += 1;
            }
        }
    }
}

impl fmt::Write for Console {
    fn write_str(&mut self, s: &str) -> fmt::Result {
        for c in s.chars() {
            self.write_char(c);
        }
        Ok(())
    }
}

pub static CONSOLE: Mutex<Option<Console>> = Mutex::new(None);

/// Cria o console numa região do framebuffer, preenchendo-a com `bg`.
pub fn init(mut fb: Framebuffer, x: usize, y: usize, w: usize, h: usize, fg: Color, bg: Color) {
    fb.fill_rect(x, y, w, h, bg);
    *CONSOLE.lock() = Some(Console { fb, x0: x, y0: y, w, h, col: 0, row: 0, fg, bg });
}

pub fn set_color(fg: Color) {
    if let Some(c) = CONSOLE.lock().as_mut() {
        c.fg = fg;
    }
}

#[doc(hidden)]
pub fn _print(args: fmt::Arguments) {
    use core::fmt::Write;
    x86_64::instructions::interrupts::without_interrupts(|| {
        if let Some(c) = CONSOLE.lock().as_mut() {
            let _ = c.write_fmt(args);
        }
    });
}

/// Escreve na tela e também na serial.
#[macro_export]
macro_rules! kprint {
    ($($arg:tt)*) => {{
        $crate::console::_print(format_args!($($arg)*));
        $crate::serial::_print(format_args!($($arg)*));
    }};
}

#[macro_export]
macro_rules! kprintln {
    () => ($crate::kprint!("\n"));
    ($($arg:tt)*) => ($crate::kprint!("{}\n", format_args!($($arg)*)));
}
