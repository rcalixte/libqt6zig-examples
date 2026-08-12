const std = @import("std");
const qt6 = @import("libqt6zig");
const QApplication = qt6.QApplication;
const QDialog = qt6.QDialog;
const QTreeWidget = qt6.QTreeWidget;
const KTreeWidgetSearchLine = qt6.KTreeWidgetSearchLine;
const KTreeWidgetSearchLineWidget = qt6.KTreeWidgetSearchLineWidget;
const QTreeWidgetItem = qt6.QTreeWidgetItem;
const QVBoxLayout = qt6.QVBoxLayout;
const QHBoxLayout = qt6.QHBoxLayout;
const QPushButton = qt6.QPushButton;
const qnamespace_enums = qt6.qnamespace_enums;
const QDialogButtonBox = qt6.QDialogButtonBox;
const qdialogbuttonbox_enums = qt6.qdialogbuttonbox_enums;
const QShowEvent = qt6.QShowEvent;

var allocator: std.mem.Allocator = undefined;

var dialog: QDialog = undefined;
var treewidget: QTreeWidget = undefined;
var searchline: KTreeWidgetSearchLine = undefined;

pub fn main(init: std.process.Init) !void {
    const argv = try qt6.init(init.gpa, init.minimal.args);
    defer qt6.deinit(init.gpa, argv);
    var argc: i32 = @intCast(argv.len);
    const qapp: QApplication = .new(init.arena.allocator(), &argc, argv);
    defer qapp.delete();

    allocator = init.gpa;

    dialog = .new2();

    dialog.setWindowTitle("Qt 6 KItemViews");
    dialog.setWhatsThis("This is a test dialog for KTreeWidgetSearchLineTest");

    treewidget = .new(dialog);
    treewidget.setColumnCount(4);
    const labels = [_][]const u8{ "Item", "Price", "HIDDEN COLUMN", "Source" };
    treewidget.setHeaderLabels(allocator, &labels);
    treewidget.hideColumn(2);

    const searchwidget = KTreeWidgetSearchLineWidget.new3(dialog, treewidget);
    searchline = searchwidget.searchLine();

    const red_s = [_][]const u8{"Red"};
    const red = QTreeWidgetItem.new4(allocator, treewidget, &red_s);
    red.setWhatsThis(0, "This item is red");
    red.setWhatsThis(1, "This item is pricey");
    treewidget.expandItem(red);

    const blue_s = [_][]const u8{"Blue"};
    const blue = QTreeWidgetItem.new4(allocator, treewidget, &blue_s);
    treewidget.expandItem(blue);

    const green_s = [_][]const u8{"Green"};
    const green = QTreeWidgetItem.new4(allocator, treewidget, &green_s);
    treewidget.expandItem(green);

    const yellow_s = [_][]const u8{"Yellow"};
    const yellow = QTreeWidgetItem.new4(allocator, treewidget, &yellow_s);
    treewidget.expandItem(yellow);

    createSecondLevel(red);
    createSecondLevel(blue);
    createSecondLevel(green);
    createSecondLevel(yellow);

    const vboxlayout = QVBoxLayout.new(dialog);
    const hboxlayout = QHBoxLayout.new2();

    const case_sensitive = QPushButton.new5("&Case Sensitive", dialog);
    case_sensitive.setCheckable(true);
    case_sensitive.onToggled(switchCaseSensitivity);
    hboxlayout.addWidget(case_sensitive);

    const keep_parents_visible = QPushButton.new5("Keep &Parents Visible", dialog);
    keep_parents_visible.setCheckable(true);
    keep_parents_visible.setChecked(true);
    keep_parents_visible.onToggled(switchKeepParentsVisible);
    hboxlayout.addWidget(keep_parents_visible);

    const buttonbox = QDialogButtonBox.new(dialog);
    buttonbox.setStandardButtons(qdialogbuttonbox_enums.StandardButton.Ok |
        qdialogbuttonbox_enums.StandardButton.Cancel);

    buttonbox.onAccepted(onAccepted);
    buttonbox.onRejected(onRejected);

    vboxlayout.addWidget(searchwidget);
    vboxlayout.addWidget(treewidget);
    vboxlayout.addLayout(hboxlayout);
    vboxlayout.addWidget(buttonbox);

    searchline.setFocus();
    dialog.resize(350, 600);
    dialog.onShowEvent(showEvent);

    _ = dialog.exec();
}

fn createSecondLevel(item: QTreeWidgetItem) void {
    const beans_s = [_][]const u8{"Beans"};
    const beans = QTreeWidgetItem.new7(allocator, item, &beans_s);
    treewidget.expandItem(beans);
    createThirdLevel(beans);

    const grapes_s = [_][]const u8{"Grapes"};
    const grapes = QTreeWidgetItem.new7(allocator, item, &grapes_s);
    treewidget.expandItem(grapes);
    createThirdLevel(grapes);

    const plums_s = [_][]const u8{"Plums"};
    const plums = QTreeWidgetItem.new7(allocator, item, &plums_s);
    treewidget.expandItem(plums);
    createThirdLevel(plums);

    const bananas_s = [_][]const u8{"Bananas"};
    const bananas = QTreeWidgetItem.new7(allocator, item, &bananas_s);
    treewidget.expandItem(bananas);
    createThirdLevel(bananas);
}

fn createThirdLevel(item: QTreeWidgetItem) void {
    const growing = [_][]const u8{ "Growing", "$2.00", "", "Farmer" };
    _ = QTreeWidgetItem.new7(allocator, item, &growing);
    const ripe = [_][]const u8{ "Ripe", "$8.00", "", "Market" };
    _ = QTreeWidgetItem.new7(allocator, item, &ripe);
    const decaying = [_][]const u8{ "Decaying", "$0.50", "", "Ground" };
    _ = QTreeWidgetItem.new7(allocator, item, &decaying);
    const pickled = [_][]const u8{ "Pickled", "$4.00", "", "Shop" };
    _ = QTreeWidgetItem.new7(allocator, item, &pickled);
}

fn switchCaseSensitivity(_: QPushButton, checked: bool) callconv(.c) void {
    searchline.setCaseSensitivity(if (checked)
        qnamespace_enums.CaseSensitivity.CaseSensitive
    else
        qnamespace_enums.CaseSensitivity.CaseInsensitive);
}

fn switchKeepParentsVisible(_: QPushButton, checked: bool) callconv(.c) void {
    searchline.setKeepParentsVisible(checked);
}

fn onAccepted(_: QDialogButtonBox) callconv(.c) void {
    dialog.accept();
}

fn onRejected(_: QDialogButtonBox) callconv(.c) void {
    dialog.reject();
}

fn showEvent(self: QDialog, event: QShowEvent) callconv(.c) void {
    self.superShowEvent(event);

    const headerview = treewidget.header();
    for (0..@intCast(headerview.count())) |i|
        if (!headerview.isSectionHidden(@intCast(i)))
            treewidget.resizeColumnToContents(@intCast(i));
}
