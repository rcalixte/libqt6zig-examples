const std = @import("std");
const qt6 = @import("libqt6zig");
const C = qt6.C;
const qapplication = qt6.qapplication;
const qdialog = qt6.qdialog;
const qtreewidget = qt6.qtreewidget;
const ktreewidgetsearchline = qt6.ktreewidgetsearchline;
const ktreewidgetsearchlinewidget = qt6.ktreewidgetsearchlinewidget;
const qtreewidgetitem = qt6.qtreewidgetitem;
const qvboxlayout = qt6.qvboxlayout;
const qhboxlayout = qt6.qhboxlayout;
const qpushbutton = qt6.qpushbutton;
const qnamespace_enums = qt6.qnamespace_enums;
const qdialogbuttonbox = qt6.qdialogbuttonbox;
const qdialogbuttonbox_enums = qt6.qdialogbuttonbox_enums;
const qheaderview = qt6.qheaderview;

var gpa = @import("alloc_config").gpa;
const allocator = gpa.allocator();

var dialog: C.QDialog = undefined;
var treewidget: C.QTreeWidget = undefined;
var m_searchline: C.KTreeWidgetSearchLine = undefined;

pub fn main() void {
    const argc = std.os.argv.len;
    const argv = std.os.argv.ptr;
    const qapp = qapplication.New(argc, argv);
    defer qapplication.QDelete(qapp);

    defer _ = gpa.deinit();

    dialog = qdialog.New2();

    qdialog.SetWindowTitle(dialog, "Qt 6 KItemViews");
    qdialog.SetWhatsThis(dialog, "This is a test dialog for KTreeWidgetSearchLineTest");

    treewidget = qtreewidget.New(dialog);
    qtreewidget.SetColumnCount(treewidget, 4);
    const labels = [_][]const u8{ "Item", "Price", "HIDDEN COLUMN", "Source" };
    qtreewidget.SetHeaderLabels(treewidget, &labels, allocator);
    qtreewidget.HideColumn(treewidget, 2);

    const searchwidget = ktreewidgetsearchlinewidget.New3(dialog, treewidget);
    m_searchline = ktreewidgetsearchlinewidget.SearchLine(searchwidget);

    const red_s = [_][]const u8{"Red"};
    const red = qtreewidgetitem.New4(treewidget, &red_s, allocator);
    qtreewidgetitem.SetWhatsThis(red, 0, "This item is red");
    qtreewidgetitem.SetWhatsThis(red, 1, "This item is pricey");
    qtreewidget.ExpandItem(treewidget, red);

    const blue_s = [_][]const u8{"Blue"};
    const blue = qtreewidgetitem.New4(treewidget, &blue_s, allocator);
    qtreewidget.ExpandItem(treewidget, blue);

    const green_s = [_][]const u8{"Green"};
    const green = qtreewidgetitem.New4(treewidget, &green_s, allocator);
    qtreewidget.ExpandItem(treewidget, green);

    const yellow_s = [_][]const u8{"Yellow"};
    const yellow = qtreewidgetitem.New4(treewidget, &yellow_s, allocator);
    qtreewidget.ExpandItem(treewidget, yellow);

    create2ndLevel(red);
    create2ndLevel(blue);
    create2ndLevel(green);
    create2ndLevel(yellow);

    const vboxlayout = qvboxlayout.New(dialog);
    const hboxlayout = qhboxlayout.New2();

    const case_sensitive = qpushbutton.New5("&Case Sensitive", dialog);
    qhboxlayout.AddWidget(hboxlayout, case_sensitive);

    qpushbutton.SetCheckable(case_sensitive, true);
    qpushbutton.OnToggled(case_sensitive, switchCaseSensitivity);

    const keep_parents_visible = qpushbutton.New5("Keep &Parents Visible", dialog);
    qhboxlayout.AddWidget(hboxlayout, keep_parents_visible);

    qpushbutton.SetCheckable(keep_parents_visible, true);
    qpushbutton.SetChecked(keep_parents_visible, true);
    qpushbutton.OnToggled(keep_parents_visible, switchKeepParentsVisible);

    const buttonbox = qdialogbuttonbox.New(dialog);
    qdialogbuttonbox.SetStandardButtons(buttonbox, qdialogbuttonbox_enums.StandardButton.Ok | qdialogbuttonbox_enums.StandardButton.Cancel);

    qdialogbuttonbox.OnAccepted(buttonbox, onAccepted);
    qdialogbuttonbox.OnRejected(buttonbox, onRejected);

    qvboxlayout.AddWidget(vboxlayout, searchwidget);
    qvboxlayout.AddWidget(vboxlayout, treewidget);
    qvboxlayout.AddLayout(vboxlayout, hboxlayout);
    qvboxlayout.AddWidget(vboxlayout, buttonbox);

    ktreewidgetsearchline.SetFocus(m_searchline);
    qdialog.Resize(dialog, 350, 600);
    qdialog.OnShowEvent(dialog, showEvent);

    _ = qdialog.Exec(dialog);
}

