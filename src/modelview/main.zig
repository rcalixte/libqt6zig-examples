const std = @import("std");
const qt6 = @import("libqt6zig");
const qapplication = qt6.qapplication;
const qsplitter = qt6.qsplitter;
const qdir = qt6.qdir;
const qfilesystemmodel = qt6.qfilesystemmodel;
const qmodelindex = qt6.qmodelindex;
const qtreeview = qt6.qtreeview;
const qlistview = qt6.qlistview;

const getAllocatorConfig = @import("alloc_config").getAllocatorConfig;
const config = getAllocatorConfig();
var gda: std.heap.DebugAllocator(config) = .init;
const allocator = gda.allocator();

pub fn main() void {
    const argc = std.os.argv.len;
    const argv = std.os.argv.ptr;
    _ = qapplication.New(argc, argv);

    defer _ = gda.deinit();

    const splitter = qsplitter.New2();

    const dir = qdir.CurrentPath(allocator);
    defer allocator.free(dir);

    const model = qfilesystemmodel.New();
    defer qfilesystemmodel.QDelete(model);
    const modelindex = qfilesystemmodel.SetRootPath(model, dir);
    defer qmodelindex.QDelete(modelindex);

    const tree = qtreeview.New(splitter);
    qtreeview.SetModel(tree, model);
    qtreeview.SetRootIndex(tree, modelindex);

    const list = qlistview.New(splitter);
    qlistview.SetModel(list, model);
    qlistview.SetRootIndex(list, modelindex);

    const tree_model = qtreeview.SelectionModel(tree);
    qlistview.SetSelectionModel(list, tree_model);

    qsplitter.SetWindowTitle(splitter, "Folder Model Views");
    qsplitter.Show(splitter);

    _ = qapplication.Exec();
}
