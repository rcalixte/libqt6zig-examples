const std = @import("std");
const qt6 = @import("libqt6zig");
const QApplication = qt6.QApplication;
const QWidget = qt6.QWidget;
const QPaintEvent = qt6.QPaintEvent;
const qpalette_enums = qt6.qpalette_enums;
const QBasicTimer = qt6.QBasicTimer;
const QFont = qt6.QFont;
const QFontMetrics = qt6.QFontMetrics;
const QColor = qt6.QColor;
const QStylePainter = qt6.QStylePainter;
const QTimerEvent = qt6.QTimerEvent;
const QDialog = qt6.QDialog;
const QVBoxLayout = qt6.QVBoxLayout;
const QLineEdit = qt6.QLineEdit;

var wiggly: WigglyWidget = .{};

const wiggly_text = "Hello Wiggly Text";
const max_len: i32 = 32;
const sine_table = [_]i32{
    0,    38,  71,  92,
    100,  92,  71,  38,
    0,    -38, -71, -92,
    -100, -92, -71, -38,
};

pub const WigglyWidget = struct {
    timer: QBasicTimer = undefined,
    buffer: [max_len:0]u8 = undefined,
    text: []u8 = &.{},
    step: usize = 0,
    widget: QWidget = undefined,
    font_metrics: QFontMetrics = undefined,
    color: QColor = undefined,

    pub fn init(self: *WigglyWidget, text: []const u8) !void {
        self.text = try std.fmt.bufPrint(&self.buffer, "{s}", .{text});

        self.widget = .new2();
        self.widget.setBackgroundRole(qpalette_enums.ColorRole.Midlight);
        self.widget.setAutoFillBackground(true);

        self.timer = .new();
        self.timer.start3(60, self.widget);

        const font = QFont.new();
        defer font.delete();

        font.setPointSize(font.pointSize() + 25);
        self.widget.setFont(font);

        const wiggly_font = QFont.new();
        defer wiggly_font.delete();

        self.font_metrics = .new(wiggly_font);
        self.color = .new3();

        self.widget.onPaintEvent(onPaintEvent);
        self.widget.onTimerEvent(onTimerEvent);
    }

    pub fn deinit(self: *const WigglyWidget) void {
        self.timer.delete();
        self.color.delete();
        self.font_metrics.delete();
        self.widget.deleteLater();
    }

    fn onPaintEvent(self: QWidget, _: QPaintEvent) callconv(.c) void {
        var x = @divFloor(self.width() - wiggly.font_metrics.horizontalAdvance(wiggly.text), 4);
        const y = @divFloor(self.height() + wiggly.font_metrics.ascent() - wiggly.font_metrics.descent(), 2);

        const painter = QStylePainter.new(self);
        defer painter.delete();

        for (0..wiggly.text.len) |i| {
            const index: usize = @mod(wiggly.step + i, sine_table.len);
            wiggly.color.setHsv(@intCast((63 - index) * (sine_table.len / 4)), 255, 191);
            painter.setPen(wiggly.color);
            painter.drawText3(
                x,
                y - @divFloor(sine_table[index] * wiggly.font_metrics.height() * 2, 300),
                wiggly.text[i..][0..1],
            );
            x += wiggly.font_metrics.horizontalAdvance(wiggly.text[i..][0..1]) * 3;
        }
    }

    fn onTimerEvent(self: QWidget, event: QTimerEvent) callconv(.c) void {
        if (event.timerId() == wiggly.timer.timerId()) {
            wiggly.step += 1;
            self.update();
        } else {
            self.superTimerEvent(event);
        }
    }
};

pub fn main(init: std.process.Init) !void {
    const argv = try qt6.init(init.gpa, init.minimal.args);
    defer qt6.deinit(init.gpa, argv);
    var argc: i32 = @intCast(argv.len);
    const qapp: QApplication = .new(init.arena.allocator(), &argc, argv);
    defer qapp.delete();

    const dialog = QDialog.new2();
    defer dialog.delete();

    dialog.setWindowTitle("Qt 6 Wiggly Text Example");
    dialog.resize(500, 180);

    try wiggly.init(wiggly_text);
    defer wiggly.deinit();

    const line_edit = QLineEdit.new2();
    line_edit.setText(wiggly_text);
    line_edit.setMaxLength(max_len - 1);
    line_edit.onTextChanged(onTextChanged);

    const layout = QVBoxLayout.new(dialog);
    layout.addWidget(wiggly.widget);
    layout.addWidget(line_edit);

    dialog.show();

    _ = QApplication.exec();
}

fn onTextChanged(_: QLineEdit, text: [*:0]const u8) callconv(.c) void {
    wiggly.text = std.fmt.bufPrint(
        &wiggly.buffer,
        "{s}",
        .{std.mem.span(text)},
    ) catch @panic("Failed to bufPrint");

    wiggly.widget.update();
}
