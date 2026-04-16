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

    pub fn init(alloc: std.mem.Allocator, text: []const u8) !*WigglyWidget {
        var self = try alloc.create(WigglyWidget);

        self.step = 0;
        self.text = try std.fmt.bufPrint(&self.buffer, "{s}", .{text});

        self.widget = QWidget.New2();
        self.widget.SetBackgroundRole(qpalette_enums.ColorRole.Midlight);
        self.widget.SetAutoFillBackground(true);

        self.timer = QBasicTimer.New();
        self.timer.Start3(60, self.widget);

        const font = QFont.New();
        defer font.Delete();

        font.SetPointSize(font.PointSize() + 25);
        self.widget.SetFont(font);

        self.widget.OnPaintEvent(onPaintEvent);
        self.widget.OnTimerEvent(onTimerEvent);

        return self;
    }

    pub fn deinit(self: *WigglyWidget, alloc: std.mem.Allocator) void {
        self.timer.Delete();
        self.widget.DeleteLater();
        alloc.destroy(self);
    }

    fn onPaintEvent(self: QWidget, _: QPaintEvent) callconv(.c) void {
        const font = QFont.New();
        defer font.Delete();

        const font_metrics = QFontMetrics.New(font);
        defer font_metrics.Delete();

        var x = @divFloor(self.Width() - font_metrics.HorizontalAdvance(wiggly.text), 4);
        const y = @divFloor(self.Height() + font_metrics.Ascent() - font_metrics.Descent(), 2);

        const color = QColor.New3();
        defer color.Delete();

        const painter = QStylePainter.New(self);
        defer painter.Delete();

        for (0..wiggly.text.len) |i| {
            const index: usize = @mod(wiggly.step + i, sine_table.len);
            color.SetHsv(@intCast((63 - index) * (sine_table.len / 4)), 255, 191);
            painter.SetPen(color);
            painter.DrawText3(
                x,
                y - @divFloor(sine_table[index] * font_metrics.Height() * 2, 300),
                wiggly.text[i..][0..1],
            );
            x += font_metrics.HorizontalAdvance(wiggly.text[i..][0..1]) * 3;
        }
    }

    fn onTimerEvent(self: QWidget, event: QTimerEvent) callconv(.c) void {
        if (event.TimerId() == wiggly.timer.TimerId()) {
            wiggly.step += 1;
            self.Update();
        } else {
            self.SuperTimerEvent(event);
        }
    }
};

pub fn main(init: std.process.Init) !void {
    const argv = try qt6.init(init.gpa, init.minimal.args);
    defer qt6.deinit(init.gpa, argv);
    var argc: i32 = @intCast(argv.len);
    const qapp = QApplication.New(init.arena.allocator(), &argc, argv);
    defer qapp.Delete();

    const dialog = QDialog.New2();
    defer dialog.Delete();

    dialog.SetWindowTitle("Qt 6 Wiggly Text Example");
    dialog.Resize(500, 180);

    wiggly = try WigglyWidget.init(init.gpa, wiggly_text);
    defer wiggly.deinit(init.gpa);

    const line_edit = QLineEdit.New2();
    line_edit.SetText(wiggly_text);
    line_edit.SetMaxLength(max_len - 1);
    line_edit.OnTextChanged(onTextChanged);

    const layout = QVBoxLayout.New(dialog);
    layout.AddWidget(wiggly.widget);
    layout.AddWidget(line_edit);

    dialog.Show();

    _ = QApplication.Exec();
}

fn onTextChanged(_: QLineEdit, text: [*:0]const u8) callconv(.c) void {
    wiggly.text = std.fmt.bufPrint(
        &wiggly.buffer,
        "{s}",
        .{std.mem.span(text)},
    ) catch @panic("Failed to bufPrint");

    wiggly.widget.Update();
}
