const std = @import("std");
const qt6 = @import("libqt6zig");
const C = qt6.C;
const qapplication = qt6.qapplication;
const qmainwindow = qt6.qmainwindow;
const kcolorschememanager = qt6.kcolorschememanager;
const qlistview = qt6.qlistview;
const qdialogbuttonbox = qt6.qdialogbuttonbox;
const qdialogbuttonbox_enums = qt6.qdialogbuttonbox_enums;
const qwidget = qt6.qwidget;
const qvboxlayout = qt6.qvboxlayout;
const qmenu = qt6.qmenu;
const kcolorschememenu = qt6.kcolorschememenu;
const qmenubar = qt6.qmenubar;

var manager: C.KColorSchemeManager = null;

pub fn main() void {
    const argc = std.os.argv.len;
    const argv = std.os.argv.ptr;
    const qapp = qapplication.New(argc, argv);
    defer qapplication.Delete(qapp);

    const window = qmainwindow.New2();
    defer qmainwindow.Delete(window);
    qmainwindow.SetWindowTitle(window, "Qt 6 KConfigWidgets");
    qmainwindow.SetMinimumSize2(window, 400, 450);
    manager = kcolorschememanager.Instance();
    const listview = qlistview.New(window);
    const manager_model = kcolorschememanager.Model(manager);
    qlistview.SetModel(listview, manager_model);
    qlistview.OnClicked(listview, onClicked);

    const box = qdialogbuttonbox.New7(qdialogbuttonbox_enums.StandardButton.Close, window);
    qdialogbuttonbox.OnRejected(box, quit_callback);

    const widget = qwidget.New2();
    const layout = qvboxlayout.New(widget);
    qvboxlayout.AddWidget(layout, listview);
    qvboxlayout.AddWidget(layout, box);

    qmainwindow.SetCentralWidget(window, widget);

    const menu = qmenu.New4("Menu", window);
    const manager_menu = kcolorschememenu.CreateMenu(manager, window);
    qmenu.AddAction(menu, manager_menu);
    _ = qmenubar.AddMenu(qmainwindow.MenuBar(window), menu);

    qmainwindow.Show(window);

    _ = qapplication.Exec();
}

fn onClicked(_: ?*anyopaque, index: ?*anyopaque) callconv(.c) void {
    kcolorschememanager.ActivateScheme(manager, index);
}

fn quit_callback(_: ?*anyopaque) callconv(.c) void {
    qapplication.Quit();
}
