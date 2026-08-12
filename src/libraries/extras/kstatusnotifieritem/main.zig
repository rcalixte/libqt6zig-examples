const std = @import("std");
const qt6 = @import("libqt6zig");
const QApplication = qt6.QApplication;
const QObject = qt6.QObject;
const KStatusNotifierItem = qt6.KStatusNotifierItem;
const qnamespace_enums = qt6.qnamespace_enums;
const kstatusnotifieritem_enums = qt6.kstatusnotifieritem_enums;
const QMenu = qt6.QMenu;
const QMessageBox = qt6.QMessageBox;
const QWidget = qt6.QWidget;
const QTextEdit = qt6.QTextEdit;
const QIcon = qt6.QIcon;
const QColor = qt6.QColor;
const QPixmap = qt6.QPixmap;
const QAction = qt6.QAction;
const QPoint = qt6.QPoint;
const QCloseEvent = qt6.QCloseEvent;

var allocator: std.mem.Allocator = undefined;
var status_notifier_item: KStatusNotifierItem = undefined;
var text_edit: QTextEdit = undefined;
const title = "Qt 6 KStatusNotifierItem Example";

pub fn main(init: std.process.Init) !void {
    const argv = try qt6.init(init.gpa, init.minimal.args);
    defer qt6.deinit(init.gpa, argv);
    var argc: i32 = @intCast(argv.len);
    const qapp: QApplication = .new(init.arena.allocator(), &argc, argv);
    defer qapp.delete();

    allocator = init.gpa;

    status_notifier_item = .new2("org.libqt6zig.kstatusnotifieritemexample");
    defer status_notifier_item.delete();

    const red_icon = createIcon(qnamespace_enums.GlobalColor.Red);
    defer red_icon.delete();

    status_notifier_item.setIconByPixmap(red_icon);
    status_notifier_item.setCategory(kstatusnotifieritem_enums.ItemCategory.Communications);
    status_notifier_item.setStatus(kstatusnotifieritem_enums.ItemStatus.Active);
    status_notifier_item.setToolTipTitle(title);

    const green_icon = createIcon(qnamespace_enums.GlobalColor.Green);
    defer green_icon.delete();

    const menu = QMenu.new2();
    const attention_action = menu.addAction3(green_icon, "NeedsAttention");
    attention_action.onTriggered(onTriggered);

    const magenta_icon = createIcon(qnamespace_enums.GlobalColor.Magenta);
    defer magenta_icon.delete();

    const active_action = menu.addAction3(magenta_icon, "Active");
    active_action.onTriggered(onTriggered);

    const sub_menu = QMenu.new3("Sub Menu");
    defer sub_menu.delete();

    const menu_icon = createIcon(qnamespace_enums.GlobalColor.DarkBlue);
    defer menu_icon.delete();

    sub_menu.setIcon(menu_icon);

    const yellow_icon = createIcon(qnamespace_enums.GlobalColor.Yellow);
    defer yellow_icon.delete();

    const sub_action = sub_menu.addAction3(yellow_icon, "Passive");
    sub_action.onTriggered(onTriggered);

    _ = menu.addMenu(sub_menu);
    status_notifier_item.setContextMenu(menu);
    status_notifier_item.onActivateRequested(onActivateRequested);
    status_notifier_item.onSecondaryActivateRequested(onSecondaryActivateRequested);
    status_notifier_item.onScrollRequested(onScrollRequested);

    _ = QMessageBox.information(
        QWidget{ .ptr = null },
        title,
        "Check your system tray for the status notifier item icon.\n\n" ++
            "In order to quit the example, close the text edit window or quit via the system tray menu.",
    );

    text_edit = .new3("Logged activity:");
    defer text_edit.delete();

    text_edit.setReadOnly(true);
    text_edit.setMinimumSize2(400, 300);
    text_edit.setWindowTitle(title);
    text_edit.onCloseEvent(onCloseEvent);

    text_edit.show();

    _ = QApplication.exec();
}

fn createIcon(color: i32) QIcon {
    const pixmap = QPixmap.new2(16, 16);
    defer pixmap.delete();

    const fill_color = QColor.new4(color);
    defer fill_color.delete();

    pixmap.fill1(fill_color);

    return .new2(pixmap);
}

fn onTriggered(self: QAction) callconv(.c) void {
    const text = self.text(allocator);
    defer allocator.free(text);

    if (std.mem.eql(u8, text, "NeedsAttention")) {
        const icon = createIcon(qnamespace_enums.GlobalColor.Blue);
        defer icon.delete();

        status_notifier_item.setIconByPixmap(icon);
        status_notifier_item.setStatus(kstatusnotifieritem_enums.ItemStatus.NeedsAttention);
    } else if (std.mem.eql(u8, text, "Active")) {
        const icon = createIcon(qnamespace_enums.GlobalColor.Red);
        defer icon.delete();

        status_notifier_item.setIconByPixmap(icon);
        status_notifier_item.setStatus(kstatusnotifieritem_enums.ItemStatus.Active);
    } else if (std.mem.eql(u8, text, "Passive"))
        status_notifier_item.setStatus(kstatusnotifieritem_enums.ItemStatus.Passive);
}

fn onActivateRequested(_: KStatusNotifierItem, active: bool, pos: QPoint) callconv(.c) void {
    const text = std.fmt.allocPrint(
        allocator,
        "Activated: active = {any}, pos = ({d}, {d})",
        .{ active, pos.x(), pos.y() },
    ) catch @panic("Failed to allocPrint");
    defer allocator.free(text);

    text_edit.append(text);
}

fn onSecondaryActivateRequested(_: KStatusNotifierItem, pos: QPoint) callconv(.c) void {
    const text = std.fmt.allocPrint(
        allocator,
        "Secondary Activated: pos = ({d}, {d})",
        .{ pos.x(), pos.y() },
    ) catch @panic("Failed to allocPrint");
    defer allocator.free(text);

    text_edit.append(text);
}

fn onScrollRequested(_: KStatusNotifierItem, delta: i32, orientation: i32) callconv(.c) void {
    const direction = if (orientation == qnamespace_enums.Orientation.Horizontal)
        "Horizontally"
    else
        "Vertically";
    const text = std.fmt.allocPrint(
        allocator,
        "Scrolled {s}: delta = {d}",
        .{ direction, delta },
    ) catch @panic("Failed to allocPrint");
    defer allocator.free(text);

    text_edit.append(text);
}

fn onCloseEvent(_: QTextEdit, _: QCloseEvent) callconv(.c) void {
    QApplication.quit();
}
