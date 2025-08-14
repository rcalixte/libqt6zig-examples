const std = @import("std");
const qt6 = @import("libqt6zig");
const ui = @import("design.zig");
const qapplication = qt6.qapplication;
const qmainwindow = qt6.qmainwindow;

const getAllocatorConfig = @import("alloc_config").getAllocatorConfig;
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
