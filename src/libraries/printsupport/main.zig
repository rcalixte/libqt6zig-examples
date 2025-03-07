const std = @import("std");
const qt6 = @import("libqt6zig");
const qapplication = qt6.qapplication;
const qpushbutton = qt6.qpushbutton;
const qprintdialog = qt6.qprintdialog;

pub fn main() void {
    const argc = std.os.argv.len;
    const argv = std.os.argv.ptr;
    _ = qapplication.New(argc, argv);

    const button = qpushbutton.New3("QPrintSupport sample");
    defer qpushbutton.QDelete(button);

    qpushbutton.SetFixedWidth(button, 320);
    qpushbutton.OnPressed(button, onPressed);

    qpushbutton.Show(button);

    _ = qapplication.Exec();
}

fn onPressed(_: ?*anyopaque) callconv(.c) void {
    const dialog = qprintdialog.New3();
    // cleaned up in onFinished

    qprintdialog.OnFinished(dialog, onFinished);
    qprintdialog.Show(dialog);
}

fn onFinished(self: ?*anyopaque, _: i32) callconv(.c) void {
    qprintdialog.DeleteLater(self);
}
