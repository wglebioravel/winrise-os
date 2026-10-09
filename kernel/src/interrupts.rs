//! IDT (Interrupt Descriptor Table) com tratadores das exceções da CPU.

use spin::LazyLock as Lazy;
use x86_64::instructions::port::Port;
use x86_64::registers::control::Cr2;
use x86_64::structures::idt::{InterruptDescriptorTable, InterruptStackFrame, PageFaultErrorCode};

use crate::gdt;

static IDT: Lazy<InterruptDescriptorTable> = Lazy::new(|| {
    let mut idt = InterruptDescriptorTable::new();
    idt.divide_error.set_handler_fn(divide_error);
    idt.breakpoint.set_handler_fn(breakpoint);
    idt.invalid_opcode.set_handler_fn(invalid_opcode);
    idt.general_protection_fault.set_handler_fn(general_protection);
    idt.page_fault.set_handler_fn(page_fault);
    unsafe {
        idt.double_fault
            .set_handler_fn(double_fault)
            .set_stack_index(gdt::DOUBLE_FAULT_IST_INDEX);
    }
    idt
});

pub fn init() {
    IDT.load();
    disable_legacy_pic();
}

/// Mascara todas as linhas dos PICs 8259 legados; usaremos o APIC no futuro.
fn disable_legacy_pic() {
    unsafe {
        Port::<u8>::new(0x21).write(0xFF);
        Port::<u8>::new(0xA1).write(0xFF);
    }
}

extern "x86-interrupt" fn breakpoint(frame: InterruptStackFrame) {
    crate::kprintln!("[int] breakpoint (#BP) tratado em {:#x}", frame.instruction_pointer.as_u64());
}

extern "x86-interrupt" fn divide_error(frame: InterruptStackFrame) {
    panic!("EXCECAO: divisao por zero (#DE)\n{:#?}", frame);
}

extern "x86-interrupt" fn invalid_opcode(frame: InterruptStackFrame) {
    panic!("EXCECAO: opcode invalido (#UD)\n{:#?}", frame);
}

extern "x86-interrupt" fn general_protection(frame: InterruptStackFrame, code: u64) {
    panic!("EXCECAO: protecao geral (#GP), codigo {:#x}\n{:#?}", code, frame);
}

extern "x86-interrupt" fn page_fault(frame: InterruptStackFrame, code: PageFaultErrorCode) {
    panic!(
        "EXCECAO: page fault (#PF) no endereco {:?}, codigo {:?}\n{:#?}",
        Cr2::read(),
        code,
        frame
    );
}

extern "x86-interrupt" fn double_fault(frame: InterruptStackFrame, _code: u64) -> ! {
    panic!("EXCECAO: double fault (#DF)\n{:#?}", frame);
}
