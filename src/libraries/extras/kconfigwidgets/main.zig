const std = @import("std");
const qt6 = @import("libqt6zig");
const QApplication = qt6.QApplication;
const QMainWindow = qt6.QMainWindow;
const KColorSchemeManager = qt6.KColorSchemeManager;
const QListView = qt6.QListView;
const QDialogButtonBox = qt6.QDialogButtonBox;
const qdialogbuttonbox_enums = qt6.qdialogbuttonbox_enums;
const QWidget = qt6.QWidget;
const QVBoxLayout = qt6.QVBoxLayout;
const QMenu = qt6.QMenu;
const KColorSchemeMenu = qt6.KColorSchemeMenu;
const QModelIndex = qt6.QModelIndex;

var manager: KColorSchemeManager = undefined;

pub fn main(init: std.process.Init) !void {
    const argv = try qt6.init(init.gpa, init.minimal.args);
    defer qt6.deinit(init.gpa, argv);
    var argc: i32 = @intCast(argv.len);
    const qapp = QApplication.New(init.arena.allocator(), &argc, argv);
    defer qapp.Delete();

    const window = QMainWindow.New2();
    defer window.Delete();
    window.SetWindowTitle("Qt 6 KConfigWidgets");
    window.SetMinimumSize2(400, 450);
    manager = KColorSchemeManager.Instance();
    const listview = QListView.New(window);
    const manager_model = manager.Model();
    listview.SetModel(manager_model);
    listview.OnClicked(onClicked);

    const box = QDialogButtonBox.New7(qdialogbuttonbox_enums.StandardButton.Close, window);
    box.OnRejected(quit_callback);

    const widget = QWidget.New2();
    const layout = QVBoxLayout.New(widget);
    layout.AddWidget(listview);
    layout.AddWidget(box);

    window.SetCentralWidget(widget);

    const menu = QMenu.New4("Menu", window);
    const manager_menu = KColorSchemeMenu.CreateMenu(manager, window);
    menu.AddAction(manager_menu);
    _ = window.MenuBar().AddMenu(menu);

    window.Show();

    _ = QApplication.Exec();
}

fn onClicked(_: QListView, index: QModelIndex) callconv(.c) void {
    manager.ActivateScheme(index);
}

fn quit_callback(_: QDialogButtonBox) callconv(.c) void {
    QApplication.Quit();
}
