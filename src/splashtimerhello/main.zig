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
    const qapp = QApplication.New(init.arena.allocator(), &argc, argv);
    defer qapp.Delete();

    const pixmap = QPixmap.New4("assets/libqt6zig-examples.png");
    defer pixmap.Delete();

    const splash = QSplashScreen.New4(pixmap, qnamespace_enums.WindowType.WindowStaysOnTopHint);
    defer splash.Delete();

    splash.OnMousePressEvent(onMousePressEvent);

    const widget = QWidget.New2();
    defer widget.Delete();

    widget.SetWindowTitle("Hello world");

    const button = QPushButton.New5("Hello world!", widget);
    button.SetFixedWidth(320);
    button.OnClicked(onClicked);

    splash.Show();

    const timer = QTimer.New();
    defer timer.Delete();

    const splash_qv = QVariant.New7(@intFromPtr(splash.ptr));
    _ = timer.SetProperty("splash", splash_qv);

    const widget_qv = QVariant.New7(@intFromPtr(widget.ptr));
    _ = timer.SetProperty("widget", widget_qv);

    timer.Start(3000);
    timer.OnTimeout(onTimeout);

    _ = QApplication.Exec();

    std.debug.print("OK!\n", .{});
}

fn onClicked(self: QPushButton) callconv(.c) void {
    counter += 1;
    const formatted = std.fmt.bufPrint(
        &buffer,
        "You have clicked the button {d} time(s)",
        .{counter},
    ) catch @panic("Failed to bufPrint");
    self.SetText(formatted);
}

fn onMousePressEvent(_: QSplashScreen, _: QMouseEvent) callconv(.c) void {}

fn onTimeout(self: QTimer) callconv(.c) void {
    const splash_qv = self.Property("splash");
    const splash_i = splash_qv.ToLongLong();

    const widget_qv = self.Property("widget");
    const widget_i = widget_qv.ToLongLong();

    const s: QSplashScreen = .{ .ptr = @ptrFromInt(@as(usize, @intCast(splash_i))) };
    _ = s.Close();

    const w: QWidget = .{ .ptr = @ptrFromInt(@as(usize, @intCast(widget_i))) };
    w.Show();

    self.Stop();
}
