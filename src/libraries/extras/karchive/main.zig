const std = @import("std");
const qt6 = @import("libqt6zig");
const qcoreapplication = qt6.qcoreapplication;
const kzip = qt6.kzip;
const qiodevicebase_enums = qt6.qiodevicebase_enums;

const file_path = "zig-out/hello.zip";
var buffer: [64]u8 = undefined;

pub fn main(init: std.process.Init) !void {
    const argv = try qt6.init(init.gpa, init.minimal.args);
    defer qt6.deinit(init.gpa, argv);
    var argc: i32 = @intCast(argv.len);
    const qapp = qcoreapplication.New(&argc, argv, init.arena.allocator());
    defer qcoreapplication.Delete(qapp);

    const archive = kzip.New(file_path);
    defer kzip.Delete(archive);

    if (kzip.Open(archive, qiodevicebase_enums.OpenModeFlag.WriteOnly)) {
        defer _ = kzip.Close(archive);

        var data = "The whole world inside a hello".*;
        _ = kzip.WriteFile(archive, "world", &data);
        const msg = std.fmt.bufPrint(&buffer, "Successfully wrote to '{s}'\n", .{file_path}) catch @panic("Failed to write to buffer");
        try std.Io.File.stdout().writeStreamingAll(init.io, msg);
    } else {
        const msg = std.fmt.bufPrint(&buffer, "Failed to open '{s}' for writing\n", .{file_path}) catch @panic("Failed to write to buffer");
        try std.Io.File.stdout().writeStreamingAll(init.io, msg);
    }
}
