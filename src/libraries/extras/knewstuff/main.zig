const std = @import("std");
const qt6 = @import("libqt6zig");
const QApplication = qt6.QApplication;
const QWidget = qt6.QWidget;
const KNSWidgets__Button = qt6.KNSWidgets__Button;
const QVBoxLayout = qt6.QVBoxLayout;

pub fn main(init: std.process.Init) !void {
    const argv = try qt6.init(init.gpa, init.minimal.args);
    defer qt6.deinit(init.gpa, argv);
    var argc: i32 = @intCast(argv.len);
    const qapp = QApplication.New(init.arena.allocator(), &argc, argv);
    defer qapp.Delete();

    const widget = QWidget.New2();
    defer widget.Delete();

    widget.SetWindowTitle("Qt 6 KNewStuff Example");
    widget.SetMinimumSize2(300, 100);

    const button = KNSWidgets__Button.New(widget);
    button.SetText("Click me!");
    button.SetMinimumWidth(100);

    const layout = QVBoxLayout.New2();
    layout.AddWidget(button);
    widget.SetLayout(layout);

    widget.Show();

    _ = QApplication.Exec();
}
