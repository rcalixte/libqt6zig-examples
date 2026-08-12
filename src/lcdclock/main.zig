const std = @import("std");
const qt6 = @import("libqt6zig");
const QApplication = qt6.QApplication;
const QWidget = qt6.QWidget;
const QHBoxLayout = qt6.QHBoxLayout;
const QLCDNumber = qt6.QLCDNumber;
const QTime = qt6.QTime;
const QTimer = qt6.QTimer;

var allocator: std.mem.Allocator = undefined;

var lcd: QLCDNumber = undefined;
var time: QTime = undefined;

pub fn main(init: std.process.Init) !void {
    const argv = try qt6.init(init.gpa, init.minimal.args);
    defer qt6.deinit(init.gpa, argv);
    var argc: i32 = @intCast(argv.len);
    const qapp: QApplication = .new(init.arena.allocator(), &argc, argv);
    defer qapp.delete();

    allocator = init.gpa;

    const widget = QWidget.new2();
    defer widget.delete();

    widget.setWindowTitle("Qt 6 LCD Clock Example");
    widget.resize(360, 240);

    const hbox = QHBoxLayout.new(widget);
    lcd = .new(widget);

    lcd.setStyleSheet("background-color: #ec915c; color: white;");

    showTime(.{ .ptr = null });

    hbox.addWidget(lcd);

    const timer = QTimer.new2(widget);
    timer.start(1000);
    timer.onTimeout(showTime);

    widget.show();

    _ = QApplication.exec();
}

fn showTime(_: QTimer) callconv(.c) void {
    time = .currentTime();
    defer time.delete();

    const lcd_format = if (@mod(time.second(), 2) == 0) "hh:mm" else "hh mm";

    const text = time.toString2(allocator, lcd_format);
    defer allocator.free(text);

    lcd.display(text);
}
