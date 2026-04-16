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
    const qapp = QApplication.New(init.arena.allocator(), &argc, argv);
    defer qapp.Delete();

    const splitter = QSplitter.New2();
    defer splitter.Delete();

    const dir = QDir.CurrentPath(init.gpa);
    defer init.gpa.free(dir);

    const model = QFileSystemModel.New();
    defer model.Delete();
    const modelindex = model.SetRootPath(dir);
    defer modelindex.Delete();

    const tree = QTreeView.New(splitter);
    tree.SetModel(model);
    tree.SetRootIndex(modelindex);

    const list = QListView.New(splitter);
    list.SetModel(model);
    list.SetRootIndex(modelindex);

    const tree_model = tree.SelectionModel();
    list.SetSelectionModel(tree_model);

    splitter.SetWindowTitle("Folder Model Views");
    splitter.Show();

    _ = QApplication.Exec();
}
