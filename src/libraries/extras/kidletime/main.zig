const std = @import("std");
const qt6 = @import("libqt6zig");
const C = qt6.C;
const qapplication = qt6.qapplication;
const qwidget = qt6.qwidget;
const qvboxlayout = qt6.qvboxlayout;
const qlabel = qt6.qlabel;
const qnamespace_enums = qt6.qnamespace_enums;
const kidletime = qt6.kidletime;

var label: C.QLabel = undefined;

pub fn main() void {
    const argc = std.os.argv.len;
    const argv = std.os.argv.ptr;
    const qapp = qapplication.New(argc, argv);
    defer qapplication.QDelete(qapp);

    const widget = qwidget.New2();
    defer qwidget.QDelete(widget);

    qwidget.SetWindowTitle(widget, "Qt 6 KIdleTime Example");
    qwidget.SetFixedSize2(widget, 550, 150);

    const layout = qvboxlayout.New2();
    label = qlabel.New2();
    qlabel.SetAlignment(label, qnamespace_enums.AlignmentFlag.AlignCenter);
    qlabel.SetTextFormat(label, qnamespace_enums.TextFormat.MarkdownText);
    qlabel.SetText(label, "### This text will stay here until you have been idle for 5 seconds.");

    const idleTime = kidletime.Instance();
    kidletime.CatchNextResumeEvent(idleTime);
    kidletime.SimulateUserActivity(idleTime);
    kidletime.OnResumingFromIdle(idleTime, onResumingFromIdle);
    kidletime.OnTimeoutReached(idleTime, onTimeoutReached);

    qvboxlayout.AddStretch(layout);
    qvboxlayout.AddWidget(layout, label);
    qvboxlayout.AddStretch(layout);
    qwidget.SetLayout(widget, layout);

    qwidget.Show(widget);

    _ = qapplication.Exec();
}

fn onResumingFromIdle(self: ?*anyopaque) callconv(.c) void {
    kidletime.RemoveAllIdleTimeouts(self);
    _ = kidletime.AddIdleTimeout(self, 5000);
}

fn onTimeoutReached(_: ?*anyopaque, _: i32, _: i32) callconv(.c) void {
    qlabel.SetText(label, "## Timeout reached!");
}
