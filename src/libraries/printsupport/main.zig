const std = @import("std");
const qt6 = @import("libqt6zig");
const qapplication = qt6.qapplication;
const qpushbutton = qt6.qpushbutton;
const qprintdialog = qt6.qprintdialog;

pub fn main(init: std.process.Init) !void {
    const argv = try qt6.init(init.gpa, init.minimal.args);
    defer qt6.deinit(init.gpa, argv);
    var argc: i32 = @intCast(argv.len);
    const qapp = qapplication.New(&argc, argv, init.arena.allocator());
    defer qapplication.Delete(qapp);

    const button = qpushbutton.New3("QPrintSupport sample");
    defer qpushbutton.Delete(button);

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
