const std = @import("std");
const qt6 = @import("libqt6zig");
const qapplication = qt6.qapplication;
const kfilecustomdialog = qt6.kfilecustomdialog;
const qlabel = qt6.qlabel;

pub fn main() void {
    const argc = std.os.argv.len;
    const argv = std.os.argv.ptr;
    const qapp = qapplication.New(argc, argv);
    defer qapplication.Delete(qapp);

    const dialog = kfilecustomdialog.New2();
    defer kfilecustomdialog.Delete(dialog);

    kfilecustomdialog.SetWindowTitle(dialog, "Qt 6 KIO Example");

    const label = qlabel.New3("Select a file or directory");

    kfilecustomdialog.SetCustomWidget(dialog, label);

    _ = kfilecustomdialog.Exec(dialog);
}
