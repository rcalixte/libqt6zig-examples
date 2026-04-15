const std = @import("std");
const qt6 = @import("libqt6zig");
const qapplication = qt6.qapplication;
const qtermwidget = qt6.qtermwidget;

pub fn main(init: std.process.Init) !void {
    const argv = try qt6.init(init.gpa, init.minimal.args);
    defer qt6.deinit(init.gpa, argv);
    var argc: i32 = @intCast(argv.len);
    const qapp = qapplication.New(&argc, argv, init.arena.allocator());
    defer qapplication.Delete(qapp);

    const term = qtermwidget.New3();
    defer qtermwidget.Delete(term);

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
