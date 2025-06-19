const std = @import("std");
const builtin = @import("builtin");
const qt6 = @import("libqt6zig");
const qapplication = qt6.qapplication;
const qwidget = qt6.qwidget;
const qhboxlayout = qt6.qhboxlayout;
const qlcdnumber = qt6.qlcdnumber;
const qtime = qt6.qtime;
const qtimer = qt6.qtimer;

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

    const text = qtime.ToStringWithFormat(time, lcd_format, allocator);
    defer allocator.free(text);

    qlcdnumber.Display(lcd, text);
}

pub fn getAllocatorConfig() std.heap.DebugAllocatorConfig {
    if (builtin.mode == .Debug) {
        return std.heap.DebugAllocatorConfig{
            .safety = true,
            .never_unmap = true,
            .retain_metadata = true,
            .verbose_log = false,
        };
    } else {
        return std.heap.DebugAllocatorConfig{
            .safety = false,
            .never_unmap = false,
            .retain_metadata = false,
            .verbose_log = false,
        };
    }
}
