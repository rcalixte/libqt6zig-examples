const std = @import("std");
const qt6 = @import("libqt6zig");
const qapplication = qt6.qapplication;
const qtermwidget = qt6.qtermwidget;

pub fn main() void {
    const argc = std.os.argv.len;
    const argv = std.os.argv.ptr;
    _ = qapplication.New(argc, argv);

    const term = qtermwidget.New3();
    defer qtermwidget.QDelete(term);

    qtermwidget.SetWindowTitle(term, "Qt 6 QTermWidget Example");
    qtermwidget.SetMinimumSize2(term, 640, 480);
    qtermwidget.SetColorScheme(term, "WhiteOnBlack");
    qtermwidget.OnFinished(term, on_finished);

    qtermwidget.Show(term);

    _ = qapplication.Exec();
}

fn on_finished(_: ?*anyopaque) callconv(.c) void {
    qapplication.Quit();
}
