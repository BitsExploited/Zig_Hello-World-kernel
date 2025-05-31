// Multiboot header for QEMU/GRUB compatibility
const MULTIBOOT_MAGIC: u32 = 0x1BADB002;
const MULTIBOOT_FLAGS: u32 = 0x00000000;
const MULTIBOOT_CHECKSUM: u32 = 0xE4524FFE; // Pre-calculated: -(0x1BADB002 + 0x00000000)

export const multiboot_header align(4) linksection(".multiboot") = [_]u32{
    MULTIBOOT_MAGIC,
    MULTIBOOT_FLAGS,
    MULTIBOOT_CHECKSUM,
};

export fn _start() callconv(.C) noreturn {
    const vga_buffer: [*]volatile u16 = @ptrFromInt(0xb8000);
    const message = "Hello, Zig Kernel!";
    
    for (message, 0..) |c, i| {
        // Cast the character to u16 first, then combine with attribute
        vga_buffer[i] = (@as(u16, 0x0f) << 8) | @as(u16, c);
    }
    
    while (true) {
        asm volatile ("hlt");
    }
}
