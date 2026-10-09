//! Acesso de baixo nível ao framebuffer linear entregue pelo Limine.

use noto_sans_mono_bitmap::{FontWeight, RasterHeight, get_raster, get_raster_width};

#[derive(Clone, Copy, PartialEq, Eq)]
pub struct Color {
    pub r: u8,
    pub g: u8,
    pub b: u8,
}

impl Color {
    pub const fn rgb(r: u8, g: u8, b: u8) -> Self {
        Self { r, g, b }
    }

    /// Interpolação linear entre duas cores (`t` em 0..=255).
    pub fn lerp(a: Color, b: Color, t: u32) -> Color {
        let mix = |x: u8, y: u8| ((x as u32 * (255 - t) + y as u32 * t) / 255) as u8;
        Color::rgb(mix(a.r, b.r), mix(a.g, b.g), mix(a.b, b.b))
    }
}

pub struct Framebuffer {
    addr: *mut u8,
    pub width: usize,
    pub height: usize,
    pitch: usize,
    bytes_per_pixel: usize,
    red_shift: u8,
    green_shift: u8,
    blue_shift: u8,
}

// O framebuffer é memória mapeada exclusiva do kernel; o acesso é protegido por Mutex.
unsafe impl Send for Framebuffer {}

impl Framebuffer {
    pub fn from_limine(fb: &limine::framebuffer::Framebuffer) -> Self {
        Self {
            addr: fb.address() as *mut u8,
            width: fb.width as usize,
            height: fb.height as usize,
            pitch: fb.pitch as usize,
            bytes_per_pixel: (fb.bpp as usize).div_ceil(8),
            red_shift: fb.red_mask_shift,
            green_shift: fb.green_mask_shift,
            blue_shift: fb.blue_mask_shift,
        }
    }

    pub fn bpp(&self) -> usize {
        self.bytes_per_pixel * 8
    }

    #[inline]
    fn encode(&self, c: Color) -> u32 {
        ((c.r as u32) << self.red_shift)
            | ((c.g as u32) << self.green_shift)
            | ((c.b as u32) << self.blue_shift)
    }

    #[inline]
    pub fn put_pixel(&mut self, x: usize, y: usize, c: Color) {
        if x >= self.width || y >= self.height {
            return;
        }
        let value = self.encode(c);
        let offset = y * self.pitch + x * self.bytes_per_pixel;
        unsafe {
            let p = self.addr.add(offset);
            if self.bytes_per_pixel == 4 {
                (p as *mut u32).write_volatile(value);
            } else {
                for i in 0..self.bytes_per_pixel {
                    p.add(i).write_volatile((value >> (8 * i)) as u8);
                }
            }
        }
    }

    pub fn fill_rect(&mut self, x: usize, y: usize, w: usize, h: usize, c: Color) {
        let x_end = (x + w).min(self.width);
        let y_end = (y + h).min(self.height);
        for yy in y..y_end {
            for xx in x..x_end {
                self.put_pixel(xx, yy, c);
            }
        }
    }

    /// Contorno de retângulo com espessura `t`.
    pub fn stroke_rect(&mut self, x: usize, y: usize, w: usize, h: usize, t: usize, c: Color) {
        self.fill_rect(x, y, w, t, c);
        self.fill_rect(x, y + h - t, w, t, c);
        self.fill_rect(x, y, t, h, c);
        self.fill_rect(x + w - t, y, t, h, c);
    }

    /// Fundo com degradê vertical.
    pub fn fill_vertical_gradient(&mut self, top: Color, bottom: Color) {
        for y in 0..self.height {
            let t = (y * 255 / self.height.max(1)) as u32;
            let c = Color::lerp(top, bottom, t);
            for x in 0..self.width {
                self.put_pixel(x, y, c);
            }
        }
    }

    /// Desenha um caractere com antialiasing sobre uma cor de fundo conhecida.
    /// Retorna a largura avançada em pixels.
    pub fn draw_char(
        &mut self,
        x: usize,
        y: usize,
        ch: char,
        weight: FontWeight,
        size: RasterHeight,
        fg: Color,
        bg: Color,
    ) -> usize {
        let raster = get_raster(ch, weight, size).or_else(|| get_raster('?', weight, size));
        if let Some(r) = raster {
            for (dy, row) in r.raster().iter().enumerate() {
                for (dx, &alpha) in row.iter().enumerate() {
                    if alpha > 0 {
                        self.put_pixel(x + dx, y + dy, Color::lerp(bg, fg, alpha as u32));
                    }
                }
            }
        }
        get_raster_width(weight, size)
    }

    pub fn draw_text(
        &mut self,
        x: usize,
        y: usize,
        text: &str,
        weight: FontWeight,
        size: RasterHeight,
        fg: Color,
        bg: Color,
    ) {
        let mut cx = x;
        for ch in text.chars() {
            cx += self.draw_char(cx, y, ch, weight, size, fg, bg);
        }
    }

    pub fn text_width(text: &str, weight: FontWeight, size: RasterHeight) -> usize {
        text.chars().count() * get_raster_width(weight, size)
    }
}
