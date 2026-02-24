const std = @import("std");
const qt6 = @import("libqt6zig");
const qcoreapplication = qt6.qcoreapplication;
const kzip = qt6.kzip;
const qiodevicebase_enums = qt6.qiodevicebase_enums;

const ZIP_FILE = "zig-out/hello.zip";
var buffer: [64]u8 = undefined;

pub fn main() !void {
    const argc = std.os.argv.len;
    const argv = std.os.argv.ptr;
    const qapp = qcoreapplication.New(argc, argv);
    defer qcoreapplication.Delete(qapp);

    const archive = kzip.New(ZIP_FILE);
    defer kzip.Delete(archive);

    var stdout_writer = std.fs.File.stdout().writer(&buffer);

    if (kzip.Open(archive, qiodevicebase_enums.OpenModeFlag.WriteOnly)) {
        defer _ = kzip.Close(archive);

        var data = "The whole world inside a hello".*;
        _ = kzip.WriteFile(archive, "world", &data);
        try stdout_writer.interface.print("Successfully wrote to '{s}'\n", .{ZIP_FILE});
        try stdout_writer.interface.flush();
    } else {
        try stdout_writer.interface.print("Failed to open '{s}' for writing\n", .{ZIP_FILE});
        try stdout_writer.interface.flush();
    }
}
