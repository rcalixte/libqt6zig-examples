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

var wiggly: *WigglyWidget = undefined;

const wiggly_text = "Hello Wiggly Text";
const max_len: i32 = 32;
const sine_table = [_]i32{
    0,    38,  71,  92,
    100,  92,  71,  38,
    0,    -38, -71, -92,
    -100, -92, -71, -38,
};

pub const WigglyWidget = struct {
    timer: QBasicTimer,
    buffer: [max_len:0]u8,
    text: []u8,
    step: usize,
    widget: QWidget,

    pub fn create(alloc: std.mem.Allocator, text: []const u8) !*WigglyWidget {
        var self = try alloc.create(WigglyWidget);
        errdefer alloc.destroy(self);

        self.step = 0;
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

        self.widget.onPaintEvent(onPaintEvent);
        self.widget.onTimerEvent(onTimerEvent);

        return self;
    }

    pub fn destroy(self: *WigglyWidget, alloc: std.mem.Allocator) void {
        self.timer.delete();
        self.widget.deleteLater();
        alloc.destroy(self);
    }

    fn onPaintEvent(self: QWidget, _: QPaintEvent) callconv(.c) void {
        const font = QFont.new();
        defer font.delete();

        const font_metrics = QFontMetrics.new(font);
        defer font_metrics.delete();

        var x = @divFloor(self.width() - font_metrics.horizontalAdvance(wiggly.text), 4);
        const y = @divFloor(self.height() + font_metrics.ascent() - font_metrics.descent(), 2);

        const color = QColor.new3();
        defer color.delete();

        const painter = QStylePainter.new(self);
        defer painter.delete();

        for (0..wiggly.text.len) |i| {
            const index: usize = @mod(wiggly.step + i, sine_table.len);
            color.setHsv(@intCast((63 - index) * (sine_table.len / 4)), 255, 191);
            painter.setPen(color);
            painter.drawText3(
                x,
                y - @divFloor(sine_table[index] * font_metrics.height() * 2, 300),
                wiggly.text[i..][0..1],
            );
            x += font_metrics.horizontalAdvance(wiggly.text[i..][0..1]) * 3;
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

    wiggly = try .create(init.gpa, wiggly_text);
    defer wiggly.destroy(init.gpa);

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
