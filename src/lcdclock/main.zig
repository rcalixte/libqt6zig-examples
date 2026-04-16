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
    const qapp = QApplication.New(init.arena.allocator(), &argc, argv);
    defer qapp.Delete();

    allocator = init.gpa;

    const widget = QWidget.New2();
    defer widget.Delete();

    widget.SetWindowTitle("Qt 6 LCD Clock Example");
    widget.Resize(360, 240);

    const hbox = QHBoxLayout.New(widget);
    lcd = QLCDNumber.New(widget);

    lcd.SetStyleSheet("background-color: #ec915c; color: white;");

    show_time(.{ .ptr = null });

    hbox.AddWidget(lcd);

    const timer = QTimer.New2(widget);
    timer.Start(1000);
    timer.OnTimeout(show_time);

    widget.Show();

    _ = QApplication.Exec();
}

fn show_time(_: QTimer) callconv(.c) void {
    time = QTime.CurrentTime();
    defer time.Delete();

    const lcd_format = if (@mod(time.Second(), 2) == 0) "hh:mm" else "hh mm";

    const text = time.ToString2(allocator, lcd_format);
    defer allocator.free(text);

    lcd.Display(text);
}
