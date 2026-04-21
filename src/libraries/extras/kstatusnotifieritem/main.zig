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
    const qapp = QApplication.New(init.arena.allocator(), &argc, argv);
    defer qapp.Delete();

    allocator = init.gpa;

    status_notifier_item = KStatusNotifierItem.New2("org.libqt6zig.kstatusnotifieritemexample");
    defer status_notifier_item.Delete();

    const red_icon = createIcon(qnamespace_enums.GlobalColor.Red);
    defer red_icon.Delete();

    status_notifier_item.SetIconByPixmap(red_icon);
    status_notifier_item.SetCategory(kstatusnotifieritem_enums.ItemCategory.Communications);
    status_notifier_item.SetStatus(kstatusnotifieritem_enums.ItemStatus.Active);
    status_notifier_item.SetToolTipTitle(title);

    const green_icon = createIcon(qnamespace_enums.GlobalColor.Green);
    defer green_icon.Delete();

    const menu = QMenu.New2();
    const attention_action = menu.AddAction3(green_icon, "NeedsAttention");
    attention_action.OnTriggered(onTriggered);

    const magenta_icon = createIcon(qnamespace_enums.GlobalColor.Magenta);
    defer magenta_icon.Delete();

    const active_action = menu.AddAction3(magenta_icon, "Active");
    active_action.OnTriggered(onTriggered);

    const sub_menu = QMenu.New3("Sub Menu");
    const menu_icon = createIcon(qnamespace_enums.GlobalColor.DarkBlue);
    defer menu_icon.Delete();

    sub_menu.SetIcon(menu_icon);

    const yellow_icon = createIcon(qnamespace_enums.GlobalColor.Yellow);
    defer yellow_icon.Delete();

    const sub_action = sub_menu.AddAction3(yellow_icon, "Passive");
    sub_action.OnTriggered(onTriggered);

    _ = menu.AddMenu(sub_menu);
    status_notifier_item.SetContextMenu(menu);
    status_notifier_item.OnActivateRequested(onActivateRequested);
    status_notifier_item.OnSecondaryActivateRequested(onSecondaryActivateRequested);
    status_notifier_item.OnScrollRequested(onScrollRequested);

    _ = QMessageBox.Information(
        QWidget{ .ptr = null },
        title,
        "Check your system tray for the status notifier item icon.\n\n" ++
            "In order to quit the example, close the text edit window or quit via the system tray menu.",
    );

    text_edit = QTextEdit.New3("Logged activity:");
    defer text_edit.Delete();

    text_edit.SetReadOnly(true);
    text_edit.SetMinimumSize2(400, 300);
    text_edit.SetWindowTitle(title);
    text_edit.OnCloseEvent(onCloseEvent);

    text_edit.Show();

    _ = QApplication.Exec();
}

fn createIcon(color: i32) QIcon {
    const pixmap = QPixmap.New2(16, 16);
    defer pixmap.Delete();

    const fill_color = QColor.New4(color);
    defer fill_color.Delete();

    pixmap.Fill1(fill_color);

    return QIcon.New2(pixmap);
}

fn onTriggered(self: QAction) callconv(.c) void {
    const text = self.Text(allocator);
    defer allocator.free(text);

    if (std.mem.eql(u8, text, "NeedsAttention")) {
        const icon = createIcon(qnamespace_enums.GlobalColor.Blue);
        defer icon.Delete();

        status_notifier_item.SetIconByPixmap(icon);
        status_notifier_item.SetStatus(kstatusnotifieritem_enums.ItemStatus.NeedsAttention);
    } else if (std.mem.eql(u8, text, "Active")) {
        const icon = createIcon(qnamespace_enums.GlobalColor.Red);
        defer icon.Delete();

        status_notifier_item.SetIconByPixmap(icon);
        status_notifier_item.SetStatus(kstatusnotifieritem_enums.ItemStatus.Active);
    } else if (std.mem.eql(u8, text, "Passive"))
        status_notifier_item.SetStatus(kstatusnotifieritem_enums.ItemStatus.Passive);
}

fn onActivateRequested(_: KStatusNotifierItem, active: bool, pos: QPoint) callconv(.c) void {
    const text = std.fmt.allocPrint(
        allocator,
        "Activated: active = {any}, pos = ({d}, {d})",
        .{ active, pos.X(), pos.Y() },
    ) catch @panic("Failed to allocPrint");
    defer allocator.free(text);

    text_edit.Append(text);
}

fn onSecondaryActivateRequested(_: KStatusNotifierItem, pos: QPoint) callconv(.c) void {
    const text = std.fmt.allocPrint(
        allocator,
        "Secondary Activated: pos = ({d}, {d})",
        .{ pos.X(), pos.Y() },
    ) catch @panic("Failed to allocPrint");
    defer allocator.free(text);

    text_edit.Append(text);
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

    text_edit.Append(text);
}

fn onCloseEvent(_: QTextEdit, _: QCloseEvent) callconv(.c) void {
    QApplication.Quit();
}
