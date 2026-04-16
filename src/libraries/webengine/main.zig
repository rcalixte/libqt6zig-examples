const std = @import("std");
const qt6 = @import("libqt6zig");
const QApplication = qt6.QApplication;
const QWebEngineView = qt6.QWebEngineView;
const QUrl = qt6.QUrl;

pub fn main(init: std.process.Init) !void {
    const argv = try qt6.init(init.gpa, init.minimal.args);
    defer qt6.deinit(init.gpa, argv);
    var argc: i32 = @intCast(argv.len);
    const qapp = QApplication.New(init.arena.allocator(), &argc, argv);
    defer qapp.Delete();

    const webengine = QWebEngineView.New2();
    defer webengine.Delete();

    const url = QUrl.New3("https://github.com/rcalixte/libqt6zig-examples");
    defer url.Delete();

    webengine.SetUrl(url);
    webengine.SetGeometry(100, 100, 640, 480);
    webengine.SetVisible(true);

    _ = QApplication.Exec();
}
