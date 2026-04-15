const std = @import("std");
const qt6 = @import("libqt6zig");
const qapplication = qt6.qapplication;
const kbookmarkmanager = qt6.kbookmarkmanager;
const kbookmarkdialog = qt6.kbookmarkdialog;
const qurl = qt6.qurl;

pub fn main(init: std.process.Init) !void {
    const argv = try qt6.init(init.gpa, init.minimal.args);
    defer qt6.deinit(init.gpa, argv);
    var argc: i32 = @intCast(argv.len);
    const qapp = qapplication.New(&argc, argv, init.arena.allocator());
    defer qapplication.Delete(qapp);

    const manager = kbookmarkmanager.New("assets/example.xml");
    defer kbookmarkmanager.Delete(manager);

    const dialog = kbookmarkdialog.New(manager);
    defer kbookmarkdialog.Delete(dialog);

    const url = qurl.New3("https://github.com/rcalixte/libqt6zig-examples");
    defer qurl.Delete(url);

    _ = kbookmarkdialog.AddBookmark(dialog, "Qt 6 examples for Zig", url, "www");
}
