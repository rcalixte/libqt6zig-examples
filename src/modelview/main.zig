const std = @import("std");
const qt6 = @import("libqt6zig");
const QApplication = qt6.QApplication;
const QSplitter = qt6.QSplitter;
const QDir = qt6.QDir;
const QFileSystemModel = qt6.QFileSystemModel;
const QTreeView = qt6.QTreeView;
const QListView = qt6.QListView;

pub fn main(init: std.process.Init) !void {
    const argv = try qt6.init(init.gpa, init.minimal.args);
    defer qt6.deinit(init.gpa, argv);
    var argc: i32 = @intCast(argv.len);
    const qapp: QApplication = .new(init.arena.allocator(), &argc, argv);
    defer qapp.delete();

    const splitter = QSplitter.new2();
    defer splitter.delete();

    const dir = QDir.currentPath(init.gpa);
    defer init.gpa.free(dir);

    const model = QFileSystemModel.new();
    defer model.delete();
    const modelindex = model.setRootPath(dir);
    defer modelindex.delete();

    const tree = QTreeView.new(splitter);
    tree.setModel(model);
    tree.setRootIndex(modelindex);

    const list = QListView.new(splitter);
    list.setModel(model);
    list.setRootIndex(modelindex);

    const tree_model = tree.selectionModel();
    list.setSelectionModel(tree_model);

    splitter.setWindowTitle("Folder Model Views");
    splitter.show();

    _ = QApplication.exec();
}
