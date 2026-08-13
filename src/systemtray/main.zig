const std = @import("std");
const qt6 = @import("libqt6zig");
const QApplication = qt6.QApplication;
const QSystemTrayIcon = qt6.QSystemTrayIcon;
const QMessageBox = qt6.QMessageBox;
const QWidget = qt6.QWidget;
const QDialog = qt6.QDialog;
const QStyleOption = qt6.QStyleOption;
const QGroupBox = qt6.QGroupBox;
const QLabel = qt6.QLabel;
const QComboBox = qt6.QComboBox;
const qicon_enums = qt6.qicon_enums;
const qsystemtrayicon_enums = qt6.qsystemtrayicon_enums;
const QVariant = qt6.QVariant;
const qstyle_enums = qt6.qstyle_enums;
const QSpinBox = qt6.QSpinBox;
const QTextEdit = qt6.QTextEdit;
const QPushButton = qt6.QPushButton;
const QGridLayout = qt6.QGridLayout;
const QLineEdit = qt6.QLineEdit;
const QAction = qt6.QAction;
const QMenu = qt6.QMenu;
const QVBoxLayout = qt6.QVBoxLayout;

var type_combo: QComboBox = undefined;
var dialog: QDialog = undefined;
var duration_spinbox: QSpinBox = undefined;
var title_edit: QLineEdit = undefined;
var body_edit: QTextEdit = undefined;
var tray_icon: QSystemTrayIcon = undefined;

var allocator: std.mem.Allocator = undefined;

const window_title = "Qt 6 System Tray Example";

