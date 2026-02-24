const std = @import("std");
const qt6 = @import("libqt6zig");
const qapplication = qt6.qapplication;
const qwebengineview = qt6.qwebengineview;
const qurl = qt6.qurl;

pub fn main() void {
    const argc = std.os.argv.len;
    const argv = std.os.argv.ptr;
    const qapp = qapplication.New(argc, argv);
    defer qapplication.Delete(qapp);

    const webengine = qwebengineview.New2();
    defer qwebengineview.Delete(webengine);

    const url = qurl.New3("https://github.com/rcalixte/libqt6zig-examples");
    defer qurl.Delete(url);

    qwebengineview.SetUrl(webengine, url);
    qwebengineview.SetGeometry(webengine, 100, 100, 640, 480);
    qwebengineview.SetVisible(webengine, true);

    _ = qapplication.Exec();
}
