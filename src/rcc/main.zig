const std = @import("std");
const qt6 = @import("libqt6zig");
const rcc = @import("rcc.zig");
const qapplication = qt6.qapplication;
const qwidget = qt6.qwidget;
const qhboxlayout = qt6.qhboxlayout;
const qradiobutton = qt6.qradiobutton;
const qicon = qt6.qicon;
const qsize = qt6.qsize;

pub fn main(init: std.process.Init) !void {
    const argv = try qt6.init(init.gpa, init.minimal.args);
    defer qt6.deinit(init.gpa, argv);
    var argc: i32 = @intCast(argv.len);
    const qapp = qapplication.New(&argc, argv, init.arena.allocator());
    defer qapplication.Delete(qapp);

    var ok = rcc.init();
    if (!ok)
        try std.Io.File.stdout().writeStreamingAll(init.io, "Resource initialization failed!\n");
    defer {
        ok = rcc.deinit();
        if (!ok)
            std.Io.File.stdout().writeStreamingAll(
                init.io,
                "Resource deinitialization failed!\n",
            ) catch @panic("Failed to stdout deinit\n");
    }

    const widget = qwidget.New2();
    defer qwidget.Delete(widget);

    qwidget.SetMinimumSize2(widget, 650, 150);

    const hbox = qhboxlayout.New(widget);

    const radio1 = qradiobutton.New2();
    qradiobutton.SetToolTip(radio1, "Qt");
    const icon1 = qicon.New4(":/images/qt.png");
    defer qicon.Delete(icon1);
    qradiobutton.SetIcon(radio1, icon1);
    const size1 = qsize.New4(50, 50);
    defer qsize.Delete(size1);
    qradiobutton.SetIconSize(radio1, size1);

    const radio2 = qradiobutton.New2();
    qradiobutton.SetToolTip(radio2, "Zig");
    const icon2 = qicon.New4(":/images/zig.png");
    defer qicon.Delete(icon2);
    qradiobutton.SetIcon(radio2, icon2);
    const size2 = qsize.New4(50, 50);
    defer qsize.Delete(size2);
    qradiobutton.SetIconSize(radio2, size2);

    const radio3 = qradiobutton.New2();
    qradiobutton.SetToolTip(radio3, "libqt6zig");
    const icon3 = qicon.New4(":/images/libqt6zig.png");
    defer qicon.Delete(icon3);
    qradiobutton.SetIcon(radio3, icon3);
    const size3 = qsize.New4(120, 40);
    defer qsize.Delete(size3);
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
