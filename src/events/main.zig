const std = @import("std");
const qt6 = @import("libqt6zig");
const qapplication = qt6.qapplication;
const qkeyevent = qt6.qkeyevent;
const qlabel = qt6.qlabel;
const qmouseevent = qt6.qmouseevent;
const qnamespace_enums = qt6.qnamespace_enums;
const qwidget = qt6.qwidget;
const qwheelevent = qt6.qwheelevent;
const qvboxlayout = qt6.qvboxlayout;

pub fn main() void {
    const argc = std.os.argv.len;
    const argv = std.os.argv.ptr;
    _ = qapplication.New(argc, argv);

    const widget = qwidget.New2();
    defer qwidget.QDelete(widget);

    qwidget.SetFixedWidth(widget, 400);
    qwidget.SetFixedHeight(widget, 100);

    const label = qlabel.New5("Press any key or click the mouse here!", widget);

    qlabel.SetFocusPolicy(label, qnamespace_enums.FocusPolicy.StrongFocus);
    qlabel.OnKeyPressEvent(label, keyPressEvent);
    qlabel.OnMousePressEvent(label, mousePressEvent);

    qwidget.Show(widget);

    _ = qapplication.Exec();
}

fn mousePressEvent(self: ?*anyopaque, event: ?*anyopaque) callconv(.c) void {
    const mouse = qmouseevent.Button(event);
    var buffer: [64]u8 = undefined;
    switch (mouse) {
        qnamespace_enums.MouseButton.LeftButton => {
            const text = "Left mouse button pressed!";
            const formatted = std.fmt.bufPrintZ(&buffer, text, .{}) catch @panic("Buffer full");
            qlabel.SetText(self, formatted);
        },
        qnamespace_enums.MouseButton.RightButton => {
            const text = "Right mouse button pressed!";
            const formatted = std.fmt.bufPrintZ(&buffer, text, .{}) catch @panic("Buffer full");
            qlabel.SetText(self, formatted);
        },
        else => {
            const text = "Mouse button keycode: {}";
            const formatted = std.fmt.bufPrintZ(&buffer, text, .{mouse}) catch @panic("Buffer full");
            qlabel.SetText(self, formatted);
        },
    }
}

fn keyPressEvent(self: ?*anyopaque, event: ?*anyopaque) callconv(.c) void {
    const key = qkeyevent.Key(event);
    var buffer: [64]u8 = undefined;
    const text = "You pressed key code: {}";
    const formatted = std.fmt.bufPrintZ(&buffer, text, .{key}) catch @panic("Buffer full");
    qlabel.SetText(self, formatted);
}
