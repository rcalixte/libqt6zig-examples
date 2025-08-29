const std = @import("std");
const qt6 = @import("libqt6zig");
const rcc = @import("rcc.zig");
const qapplication = qt6.qapplication;
const qwidget = qt6.qwidget;
const qhboxlayout = qt6.qhboxlayout;
const qradiobutton = qt6.qradiobutton;
const qicon = qt6.qicon;
const qsize = qt6.qsize;

var buffer: [64]u8 = undefined;
var stdout_writer = std.fs.File.stdout().writer(&buffer);

pub fn main() !void {
    // Initialize Qt application
    const argc = std.os.argv.len;
    const argv = std.os.argv.ptr;
    _ = qapplication.New(argc, argv);

    var ok = rcc.init();
    if (!ok) {
        try stdout_writer.interface.writeAll("Resource initialization failed!\n");
        try stdout_writer.interface.flush();
    }
    defer {
        ok = rcc.deinit();
        if (!ok) {
            stdout_writer.interface.writeAll("Resource deinitialization failed!\n") catch @panic("Failed to stdout deinit\n");
            stdout_writer.interface.flush() catch @panic("Failed to flush stdout writer");
        }
    }

    const widget = qwidget.New2();
    defer qwidget.QDelete(widget);

    qwidget.SetMinimumSize2(widget, 650, 150);

    const hbox = qhboxlayout.New(widget);

    const radio1 = qradiobutton.New(widget);
    qradiobutton.SetToolTip(radio1, "Qt");
    const icon1 = qicon.New4(":/images/qt.png");
    defer qicon.QDelete(icon1);
    qradiobutton.SetIcon(radio1, icon1);
    const size1 = qsize.New4(50, 50);
    defer qsize.QDelete(size1);
    qradiobutton.SetIconSize(radio1, size1);

    const radio2 = qradiobutton.New(widget);
    qradiobutton.SetToolTip(radio2, "Zig");
    const icon2 = qicon.New4(":/images/zig.png");
    defer qicon.QDelete(icon2);
    qradiobutton.SetIcon(radio2, icon2);
    const size2 = qsize.New4(50, 50);
    defer qsize.QDelete(size2);
    qradiobutton.SetIconSize(radio2, size2);

    const radio3 = qradiobutton.New(widget);
    qradiobutton.SetToolTip(radio3, "libqt6zig");
    const icon3 = qicon.New4(":/images/libqt6zig.png");
    defer qicon.QDelete(icon3);
    qradiobutton.SetIcon(radio3, icon3);
    const size3 = qsize.New4(120, 40);
    defer qsize.QDelete(size3);
    qradiobutton.SetIconSize(radio3, size3);

    qhboxlayout.AddStretch(hbox);
    qhboxlayout.AddWidget(hbox, radio1);
    qhboxlayout.AddStretch(hbox);
    qhboxlayout.AddWidget(hbox, radio2);
    qhboxlayout.AddStretch(hbox);
    qhboxlayout.AddWidget(hbox, radio3);
    qhboxlayout.AddStretch(hbox);

    qwidget.Show(widget);

    _ = qapplication.Exec();
}
