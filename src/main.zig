const std = @import("std");
const zigimg = @import("zigimg");

pub fn main() !void {
    var gpa = std.heap.DebugAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    var io_threaded: std.Io.Threaded = .init_single_threaded;
    const encoded = try std.Io.Dir.cwd().readFileAlloc(
        io_threaded.io(),
        "assets/zig.png",
        allocator,
        .unlimited,
    );
    defer allocator.free(encoded);

    var image = try zigimg.Image.fromMemory(allocator, encoded);
    defer image.deinit(allocator);

    std.debug.print("decoded {d}x{d}\n", .{ image.width, image.height });
}
