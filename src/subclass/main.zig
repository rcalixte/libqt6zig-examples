const std = @import("std");
const qt6 = @import("libqt6zig");
const QApplication = qt6.QApplication;
const qnamespace_enums = qt6.qnamespace_enums;
const QGroupBox = qt6.QGroupBox;
const QPaintEvent = qt6.QPaintEvent;
const QStylePainter = qt6.QStylePainter;
const QBrush = qt6.QBrush;
const QContextMenuEvent = qt6.QContextMenuEvent;
const QKeyEvent = qt6.QKeyEvent;

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
    const qapp: QApplication = .new(init.arena.allocator(), &argc, argv);
    defer qapp.delete();

    QApplication.setApplicationDisplayName("Right-click to change the color");

    const groupbox = QGroupBox.new2();
    defer groupbox.delete();

    groupbox.setTitle("QGroupBox title");
    groupbox.setFixedSize2(320, 240);
    groupbox.setMinimumSize2(100, 100);
    groupbox.onPaintEvent(onPaintEvent);
    groupbox.onContextMenuEvent(onContextMenuEvent);
    groupbox.onKeyPressEvent(onKeyPressEvent);

    groupbox.show();

    _ = QApplication.exec();
}

fn onPaintEvent(self: QGroupBox, ev: QPaintEvent) callconv(.c) void {
    // Call the base class's PaintEvent to get initial content
    // (Comment this out to see the QGroupBox disappear)
    self.superPaintEvent(ev);

    // Then, draw on top of it
    const painter = QStylePainter.new(self);
    defer painter.delete();

    const brush = QBrush.new12(colors[current_color], qnamespace_enums.BrushStyle.SolidPattern);
    defer brush.delete();

    painter.setBrush(brush);
    painter.drawRect2(80, 60, 160, 120);
}

fn onContextMenuEvent(self: QGroupBox, ev: QContextMenuEvent) callconv(.c) void {
    self.superContextMenuEvent(ev);

    current_color +%= 1;
    self.update();
}

fn onKeyPressEvent(self: QGroupBox, ev: QKeyEvent) callconv(.c) void {
    self.superKeyPressEvent(ev);

    const title = std.fmt.bufPrint(
        &buffer,
        "Keypress {d}",
        .{ev.key()},
    ) catch @panic("Buffer full");
    self.setTitle(title);
}
