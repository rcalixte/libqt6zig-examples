const std = @import("std");
const qt6 = @import("libqt6zig");
const QApplication = qt6.QApplication;
const QAbstractListModel = qt6.QAbstractListModel;
const QListView = qt6.QListView;
const qnamespace_enums = qt6.qnamespace_enums;
const QModelIndex = qt6.QModelIndex;
const QVariant = qt6.QVariant;
const QColor = qt6.QColor;

var buf: [16]u8 = undefined;

pub fn main(init: std.process.Init) !void {
    const argv = try qt6.init(init.gpa, init.minimal.args);
    defer qt6.deinit(init.gpa, argv);
    var argc: i32 = @intCast(argv.len);
    const qapp: QApplication = .new(init.arena.allocator(), &argc, argv);
    defer qapp.delete();

    const model = QAbstractListModel.new();
    defer model.delete();

    model.onRowCount(onRowCount);
    model.onData(onData);

    const listview = QListView.new2();
    defer listview.delete();

    listview.setModel(model);
    listview.show();

    _ = QApplication.exec();
}

fn onRowCount(_: QAbstractListModel, _: QModelIndex) callconv(.c) i32 {
    return 1000;
}

fn onData(_: QAbstractListModel, index: QModelIndex, role: i32) callconv(.c) QVariant {
    switch (role) {
        qnamespace_enums.ItemDataRole.ForegroundRole => if (@mod(index.row(), 2) == 0) {
            const color = QColor.new5(0, 0, 0);
            defer color.delete();
            return color.toQVariant();
        } else {
            const color = QColor.new5(255, 0, 0);
            defer color.delete();
            return color.toQVariant();
        },
        qnamespace_enums.ItemDataRole.BackgroundRole => if (@mod(index.row(), 2) == 0) {
            const color = QColor.new5(255, 255, 255);
            defer color.delete();
            return color.toQVariant();
        } else {
            const color = QColor.new5(80, 80, 80);
            defer color.delete();
            return color.toQVariant();
        },
        qnamespace_enums.ItemDataRole.DisplayRole => {
            const str = std.fmt.bufPrint(&buf, "this is row {d}", .{index.row()}) catch
                @panic("failed to bufPrint");
            return .new24(str);
        },
        else => return .new(),
    }
}
