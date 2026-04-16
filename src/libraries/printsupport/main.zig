const std = @import("std");
const qt6 = @import("libqt6zig");
const QApplication = qt6.QApplication;
const QPushButton = qt6.QPushButton;
const QPrintDialog = qt6.QPrintDialog;

pub fn main(init: std.process.Init) !void {
    const argv = try qt6.init(init.gpa, init.minimal.args);
    defer qt6.deinit(init.gpa, argv);
    var argc: i32 = @intCast(argv.len);
    const qapp = QApplication.New(init.arena.allocator(), &argc, argv);
    defer qapp.Delete();

    const button = QPushButton.New3("QPrintSupport sample");
    defer button.Delete();

    button.SetFixedWidth(320);
    button.OnPressed(onPressed);

    button.Show();

    _ = QApplication.Exec();
}

fn onPressed(_: QPushButton) callconv(.c) void {
    const dialog = QPrintDialog.New3();
    // cleaned up in onFinished

    dialog.OnFinished(onFinished);
    dialog.Show();
}

fn onFinished(self: QPrintDialog, _: i32) callconv(.c) void {
    self.DeleteLater();
}
