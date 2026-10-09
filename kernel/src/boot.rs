//! Requisições ao bootloader Limine.
//!
//! O Limine procura estas estruturas dentro da seção `.limine_requests`
//! do executável e preenche as respostas antes de saltar para `kmain`.

use limine::{BaseRevision, RequestsEndMarker, RequestsStartMarker};
use limine::request::{
    BootloaderInfoRequest, DateAtBootRequest, FirmwareTypeRequest, FramebufferRequest, HhdmRequest, MemmapRequest,
    StackSizeRequest,
};

/// Revisão 3 do protocolo: suportada pelo Limine 8.x/9.x.
#[used]
#[unsafe(link_section = ".limine_requests")]
pub static BASE_REVISION: BaseRevision = BaseRevision::with_revision(3);

#[used]
#[unsafe(link_section = ".limine_requests")]
pub static FRAMEBUFFER: FramebufferRequest = FramebufferRequest::new();

#[used]
#[unsafe(link_section = ".limine_requests")]
pub static MEMMAP: MemmapRequest = MemmapRequest::new();

#[used]
#[unsafe(link_section = ".limine_requests")]
pub static HHDM: HhdmRequest = HhdmRequest::new();

#[used]
#[unsafe(link_section = ".limine_requests")]
pub static BOOTLOADER_INFO: BootloaderInfoRequest = BootloaderInfoRequest::new();

#[used]
#[unsafe(link_section = ".limine_requests")]
pub static FIRMWARE_TYPE: FirmwareTypeRequest = FirmwareTypeRequest::new();

#[used]
#[unsafe(link_section = ".limine_requests")]
pub static DATE_AT_BOOT: DateAtBootRequest = DateAtBootRequest::new();

/// Pilha de 256 KiB para o kernel.
#[used]
#[unsafe(link_section = ".limine_requests")]
pub static STACK_SIZE: StackSizeRequest = StackSizeRequest::new(256 * 1024);

#[used]
#[unsafe(link_section = ".limine_requests_start")]
static _START_MARKER: RequestsStartMarker = RequestsStartMarker::new();

#[used]
#[unsafe(link_section = ".limine_requests_end")]
static _END_MARKER: RequestsEndMarker = RequestsEndMarker::new();
