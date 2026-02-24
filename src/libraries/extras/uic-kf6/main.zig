const std = @import("std");
const qt6 = @import("libqt6zig");
const ui = @import("design.zig");
const qapplication = qt6.qapplication;
const qmainwindow = qt6.qmainwindow;

var gpa = @import("alloc_config").gpa;
const allocator = gpa.allocator();

pub fn main() !void {
    const argc = std.os.argv.len;
    const argv = std.os.argv.ptr;
    const qapp = qapplication.New(argc, argv);
    defer qapplication.Delete(qapp);

    defer _ = gpa.deinit();

    const uic = try ui.NewMainWindowUi(allocator);
    defer allocator.destroy(uic);

    qmainwindow.Show(uic.MainWindow);

    _ = qapplication.Exec();
}
