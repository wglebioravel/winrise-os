//! Leitura do mapa de memória fornecido pelo Limine.

use limine::memmap::{self, Entry};

#[derive(Default, Clone, Copy)]
pub struct MemoryStats {
    pub usable: u64,
    pub reclaimable: u64,
    pub total: u64,
    pub regions: usize,
}

pub fn type_name(t: u64) -> &'static str {
    match t {
        memmap::MEMMAP_USABLE => "usavel",
        memmap::MEMMAP_RESERVED => "reservada",
        memmap::MEMMAP_ACPI_RECLAIMABLE => "ACPI recuperavel",
        memmap::MEMMAP_ACPI_NVS => "ACPI NVS",
        memmap::MEMMAP_BAD_MEMORY => "defeituosa",
        memmap::MEMMAP_BOOTLOADER_RECLAIMABLE => "bootloader",
        memmap::MEMMAP_EXECUTABLE_AND_MODULES => "kernel/modulos",
        memmap::MEMMAP_FRAMEBUFFER => "framebuffer",
        _ => "desconhecida",
    }
}

pub fn stats(entries: &[&Entry]) -> MemoryStats {
    let mut s = MemoryStats { regions: entries.len(), ..Default::default() };
    for e in entries {
        match e.type_ {
            memmap::MEMMAP_USABLE => s.usable += e.length,
            memmap::MEMMAP_BOOTLOADER_RECLAIMABLE | memmap::MEMMAP_ACPI_RECLAIMABLE => {
                s.reclaimable += e.length
            }
            _ => {}
        }
        if e.type_ != memmap::MEMMAP_RESERVED && e.type_ != memmap::MEMMAP_FRAMEBUFFER {
            s.total += e.length;
        }
    }
    s
}

/// Formata bytes como "x.y GiB" / "x MiB".
pub struct Size(pub u64);

impl core::fmt::Display for Size {
    fn fmt(&self, f: &mut core::fmt::Formatter<'_>) -> core::fmt::Result {
        const MIB: u64 = 1024 * 1024;
        const GIB: u64 = 1024 * MIB;
        if self.0 >= GIB {
            let tenths = self.0 * 10 / GIB;
            write!(f, "{}.{} GiB", tenths / 10, tenths % 10)
        } else if self.0 >= MIB {
            write!(f, "{} MiB", self.0 / MIB)
        } else {
            write!(f, "{} KiB", self.0 / 1024)
        }
    }
}
