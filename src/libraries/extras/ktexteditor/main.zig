const std = @import("std");
const qt6 = @import("libqt6zig");
const QApplication = qt6.QApplication;
const QMainWindow = qt6.QMainWindow;
const KTextEditor__Editor = qt6.KTextEditor__Editor;
const QUrl = qt6.QUrl;
const KTextEditor__MainWindow = qt6.KTextEditor__MainWindow;
const QToolBar = qt6.QToolBar;
const QAction = qt6.QAction;

var editor: KTextEditor__Editor = undefined;
const file = "src/libraries/extras/ktexteditor/main.zig";

pub fn main(init: std.process.Init) !void {
    const argv = try qt6.init(init.gpa, init.minimal.args);
    defer qt6.deinit(init.gpa, argv);
    var argc: i32 = @intCast(argv.len);
    const qapp: QApplication = .new(init.arena.allocator(), &argc, argv);
    defer qapp.delete();

    const window = QMainWindow.new2();
    defer window.delete();

    window.setWindowTitle("Qt 6 KTextEditor Example");
    window.setMinimumSize2(950, 1020);

    editor = .instance();

    const doc = editor.createDocument(window);
    defer doc.delete();

    const url = QUrl.fromLocalFile(file);
    defer url.delete();

    if (doc.openUrl(url)) {
        doc.setModifiedOnDiskWarning(true);
        const view = doc.createView(window, KTextEditor__MainWindow{ .ptr = null });
        const toolbar = QToolBar.new3();
        _ = toolbar.addAction2("Configure");
        toolbar.onActionTriggered(toolbarTriggered);
        window.addToolBar2(toolbar);
        window.setCentralWidget(view);

        window.show();

        _ = QApplication.exec();
    }
}

fn toolbarTriggered(self: QToolBar, _: QAction) callconv(.c) void {
    editor.configDialog(self);
}
