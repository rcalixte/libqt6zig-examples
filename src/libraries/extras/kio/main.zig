const std = @import("std");
const qt6 = @import("libqt6zig");
const QApplication = qt6.QApplication;
const KFileCustomDialog = qt6.KFileCustomDialog;
const QLabel = qt6.QLabel;

pub fn main(init: std.process.Init) !void {
    const argv = try qt6.init(init.gpa, init.minimal.args);
    defer qt6.deinit(init.gpa, argv);
    var argc: i32 = @intCast(argv.len);
    const qapp: QApplication = .new(init.arena.allocator(), &argc, argv);
    defer qapp.delete();

    const dialog = KFileCustomDialog.new2();
    defer dialog.delete();

    dialog.setWindowTitle("Qt 6 KIO Example");

    const label = QLabel.new5("Select a file or directory", dialog);

    dialog.setCustomWidget(label);

    _ = dialog.exec();
}
