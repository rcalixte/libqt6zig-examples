const std = @import("std");
const qt6 = @import("libqt6zig");
const QApplication = qt6.QApplication;
const QSvgWidget = qt6.QSvgWidget;

pub fn main(init: std.process.Init) !void {
    const argv = try qt6.init(init.gpa, init.minimal.args);
    defer qt6.deinit(init.gpa, argv);
    var argc: i32 = @intCast(argv.len);
    const qapp = QApplication.New(init.arena.allocator(), &argc, argv);
    defer qapp.Delete();

    const svg = QSvgWidget.New3("assets/libqt6zig-examples.svg");
    defer svg.Delete();

    svg.Show();

    _ = QApplication.Exec();
}
