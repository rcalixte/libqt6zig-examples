const std = @import("std");
const qt6 = @import("libqt6zig");
const qapplication = qt6.qapplication;
const qsvgwidget = qt6.qsvgwidget;

pub fn main() void {
    const argc = std.os.argv.len;
    const argv = std.os.argv.ptr;
    const qapp = qapplication.New(argc, argv);
    defer qapplication.QDelete(qapp);

    const svg = qsvgwidget.New3("assets/libqt6zig-examples.svg");
    defer qsvgwidget.QDelete(svg);

    qsvgwidget.Show(svg);

    _ = qapplication.Exec();
}
