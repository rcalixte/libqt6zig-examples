const std = @import("std");
const qt6 = @import("libqt6zig");
const QApplication = qt6.QApplication;
const QWidget = qt6.QWidget;
const QLabel = qt6.QLabel;
const qsizepolicy_enums = qt6.qsizepolicy_enums;
const qnamespace_enums = qt6.qnamespace_enums;
const QResizeEvent = qt6.QResizeEvent;
const QVBoxLayout = qt6.QVBoxLayout;
const QGroupBox = qt6.QGroupBox;
const QSpinBox = qt6.QSpinBox;
const QCheckBox = qt6.QCheckBox;
const QGridLayout = qt6.QGridLayout;
const QPushButton = qt6.QPushButton;
const QKeySequence = qt6.QKeySequence;
const QHBoxLayout = qt6.QHBoxLayout;
const QTimer = qt6.QTimer;
const QPoint = qt6.QPoint;
const QPixmap = qt6.QPixmap;
const QStandardPaths = qt6.QStandardPaths;
const qstandardpaths_enums = qt6.qstandardpaths_enums;
const QDir = qt6.QDir;
const QFileDialog = qt6.QFileDialog;
const qfiledialog_enums = qt6.qfiledialog_enums;
const QImageWriter = qt6.QImageWriter;
const qdialog_enums = qt6.qdialog_enums;
const QMessageBox = qt6.QMessageBox;

var allocator: std.mem.Allocator = undefined;

var screenshot: QWidget = undefined;
var screenshot_label: QLabel = undefined;
var delay_spinbox: QSpinBox = undefined;
var hide_checkbox: QCheckBox = undefined;
var new_button: QPushButton = undefined;
var original_pixmap: QPixmap = undefined;

const format = "png";

pub fn main(init: std.process.Init) !void {
    const argv = try qt6.init(init.gpa, init.minimal.args);
    defer qt6.deinit(init.gpa, argv);
    var argc: i32 = @intCast(argv.len);
    const qapp: QApplication = .new(init.arena.allocator(), &argc, argv);
    defer qapp.delete();

    allocator = init.gpa;

    screenshot = .new2();
    defer screenshot.delete();

    screenshot.setWindowTitle("Qt 6 Screenshot Example");
    screenshot.setMinimumSize2(400, 300);

    screenshot_label = .new5("Take a screenshot", screenshot);
    screenshot_label.setSizePolicy2(
        qsizepolicy_enums.Policy.Expanding,
        qsizepolicy_enums.Policy.Expanding,
    );
    screenshot_label.setAlignment(qnamespace_enums.AlignmentFlag.AlignCenter);

    const screen = screenshot.screen();

    const rect = screen.geometry();
    defer rect.delete();

    screenshot_label.setMinimumSize2(
        @divTrunc(rect.width(), 8),
        @divTrunc(rect.height(), 8),
    );

    const main_layout = QVBoxLayout.new(screenshot);
    main_layout.addWidget(screenshot_label);

    const options_groupbox = QGroupBox.new4("Options", screenshot);

    delay_spinbox = .new(options_groupbox);
    delay_spinbox.setSuffix(" s");
    delay_spinbox.setMaximum(60);
    delay_spinbox.setMinimum(0);
    delay_spinbox.onValueChanged(onDelayChanged);

    hide_checkbox = .new4("Hide This Window", options_groupbox);

    const options_layout = QGridLayout.new(options_groupbox);
    options_layout.addWidget2(
        QLabel.new5("Screenshot Delay:", screenshot),
        0,
        0,
    );
    options_layout.addWidget2(delay_spinbox, 0, 1);
    options_layout.addWidget3(hide_checkbox, 1, 0, 1, 2);

    main_layout.addWidget(options_groupbox);

    new_button = .new5("New Screenshot", screenshot);
    new_button.onClicked(newScreenshot);

    const save_button = QPushButton.new5("Save Screenshot", screenshot);
    save_button.onClicked(saveScreenshot);

    const quit_shortcut = QKeySequence.new3(
        qnamespace_enums.KeyboardModifier.ControlModifier | qnamespace_enums.Key.Key_Q,
    );
    defer quit_shortcut.delete();

    const quit_button = QPushButton.new5("Quit", screenshot);
    quit_button.onClicked(onQuit);
    quit_button.setShortcut(quit_shortcut);

    const buttons_layout = QHBoxLayout.new2();
    buttons_layout.addWidget(new_button);
    buttons_layout.addWidget(save_button);
    buttons_layout.addWidget(quit_button);
    buttons_layout.addStretch();

    main_layout.addLayout(buttons_layout);

    shootScreenshot();

    delay_spinbox.setValue(5);

    const available_geometry = screen.availableGeometry();
    defer available_geometry.delete();

    const top_left_point = available_geometry.topLeft();
    defer top_left_point.delete();

    const offset = QPoint.new4(50, 50);
    defer offset.delete();

    _ = top_left_point.operatorPlusAssign(offset);

    screenshot.move2(top_left_point);
    screenshot.onResizeEvent(onResizeEvent);

    screenshot.show();

    _ = QApplication.exec();
}

