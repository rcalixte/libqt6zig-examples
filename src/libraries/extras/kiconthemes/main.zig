const std = @import("std");
const qt6 = @import("libqt6zig");
const QApplication = qt6.QApplication;
const KIconButton = qt6.KIconButton;

pub fn main(init: std.process.Init) !void {
    const argv = try qt6.init(init.gpa, init.minimal.args);
    defer qt6.deinit(init.gpa, argv);
    var argc: i32 = @intCast(argv.len);
    const qapp = QApplication.New(init.arena.allocator(), &argc, argv);
    defer qapp.Delete();

    const button = KIconButton.New2();
    defer button.Delete();

    button.SetWindowTitle("Qt 6 KIconThemes Example");
    button.SetText("Click to open the chooser dialog");
    button.SetMinimumSize2(320, 70);
    button.SetIconSize(64);

    button.Show();

    _ = QApplication.Exec();
}
