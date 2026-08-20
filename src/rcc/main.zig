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
    const qapp: QApplication = .new(init.arena.allocator(), &argc, argv);
    defer qapp.delete();

    var ok = rcc.init();
    if (!ok)
        std.log.err("Resource initialization failed!", .{});
    defer {
        ok = rcc.deinit();
        if (!ok)
            std.log.err("Resource deinitialization failed!", .{});
    }

    const widget = QWidget.new2();
    defer widget.delete();

    widget.setMinimumSize2(650, 150);

    const hbox = QHBoxLayout.new(widget);

    const radio1 = QRadioButton.new2();
    radio1.setToolTip("Qt");
    const icon1 = QIcon.new4(":/images/qt.png");
    defer icon1.delete();
    radio1.setIcon(icon1);
    const size1 = QSize.new4(50, 50);
    defer size1.delete();
    radio1.setIconSize(size1);

    const radio2 = QRadioButton.new2();
    radio2.setToolTip("Zig");
    const icon2 = QIcon.new4(":/images/zig.png");
    defer icon2.delete();
    radio2.setIcon(icon2);
    const size2 = QSize.new4(50, 50);
    defer size2.delete();
    radio2.setIconSize(size2);

    const radio3 = QRadioButton.new2();
    radio3.setToolTip("libqt6zig");
    const icon3 = QIcon.new4(":/images/libqt6zig.png");
    defer icon3.delete();
    radio3.setIcon(icon3);
    const size3 = QSize.new4(120, 40);
    defer size3.delete();
    radio3.setIconSize(size3);

    hbox.addStretch();
    hbox.addWidget(radio1);
    hbox.addStretch();
    hbox.addWidget(radio2);
    hbox.addStretch();
    hbox.addWidget(radio3);
    hbox.addStretch();

    widget.show();

    _ = QApplication.exec();
}
