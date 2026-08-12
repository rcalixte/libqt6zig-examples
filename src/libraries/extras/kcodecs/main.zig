const std = @import("std");
const qt6 = @import("libqt6zig");
const QApplication = qt6.QApplication;
const KCharsets = qt6.KCharsets;
const QWidget = qt6.QWidget;
const QVBoxLayout = qt6.QVBoxLayout;
const QLabel = qt6.QLabel;
const QListWidget = qt6.QListWidget;

pub fn main(init: std.process.Init) !void {
    const argv = try qt6.init(init.gpa, init.minimal.args);
    defer qt6.deinit(init.gpa, argv);
    var argc: i32 = @intCast(argv.len);
    const qapp: QApplication = .new(init.arena.allocator(), &argc, argv);
    defer qapp.delete();

    const charsets = KCharsets.charsets();

    const names = charsets.availableEncodingNames(init.gpa);
    defer {
        for (names) |name|
            init.gpa.free(name);
        init.gpa.free(names);
    }

    const widget = QWidget.new2();
    defer widget.delete();

    widget.setWindowTitle("Qt 6 KCharsets");
    widget.setMinimumSize2(300, 400);

    const vboxlayout = QVBoxLayout.new2();
    const listwidget = QListWidget.new2();
    listwidget.addItems(init.gpa, names);

    vboxlayout.addWidget(QLabel.new3("Available Encodings:"));
    vboxlayout.addWidget(listwidget);
    widget.setLayout(vboxlayout);

    widget.show();

    _ = QApplication.exec();
}
