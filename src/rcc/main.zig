const std = @import("std");
const qt6 = @import("libqt6zig");
const rcc = @import("rcc.zig");
const QApplication = qt6.QApplication;
const QWidget = qt6.QWidget;
const QHBoxLayout = qt6.QHBoxLayout;
const QRadioButton = qt6.QRadioButton;
const QIcon = qt6.QIcon;
const QSize = qt6.QSize;

pub fn main(init: std.process.Init) !void {
    const argv = try qt6.init(init.gpa, init.minimal.args);
    defer qt6.deinit(init.gpa, argv);
    var argc: i32 = @intCast(argv.len);
    const qapp = QApplication.New(init.arena.allocator(), &argc, argv);
    defer qapp.Delete();

    var ok = rcc.init();
    if (!ok)
        try std.Io.File.stdout().writeStreamingAll(init.io, "Resource initialization failed!\n");
    defer {
        ok = rcc.deinit();
        if (!ok)
            std.Io.File.stdout().writeStreamingAll(
                init.io,
                "Resource deinitialization failed!\n",
            ) catch @panic("Failed to stdout deinit\n");
    }

    const widget = QWidget.New2();
    defer widget.Delete();

    widget.SetMinimumSize2(650, 150);

    const hbox = QHBoxLayout.New(widget);

    const radio1 = QRadioButton.New2();
    radio1.SetToolTip("Qt");
    const icon1 = QIcon.New4(":/images/qt.png");
    defer icon1.Delete();
    radio1.SetIcon(icon1);
    const size1 = QSize.New4(50, 50);
    defer size1.Delete();
    radio1.SetIconSize(size1);

    const radio2 = QRadioButton.New2();
    radio2.SetToolTip("Zig");
    const icon2 = QIcon.New4(":/images/zig.png");
    defer icon2.Delete();
    radio2.SetIcon(icon2);
    const size2 = QSize.New4(50, 50);
    defer size2.Delete();
    radio2.SetIconSize(size2);

    const radio3 = QRadioButton.New2();
    radio3.SetToolTip("libqt6zig");
    const icon3 = QIcon.New4(":/images/libqt6zig.png");
    defer icon3.Delete();
    radio3.SetIcon(icon3);
    const size3 = QSize.New4(120, 40);
    defer size3.Delete();
    radio3.SetIconSize(size3);

    hbox.AddStretch();
    hbox.AddWidget(radio1);
    hbox.AddStretch();
    hbox.AddWidget(radio2);
    hbox.AddStretch();
    hbox.AddWidget(radio3);
    hbox.AddStretch();

    widget.Show();

    _ = QApplication.Exec();
}