pub fn main(init: std.process.Init) !void {
    const argv = try qt6.init(init.gpa, init.minimal.args);
    defer qt6.deinit(init.gpa, argv);
    var argc: i32 = @intCast(argv.len);
    const qapp: QApplication = .new(init.arena.allocator(), &argc, argv);
    defer qapp.delete();

    if (!QSystemTrayIcon.isSystemTrayAvailable()) {
        _ = QMessageBox.critical(
            QWidget{ .ptr = null },
            window_title,
            "No system tray available.",
        );
        return;
    }

    allocator = init.gpa;

    QApplication.setQuitOnLastWindowClosed(false);

    const message_box = QGroupBox.new3("Balloon Message");
    type_combo = .new2();

    const no_variant = QVariant.new4(qsystemtrayicon_enums.MessageIcon.NoIcon);
    defer no_variant.delete();

    const info_variant = QVariant.new4(qsystemtrayicon_enums.MessageIcon.Information);
    defer info_variant.delete();

    const warn_variant = QVariant.new4(qsystemtrayicon_enums.MessageIcon.Warning);
    defer warn_variant.delete();

    const crit_variant = QVariant.new4(qsystemtrayicon_enums.MessageIcon.Critical);
    defer crit_variant.delete();

    dialog = .new2();
    dialog.setWindowTitle(window_title);
    dialog.resize(400, 300);
    const style = dialog.style();

    const info_icon = style.standardIcon(
        qstyle_enums.StandardPixmap.SP_MessageBoxInformation,
        QStyleOption{ .ptr = null },
        QWidget{ .ptr = null },
    );
    defer info_icon.delete();

    const warn_icon = style.standardIcon(
        qstyle_enums.StandardPixmap.SP_MessageBoxWarning,
        QStyleOption{ .ptr = null },
        QWidget{ .ptr = null },
    );
    defer warn_icon.delete();

    const crit_icon = style.standardIcon(
        qstyle_enums.StandardPixmap.SP_MessageBoxCritical,
        QStyleOption{ .ptr = null },
        QWidget{ .ptr = null },
    );
    defer crit_icon.delete();

    type_combo.addItem22("None", no_variant);
    type_combo.addItem3(info_icon, "Information", info_variant);
    type_combo.addItem3(warn_icon, "Warning", warn_variant);
    type_combo.addItem3(crit_icon, "Critical", crit_variant);
    type_combo.setCurrentIndex(1);

    const duration_label = QLabel.new3("Duration:");
    duration_spinbox = .new2();
    duration_spinbox.setRange(5, 60);
    duration_spinbox.setSuffix(" s");
    duration_spinbox.setValue(15);

    const warning_label = QLabel.new3("(some systems might ignore this hint)");
    warning_label.setIndent(10);

    title_edit = .new3("Cannot connect to network");
    body_edit = .new2();
    body_edit.setPlainText(
        \\Don't believe me. Honestly, I don't have a clue.
        \\Click this balloon for details.
    );

    const quit_button = QPushButton.new3("&Quit");
    quit_button.setFixedWidth(100);
    quit_button.onClicked(onQuitButton);

    const show_button = QPushButton.new3("Show Message");
    show_button.setDefault(true);
    show_button.onClicked(onShowMessage);

    const message_layout = QGridLayout.new2();
    message_layout.addWidget2(QLabel.new3("Type:"), 0, 0);
    message_layout.addWidget3(type_combo, 0, 1, 1, 2);
    message_layout.addWidget2(duration_label, 1, 0);
    message_layout.addWidget2(duration_spinbox, 1, 1);
    message_layout.addWidget3(warning_label, 1, 2, 1, 3);
    message_layout.addWidget2(QLabel.new3("Title"), 2, 0);
    message_layout.addWidget3(title_edit, 2, 1, 1, 4);
    message_layout.addWidget2(QLabel.new3("Body:"), 3, 0);
    message_layout.addWidget3(body_edit, 3, 1, 2, 4);
    message_layout.addWidget2(show_button, 5, 4);
    message_layout.setColumnStretch(3, 1);
    message_layout.setRowStretch(4, 1);
    message_box.setLayout(message_layout);

    const minimize_action = QAction.new5("Mi&nimize", dialog);
    minimize_action.onTriggered(onMinimize);

    const maximize_action = QAction.new5("Ma&ximize", dialog);
    maximize_action.onTriggered(onMaximize);

    const restore_action = QAction.new5("&Restore", dialog);
    restore_action.onTriggered(onRestore);

    const quit_action = QAction.new5("&Quit", dialog);
    quit_action.onTriggered(onQuit);

    const tray_menu = QMenu.new(dialog);
    tray_menu.addAction(minimize_action);
    tray_menu.addAction(maximize_action);
    tray_menu.addAction(restore_action);
    _ = tray_menu.addSeparator();
    tray_menu.addAction(quit_action);

    tray_icon = .new3(dialog);
    tray_icon.setContextMenu(tray_menu);
    tray_icon.onMessageClicked(onMessageClicked);

    const layout = QVBoxLayout.new2();
    layout.addWidget(message_box);
    layout.addWidget(quit_button);
    dialog.setLayout(layout);
    dialog.setWindowIcon(info_icon);
    tray_icon.setIcon(info_icon);

    tray_icon.show();
    dialog.show();

    _ = QApplication.exec();
}

fn onQuitButton(_: QPushButton) callconv(.c) void {
    QApplication.quit();
}

fn onShowMessage(_: QPushButton) callconv(.c) void {
    const type_variant = type_combo.itemData(type_combo.currentIndex());
    defer type_variant.delete();

    const selected_icon = type_variant.toInt();

    const title_text = title_edit.text(allocator);
    defer allocator.free(title_text);

    const msg_text = body_edit.toPlainText(allocator);
    defer allocator.free(msg_text);

    tray_icon.showMessage42(
        title_text,
        msg_text,
        selected_icon,
        duration_spinbox.value() * 1000,
    );
}

fn onMinimize(_: QAction) callconv(.c) void {
    dialog.hide();
}

fn onMaximize(_: QAction) callconv(.c) void {
    dialog.showMaximized();
}

fn onRestore(_: QAction) callconv(.c) void {
    dialog.showNormal();
}

fn onQuit(_: QAction) callconv(.c) void {
    QApplication.quit();
}

fn onMessageClicked(_: QSystemTrayIcon) callconv(.c) void {
    _ = QMessageBox.information(dialog, window_title,
        \\Sorry, I already gave what help I could.
        \\Maybe you should try asking a human?
    );
}
