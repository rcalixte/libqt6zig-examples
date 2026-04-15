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
var buffer: [64]u8 = undefined;

pub fn main(init: std.process.Init) !void {
    const argv = try qt6.init(init.gpa, init.minimal.args);
    defer qt6.deinit(init.gpa, argv);
    var argc: i32 = @intCast(argv.len);
    const qapp = qapplication.New(&argc, argv, init.arena.allocator());
    defer qapplication.Delete(qapp);

    const pixmap = qpixmap.New4("assets/libqt6zig-examples.png");
    defer qpixmap.Delete(pixmap);

    const splash = qsplashscreen.New4(pixmap, qnamespace_enums.WindowType.WindowStaysOnTopHint);
    defer qsplashscreen.Delete(splash);

    qsplashscreen.OnMousePressEvent(splash, onMousePressEvent);

    const widget = qwidget.New2();
    defer qwidget.Delete(widget);

    qwidget.SetWindowTitle(widget, "Hello world");

    const button = qpushbutton.New5("Hello world!", widget);
    qpushbutton.SetFixedWidth(button, 320);
    qpushbutton.OnClicked(button, onClicked);

    qsplashscreen.Show(splash);

    const timer = qtimer.New();
    defer qtimer.Delete(timer);

    const splash_qv = qvariant.New7(@intFromPtr(splash));
    _ = qtimer.SetProperty(timer, "splash", splash_qv);

    const widget_qv = qvariant.New7(@intFromPtr(widget));
    _ = qtimer.SetProperty(timer, "widget", widget_qv);

    qtimer.Start(timer, 3000);
    qtimer.OnTimeout(timer, onTimeout);

    _ = qapplication.Exec();

    std.debug.print("OK!\n", .{});
}

fn onClicked(self: ?*anyopaque) callconv(.c) void {
    counter += 1;
    const formatted = std.fmt.bufPrint(
        &buffer,
        "You have clicked the button {d} time(s)",
        .{counter},
    ) catch @panic("Failed to bufPrint");
    qpushbutton.SetText(self, formatted);
}

fn onMousePressEvent(_: ?*anyopaque, _: ?*anyopaque) callconv(.c) void {}

fn onTimeout(self: ?*anyopaque) callconv(.c) void {
    const splash_qv = qtimer.Property(self, "splash");
    const splash_i = qvariant.ToLongLong(splash_qv);

    const widget_qv = qtimer.Property(self, "widget");
    const widget_i = qvariant.ToLongLong(widget_qv);

    _ = qsplashscreen.Close(@ptrFromInt(@as(usize, @intCast(splash_i))));
    qwidget.Show(@ptrFromInt(@as(usize, @intCast(widget_i))));
    qtimer.Stop(self);
}
