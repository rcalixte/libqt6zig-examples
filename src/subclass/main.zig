const std = @import("std");
const qt6 = @import("libqt6zig");
const qapplication = qt6.qapplication;
const qnamespace_enums = qt6.qnamespace_enums;
const qgroupbox = qt6.qgroupbox;
const qstylepainter = qt6.qstylepainter;
const qbrush = qt6.qbrush;
const qkeyevent = qt6.qkeyevent;

var buffer: [32]u8 = undefined;
var currentColor: u2 = 0;

const useColors = [_]i32{
    qnamespace_enums.GlobalColor.Black,
    qnamespace_enums.GlobalColor.Red,
    qnamespace_enums.GlobalColor.Green,
    qnamespace_enums.GlobalColor.Blue,
};

pub fn main() void {
    const argc = std.os.argv.len;
    const argv = std.os.argv.ptr;
    const qapp = qapplication.New(argc, argv);
    defer qapplication.Delete(qapp);

    qapplication.SetApplicationDisplayName("Right-click to change the color");

    const groupbox = qgroupbox.New2();
    defer qgroupbox.Delete(groupbox);

    qgroupbox.SetTitle(groupbox, "QGroupBox title");
    qgroupbox.SetFixedSize2(groupbox, 320, 240);
    qgroupbox.SetMinimumSize2(groupbox, 100, 100);
    qgroupbox.OnPaintEvent(groupbox, onPaintEvent);
    qgroupbox.OnContextMenuEvent(groupbox, onContextMenuEvent);
    qgroupbox.OnKeyPressEvent(groupbox, onKeyPressEvent);

    qgroupbox.Show(groupbox);

    _ = qapplication.Exec();
}

fn onPaintEvent(self: ?*anyopaque, ev: ?*anyopaque) callconv(.c) void {
    // Call the base class's PaintEvent to get initial content
    // (Comment this out to see the QGroupBox disappear)
    qgroupbox.SuperPaintEvent(self, ev);

    // Then, draw on top of it
    const painter = qstylepainter.New(self);
    defer qstylepainter.Delete(painter);

    const brush = qbrush.New12(useColors[currentColor], qnamespace_enums.BrushStyle.SolidPattern);
    defer qbrush.Delete(brush);

    qstylepainter.SetBrush(painter, brush);
    qstylepainter.DrawRect2(painter, 80, 60, 160, 120);
}

fn onContextMenuEvent(self: ?*anyopaque, ev: ?*anyopaque) callconv(.c) void {
    qgroupbox.SuperContextMenuEvent(self, ev);

    currentColor +%= 1;
    qgroupbox.Update(self);
}

fn onKeyPressEvent(self: ?*anyopaque, ev: ?*anyopaque) callconv(.c) void {
    qgroupbox.SuperKeyPressEvent(self, ev);

    const text = "Keypress {d}";
    const title = std.fmt.bufPrintZ(&buffer, text, .{qkeyevent.Key(ev)}) catch @panic("Buffer full");
    qgroupbox.SetTitle(self, title);
}
