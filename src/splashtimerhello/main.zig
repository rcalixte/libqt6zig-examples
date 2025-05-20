const std = @import("std");
const qt6 = @import("libqt6zig");
const qapplication = qt6.qapplication;
const qpushbutton = qt6.qpushbutton;
const qwidget = qt6.qwidget;
const qpixmap = qt6.qpixmap;
const qsplashscreen = qt6.qsplashscreen;
const qnamespace_enums = qt6.qnamespace_enums;
const qtimer = qt6.qtimer;
const qvariant = qt6.qvariant;

var counter: usize = 0;

pub fn main() void {
    // Initialize Qt application
    const argc = std.os.argv.len;
    const argv = std.os.argv.ptr;
    _ = qapplication.New(argc, argv);

    const pixmap = qpixmap.New4("assets/libqt6zig-examples.png");
    defer qpixmap.QDelete(pixmap);

    const splash = qsplashscreen.New4(pixmap, qnamespace_enums.WindowType.WindowStaysOnTopHint);
    defer qsplashscreen.QDelete(splash);

    qsplashscreen.OnMousePressEvent(splash, onMousePressEvent);

    const text = "Hello world!";
    const widget = qwidget.New2();
    if (widget == null) @panic("Failed to create widget");
    defer qwidget.QDelete(widget);

    qwidget.SetWindowTitle(widget, "Hello world");

    // We don't need to free the button, it's a child of the widget
    const button = qpushbutton.New5(text, widget);
    qpushbutton.SetFixedWidth(button, 320);

    qpushbutton.OnClicked(button, button_callback);

    qsplashscreen.Show(splash);

    const timer = qtimer.New();
    defer qtimer.QDelete(timer);

    const splash_qv = qvariant.New7(@intFromPtr(splash));
    _ = qtimer.SetProperty(timer, "splash", splash_qv);

    const widget_qv = qvariant.New7(@intFromPtr(widget));
    _ = qtimer.SetProperty(timer, "widget", widget_qv);

    qtimer.Start(timer, 3000);
    qtimer.OnTimerEvent(timer, onTimerEvent);

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

fn onMousePressEvent(_: ?*anyopaque, _: ?*anyopaque) callconv(.c) void {}

fn onTimerEvent(self: ?*anyopaque, _: ?*anyopaque) callconv(.c) void {
    const splash_qv = qtimer.Property(self, "splash");
    const splash_i = qvariant.ToLongLong(splash_qv);

    const widget_qv = qtimer.Property(self, "widget");
    const widget_i = qvariant.ToLongLong(widget_qv);

    _ = qsplashscreen.Close(@ptrFromInt(@as(usize, @intCast(splash_i))));
    qwidget.Show(@ptrFromInt(@as(usize, @intCast(widget_i))));
    qtimer.Stop(self);
}
