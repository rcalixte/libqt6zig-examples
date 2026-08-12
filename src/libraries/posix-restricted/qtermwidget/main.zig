const std = @import("std");
const qt6 = @import("libqt6zig");
const QApplication = qt6.QApplication;
const QTermWidget = qt6.QTermWidget;

pub fn main(init: std.process.Init) !void {
    const argv = try qt6.init(init.gpa, init.minimal.args);
    defer qt6.deinit(init.gpa, argv);
    var argc: i32 = @intCast(argv.len);
    const qapp: QApplication = .new(init.arena.allocator(), &argc, argv);
    defer qapp.delete();

    const term = QTermWidget.new3();
    defer term.delete();

    term.setWindowTitle("Qt 6 QTermWidget Example");
    term.setMinimumSize2(640, 480);
    term.setColorScheme("WhiteOnBlack");
    term.onFinished(onFinished);

    term.show();

    _ = QApplication.exec();
}

fn onFinished(self: QTermWidget) callconv(.c) void {
    _ = self.close();
}
