const std = @import("std");
const qt6 = @import("libqt6zig");
const qapplication = qt6.qapplication;
const kfilecustomdialog = qt6.kfilecustomdialog;
const qlabel = qt6.qlabel;

pub fn main(init: std.process.Init) !void {
    const argv = try qt6.init(init.gpa, init.minimal.args);
    defer qt6.deinit(init.gpa, argv);
    var argc: i32 = @intCast(argv.len);
    const qapp = qapplication.New(&argc, argv, init.arena.allocator());
    defer qapplication.Delete(qapp);

    const dialog = kfilecustomdialog.New2();
    defer kfilecustomdialog.Delete(dialog);

    kfilecustomdialog.SetWindowTitle(dialog, "Qt 6 KIO Example");

    const label = qlabel.New3("Select a file or directory");

    kfilecustomdialog.SetCustomWidget(dialog, label);

    _ = kfilecustomdialog.Exec(dialog);
}
