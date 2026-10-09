//! Driver mínimo para a porta serial COM1 (UART 16550).
//!
//! Usado para depuração: tudo que o kernel escreve com `serial_println!`
//! aparece no terminal do QEMU (`-serial stdio`) ou num cabo serial real.

use core::fmt;
use spin::Mutex;
use x86_64::instructions::port::Port;

const COM1: u16 = 0x3F8;

pub struct SerialPort {
    base: u16,
    present: bool,
}

impl SerialPort {
    const fn new(base: u16) -> Self {
        Self { base, present: false }
    }

    fn port(&self, offset: u16) -> Port<u8> {
        Port::new(self.base + offset)
    }

    /// Configura 115200 baud, 8N1, FIFOs ativadas, e faz um teste de loopback.
    fn init(&mut self) {
        unsafe {
            self.port(1).write(0x00); // desativa interrupções
            self.port(3).write(0x80); // DLAB = 1
            self.port(0).write(0x01); // divisor (low) -> 115200 baud
            self.port(1).write(0x00); // divisor (high)
            self.port(3).write(0x03); // 8 bits, sem paridade, 1 stop bit
            self.port(2).write(0xC7); // FIFO ativada, limpa, limite 14 bytes
            self.port(4).write(0x1E); // modo loopback para teste
            self.port(0).write(0xAE);
            self.present = self.port(0).read() == 0xAE;
            self.port(4).write(0x0F); // modo normal (DTR, RTS, OUT1, OUT2)
        }
    }

    fn write_byte(&mut self, byte: u8) {
        if !self.present {
            return;
        }
        // Espera o buffer de transmissão esvaziar (com limite, para nunca travar).
        for _ in 0..100_000 {
            if unsafe { self.port(5).read() } & 0x20 != 0 {
                break;
            }
            core::hint::spin_loop();
        }
        unsafe { self.port(0).write(byte) };
    }
}

impl fmt::Write for SerialPort {
    fn write_str(&mut self, s: &str) -> fmt::Result {
        for b in s.bytes() {
            if b == b'\n' {
                self.write_byte(b'\r');
            }
            self.write_byte(b);
        }
        Ok(())
    }
}

pub static SERIAL1: Mutex<SerialPort> = Mutex::new(SerialPort::new(COM1));

pub fn init() {
    SERIAL1.lock().init();
}

#[doc(hidden)]
pub fn _print(args: fmt::Arguments) {
    use core::fmt::Write;
    x86_64::instructions::interrupts::without_interrupts(|| {
        let _ = SERIAL1.lock().write_fmt(args);
    });
}

#[macro_export]
macro_rules! serial_print {
    ($($arg:tt)*) => ($crate::serial::_print(format_args!($($arg)*)));
}

#[macro_export]
macro_rules! serial_println {
    () => ($crate::serial_print!("\n"));
    ($($arg:tt)*) => ($crate::serial_print!("{}\n", format_args!($($arg)*)));
}
