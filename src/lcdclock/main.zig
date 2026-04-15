const std = @import("std");
const qt6 = @import("libqt6zig");
const C = qt6.C;
const qapplication = qt6.qapplication;
const qwidget = qt6.qwidget;
const qhboxlayout = qt6.qhboxlayout;
const qlcdnumber = qt6.qlcdnumber;
const qtime = qt6.qtime;
const qtimer = qt6.qtimer;

var allocator: std.mem.Allocator = undefined;

var lcd: C.QLCDNumber = null;
var time: C.QTime = null;

pub fn main(init: std.process.Init) !void {
    const argv = try qt6.init(init.gpa, init.minimal.args);
    defer qt6.deinit(init.gpa, argv);
    var argc: i32 = @intCast(argv.len);
    const qapp = qapplication.New(&argc, argv, init.arena.allocator());
    defer qapplication.Delete(qapp);

    allocator = init.gpa;

    const widget = qwidget.New2();
    defer qwidget.Delete(widget);

    qwidget.SetWindowTitle(widget, "Qt 6 LCD Clock Example");
    qwidget.Resize(widget, 360, 240);

    const hbox = qhboxlayout.New(widget);
    lcd = qlcdnumber.New(widget);

    qlcdnumber.SetStyleSheet(lcd, "background-color: #ec915c; color: white;");

    show_time(null);

    qhboxlayout.AddWidget(hbox, lcd);

    const timer = qtimer.New2(widget);
    qtimer.Start(timer, 1000);
    qtimer.OnTimeout(timer, show_time);

    qwidget.Show(widget);

    _ = qapplication.Exec();
}

fn show_time(_: ?*anyopaque) callconv(.c) void {
    time = qtime.CurrentTime();
    defer qtime.Delete(time);

    const lcd_format = if (@mod(qtime.Second(time), 2) == 0) "hh:mm" else "hh mm";

    const text = qtime.ToString2(time, lcd_format, allocator);
    defer allocator.free(text);

    qlcdnumber.Display(lcd, text);
}
