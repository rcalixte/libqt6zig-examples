const std = @import("std");
const qt6 = @import("libqt6zig");
const qapplication = qt6.qapplication;
const qsciscintilla = qt6.qsciscintilla;

pub fn main(init: std.process.Init) !void {
    const argv = try qt6.init(init.gpa, init.minimal.args);
    defer qt6.deinit(init.gpa, argv);
    var argc: i32 = @intCast(argv.len);
    const qapp = qapplication.New(&argc, argv, init.arena.allocator());
    defer qapplication.Delete(qapp);

    const area = qsciscintilla.New2();
    defer qsciscintilla.Delete(area);

    qsciscintilla.SetFixedSize2(area, 640, 480);
    qsciscintilla.Show(area);

    _ = qapplication.Exec();
}
