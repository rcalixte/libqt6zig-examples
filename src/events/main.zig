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
    const qapp = QApplication.New(init.arena.allocator(), &argc, argv);
    defer qapp.Delete();

    const widget = QWidget.New2();
    defer widget.Delete();

    widget.SetFixedWidth(400);
    widget.SetFixedHeight(100);
    widget.OnMousePressEvent(widgetMousePressEvent);
    widget.OnKeyPressEvent(widgetKeyPressEvent);

    label = QLabel.New3("### Press any key or click the mouse here!");
    label.SetFocusPolicy(qnamespace_enums.FocusPolicy.StrongFocus);
    label.SetTextFormat(qnamespace_enums.TextFormat.MarkdownText);
    label.SetAlignment(qnamespace_enums.AlignmentFlag.AlignCenter);
    label.OnMousePressEvent(labelMousePressEvent);
    label.OnKeyPressEvent(labelKeyPressEvent);

    const layout = QVBoxLayout.New2();
    layout.AddStretch();
    layout.AddWidget(label);
    layout.AddStretch();
    widget.SetLayout(layout);

    widget.Show();

    _ = QApplication.Exec();
}

fn widgetMousePressEvent(_: QWidget, event: QMouseEvent) callconv(.c) void {
    const mouse = event.Button();
    switch (mouse) {
        qnamespace_enums.MouseButton.LeftButton => label.SetText("## Left mouse button pressed!"),
        qnamespace_enums.MouseButton.RightButton => label.SetText("## Right mouse button pressed!"),
        else => {
            const formatted = std.fmt.bufPrint(
                &buffer,
                "## Mouse button keycode: {d}",
                .{mouse},
            ) catch @panic("Buffer full");
            label.SetText(formatted);
        },
    }
}

fn widgetKeyPressEvent(_: QWidget, event: QKeyEvent) callconv(.c) void {
    const key = event.Key();
    const formatted = std.fmt.bufPrint(
        &buffer,
        "## You pressed key code: {d}",
        .{key},
    ) catch @panic("Buffer full");
    label.SetText(formatted);
}

fn labelMousePressEvent(self: QLabel, event: QMouseEvent) callconv(.c) void {
    const mouse = event.Button();
    switch (mouse) {
        qnamespace_enums.MouseButton.LeftButton => self.SetText("## Left mouse button pressed!"),
        qnamespace_enums.MouseButton.RightButton => self.SetText("## Right mouse button pressed!"),
        else => {
            const formatted = std.fmt.bufPrint(
                &buffer,
                "## Mouse button keycode: {d}",
                .{mouse},
            ) catch @panic("Buffer full");
            self.SetText(formatted);
        },
    }
}

fn labelKeyPressEvent(self: QLabel, event: QKeyEvent) callconv(.c) void {
    const key = event.Key();
    const formatted = std.fmt.bufPrint(
        &buffer,
        "## You pressed key code: {d}",
        .{key},
    ) catch @panic("Buffer full");
    self.SetText(formatted);
}
