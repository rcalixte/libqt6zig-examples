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
    const qapp = QApplication.New(init.arena.allocator(), &argc, argv);
    defer qapp.Delete();

    const charsets = KCharsets.Charsets();

    const names = charsets.AvailableEncodingNames(init.gpa);
    defer {
        for (names) |name|
            init.gpa.free(name);
        init.gpa.free(names);
    }

    const widget = QWidget.New2();
    defer widget.Delete();

    widget.SetWindowTitle("Qt 6 KCharsets");
    widget.SetMinimumSize2(300, 400);

    const vboxlayout = QVBoxLayout.New2();
    const label = QLabel.New3("Available Encodings:");
    const listwidget = QListWidget.New2();

    listwidget.AddItems(init.gpa, names);

    vboxlayout.AddWidget(label);
    vboxlayout.AddWidget(listwidget);
    widget.SetLayout(vboxlayout);

    widget.Show();

    _ = QApplication.Exec();
}
