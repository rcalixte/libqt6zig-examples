const std = @import("std");
const qt6 = @import("libqt6zig");
const qapplication = qt6.qapplication;
const qwidget = qt6.qwidget;
const qhboxlayout = qt6.qhboxlayout;
const qlcdnumber = qt6.qlcdnumber;
const qtime = qt6.qtime;
const qtimer = qt6.qtimer;

const getAllocatorConfig = @import("alloc_config").getAllocatorConfig;
const config = getAllocatorConfig();
var gda: std.heap.DebugAllocator(config) = .init;
const allocator = gda.allocator();

var lcd: ?*anyopaque = undefined;
var time: ?*anyopaque = undefined;

pub fn main() void {
    // Initialize Qt application
    const argc = std.os.argv.len;
    const argv = std.os.argv.ptr;
    _ = qapplication.New(argc, argv);

    const widget = qwidget.New2();
    defer qwidget.QDelete(widget);

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
    defer qtime.QDelete(time);

    const lcd_format = if (@mod(qtime.Second(time), 2) == 0) "hh:mm" else "hh mm";

    const text = qtime.ToString2(time, lcd_format, allocator);
    defer allocator.free(text);

    qlcdnumber.Display(lcd, text);
}