fn create2ndLevel(item: C.QTreeWidgetItem) void {
    const beans_s = [_][]const u8{"Beans"};
    const beans = qtreewidgetitem.New7(item, &beans_s, allocator);
    qtreewidget.ExpandItem(treewidget, beans);
    create3rdLevel(beans);

    const grapes_s = [_][]const u8{"Grapes"};
    const grapes = qtreewidgetitem.New7(item, &grapes_s, allocator);
    qtreewidget.ExpandItem(treewidget, grapes);
    create3rdLevel(grapes);

    const plums_s = [_][]const u8{"Plums"};
    const plums = qtreewidgetitem.New7(item, &plums_s, allocator);
    qtreewidget.ExpandItem(treewidget, plums);
    create3rdLevel(plums);

    const bananas_s = [_][]const u8{"Bananas"};
    const bananas = qtreewidgetitem.New7(item, &bananas_s, allocator);
    qtreewidget.ExpandItem(treewidget, bananas);
    create3rdLevel(bananas);
}

fn create3rdLevel(item: C.QTreeWidgetItem) void {
    const growing = [_][]const u8{ "Growing", "$2.00", "", "Farmer" };
    _ = qtreewidgetitem.New7(item, &growing, allocator);
    const ripe = [_][]const u8{ "Ripe", "$8.00", "", "Market" };
    _ = qtreewidgetitem.New7(item, &ripe, allocator);
    const decaying = [_][]const u8{ "Decaying", "$0.50", "", "Ground" };
    _ = qtreewidgetitem.New7(item, &decaying, allocator);
    const pickled = [_][]const u8{ "Pickled", "$4.00", "", "Shop" };
    _ = qtreewidgetitem.New7(item, &pickled, allocator);
}

fn switchCaseSensitivity(_: ?*anyopaque, checked: bool) callconv(.c) void {
    ktreewidgetsearchline.SetCaseSensitivity(m_searchline, if (checked) qnamespace_enums.CaseSensitivity.CaseSensitive else qnamespace_enums.CaseSensitivity.CaseInsensitive);
}

fn switchKeepParentsVisible(_: ?*anyopaque, checked: bool) callconv(.c) void {
    ktreewidgetsearchline.SetKeepParentsVisible(m_searchline, checked);
}

fn onAccepted(_: ?*anyopaque) callconv(.c) void {
    qdialog.Accept(dialog);
}

fn onRejected(_: ?*anyopaque) callconv(.c) void {
    qdialog.Reject(dialog);
}

fn showEvent(self: ?*anyopaque, event: ?*anyopaque) callconv(.c) void {
    qdialog.QBaseShowEvent(self, event);

    const headerview = qtreewidget.Header(treewidget);
    for (0..@intCast(qheaderview.Count(headerview))) |i| {
        if (!qheaderview.IsSectionHidden(headerview, @intCast(i))) {
            qtreewidget.ResizeColumnToContents(treewidget, @intCast(i));
        }
    }
}
