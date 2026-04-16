const std = @import("std");
const qt6 = @import("libqt6zig");
const ui = @import("design.zig");
const QApplication = qt6.QApplication;

pub fn main(init: std.process.Init) !void {
    const argv = try qt6.init(init.gpa, init.minimal.args);
    defer qt6.deinit(init.gpa, argv);
    var argc: i32 = @intCast(argv.len);
    const qapp = QApplication.New(init.arena.allocator(), &argc, argv);
    defer qapp.Delete();

    const uic = try ui.create(init.gpa);
    defer uic.destroy(init.gpa);

    uic.MainWindow.Show();

    _ = QApplication.Exec();
}
