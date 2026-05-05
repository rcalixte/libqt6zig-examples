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
var variant_black: QVariant = undefined;
var variant_grey: QVariant = undefined;
var variant_red: QVariant = undefined;
var variant_white: QVariant = undefined;
var variant_ret: QVariant = undefined;

pub fn main(init: std.process.Init) !void {
    const argv = try qt6.init(init.gpa, init.minimal.args);
    defer qt6.deinit(init.gpa, argv);
    var argc: i32 = @intCast(argv.len);
    const qapp = QApplication.New(init.arena.allocator(), &argc, argv);
    defer qapp.Delete();

    const model = QAbstractListModel.New();
    defer model.Delete();

    const color0 = QColor.New5(0, 0, 0);
    defer color0.Delete();
    variant_black = color0.ToQVariant();
    defer variant_black.Delete();

    const color1 = QColor.New5(255, 0, 0);
    defer color1.Delete();
    variant_red = color1.ToQVariant();
    defer variant_red.Delete();

    const color2 = QColor.New5(255, 255, 255);
    defer color2.Delete();
    variant_white = color2.ToQVariant();
    defer variant_white.Delete();

    const color3 = QColor.New5(80, 80, 80);
    defer color3.Delete();
    variant_grey = color3.ToQVariant();
    defer variant_grey.Delete();

    variant_ret = QVariant.New();
    defer variant_ret.Delete();

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
        qnamespace_enums.ItemDataRole.ForegroundRole => if (@mod(index.Row(), 2) == 0)
            return variant_black
        else
            return variant_red,
        qnamespace_enums.ItemDataRole.BackgroundRole => if (@mod(index.Row(), 2) == 0)
            return variant_white
        else
            return variant_grey,
        qnamespace_enums.ItemDataRole.DisplayRole => {
            const str = std.fmt.bufPrint(&buf, "this is row {d}", .{index.Row()}) catch @panic("failed to bufPrint");
            const variant = QVariant.New24(str);
            defer variant.Delete();

            variant_ret.SetValue(variant);
            return variant_ret;
        },
        else => {
            variant_ret.Clear();
            return variant_ret;
        },
    }
}
