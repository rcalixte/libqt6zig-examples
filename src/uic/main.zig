const std = @import("std");
const qt6 = @import("libqt6zig");
const ui = @import("design.zig");
const qapplication = qt6.qapplication;
const qmainwindow = qt6.qmainwindow;

pub fn main(init: std.process.Init) !void {
    const argv = try qt6.init(init.gpa, init.minimal.args);
    defer qt6.deinit(init.gpa, argv);
    var argc: i32 = @intCast(argv.len);
    const qapp = qapplication.New(&argc, argv, init.arena.allocator());

    defer qapplication.Delete(qapp);

    const uic = try ui.create(init.gpa);
    defer uic.destroy(init.gpa);

    qmainwindow.Show(uic.MainWindow);

    _ = qapplication.Exec();
}
