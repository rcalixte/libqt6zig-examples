const std = @import("std");
const qt6 = @import("libqt6zig");
const QApplication = qt6.QApplication;
const QStandardItemModel = qt6.QStandardItemModel;
const QStandardItem = qt6.QStandardItem;
const KRearrangeColumnsProxyModel = qt6.KRearrangeColumnsProxyModel;
const QTreeView = qt6.QTreeView;
const QTimer = qt6.QTimer;

var proxy: KRearrangeColumnsProxyModel = undefined;
var row: [4]QStandardItem = undefined;

pub fn main(init: std.process.Init) !void {
    const argv = try qt6.init(init.gpa, init.minimal.args);
    defer qt6.deinit(init.gpa, argv);
    var argc: i32 = @intCast(argv.len);
    const qapp: QApplication = .new(init.arena.allocator(), &argc, argv);
    defer qapp.delete();

    const source = QStandardItemModel.new();
    defer source.delete();

    source.appendRow(makeStandardItemsList(&.{ "A0", "B0", "C0", "D0" }));
    source.appendRow(makeStandardItemsList(&.{ "A1", "B1", "C1", "D1" }));
    source.appendRow(makeStandardItemsList(&.{ "A2", "B2", "C2", "D2" }));
    source.setHorizontalHeaderLabels(init.gpa, &.{ "H1", "H2", "H3", "H4" });

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

    timer.start(3000);
    timer.onTimeout(timerCallback);

    _ = QApplication.exec();
}

fn makeStandardItemsList(labels: []const []const u8) []QStandardItem {
    for (labels, 0..) |label, i|
        row[i] = .new2(label);
    return row[0..];
}

fn timerCallback(_: QTimer) callconv(.c) void {
    var columns = [_]i32{ 2, 1, 0, 3 };
    proxy.setSourceColumns(&columns);
}
