const std = @import("std");
const builtin = @import("builtin");

// Not all architectures are tested
fn qemu_name(this: std.Target.Cpu.Arch) ?[]const u8 {
    return switch (this) {
        .aarch64 => "qemu-system-aarch64",
        .arm => "qemu-system-arm",
        .loongarch64 => "qemu-system-loongarch64",
        .m68k => "qemu-system-m68k",
        .mips => "qemu-system-mips",
        .mips64 => "qemu-system-mips64",
        .mipsel => "qemu-system-mipsel",
        .mips64el => "qemu-system-mips64el",
        .powerpc => "qemu-system-ppc",
        .powerpc64 => "qemu-system-ppc64",
        .riscv32 => "qemu-system-riscv32",
        .riscv64 => "qemu-system-riscv64",
        .s390x => "qemu-system-s390x",
        .sparc => "qemu-system-sparc",
        .sparc64 => "qemu-system-sparc64",
        .x86 => "qemu-system-i386",
        .x86_64 => "qemu-system-x86_64",
        else => return null,
    };
}

pub fn build(b: *std.Build) !void {
    // const target = b.standardTargetOptions(.{});
    const arch = b.option(std.Target.Cpu.Arch, "arch", "Instruction set architecture. Native by default.") orelse builtin.cpu.arch;
    const target = b.resolveTargetQuery(.{
        .cpu_arch = arch,
        .os_tag = .linux,
        .cpu_model = .baseline,
    });
    const optimize = b.standardOptimizeOption(.{});

    const pid0_exe = b.addExecutable(.{
        .name = "init",
        .root_module = b.createModule(.{
            .root_source_file = b.path("src/init.zig"),
            .target = target,
            .optimize = optimize,
            .imports = &.{},
        }),
    });

    b.installArtifact(pid0_exe);

    const mkcpio_run_step = b.step("mkcpio", "Create cpio archive.");
    const mkcpio_run_cmd = b.addSystemCommand(&.{
        "cpio",
        "-o",
        "--reproducible",
        "--quiet",
        "-H",
        "newc",
        "-O",
        "../rootfs.cpio",
    });
    mkcpio_run_cmd.stdin = .{ .bytes = pid0_exe.name };
    mkcpio_run_cmd.cwd = try .join(.{ .cwd_relative = b.install_prefix }, b.allocator, "bin");
    mkcpio_run_step.dependOn(&mkcpio_run_cmd.step);
    mkcpio_run_cmd.step.dependOn(b.getInstallStep());

    const vm_run_step = b.step("run-vm", "Run the init inside a VM use qemu.");
    var vm_run_args: std.ArrayList([]const u8) = .init(b.allocator);
    try vm_run_args.append(qemu_name(arch) orelse std.debug.panic("Unsupported architecture: {any}\n", .{arch}));
    try vm_run_args.append("-initrd");
    try vm_run_args.append("./zig-out/rootfs.cpio");

    if (b.args) |args| {
        for (args) |arg|
            try vm_run_args.append(arg);
    }

    const vm_run_cmd = b.addSystemCommand(try vm_run_args.toOwnedSlice());
    vm_run_cmd.stdio = .inherit;
    vm_run_step.dependOn(&vm_run_cmd.step);
    vm_run_cmd.step.dependOn(&mkcpio_run_cmd.step);

    // tests
    const pid0_tests = b.addTest(.{
        .root_module = pid0_exe.root_module,
    });
    const run_pid0_tests = b.addRunArtifact(pid0_tests);

    const test_step = b.step("test", "Run tests");
    test_step.dependOn(&run_pid0_tests.step);
}
