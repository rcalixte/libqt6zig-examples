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
    const qapp: QApplication = .new(init.arena.allocator(), &argc, argv);
    defer qapp.delete();

    const widget = QWidget.new2();
    defer widget.delete();

    widget.setWindowTitle("Qt 6 KIdleTime Example");
    widget.setFixedSize2(550, 150);

    const layout = QVBoxLayout.new2();
    label = .new2();
    label.setAlignment(qnamespace_enums.AlignmentFlag.AlignCenter);
    label.setTextFormat(qnamespace_enums.TextFormat.MarkdownText);
    label.setText("### This text will stay here until you have been idle for 5 seconds.");

    const idle_time = KIdleTime.instance();
    idle_time.catchNextResumeEvent();
    idle_time.simulateUserActivity();
    idle_time.onResumingFromIdle(onResumingFromIdle);
    idle_time.onTimeoutReached(onTimeoutReached);

    layout.addStretch();
    layout.addWidget(label);
    layout.addStretch();
    widget.setLayout(layout);

    widget.show();

    _ = QApplication.exec();
}

fn onResumingFromIdle(self: KIdleTime) callconv(.c) void {
    self.removeAllIdleTimeouts();
    _ = self.addIdleTimeout(5000);
}

fn onTimeoutReached(_: KIdleTime, _: i32, _: i32) callconv(.c) void {
    label.setText("## Timeout reached!");
}
