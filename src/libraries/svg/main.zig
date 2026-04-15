const std = @import("std");
const qt6 = @import("libqt6zig");
const qapplication = qt6.qapplication;
const qsvgwidget = qt6.qsvgwidget;

pub fn main(init: std.process.Init) !void {
    const argv = try qt6.init(init.gpa, init.minimal.args);
    defer qt6.deinit(init.gpa, argv);
    var argc: i32 = @intCast(argv.len);
    const qapp = qapplication.New(&argc, argv, init.arena.allocator());
    defer qapplication.Delete(qapp);

    const svg = qsvgwidget.New3("assets/libqt6zig-examples.svg");
    defer qsvgwidget.Delete(svg);

    qsvgwidget.Show(svg);

    _ = qapplication.Exec();
}
