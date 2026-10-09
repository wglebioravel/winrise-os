//! Identificação do processador via instrução CPUID.

use core::arch::x86_64::__cpuid;

pub struct CpuInfo {
    vendor: [u8; 12],
    brand: [u8; 48],
}

impl CpuInfo {
    pub fn vendor(&self) -> &str {
        core::str::from_utf8(&self.vendor).unwrap_or("?")
    }

    pub fn brand(&self) -> &str {
        let len = self.brand.iter().position(|&b| b == 0).unwrap_or(48);
        core::str::from_utf8(&self.brand[..len]).unwrap_or("?").trim()
    }
}

pub fn info() -> CpuInfo {
    let mut vendor = [0u8; 12];
    let mut brand = [0u8; 48];
    let r = __cpuid(0);
    vendor[0..4].copy_from_slice(&r.ebx.to_le_bytes());
    vendor[4..8].copy_from_slice(&r.edx.to_le_bytes());
    vendor[8..12].copy_from_slice(&r.ecx.to_le_bytes());

    if __cpuid(0x8000_0000).eax >= 0x8000_0004 {
        for (i, leaf) in (0x8000_0002u32..=0x8000_0004).enumerate() {
            let r = __cpuid(leaf);
            for (j, reg) in [r.eax, r.ebx, r.ecx, r.edx].iter().enumerate() {
                let off = i * 16 + j * 4;
                brand[off..off + 4].copy_from_slice(&reg.to_le_bytes());
            }
        }
    }
    CpuInfo { vendor, brand }
}
