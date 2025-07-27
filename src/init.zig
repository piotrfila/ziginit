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
        panic("Could not open /dev/console.\n{any}\n", .{e});
    };

    const root_dir = std.fs.openDirAbsolute("/", .{ .iterate = true }) catch |e|
        panic("Could not open root directory.\n{any}\n", .{e});

    while (true) {
        var root_it = root_dir.iterate();
        while (root_it.next() catch |e|
            panic("Error while walking root directory.\n{any}\n", .{e})) |subdir|
        {
            console.writeAll(io, "\n") catch {};
            console.writeAll(io, subdir.name) catch {};
            var dir = root_dir.openDir(subdir.name, .{ .iterate = true }) catch continue;
            defer dir.close();
            console.writeAll(io, ":") catch {};
            var it = dir.iterate();
            while (it.next() catch |e|
                panic("Error while walking /{s} directory.\n{any}\n", .{ subdir.name, e })) |item|
            {
                console.writeAll(io, "\n  ") catch {};
                console.writeAll(io, item.name) catch {};
            }
        }
        std.Thread.sleep(1 * std.time.ns_per_s);
    }
}
