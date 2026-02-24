const std = @import("std");
const qt6 = @import("libqt6zig");
const C = qt6.C;
const qapplication = qt6.qapplication;
const qmainwindow = qt6.qmainwindow;
const ktexteditor__editor = qt6.ktexteditor__editor;
const qdir = qt6.qdir;
const qurl = qt6.qurl;
const ktexteditor__document = qt6.ktexteditor__document;
const qfont = qt6.qfont;
const qtoolbar = qt6.qtoolbar;

var gpa = @import("alloc_config").gpa;
const allocator = gpa.allocator();

var editor: C.KTextEditor__Editor = null;

pub fn main() !void {
    const argc = std.os.argv.len;
    const argv = std.os.argv.ptr;
    const qapp = qapplication.New(argc, argv);
    defer qapplication.Delete(qapp);

    defer _ = gpa.deinit();

    const window = qmainwindow.New2();
    defer qmainwindow.Delete(window);

    qmainwindow.SetWindowTitle(window, "Qt 6 KTextEditor Example");
    qmainwindow.SetMinimumSize2(window, 1300, 1150);

    editor = ktexteditor__editor.Instance();
    const doc = ktexteditor__editor.CreateDocument(editor, window);

    const dir = qdir.CurrentPath(allocator);
    defer allocator.free(dir);

    const file = try std.mem.concat(allocator, u8, &.{ "file://", dir, "/src/libraries/extras/ktexteditor/main.zig" });
    defer allocator.free(file);
    const url = qurl.New3(file);
    defer qurl.Delete(url);

    _ = ktexteditor__document.OpenUrl(doc, url);
    ktexteditor__document.SetModifiedOnDiskWarning(doc, true);

    const view = ktexteditor__document.CreateView(doc, window, window);

    const toolbar = qtoolbar.New3();
    _ = qtoolbar.AddAction2(toolbar, "Configure");
    qtoolbar.OnActionTriggered(toolbar, toolbarTriggered);

    qmainwindow.AddToolBar2(window, toolbar);
    qmainwindow.SetCentralWidget(window, view);
    qmainwindow.Show(window);

    _ = qapplication.Exec();
}

fn toolbarTriggered(self: ?*anyopaque, _: ?*anyopaque) callconv(.c) void {
    ktexteditor__editor.ConfigDialog(editor, self);
}
