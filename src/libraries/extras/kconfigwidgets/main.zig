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
    const qapp: QApplication = .new(init.arena.allocator(), &argc, argv);
    defer qapp.delete();

    const window = QMainWindow.new2();
    defer window.delete();

    window.setWindowTitle("Qt 6 KConfigWidgets");
    window.setMinimumSize2(400, 450);
    manager = .instance();
    defer manager.delete();

    const listview = QListView.new(window);
    const manager_model = manager.model();
    listview.setModel(manager_model);
    listview.onClicked(onClicked);

    const box = QDialogButtonBox.new7(qdialogbuttonbox_enums.StandardButton.Close, window);
    box.onRejected(onRejected);

    const widget = QWidget.new2();
    const layout = QVBoxLayout.new(widget);
    layout.addWidget(listview);
    layout.addWidget(box);

    window.setCentralWidget(widget);

    const menu = QMenu.new4("Menu", window);
    const manager_menu = KColorSchemeMenu.createMenu(manager, window);
    menu.addAction(manager_menu);
    _ = window.menuBar().addMenu(menu);

    window.show();

    _ = QApplication.exec();
}

fn onClicked(_: QListView, index: QModelIndex) callconv(.c) void {
    manager.activateScheme(index);
}

fn onRejected(_: QDialogButtonBox) callconv(.c) void {
    QApplication.quit();
}
