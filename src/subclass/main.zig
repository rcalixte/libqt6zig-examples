const std = @import("std");
const qt6 = @import("libqt6zig");
const qapplication = qt6.qapplication;
const qnamespace_enums = qt6.qnamespace_enums;
const qgroupbox = qt6.qgroupbox;
const qstylepainter = qt6.qstylepainter;
const qbrush = qt6.qbrush;
const qkeyevent = qt6.qkeyevent;

var buffer: [32]u8 = undefined;
var current_color: u2 = 0;

const colors = [_]i32{
    qnamespace_enums.GlobalColor.Black,
    qnamespace_enums.GlobalColor.Red,
    qnamespace_enums.GlobalColor.Green,
    qnamespace_enums.GlobalColor.Blue,
};

pub fn main(init: std.process.Init) !void {
    const argv = try qt6.init(init.gpa, init.minimal.args);
    defer qt6.deinit(init.gpa, argv);
    var argc: i32 = @intCast(argv.len);
    const qapp = qapplication.New(&argc, argv, init.arena.allocator());
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

    const brush = qbrush.New12(colors[current_color], qnamespace_enums.BrushStyle.SolidPattern);
    defer qbrush.Delete(brush);

    qstylepainter.SetBrush(painter, brush);
    qstylepainter.DrawRect2(painter, 80, 60, 160, 120);
}

fn onContextMenuEvent(self: ?*anyopaque, ev: ?*anyopaque) callconv(.c) void {
    qgroupbox.SuperContextMenuEvent(self, ev);

    current_color +%= 1;
    qgroupbox.Update(self);
}

fn onKeyPressEvent(self: ?*anyopaque, ev: ?*anyopaque) callconv(.c) void {
    qgroupbox.SuperKeyPressEvent(self, ev);

    const title = std.fmt.bufPrint(
        &buffer,
        "Keypress {d}",
        .{qkeyevent.Key(ev)},
    ) catch @panic("Buffer full");
    qgroupbox.SetTitle(self, title);
}
