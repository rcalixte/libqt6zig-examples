const std = @import("std");
const qt6 = @import("libqt6zig");
const C = qt6.C;
const qapplication = qt6.qapplication;
const qstandarditemmodel = qt6.qstandarditemmodel;
const qstandarditem = qt6.qstandarditem;
const krearrangecolumnsproxymodel = qt6.krearrangecolumnsproxymodel;
const qtreeview = qt6.qtreeview;
const qtimer = qt6.qtimer;

var gpa = @import("alloc_config").gpa;
const allocator = gpa.allocator();

var proxy: C.KRearrangeColumnsProxyModel = undefined;

pub fn main() !void {
    const argc = std.os.argv.len;
    const argv = std.os.argv.ptr;
    const qapp = qapplication.New(argc, argv);
    defer qapplication.QDelete(qapp);

    defer _ = gpa.deinit();

    var row_0_items = [_][]const u8{ "A0", "B0", "C0", "D0" };
    var row_0 = try makeStandardItemsList(allocator, &row_0_items);
    defer row_0.deinit(allocator);

    var row_1_items = [_][]const u8{ "A1", "B1", "C1", "D1" };
    var row_1 = try makeStandardItemsList(allocator, &row_1_items);
    defer row_1.deinit(allocator);

    var row_2_items = [_][]const u8{ "A2", "B2", "C2", "D2" };
    var row_2 = try makeStandardItemsList(allocator, &row_2_items);
    defer row_2.deinit(allocator);

    var labels = [_][]const u8{ "H1", "H2", "H3", "H4" };

    const source = qstandarditemmodel.New();
    defer qstandarditemmodel.QDelete(source);

    qstandarditemmodel.InsertRow(source, 0, row_0.items);
    qstandarditemmodel.InsertRow(source, 1, row_1.items);
    qstandarditemmodel.InsertRow(source, 2, row_2.items);
    qstandarditemmodel.SetHorizontalHeaderLabels(source, &labels, allocator);

    proxy = krearrangecolumnsproxymodel.New();
    defer krearrangecolumnsproxymodel.QDelete(proxy);

    var columns = [_]i32{ 2, 3, 1, 0 };
    krearrangecolumnsproxymodel.SetSourceColumns(proxy, &columns);
    krearrangecolumnsproxymodel.SetSourceModel(proxy, source);

    const treeview = qtreeview.New2();
    defer qtreeview.QDelete(treeview);

    qtreeview.SetWindowTitle(treeview, "Qt 6 KItemModels Example");
    qtreeview.SetMinimumSize2(treeview, 410, 100);
    qtreeview.SetModel(treeview, proxy);

    qtreeview.Show(treeview);

    const timer = qtimer.New();
    defer qtimer.QDelete(timer);

    qtimer.Start(timer, 1000);
    qtimer.OnTimeout(timer, timerCallback);

    _ = qapplication.Exec();
}

fn makeStandardItemsList(alloc: std.mem.Allocator, labels: [][]const u8) !std.ArrayList(C.QStandardItem) {
    var row: std.ArrayList(C.QStandardItem) = try .initCapacity(alloc, labels.len);
    for (labels) |label| {
        try row.append(alloc, qstandarditem.New2(label));
    }
    return row;
}

fn timerCallback(_: ?*anyopaque) callconv(.c) void {
    var columns = [_]i32{ 2, 1, 0, 3 };
    krearrangecolumnsproxymodel.SetSourceColumns(proxy, &columns);
}
