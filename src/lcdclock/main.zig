const std = @import("std");
const builtin = @import("builtin");
const qt6 = @import("libqt6zig");
const qapplication = qt6.qapplication;
const qwidget = qt6.qwidget;
const qhboxlayout = qt6.qhboxlayout;
const qlcdnumber = qt6.qlcdnumber;
const qfont = qt6.qfont;
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
    const font = qfont.New6("DejaVu Sans", 14);
    defer qfont.QDelete(font);

    qlcdnumber.SetFont(lcd, font);
    qlcdnumber.SetStyleSheet(lcd, "background-color: #ec915c; color: white;");

    show_time(lcd, time);

    qhboxlayout.AddWidget(hbox, lcd);

    const timer = qtimer.New2(widget);
    qtimer.Start(timer, 1000);
    qtimer.OnTimerEvent(timer, show_time);

    qwidget.Show(widget);

    _ = qapplication.Exec();
}

fn show_time(_: ?*anyopaque, _: ?*anyopaque) callconv(.c) void {
    time = qtime.CurrentTime();
    defer qtime.QDelete(time);

    const text = qtime.ToStringWithFormat(time, "hh:mm", allocator);
    defer allocator.free(text);

    var lcd_text = allocator.alloc(u8, text.len) catch @panic("Failed to allocate lcd_text");
    defer allocator.free(lcd_text);

    @memcpy(lcd_text, text);

    if (@mod(qtime.Second(time), 2) == 0) {
        lcd_text[2] = ' ';
    }

    qlcdnumber.Display(lcd, lcd_text);
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
