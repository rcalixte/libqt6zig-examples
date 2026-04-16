const std = @import("std");
const qt6 = @import("libqt6zig");
const QApplication = qt6.QApplication;
const QAbstractListModel = qt6.QAbstractListModel;
const QListView = qt6.QListView;
const qnamespace_enums = qt6.qnamespace_enums;
const QModelIndex = qt6.QModelIndex;
const QVariant = qt6.QVariant;
const QColor = qt6.QColor;

pub fn main(init: std.process.Init) !void {
    const argv = try qt6.init(init.gpa, init.minimal.args);
    defer qt6.deinit(init.gpa, argv);
    var argc: i32 = @intCast(argv.len);
    const qapp = QApplication.New(init.arena.allocator(), &argc, argv);
    defer qapp.Delete();

    const model = QAbstractListModel.New();

    model.OnColumnCount(onColumnCount);
    model.OnRowCount(onRowCount);
    model.OnData(onData);

    const listview = QListView.New2();
    defer listview.Delete();

    listview.SetModel(model);
    listview.Show();

    _ = QApplication.Exec();
}

fn onRowCount(_: QAbstractListModel, _: QModelIndex) callconv(.c) i32 {
    return 1000;
}

fn onColumnCount(_: QAbstractListModel, _: QModelIndex) callconv(.c) i32 {
    return 1;
}

fn onData(_: QAbstractListModel, index: QModelIndex, role: i32) callconv(.c) QVariant {
    switch (role) {
        qnamespace_enums.ItemDataRole.ForegroundRole => if (@mod(index.Row(), 2) == 0) {
            const color = QColor.New5(0, 0, 0);
            defer color.Delete();
            return color.ToQVariant();
        } else {
            const color = QColor.New5(255, 0, 0);
            defer color.Delete();
            return color.ToQVariant();
        },
        qnamespace_enums.ItemDataRole.BackgroundRole => if (@mod(index.Row(), 2) == 0) {
            const color = QColor.New5(255, 255, 255);
            defer color.Delete();
            return color.ToQVariant();
        } else {
            const color = QColor.New5(80, 80, 80);
            defer color.Delete();
            return color.ToQVariant();
        },
        qnamespace_enums.ItemDataRole.DisplayRole => {
            var buf: [16]u8 = undefined;
            const str = std.fmt.bufPrint(&buf, "this is row {d}", .{index.Row()}) catch @panic("failed to bufPrint");
            return QVariant.New24(str);
        },
        else => return QVariant.New(),
    }
}
