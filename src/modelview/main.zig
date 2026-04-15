const std = @import("std");
const qt6 = @import("libqt6zig");
const qapplication = qt6.qapplication;
const qsplitter = qt6.qsplitter;
const qdir = qt6.qdir;
const qfilesystemmodel = qt6.qfilesystemmodel;
const qmodelindex = qt6.qmodelindex;
const qtreeview = qt6.qtreeview;
const qlistview = qt6.qlistview;

pub fn main(init: std.process.Init) !void {
    const argv = try qt6.init(init.gpa, init.minimal.args);
    defer qt6.deinit(init.gpa, argv);
    var argc: i32 = @intCast(argv.len);
    const qapp = qapplication.New(&argc, argv, init.arena.allocator());
    defer qapplication.Delete(qapp);

    const splitter = qsplitter.New2();
    defer qsplitter.Delete(splitter);

    const dir = qdir.CurrentPath(init.gpa);
    defer init.gpa.free(dir);

    const model = qfilesystemmodel.New();
    defer qfilesystemmodel.Delete(model);
    const modelindex = qfilesystemmodel.SetRootPath(model, dir);
    defer qmodelindex.Delete(modelindex);

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
