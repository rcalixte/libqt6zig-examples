const std = @import("std");
const qt6 = @import("libqt6zig");
const QApplication = qt6.QApplication;
const QPushButton = qt6.QPushButton;
const QPrintDialog = qt6.QPrintDialog;

var dialog: QPrintDialog = undefined;

pub fn main(init: std.process.Init) !void {
    const argv = try qt6.init(init.gpa, init.minimal.args);
    defer qt6.deinit(init.gpa, argv);
    var argc: i32 = @intCast(argv.len);
    const qapp: QApplication = .new(init.arena.allocator(), &argc, argv);
    defer qapp.delete();

    const button = QPushButton.new3("QPrintSupport sample");
    defer button.delete();

    dialog = .new(button);

    button.setFixedWidth(320);
    button.onPressed(onPressed);

    button.show();

    _ = QApplication.exec();
}

fn onPressed(_: QPushButton) callconv(.c) void {
    dialog.show();
}
