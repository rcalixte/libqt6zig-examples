const std = @import("std");
const qt6 = @import("libqt6zig");
const qfilesystemmodel = qt6.qfilesystemmodel;
const qnamespace_enums = qt6.qnamespace_enums;
const qlistview = qt6.qlistview;
const qtreeview = qt6.qtreeview;
const qapplication = qt6.qapplication;
const qsplitter = qt6.qsplitter;
const qdir = qt6.qdir;
const qmodelindex = qt6.qmodelindex;

const allocator = std.heap.page_allocator;

pub fn main() void {
    const argc = std.os.argv.len;
    const argv = std.os.argv.ptr;
    _ = qapplication.New(argc, argv);

    const splitter = qsplitter.New2();
    defer qsplitter.QDelete(splitter);

    const dir = qdir.CurrentPath(allocator);
    defer allocator.free(dir);

    const model = qfilesystemmodel.New();
    defer qfilesystemmodel.QDelete(model);
    _ = qfilesystemmodel.SetRootPath(model, dir);
    const modelindex = qfilesystemmodel.IndexWithPath(model, dir);
    defer qmodelindex.QDelete(modelindex);

    const tree = qtreeview.New(splitter);
    qtreeview.SetModel(tree, model);
    qtreeview.SetRootIndex(tree, modelindex);

    const list = qlistview.New(splitter);
    qlistview.SetModel(list, model);
    qlistview.SetRootIndex(list, modelindex);

    qsplitter.SetWindowTitle(splitter, "Folder Model Views");
    qsplitter.Show(splitter);

    _ = qapplication.Exec();
}
