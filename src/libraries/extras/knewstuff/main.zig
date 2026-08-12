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
    const qapp: QApplication = .new(init.arena.allocator(), &argc, argv);
    defer qapp.delete();

    const widget = QWidget.new2();
    defer widget.delete();

    widget.setWindowTitle("Qt 6 KNewStuff Example");
    widget.setMinimumSize2(300, 100);

    const button = KNSWidgets__Button.new(widget);
    button.setText("Click me!");
    button.setMinimumWidth(100);

    const layout = QVBoxLayout.new2();
    layout.addWidget(button);
    widget.setLayout(layout);

    widget.show();

    _ = QApplication.exec();
}
