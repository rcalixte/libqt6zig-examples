const std = @import("std");
const qt6 = @import("libqt6zig");
const QApplication = qt6.QApplication;
const QPushButton = qt6.QPushButton;
const QWidget = qt6.QWidget;
const QPixmap = qt6.QPixmap;
const QSplashScreen = qt6.QSplashScreen;
const qnamespace_enums = qt6.qnamespace_enums;
const QTimer = qt6.QTimer;
const QVariant = qt6.QVariant;
const QMouseEvent = qt6.QMouseEvent;

var counter: usize = 0;
var buffer: [64]u8 = undefined;

pub fn main(init: std.process.Init) !void {
    const argv = try qt6.init(init.gpa, init.minimal.args);
    defer qt6.deinit(init.gpa, argv);
    var argc: i32 = @intCast(argv.len);
    const qapp: QApplication = .new(init.arena.allocator(), &argc, argv);
    defer qapp.delete();

    const pixmap = QPixmap.new4("assets/libqt6zig-examples.png");
    defer pixmap.delete();

    const splash = QSplashScreen.new4(pixmap, qnamespace_enums.WindowType.WindowStaysOnTopHint);
    defer splash.delete();

    splash.onMousePressEvent(onMousePressEvent);

    const widget = QWidget.new2();
    defer widget.delete();

    widget.setWindowTitle("Hello world");

    const button = QPushButton.new5("Hello world!", widget);
    button.setFixedWidth(320);
    button.onClicked(onClicked);

    splash.show();

    const timer = QTimer.new();
    defer timer.delete();

    const splash_qv = QVariant.new7(@intFromPtr(splash.ptr));
    defer splash_qv.delete();

    _ = timer.setProperty("splash", splash_qv);

    const widget_qv = QVariant.new7(@intFromPtr(widget.ptr));
    defer widget_qv.delete();

    _ = timer.setProperty("widget", widget_qv);

    timer.start(3000);
    timer.onTimeout(onTimeout);

    _ = QApplication.exec();

    std.debug.print("OK!\n", .{});
}

fn onClicked(self: QPushButton) callconv(.c) void {
    counter +%= 1;
    const formatted = std.fmt.bufPrint(
        &buffer,
        "You have clicked the button {d} time(s)",
        .{counter},
    ) catch @panic("Failed to bufPrint");
    self.setText(formatted);
}

fn onMousePressEvent(_: QSplashScreen, _: QMouseEvent) callconv(.c) void {}

fn onTimeout(self: QTimer) callconv(.c) void {
    const splash_qv = self.property("splash");
    defer splash_qv.delete();

    const splash_i = splash_qv.toLongLong();

    const widget_qv = self.property("widget");
    defer widget_qv.delete();

    const widget_i = widget_qv.toLongLong();

    const s: QSplashScreen = .{ .ptr = @ptrFromInt(@as(usize, @intCast(splash_i))) };
    _ = s.close();

    const w: QWidget = .{ .ptr = @ptrFromInt(@as(usize, @intCast(widget_i))) };
    w.show();

    self.stop();
}
