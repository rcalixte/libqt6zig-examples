const std = @import("std");
const qt6 = @import("libqt6zig");
const QApplication = qt6.QApplication;
const KBookmarkManager = qt6.KBookmarkManager;
const KBookmarkDialog = qt6.KBookmarkDialog;
const QUrl = qt6.QUrl;

pub fn main(init: std.process.Init) !void {
    const argv = try qt6.init(init.gpa, init.minimal.args);
    defer qt6.deinit(init.gpa, argv);
    var argc: i32 = @intCast(argv.len);
    const qapp: QApplication = .new(init.arena.allocator(), &argc, argv);
    defer qapp.delete();

    const manager = KBookmarkManager.new("assets/example.xml");
    defer manager.delete();

    const dialog = KBookmarkDialog.new(manager);
    defer dialog.delete();

    const url = QUrl.new3("https://github.com/rcalixte/libqt6zig-examples");
    defer url.delete();

    _ = dialog.addBookmark("Qt 6 examples for Zig", url, "www");
}
