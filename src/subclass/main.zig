const std = @import("std");
const qt6 = @import("libqt6zig");
const qguiapplication = qt6.qguiapplication;
const qapplication = qt6.qapplication;
const qgroupbox = qt6.qgroupbox;
const qnamespace_enums = qt6.qnamespace_enums;
const qkeyevent = qt6.qkeyevent;
const qpainter = qt6.qpainter;
const qbrush = qt6.qbrush;
const qframe = qt6.qframe;

var currentColor: usize = 0;

const useColors = [_]i32{
    qnamespace_enums.GlobalColor.Black,
    qnamespace_enums.GlobalColor.Red,
    qnamespace_enums.GlobalColor.Green,
    qnamespace_enums.GlobalColor.Blue,
};

pub fn main() void {
    const argc = std.os.argv.len;
    const argv = std.os.argv.ptr;
    _ = qapplication.New(argc, argv);
    qapplication.SetApplicationDisplayName("Right-click to change the color");

    const groupbox = qgroupbox.New2();
    defer qgroupbox.QDelete(groupbox);

    qgroupbox.SetTitle(groupbox, "QGroupBox title");
    qgroupbox.SetFixedWidth(groupbox, 320);
    qgroupbox.SetFixedHeight(groupbox, 240);
    qgroupbox.SetMinimumHeight(groupbox, 100);
    qgroupbox.SetMinimumWidth(groupbox, 100);

    qgroupbox.SetAttribute2(groupbox, qnamespace_enums.WidgetAttribute.WA_PaintOnScreen, true);
    qgroupbox.SetAttribute2(groupbox, qnamespace_enums.WidgetAttribute.WA_NoSystemBackground, true);

    qgroupbox.OnPaintEvent(groupbox, onPaintEvent);
    qgroupbox.OnContextMenuEvent(groupbox, onContextMenuEvent);
    qgroupbox.OnKeyPressEvent(groupbox, onKeyPressEvent);

    qgroupbox.Show(groupbox);

    _ = qapplication.Exec();
}

fn onPaintEvent(self: ?*anyopaque, ev: ?*anyopaque) callconv(.c) void {
    // Call the base class's PaintEvent to get initial content
    // (Comment this out to see the QGroupBox disappear)
    qgroupbox.QBasePaintEvent(self, ev);

    // Then, draw on top of it
    const painter = qpainter.New2(self);
    defer qpainter.QDelete(painter);

    const brush = qbrush.New12(useColors[currentColor], qnamespace_enums.BrushStyle.SolidPattern);
    defer qbrush.QDelete(brush);

    qpainter.SetBrush(painter, brush);
    qpainter.DrawRect2(painter, 80, 60, 160, 120);
}

fn onContextMenuEvent(self: ?*anyopaque, ev: ?*anyopaque) callconv(.c) void {
    qgroupbox.QBaseContextMenuEvent(self, ev);

    currentColor += 1;
    if (currentColor >= useColors.len) {
        currentColor = 0;
    }
    qgroupbox.Update(self);
}

fn onKeyPressEvent(self: ?*anyopaque, ev: ?*anyopaque) callconv(.c) void {
    qgroupbox.QBaseKeyPressEvent(self, ev);

    var buffer: [32]u8 = undefined;
    const text = "Keypress {d}";
    const title = std.fmt.bufPrintZ(&buffer, text, .{qkeyevent.Key(ev)}) catch @panic("Buffer full");
    qgroupbox.SetTitle(self, title);
}
