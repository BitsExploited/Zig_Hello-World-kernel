# Zig Kernel

A minimal x86 kernel written in Zig that demonstrates basic kernel development concepts including multiboot compliance, VGA text mode output, and bare-metal programming.

## Features

- **Multiboot Compliant**: Can be loaded by GRUB and other multiboot-compatible bootloaders
- **VGA Text Output**: Displays "Hello, Zig Kernel!" in white text on black background
- **Freestanding Binary**: No dependencies on standard library or operating system
- **x86 Architecture**: Targets i386 for maximum compatibility
- **Custom Linker Script**: Precise memory layout control for kernel loading

## Project Structure

```
zig-kernel/
├── src/
│   └── kernel.zig          # Main kernel source code
├── build.zig               # Zig build configuration
├── linker.ld               # Custom linker script for memory layout
├── grub.cfg                # GRUB bootloader configuration
├── Makefile                # Build automation
└── README.md               # This file
```

## Prerequisites

### Required Software

- **Zig**: Version 0.12+ (tested with 0.13.0)
- **QEMU**: For testing and emulation
  ```bash
  # Ubuntu/Debian
  sudo apt install qemu-system-x86
  
  # Arch Linux
  sudo pacman -S qemu-full
  
  # Fedora
  sudo dnf install qemu-system-x86
  ```

### Optional (for ISO creation)
- **GRUB tools**: For creating bootable ISOs
  ```bash
  # Ubuntu/Debian
  sudo apt install grub-pc-bin xorriso
  
  # Arch Linux
  sudo pacman -S grub xorriso
  ```

## Building and Running

### Quick Start (Recommended)

```bash
# Build and run the kernel directly
make test
```

### Alternative Build Methods

```bash
# Build kernel binary only
zig build

# Build and run with QEMU
make run-kernel

# Build bootable ISO and run
make run

# Debug mode with verbose output
make run-debug

# Clean all build artifacts
make clean
```

## Technical Details

### Memory Layout

The kernel is loaded at **1MB (0x100000)** in physical memory:

| Address Range | Section | Purpose |
|---------------|---------|---------|
| 0x100000+    | .multiboot | Multiboot header for bootloader |
| 0x101000+    | .text      | Executable code |
| 0x102000+    | .rodata    | Read-only data (strings, constants) |
| 0x103000+    | .data      | Initialized global variables |
| 0x104000+    | .bss       | Uninitialized data |

### Multiboot Header

The kernel includes a multiboot header with:
- **Magic Number**: `0x1BADB002`
- **Flags**: `0x00000000` (basic multiboot)
- **Checksum**: `0xE4524FFE` (ensures header validity)

### VGA Text Mode

- **Buffer Address**: `0xB8000`
- **Format**: 16-bit values (8-bit character + 8-bit attribute)
- **Colors**: White text (0x0F) on black background (0x00)
- **Resolution**: 80x25 characters

## Code Overview

### src/kernel.zig

```zig
// Multiboot header for bootloader compatibility
export const multiboot_header align(4) linksection(".multiboot") = [_]u32{
    0x1BADB002,  // Magic number
    0x00000000,  // Flags
    0xE4524FFE,  // Checksum
};

// Kernel entry point
export fn _start() callconv(.C) noreturn {
    // Write to VGA buffer at 0xB8000
    const vga_buffer: [*]volatile u16 = @ptrFromInt(0xb8000);
    const message = "Hello, Zig Kernel!";
    
    for (message, 0..) |c, i| {
        vga_buffer[i] = (@as(u16, 0x0f) << 8) | @as(u16, c);
    }
    
    // Halt the CPU
    while (true) {
        asm volatile ("hlt");
    }
}
```

### Key Zig Features Used

- **`export`**: Makes symbols visible to the linker
- **`callconv(.C)`**: Uses C calling convention for bootloader compatibility
- **`noreturn`**: Indicates function never returns
- **`@ptrFromInt`**: Safely converts integer to pointer
- **`@as`**: Explicit type casting
- **`volatile`**: Prevents compiler optimizations on hardware access
- **`asm volatile`**: Inline assembly for CPU halt instruction

## Build Configuration

### Zig Build (build.zig)

- **Target**: `x86-freestanding-none` (no operating system)
- **CPU**: i386 for maximum compatibility
- **Entry Symbol**: `_start`
- **Linker Script**: Custom `linker.ld`
- **Optimizations**: Debug mode with frame pointers

### Linker Script (linker.ld)

- **Entry Point**: `_start`
- **Load Address**: 1MB (0x100000)
- **Alignment**: 4KB page boundaries
- **Section Order**: multiboot → text → rodata → data → bss

## Testing in QEMU

The kernel can be tested in several ways:

1. **Direct Kernel Loading**: `qemu-system-i386 -kernel zig-out/bin/kernel`
2. **ISO Boot**: `qemu-system-i386 -cdrom out/kernel.iso`
3. **Debug Mode**: Additional logging and error output

### Expected Output

When running successfully, you should see:
- QEMU window opens
- Black screen with white text: "Hello, Zig Kernel!"
- System appears to hang (normal - kernel halts after printing)

## Troubleshooting

### Common Issues

**Build Errors**:
- Ensure Zig version is 0.12+
- Check that all files are in correct locations

**QEMU Errors**:
- "Error loading ELF kernel": Multiboot header issue
- Black screen: VGA buffer access problem
- Immediate exit: Kernel crashed during startup

**File Not Found**:
- Run `zig build` first to create `zig-out/bin/kernel`
- Check file permissions

### Debug Steps

```bash
# Check if kernel file exists and is valid
ls -la zig-out/bin/kernel
file zig-out/bin/kernel

# Verify multiboot header
hexdump -C zig-out/bin/kernel | head -20

# Run with debug output
qemu-system-i386 -kernel zig-out/bin/kernel -serial stdio -d guest_errors
```

## Next Steps

This kernel provides a foundation for more advanced features:

- **Interrupt Handling**: Set up IDT and handle keyboard/timer interrupts
- **Memory Management**: Implement paging and heap allocation
- **Process Management**: Create and schedule user processes
- **File System**: Add storage device drivers and file systems
- **System Calls**: Interface between user and kernel space
- **Networking**: Network stack and device drivers

## Learning Resources

- [OSDev Wiki](https://wiki.osdev.org/) - Comprehensive OS development guide
- [Zig Language Reference](https://ziglang.org/documentation/master/) - Official Zig documentation
- [Intel x86 Manuals](https://www.intel.com/content/www/us/en/developer/articles/technical/intel-sdm.html) - Hardware reference
- [Multiboot Specification](https://www.gnu.org/software/grub/manual/multiboot/multiboot.html) - Bootloader standard


