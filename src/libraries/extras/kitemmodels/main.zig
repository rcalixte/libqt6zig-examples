const std = @import("std");
const qt6 = @import("libqt6zig");
const QApplication = qt6.QApplication;
const QStandardItemModel = qt6.QStandardItemModel;
const QStandardItem = qt6.QStandardItem;
const KRearrangeColumnsProxyModel = qt6.KRearrangeColumnsProxyModel;
const QTreeView = qt6.QTreeView;
const QTimer = qt6.QTimer;

var proxy: KRearrangeColumnsProxyModel = undefined;

pub fn main(init: std.process.Init) !void {
    const argv = try qt6.init(init.gpa, init.minimal.args);
    defer qt6.deinit(init.gpa, argv);
    var argc: i32 = @intCast(argv.len);
    const qapp: QApplication = .new(init.arena.allocator(), &argc, argv);
    defer qapp.delete();

    const row_0_items = [_][]const u8{ "A0", "B0", "C0", "D0" };
    var row_0 = try makeStandardItemsList(init.gpa, &row_0_items);
    defer row_0.deinit(init.gpa);

    const row_1_items = [_][]const u8{ "A1", "B1", "C1", "D1" };
    var row_1 = try makeStandardItemsList(init.gpa, &row_1_items);
    defer row_1.deinit(init.gpa);

    const row_2_items = [_][]const u8{ "A2", "B2", "C2", "D2" };
    var row_2 = try makeStandardItemsList(init.gpa, &row_2_items);
    defer row_2.deinit(init.gpa);

    const labels = [_][]const u8{ "H1", "H2", "H3", "H4" };

    const source = QStandardItemModel.new();
    defer source.delete();

    source.insertRow(0, row_0.items);
    source.insertRow(1, row_1.items);
    source.insertRow(2, row_2.items);
    source.setHorizontalHeaderLabels(init.gpa, &labels);

    proxy = .new();
    defer proxy.delete();

    var columns = [_]i32{ 2, 3, 1, 0 };
    proxy.setSourceColumns(&columns);
    proxy.setSourceModel(source);

    const treeview = QTreeView.new2();
    defer treeview.delete();

    treeview.setWindowTitle("Qt 6 KItemModels Example");
    treeview.setMinimumSize2(410, 100);
    treeview.setModel(proxy);

    treeview.show();

    const timer = QTimer.new();
    defer timer.delete();

    timer.start(1000);
    timer.onTimeout(timerCallback);

    _ = QApplication.exec();
}

fn makeStandardItemsList(alloc: std.mem.Allocator, labels: []const []const u8) !std.ArrayList(QStandardItem) {
    var row: std.ArrayList(QStandardItem) = try .initCapacity(alloc, labels.len);
    for (labels) |label|
        row.appendAssumeCapacity(.new2(label));
    return row;
}

fn timerCallback(_: QTimer) callconv(.c) void {
    var columns = [_]i32{ 2, 1, 0, 3 };
    proxy.setSourceColumns(&columns);
}
