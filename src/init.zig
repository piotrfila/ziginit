const std = @import("std");
// const ziginit = @import("ziginit");
const Io = std.Io;
const panic = std.debug.panic;

pub fn main() noreturn {
    if (std.os.linux.getpid() != 1)
        panic("This program is meant to be run as init.\n", .{});

    var gpa_state: std.heap.DebugAllocator(.{}) = .init;
    defer _ = gpa_state.deinit();
    const gpa = gpa_state.allocator();

    var pool: Io.ThreadPool = .init(gpa);
    defer pool.deinit();
    const io = pool.io();

    const console = Io.Dir.cwd().openFile(
        io,
        "/dev/console",
        .{ .mode = .read_write },
    ) catch |e| {
        panic("Could not open console.\n{any}\n", .{e});
    };

    while (true) {
        console.writeAll(io, "hello, world!\n") catch {};
        std.Thread.sleep(1 * std.time.ns_per_s);
    }
}
