const std = @import("std");
const qt6 = @import("libqt6zig");
const qapplication = qt6.qapplication;
const kbookmarkmanager = qt6.kbookmarkmanager;
const kbookmarkdialog = qt6.kbookmarkdialog;
const qurl = qt6.qurl;

pub fn main() void {
    const argc = std.os.argv.len;
    const argv = std.os.argv.ptr;
    const qapp = qapplication.New(argc, argv);
    defer qapplication.Delete(qapp);

    const manager = kbookmarkmanager.New("assets/example.xml");
    defer kbookmarkmanager.Delete(manager);

    const dialog = kbookmarkdialog.New(manager);
    defer kbookmarkdialog.Delete(dialog);

    const url = qurl.New3("https://github.com/rcalixte/libqt6zig-examples");
    defer qurl.Delete(url);

    _ = kbookmarkdialog.AddBookmark(dialog, "Qt 6 examples for Zig", url, "www");
}
