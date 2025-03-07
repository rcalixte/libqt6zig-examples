const std = @import("std");
const qt6 = @import("libqt6zig");
const qapplication = qt6.qapplication;
const qpushbutton = qt6.qpushbutton;
const qwidget = qt6.qwidget;

var counter: isize = 0;

pub fn main() void {
    // Initialize Qt application
    const argc = std.os.argv.len;
    const argv = std.os.argv.ptr;
    _ = qapplication.New(argc, argv);

    const text = "Hello world!";
    const widget = qwidget.New2();
    if (widget == null) @panic("Failed to create widget");
    defer qwidget.QDelete(widget);

    // We don't need to free the button, it's a child of the widget
    const button = qpushbutton.New5(text, widget);
    qpushbutton.SetFixedWidth(button, 320);

    qpushbutton.OnClicked(button, button_callback);

    qwidget.Show(widget);

    _ = qapplication.Exec();

    std.debug.print("OK!\n", .{});
}

fn button_callback(self: ?*anyopaque) callconv(.c) void {
    counter += 1;
    var buffer: [64]u8 = undefined;
    const text = "You have clicked the button {} time(s)";
    const formatted = std.fmt.bufPrintZ(&buffer, text, .{counter}) catch @panic("Failed to bufPrintZ");
    qpushbutton.SetText(self, formatted);
}
