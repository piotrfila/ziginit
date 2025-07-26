const std = @import("std");
const builtin = @import("builtin");

pub fn build(b: *std.Build) !void {
    // const target = b.standardTargetOptions(.{});
    const target = b.resolveTargetQuery(.{
        .cpu_arch = .x86_64,
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
    const kernel_append = "console=ttyS0";
    const vm_run_cmd = b.addSystemCommand(&.{
        "qemu-system-x86_64",
        "-enable-kvm",
        "-smp",
        b.option([]const u8, "vm-cores", "Number of cores for the guest system. Default is 1 cpu") orelse "1",
        "-m",
        b.option([]const u8, "vm-mem", "Amount of memory for the guest system. Default is 1 GiB") orelse "1G",
        "-kernel",
        b.option([]const u8, "vm-kernel", "Path to kernel object.") orelse std.debug.panic("You have to specify a kernel with -Dvm-kernel=", .{}),
        "-initrd",
        "./zig-out/rootfs.cpio",
        "-nographic",
        "-append",
        if (b.option([]const u8, "vm-kopts", "Additional kernel options")) |opts|
            try std.fmt.allocPrint(b.allocator, "{s} {s}", .{ kernel_append, opts })
        else
            kernel_append,
    });
    vm_run_cmd.stdio = .inherit;
    vm_run_step.dependOn(&vm_run_cmd.step);
    vm_run_cmd.step.dependOn(&mkcpio_run_cmd.step);

    // This allows the user to pass arguments to the application in the build
    // command itself, like this: `zig build run -- arg1 arg2 etc`
    // if (b.args) |args| {
    //     run_cmd.addArgs(args);
    // }

    // tests
    const pid0_tests = b.addTest(.{
        .root_module = pid0_exe.root_module,
    });
    const run_pid0_tests = b.addRunArtifact(pid0_tests);

    const test_step = b.step("test", "Run tests");
    test_step.dependOn(&run_pid0_tests.step);
}
