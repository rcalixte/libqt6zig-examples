const std = @import("std");
const qt6 = @import("libqt6zig");
const C = qt6.C;
const qapplication = qt6.qapplication;
const qwidget = qt6.qwidget;
const qpalette_enums = qt6.qpalette_enums;
const qbasictimer = qt6.qbasictimer;
const qfont = qt6.qfont;
const qfontmetrics = qt6.qfontmetrics;
const qcolor = qt6.qcolor;
const qstylepainter = qt6.qstylepainter;
const qtimerevent = qt6.qtimerevent;
const qdialog = qt6.qdialog;
const qvboxlayout = qt6.qvboxlayout;
const qlineedit = qt6.qlineedit;

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
    timer: C.QBasicTimer,
    buffer: [max_len:0]u8,
    text: []u8,
    step: usize,
    widget: C.QWidget,

    pub fn init(alloc: std.mem.Allocator, text: []const u8) !*WigglyWidget {
        var self = try alloc.create(WigglyWidget);

        self.step = 0;
        self.text = try std.fmt.bufPrint(&self.buffer, "{s}", .{text});

        self.widget = qwidget.New2();
        qwidget.SetBackgroundRole(self.widget, qpalette_enums.ColorRole.Midlight);
        qwidget.SetAutoFillBackground(self.widget, true);

        self.timer = qbasictimer.New();
        qbasictimer.Start3(self.timer, 60, self.widget);

        const font = qfont.New();
        defer qfont.Delete(font);

        qfont.SetPointSize(font, qfont.PointSize(font) + 25);
        qwidget.SetFont(self.widget, font);

        qwidget.OnPaintEvent(self.widget, onPaintEvent);
        qwidget.OnTimerEvent(self.widget, onTimerEvent);

        return self;
    }

    pub fn deinit(self: *WigglyWidget, alloc: std.mem.Allocator) void {
        qbasictimer.Delete(self.timer);
        qwidget.DeleteLater(self.widget);
        alloc.destroy(self);
    }

    fn onPaintEvent(self: ?*anyopaque, _: ?*anyopaque) callconv(.c) void {
        const font = qfont.New();
        defer qfont.Delete(font);

        const font_metrics = qfontmetrics.New(font);
        defer qfontmetrics.Delete(font_metrics);

        var x = @divFloor(qwidget.Width(self) - qfontmetrics.HorizontalAdvance(font_metrics, wiggly.text), 4);
        const y = @divFloor(qwidget.Height(self) + qfontmetrics.Ascent(font_metrics) - qfontmetrics.Descent(font_metrics), 2);

        const color = qcolor.New3();
        defer qcolor.Delete(color);

        const painter = qstylepainter.New(self);
        defer qstylepainter.Delete(painter);

        for (0..wiggly.text.len) |i| {
            const index: usize = @mod(wiggly.step + i, sine_table.len);
            qcolor.SetHsv(color, @as(i32, @intCast((63 - index) * (sine_table.len / 4))), 255, 191);
            qstylepainter.SetPen(painter, color);
            qstylepainter.DrawText3(
                painter,
                x,
                y - @divFloor(sine_table[index] * qfontmetrics.Height(font_metrics) * 2, 300),
                wiggly.text[i..][0..1],
            );
            x += qfontmetrics.HorizontalAdvance(font_metrics, wiggly.text[i..][0..1]) * 3;
        }
    }

    fn onTimerEvent(self: ?*anyopaque, event: ?*anyopaque) callconv(.c) void {
        if (qtimerevent.TimerId(event) == qbasictimer.TimerId(wiggly.timer)) {
            wiggly.step += 1;
            qwidget.Update(self);
        } else {
            qwidget.SuperTimerEvent(self, event);
        }
    }
};

pub fn main(init: std.process.Init) !void {
    const argv = try qt6.init(init.gpa, init.minimal.args);
    defer qt6.deinit(init.gpa, argv);
    var argc: i32 = @intCast(argv.len);
    const qapp = qapplication.New(&argc, argv, init.arena.allocator());
    defer qapplication.Delete(qapp);

    const dialog = qdialog.New2();
    defer qdialog.Delete(dialog);

    qdialog.SetWindowTitle(dialog, "Qt 6 Wiggly Text Example");
    qdialog.Resize(dialog, 500, 180);

    wiggly = try WigglyWidget.init(init.gpa, wiggly_text);
    defer wiggly.deinit(init.gpa);

    const line_edit = qlineedit.New2();
    qlineedit.SetText(line_edit, wiggly_text);
    qlineedit.SetMaxLength(line_edit, max_len - 1);
    qlineedit.OnTextChanged(line_edit, onTextChanged);

    const layout = qvboxlayout.New(dialog);
    qvboxlayout.AddWidget(layout, wiggly.widget);
    qvboxlayout.AddWidget(layout, line_edit);

    qdialog.Show(dialog);

    _ = qapplication.Exec();
}

fn onTextChanged(_: ?*anyopaque, text: [*:0]const u8) callconv(.c) void {
    wiggly.text = std.fmt.bufPrint(
        &wiggly.buffer,
        "{s}",
        .{std.mem.span(text)},
    ) catch @panic("Failed to bufPrint");

    qwidget.Update(wiggly.widget);
}
