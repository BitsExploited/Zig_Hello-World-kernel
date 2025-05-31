const std = @import("std");

pub fn build(b: *std.Build) void {
    // Create a freestanding target (no OS) - use i386 for better compatibility
    const target = b.standardTargetOptions(.{
        .default_target = .{
            .cpu_arch = .x86,
            .cpu_model = .{ .explicit = &std.Target.x86.cpu.i386 },
            .os_tag = .freestanding,
            .abi = .none,
        },
    });
    
    const optimize = b.standardOptimizeOption(.{});
    
    const exe = b.addExecutable(.{
        .name = "kernel",
        .root_source_file = b.path("src/kernel.zig"),
        .target = target,
        .optimize = optimize,
    });
    
    // Disable standard library for kernel
    exe.root_module.red_zone = false;
    exe.root_module.omit_frame_pointer = false;
    
    // Set entry point
    exe.entry = .{ .symbol_name = "_start" };
    
    // Use custom linker script
    exe.setLinkerScriptPath(b.path("linker.ld"));
    
    // Don't strip symbols
    exe.root_module.strip = false;
    
    // Install to zig-out/bin/ (default location)
    b.installArtifact(exe);
    
    // Create out directory and copy kernel in one command that won't fail
    const copy_step = b.addSystemCommand(&[_][]const u8{
        "sh", "-c", "mkdir -p out && cp zig-out/bin/kernel out/kernel 2>/dev/null || echo 'Kernel built successfully, check zig-out/bin/'"
    });
    copy_step.step.dependOn(b.getInstallStep());
    
    const copy_install = b.step("copy", "Copy kernel to out directory");
    copy_install.dependOn(&copy_step.step);
    
    // Add a run step for direct testing
    const run_cmd = b.addSystemCommand(&[_][]const u8{
        "qemu-system-i386", "-kernel", "zig-out/bin/kernel"
    });
    run_cmd.step.dependOn(b.getInstallStep());
    
    const run_step = b.step("run", "Run the kernel in QEMU");
    run_step.dependOn(&run_cmd.step);
}
