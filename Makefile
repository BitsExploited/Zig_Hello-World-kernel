# Makefile for Zig kernel
.PHONY: all clean run iso test

all: test

# Build and run directly with zig build
test:
	zig build run

# Alternative: build and copy manually
build:
	zig build
	mkdir -p out
	cp zig-out/bin/kernel out/kernel 2>/dev/null || echo "Check zig-out/bin/ for kernel"

# Create bootable ISO
iso: build
	mkdir -p out/iso/boot/grub
	cp out/kernel out/iso/boot/kernel.elf
	cp grub.cfg out/iso/boot/grub/grub.cfg
	grub-mkrescue -o out/kernel.iso out/iso

# Test with QEMU - direct kernel boot
run-kernel:
	zig build
	qemu-system-i386 -kernel zig-out/bin/kernel

# Test with QEMU - ISO boot (more realistic)
run: iso
	qemu-system-i386 -cdrom out/kernel.iso

# Test with more verbose output
run-debug:
	zig build
	qemu-system-i386 -kernel zig-out/bin/kernel -serial stdio -d guest_errors

# Clean build artifacts
clean:
	rm -rf out/ zig-out/ .zig-cache/
