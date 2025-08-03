const std = @import("std");
const builtin = @import("builtin");
const qt6 = @import("libqt6zig");
const ui = @import("design.zig");
const qapplication = qt6.qapplication;
const qmainwindow = qt6.qmainwindow;

const config = getAllocatorConfig();
var gda: std.heap.DebugAllocator(config) = .init;
const allocator = gda.allocator();

pub fn main() !void {
    // Initialize Qt application
    const argc = std.os.argv.len;
    const argv = std.os.argv.ptr;
    _ = qapplication.New(argc, argv);

    const uic = try ui.NewMainWindowUi(allocator);
    defer allocator.destroy(uic);

    qmainwindow.Show(uic.MainWindow);

    _ = qapplication.Exec();
}

fn getAllocatorConfig() std.heap.DebugAllocatorConfig {
    if (builtin.mode == .Debug) {
        return std.heap.DebugAllocatorConfig{
            .safety = true,
            .never_unmap = true,
            .retain_metadata = true,
            .verbose_log = false,
        };
    } else {
        return std.heap.DebugAllocatorConfig{
            .safety = false,
            .never_unmap = false,
            .retain_metadata = false,
            .verbose_log = false,
        };
    }
}
