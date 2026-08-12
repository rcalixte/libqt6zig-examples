const std = @import("std");
const qt6 = @import("libqt6zig");
const QApplication = qt6.QApplication;
const QWebEngineView = qt6.QWebEngineView;
const QUrl = qt6.QUrl;

pub fn main(init: std.process.Init) !void {
    const argv = try qt6.init(init.gpa, init.minimal.args);
    defer qt6.deinit(init.gpa, argv);
    var argc: i32 = @intCast(argv.len);
    const qapp: QApplication = .new(init.arena.allocator(), &argc, argv);
    defer qapp.delete();

    const webengine = QWebEngineView.new2();
    defer webengine.delete();

    const url = QUrl.new3("https://github.com/rcalixte/libqt6zig-examples");
    defer url.delete();

    webengine.setUrl(url);
    webengine.setGeometry(100, 100, 640, 480);
    webengine.setVisible(true);

    _ = QApplication.exec();
}
