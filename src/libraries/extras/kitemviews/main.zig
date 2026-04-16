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
var m_searchline: KTreeWidgetSearchLine = undefined;

pub fn main(init: std.process.Init) !void {
    const argv = try qt6.init(init.gpa, init.minimal.args);
    defer qt6.deinit(init.gpa, argv);
    var argc: i32 = @intCast(argv.len);
    const qapp = QApplication.New(init.arena.allocator(), &argc, argv);
    defer qapp.Delete();

    allocator = init.gpa;

    dialog = QDialog.New2();

    dialog.SetWindowTitle("Qt 6 KItemViews");
    dialog.SetWhatsThis("This is a test dialog for KTreeWidgetSearchLineTest");

    treewidget = QTreeWidget.New(dialog);
    treewidget.SetColumnCount(4);
    const labels = [_][]const u8{ "Item", "Price", "HIDDEN COLUMN", "Source" };
    treewidget.SetHeaderLabels(allocator, &labels);
    treewidget.HideColumn(2);

    const searchwidget = KTreeWidgetSearchLineWidget.New3(dialog, treewidget);
    m_searchline = searchwidget.SearchLine();

    const red_s = [_][]const u8{"Red"};
    const red = QTreeWidgetItem.New4(allocator, treewidget, &red_s);
    red.SetWhatsThis(0, "This item is red");
    red.SetWhatsThis(1, "This item is pricey");
    treewidget.ExpandItem(red);

    const blue_s = [_][]const u8{"Blue"};
    const blue = QTreeWidgetItem.New4(allocator, treewidget, &blue_s);
    treewidget.ExpandItem(blue);

    const green_s = [_][]const u8{"Green"};
    const green = QTreeWidgetItem.New4(allocator, treewidget, &green_s);
    treewidget.ExpandItem(green);

    const yellow_s = [_][]const u8{"Yellow"};
    const yellow = QTreeWidgetItem.New4(allocator, treewidget, &yellow_s);
    treewidget.ExpandItem(yellow);

    create2ndLevel(red);
    create2ndLevel(blue);
    create2ndLevel(green);
    create2ndLevel(yellow);

    const vboxlayout = QVBoxLayout.New(dialog);
    const hboxlayout = QHBoxLayout.New2();

    const case_sensitive = QPushButton.New5("&Case Sensitive", dialog);
    hboxlayout.AddWidget(case_sensitive);

    case_sensitive.SetCheckable(true);
    case_sensitive.OnToggled(switchCaseSensitivity);

    const keep_parents_visible = QPushButton.New5("Keep &Parents Visible", dialog);
    hboxlayout.AddWidget(keep_parents_visible);

    keep_parents_visible.SetCheckable(true);
    keep_parents_visible.SetChecked(true);
    keep_parents_visible.OnToggled(switchKeepParentsVisible);

    const buttonbox = QDialogButtonBox.New(dialog);
    buttonbox.SetStandardButtons(qdialogbuttonbox_enums.StandardButton.Ok | qdialogbuttonbox_enums.StandardButton.Cancel);

    buttonbox.OnAccepted(onAccepted);
    buttonbox.OnRejected(onRejected);

    vboxlayout.AddWidget(searchwidget);
    vboxlayout.AddWidget(treewidget);
    vboxlayout.AddLayout(hboxlayout);
    vboxlayout.AddWidget(buttonbox);

    m_searchline.SetFocus();
    dialog.Resize(350, 600);
    dialog.OnShowEvent(showEvent);

    _ = dialog.Exec();
}

fn create2ndLevel(item: QTreeWidgetItem) void {
    const beans_s = [_][]const u8{"Beans"};
    const beans = QTreeWidgetItem.New7(allocator, item, &beans_s);
    treewidget.ExpandItem(beans);
    create3rdLevel(beans);

    const grapes_s = [_][]const u8{"Grapes"};
    const grapes = QTreeWidgetItem.New7(allocator, item, &grapes_s);
    treewidget.ExpandItem(grapes);
    create3rdLevel(grapes);

    const plums_s = [_][]const u8{"Plums"};
    const plums = QTreeWidgetItem.New7(allocator, item, &plums_s);
    treewidget.ExpandItem(plums);
    create3rdLevel(plums);

    const bananas_s = [_][]const u8{"Bananas"};
    const bananas = QTreeWidgetItem.New7(allocator, item, &bananas_s);
    treewidget.ExpandItem(bananas);
    create3rdLevel(bananas);
}

fn create3rdLevel(item: QTreeWidgetItem) void {
    const growing = [_][]const u8{ "Growing", "$2.00", "", "Farmer" };
    _ = QTreeWidgetItem.New7(allocator, item, &growing);
    const ripe = [_][]const u8{ "Ripe", "$8.00", "", "Market" };
    _ = QTreeWidgetItem.New7(allocator, item, &ripe);
    const decaying = [_][]const u8{ "Decaying", "$0.50", "", "Ground" };
    _ = QTreeWidgetItem.New7(allocator, item, &decaying);
    const pickled = [_][]const u8{ "Pickled", "$4.00", "", "Shop" };
    _ = QTreeWidgetItem.New7(allocator, item, &pickled);
}

fn switchCaseSensitivity(_: QPushButton, checked: bool) callconv(.c) void {
    m_searchline.SetCaseSensitivity(if (checked) qnamespace_enums.CaseSensitivity.CaseSensitive else qnamespace_enums.CaseSensitivity.CaseInsensitive);
}

fn switchKeepParentsVisible(_: QPushButton, checked: bool) callconv(.c) void {
    m_searchline.SetKeepParentsVisible(checked);
}

fn onAccepted(_: QDialogButtonBox) callconv(.c) void {
    dialog.Accept();
}

fn onRejected(_: QDialogButtonBox) callconv(.c) void {
    dialog.Reject();
}

fn showEvent(self: QDialog, event: QShowEvent) callconv(.c) void {
    self.SuperShowEvent(event);

    const headerview = treewidget.Header();
    for (0..@intCast(headerview.Count())) |i|
        if (!headerview.IsSectionHidden(@intCast(i)))
            treewidget.ResizeColumnToContents(@intCast(i));
}
