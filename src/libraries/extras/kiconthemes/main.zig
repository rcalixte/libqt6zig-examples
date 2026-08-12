const std = @import("std");
const qt6 = @import("libqt6zig");
const QApplication = qt6.QApplication;
const KIconButton = qt6.KIconButton;

pub fn main(init: std.process.Init) !void {
    const argv = try qt6.init(init.gpa, init.minimal.args);
    defer qt6.deinit(init.gpa, argv);
    var argc: i32 = @intCast(argv.len);
    const qapp: QApplication = .new(init.arena.allocator(), &argc, argv);
    defer qapp.delete();

    const button = KIconButton.new2();
    defer button.delete();

    button.setWindowTitle("Qt 6 KIconThemes Example");
    button.setText("Click to open the chooser dialog");
    button.setMinimumSize2(320, 70);
    button.setIconSize(64);

    button.show();

    _ = QApplication.exec();
}
