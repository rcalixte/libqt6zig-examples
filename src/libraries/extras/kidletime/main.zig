const std = @import("std");
const qt6 = @import("libqt6zig");
const QApplication = qt6.QApplication;
const QWidget = qt6.QWidget;
const QVBoxLayout = qt6.QVBoxLayout;
const QLabel = qt6.QLabel;
const qnamespace_enums = qt6.qnamespace_enums;
const KIdleTime = qt6.KIdleTime;

var label: QLabel = undefined;

pub fn main(init: std.process.Init) !void {
    const argv = try qt6.init(init.gpa, init.minimal.args);
    defer qt6.deinit(init.gpa, argv);
    var argc: i32 = @intCast(argv.len);
    const qapp = QApplication.New(init.arena.allocator(), &argc, argv);
    defer qapp.Delete();

    const widget = QWidget.New2();
    defer widget.Delete();

    widget.SetWindowTitle("Qt 6 KIdleTime Example");
    widget.SetFixedSize2(550, 150);

    const layout = QVBoxLayout.New2();
    label = QLabel.New2();
    label.SetAlignment(qnamespace_enums.AlignmentFlag.AlignCenter);
    label.SetTextFormat(qnamespace_enums.TextFormat.MarkdownText);
    label.SetText("### This text will stay here until you have been idle for 5 seconds.");

    const idle_time = KIdleTime.Instance();
    idle_time.CatchNextResumeEvent();
    idle_time.SimulateUserActivity();
    idle_time.OnResumingFromIdle(onResumingFromIdle);
    idle_time.OnTimeoutReached(onTimeoutReached);

    layout.AddStretch();
    layout.AddWidget(label);
    layout.AddStretch();
    widget.SetLayout(layout);

    widget.Show();

    _ = QApplication.Exec();
}

fn onResumingFromIdle(self: KIdleTime) callconv(.c) void {
    self.RemoveAllIdleTimeouts();
    _ = self.AddIdleTimeout(5000);
}

fn onTimeoutReached(_: KIdleTime, _: i32, _: i32) callconv(.c) void {
    label.SetText("## Timeout reached!");
}
