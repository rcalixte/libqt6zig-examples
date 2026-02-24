const std = @import("std");
const qt6 = @import("libqt6zig");
const C = qt6.C;
const qapplication = qt6.qapplication;
const qwidget = qt6.qwidget;
const qlabel = qt6.qlabel;
const qvboxlayout = qt6.qvboxlayout;
const qnamespace_enums = qt6.qnamespace_enums;
const qmouseevent = qt6.qmouseevent;
const qkeyevent = qt6.qkeyevent;

var label: C.QLabel = null;
var buffer: [64]u8 = undefined;

pub fn main() void {
    const argc = std.os.argv.len;
    const argv = std.os.argv.ptr;
    const qapp = qapplication.New(argc, argv);
    defer qapplication.Delete(qapp);

    const widget = qwidget.New2();
    defer qwidget.Delete(widget);

    qwidget.SetFixedWidth(widget, 400);
    qwidget.SetFixedHeight(widget, 100);
    qwidget.OnMousePressEvent(widget, mousePressEvent);
    qwidget.OnKeyPressEvent(widget, keyPressEvent);

    label = qlabel.New3("### Press any key or click the mouse here!");

    qlabel.SetFocusPolicy(label, qnamespace_enums.FocusPolicy.StrongFocus);
    qlabel.SetTextFormat(label, qnamespace_enums.TextFormat.MarkdownText);
    qlabel.SetAlignment(label, qnamespace_enums.AlignmentFlag.AlignCenter);
    qlabel.OnMousePressEvent(label, mousePressEvent);
    qlabel.OnKeyPressEvent(label, keyPressEvent);

    const layout = qvboxlayout.New2();

    qvboxlayout.AddStretch(layout);
    qvboxlayout.AddWidget(layout, label);
    qvboxlayout.AddStretch(layout);
    qwidget.SetLayout(widget, layout);

    qwidget.Show(widget);

    _ = qapplication.Exec();
}

fn mousePressEvent(_: ?*anyopaque, event: ?*anyopaque) callconv(.c) void {
    const mouse = qmouseevent.Button(event);
    switch (mouse) {
        qnamespace_enums.MouseButton.LeftButton => {
            const text = "## Left mouse button pressed!";
            const formatted = std.fmt.bufPrintZ(&buffer, text, .{}) catch @panic("Buffer full");
            qlabel.SetText(label, formatted);
        },
        qnamespace_enums.MouseButton.RightButton => {
            const text = "## Right mouse button pressed!";
            const formatted = std.fmt.bufPrintZ(&buffer, text, .{}) catch @panic("Buffer full");
            qlabel.SetText(label, formatted);
        },
        else => {
            const text = "## Mouse button keycode: {d}";
            const formatted = std.fmt.bufPrintZ(&buffer, text, .{mouse}) catch @panic("Buffer full");
            qlabel.SetText(label, formatted);
        },
    }
}

fn keyPressEvent(_: ?*anyopaque, event: ?*anyopaque) callconv(.c) void {
    const key = qkeyevent.Key(event);
    const text = "## You pressed key code: {d}";
    const formatted = std.fmt.bufPrintZ(&buffer, text, .{key}) catch @panic("Buffer full");
    qlabel.SetText(label, formatted);
}
