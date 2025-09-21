const std = @import("std");
const qt6 = @import("libqt6zig");
const qapplication = qt6.qapplication;
const qwidget = qt6.qwidget;
const knswidgets__button = qt6.knswidgets__button;
const qvboxlayout = qt6.qvboxlayout;

pub fn main() void {
    const argc = std.os.argv.len;
    const argv = std.os.argv.ptr;
    const qapp = qapplication.New(argc, argv);
    defer qapplication.QDelete(qapp);

    const widget = qwidget.New2();
    defer qwidget.QDelete(widget);

    qwidget.SetWindowTitle(widget, "Qt 6 KNewStuff Example");
    qwidget.SetMinimumSize2(widget, 300, 100);

    const button = knswidgets__button.New(widget);
    knswidgets__button.SetText(button, "Click me!");
    knswidgets__button.SetMinimumWidth(button, 100);

    const layout = qvboxlayout.New2();
    qvboxlayout.AddWidget(layout, button);
    qwidget.SetLayout(widget, layout);

    qwidget.Show(widget);

    _ = qapplication.Exec();
}
