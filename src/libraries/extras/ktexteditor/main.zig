const std = @import("std");
const qt6 = @import("libqt6zig");
const QApplication = qt6.QApplication;
const QMainWindow = qt6.QMainWindow;
const KTextEditor__Editor = qt6.KTextEditor__Editor;
const QDir = qt6.QDir;
const QUrl = qt6.QUrl;
const KTextEditor__MainWindow = qt6.KTextEditor__MainWindow;
const QToolBar = qt6.QToolBar;
const QAction = qt6.QAction;

var editor: KTextEditor__Editor = undefined;

pub fn main(init: std.process.Init) !void {
    const argv = try qt6.init(init.gpa, init.minimal.args);
    defer qt6.deinit(init.gpa, argv);
    var argc: i32 = @intCast(argv.len);
    const qapp = QApplication.New(init.arena.allocator(), &argc, argv);
    defer qapp.Delete();

    const window = QMainWindow.New2();
    defer window.Delete();

    window.SetWindowTitle("Qt 6 KTextEditor Example");
    window.SetMinimumSize2(1300, 1150);

    editor = KTextEditor__Editor.Instance();
    const doc = editor.CreateDocument(window);
    const dir = QDir.CurrentPath(init.gpa);
    defer init.gpa.free(dir);

    const file = try std.mem.concat(init.gpa, u8, &.{
        "file://",
        dir,
        "/src/libraries/extras/ktexteditor/main.zig",
    });
    defer init.gpa.free(file);

    const url = QUrl.New3(file);
    defer url.Delete();

    if (doc.OpenUrl(url)) {
        doc.SetModifiedOnDiskWarning(true);
        const view = doc.CreateView(window, KTextEditor__MainWindow{ .ptr = null });
        const toolbar = QToolBar.New3();
        _ = toolbar.AddAction2("Configure");
        toolbar.OnActionTriggered(toolbarTriggered);
        window.AddToolBar2(toolbar);
        window.SetCentralWidget(view);

        window.Show();

        _ = QApplication.Exec();
    }
}

fn toolbarTriggered(self: QToolBar, _: QAction) callconv(.c) void {
    editor.ConfigDialog(self);
}
