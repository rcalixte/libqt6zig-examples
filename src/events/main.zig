const std = @import("std");
const qt6 = @import("libqt6zig");
const QApplication = qt6.QApplication;
const QWidget = qt6.QWidget;
const QLabel = qt6.QLabel;
const QVBoxLayout = qt6.QVBoxLayout;
const qnamespace_enums = qt6.qnamespace_enums;
const QMouseEvent = qt6.QMouseEvent;
const QKeyEvent = qt6.QKeyEvent;

var label: QLabel = undefined;
var buffer: [64]u8 = undefined;

pub fn main(init: std.process.Init) !void {
    const argv = try qt6.init(init.gpa, init.minimal.args);
    defer qt6.deinit(init.gpa, argv);
    var argc: i32 = @intCast(argv.len);
    const qapp: QApplication = .new(init.arena.allocator(), &argc, argv);
    defer qapp.delete();

    const widget = QWidget.new2();
    defer widget.delete();

    widget.setFixedWidth(400);
    widget.setFixedHeight(100);
    widget.onMousePressEvent(widgetMousePressEvent);
    widget.onKeyPressEvent(widgetKeyPressEvent);

    label = .new3("### Press any key or click the mouse here!");
    label.setFocusPolicy(qnamespace_enums.FocusPolicy.StrongFocus);
    label.setTextFormat(qnamespace_enums.TextFormat.MarkdownText);
    label.setAlignment(qnamespace_enums.AlignmentFlag.AlignCenter);
    label.onMousePressEvent(labelMousePressEvent);
    label.onKeyPressEvent(labelKeyPressEvent);

    const layout = QVBoxLayout.new2();
    layout.addStretch();
    layout.addWidget(label);
    layout.addStretch();
    widget.setLayout(layout);

    widget.show();

    _ = QApplication.exec();
}

fn widgetMousePressEvent(_: QWidget, event: QMouseEvent) callconv(.c) void {
    mousePressEvent(event);
}

fn labelMousePressEvent(_: QLabel, event: QMouseEvent) callconv(.c) void {
    mousePressEvent(event);
}

fn mousePressEvent(event: QMouseEvent) void {
    const mouse = event.button();
    switch (mouse) {
        qnamespace_enums.MouseButton.LeftButton => label.setText("## Left mouse button pressed!"),
        qnamespace_enums.MouseButton.RightButton => label.setText("## Right mouse button pressed!"),
        else => {
            const formatted = std.fmt.bufPrint(
                &buffer,
                "## Mouse button keycode: {d}",
                .{mouse},
            ) catch @panic("Buffer full");
            label.setText(formatted);
        },
    }
}

fn widgetKeyPressEvent(_: QWidget, event: QKeyEvent) callconv(.c) void {
    keyPressEvent(event);
}

fn labelKeyPressEvent(_: QLabel, event: QKeyEvent) callconv(.c) void {
    keyPressEvent(event);
}

fn keyPressEvent(event: QKeyEvent) void {
    const key = event.key();
    const formatted = std.fmt.bufPrint(
        &buffer,
        "## You pressed key code: {d}",
        .{key},
    ) catch @panic("Buffer full");
    label.setText(formatted);
}
