const std = @import("std");
const qt6 = @import("libqt6zig");
const qapplication = qt6.qapplication;
const qsciscintilla = qt6.qsciscintilla;

pub fn main() void {
    const argc = std.os.argv.len;
    const argv = std.os.argv.ptr;
    _ = qapplication.New(argc, argv);

    const area = qsciscintilla.New2();
    defer qsciscintilla.QDelete(area);

    qsciscintilla.SetFixedSize2(area, 640, 480);
    qsciscintilla.Show(area);

    _ = qapplication.Exec();
}