fn onDelayChanged(_: QSpinBox, value: i32) callconv(.c) void {
    if (value == 0) {
        hide_checkbox.setDisabled(true);
        hide_checkbox.setChecked(false);
    } else {
        hide_checkbox.setDisabled(false);
    }
}

fn newScreenshot(_: QPushButton) callconv(.c) void {
    if (hide_checkbox.isChecked())
        screenshot.hide();

    const timer = QTimer.new2(screenshot);
    timer.setSingleShot(true);
    timer.onTimeout(onTimeout);
    timer.start3(delay_spinbox.value() * 1000);
}

fn onTimeout(_: QTimer) callconv(.c) void {
    shootScreenshot();
}

fn saveScreenshot(_: QPushButton) callconv(.c) void {
    var initial_path = QStandardPaths.writableLocation(
        allocator,
        qstandardpaths_enums.StandardLocation.PicturesLocation,
    );
    defer allocator.free(initial_path);

    if (initial_path.len == 0) {
        allocator.free(initial_path);

        initial_path = QDir.currentPath(allocator);
    }

    const out_path = std.fmt.allocPrint(
        allocator,
        "{s}/untitled.{s}",
        .{ initial_path, format },
    ) catch @panic("Failed to allocPrint");
    defer allocator.free(out_path);

    const file_dialog = QFileDialog.new5(screenshot, "Save As", out_path);
    file_dialog.setAcceptMode(qfiledialog_enums.AcceptMode.AcceptSave);
    file_dialog.setFileMode(qfiledialog_enums.FileMode.AnyFile);
    file_dialog.setDirectory(out_path);

    const mimetypes = QImageWriter.supportedMimeTypes(allocator);
    defer {
        for (mimetypes) |mimetype|
            allocator.free(mimetype);
        allocator.free(mimetypes);
    }

    file_dialog.setMimeTypeFilters(allocator, mimetypes);
    file_dialog.selectMimeTypeFilter("image/" ++ format);
    file_dialog.setDefaultSuffix(format);

    if (file_dialog.exec() != qdialog_enums.DialogCode.Accepted)
        return;

    const selected_files = file_dialog.selectedFiles(allocator);
    defer {
        for (selected_files) |file|
            allocator.free(file);
        allocator.free(selected_files);
    }

    if (selected_files.len == 0)
        return;

    if (!original_pixmap.save(selected_files[0])) {
        const save_path = QDir.toNativeSeparators(allocator, selected_files[0]);
        defer allocator.free(save_path);

        const error_message = std.fmt.allocPrint(
            allocator,
            "Failed to save screenshot to {s}",
            .{save_path},
        ) catch @panic("Failed to allocPrint");
        defer allocator.free(error_message);

        _ = QMessageBox.warning(screenshot, "Save Error", error_message);
    }
}

fn onQuit(_: QPushButton) callconv(.c) void {
    QApplication.quit();
}

fn shootScreenshot() void {
    var screen = QApplication.primaryScreen();
    const window = screenshot.windowHandle();

    if (window.ptr != null)
        screen = window.screen();

    if (screen.ptr == null)
        return;

    if (delay_spinbox.value() != 0)
        QApplication.beep();

    original_pixmap = screen.grabWindow1(0);
    updateScreenshotLabel();

    new_button.setDisabled(false);
    if (hide_checkbox.isChecked())
        screenshot.show();
}

fn onResizeEvent(_: QWidget, _: QResizeEvent) callconv(.c) void {
    const scaled_size = original_pixmap.size();
    defer scaled_size.delete();

    const label_size = screenshot_label.size();
    defer label_size.delete();

    scaled_size.scale2(label_size, qnamespace_enums.AspectRatioMode.KeepAspectRatio);

    const pixmap = screenshot_label.pixmap2();
    defer pixmap.delete();

    const size = pixmap.size();
    defer size.delete();

    if (scaled_size.ptr != size.ptr)
        updateScreenshotLabel();
}

fn updateScreenshotLabel() void {
    const size = screenshot_label.size();
    defer size.delete();

    const pixmap = original_pixmap.scaled32(
        size,
        qnamespace_enums.AspectRatioMode.KeepAspectRatio,
        qnamespace_enums.TransformationMode.SmoothTransformation,
    );
    defer pixmap.delete();

    screenshot_label.setPixmap(pixmap);
}
