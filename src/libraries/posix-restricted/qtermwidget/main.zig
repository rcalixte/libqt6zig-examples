const std = @import("std");
const qt6 = @import("libqt6zig");
const QApplication = qt6.QApplication;
const QTermWidget = qt6.QTermWidget;

pub fn main(init: std.process.Init) !void {
    const argv = try qt6.init(init.gpa, init.minimal.args);
    defer qt6.deinit(init.gpa, argv);
    var argc: i32 = @intCast(argv.len);
    const qapp = QApplication.New(init.arena.allocator(), &argc, argv);
    defer qapp.Delete();

    const term = QTermWidget.New3();
    defer term.Delete();

    term.SetWindowTitle("Qt 6 QTermWidget Example");
    term.SetMinimumSize2(640, 480);
    term.SetColorScheme("WhiteOnBlack");
    term.OnFinished(on_finished);

    term.Show();

    _ = QApplication.Exec();
}

fn on_finished(_: QTermWidget) callconv(.c) void {
    QApplication.Quit();
}
