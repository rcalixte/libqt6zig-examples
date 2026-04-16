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
    const qapp = QApplication.New(init.arena.allocator(), &argc, argv);
    defer qapp.Delete();

    screenshot = QWidget.New2();
    defer screenshot.Delete();

    screenshot.SetWindowTitle("Qt 6 Screenshot Example");
    screenshot.SetMinimumSize2(400, 300);

    screenshot_label = QLabel.New5("Take a screenshot", screenshot);
    screenshot_label.SetSizePolicy2(
        qsizepolicy_enums.Policy.Expanding,
        qsizepolicy_enums.Policy.Expanding,
    );
    screenshot_label.SetAlignment(qnamespace_enums.AlignmentFlag.AlignCenter);

    const screen = screenshot.Screen();

    const rect = screen.Geometry();
    defer rect.Delete();

    screenshot_label.SetMinimumSize2(
        @divTrunc(rect.Width(), 8),
        @divTrunc(rect.Height(), 8),
    );

    const main_layout = QVBoxLayout.New(screenshot);
    main_layout.AddWidget(screenshot_label);

    const options_groupbox = QGroupBox.New4("Options", screenshot);

    delay_spinbox = QSpinBox.New(options_groupbox);
    delay_spinbox.SetSuffix(" s");
    delay_spinbox.SetMaximum(60);
    delay_spinbox.SetMinimum(0);
    delay_spinbox.OnValueChanged(onDelayChanged);

    hide_checkbox = QCheckBox.New4("Hide This Window", options_groupbox);

    const options_layout = QGridLayout.New(options_groupbox);
    options_layout.AddWidget2(
        QLabel.New5("Screenshot Delay:", screenshot),
        0,
        0,
    );
    options_layout.AddWidget2(delay_spinbox, 0, 1);
    options_layout.AddWidget3(hide_checkbox, 1, 0, 1, 2);

    main_layout.AddWidget(options_groupbox);

    new_button = QPushButton.New5("New Screenshot", screenshot);
    new_button.OnClicked(newScreenshot);

    const save_button = QPushButton.New5("Save Screenshot", screenshot);
    save_button.OnClicked(saveScreenshot);

    const quit_shortcut = QKeySequence.New3(
        qnamespace_enums.KeyboardModifier.ControlModifier | qnamespace_enums.Key.Key_Q,
    );
    defer quit_shortcut.Delete();

    const quit_button = QPushButton.New5("Quit", screenshot);
    quit_button.OnClicked(onQuit);
    quit_button.SetShortcut(quit_shortcut);

    const buttons_layout = QHBoxLayout.New2();
    buttons_layout.AddWidget(new_button);
    buttons_layout.AddWidget(save_button);
    buttons_layout.AddWidget(quit_button);
    buttons_layout.AddStretch();

    main_layout.AddLayout(buttons_layout);

    shootScreenshot();

    delay_spinbox.SetValue(5);

    const available_geometry = screen.AvailableGeometry();
    defer available_geometry.Delete();

    const top_left_point = available_geometry.TopLeft();
    defer top_left_point.Delete();

    const offset = QPoint.New4(50, 50);
    defer offset.Delete();

    _ = top_left_point.OperatorPlusAssign(offset);

    screenshot.Move2(top_left_point);
    screenshot.OnResizeEvent(onResizeEvent);

    screenshot.Show();

    _ = QApplication.Exec();
}

fn onDelayChanged(_: QSpinBox, value: i32) callconv(.c) void {
    if (value == 0) {
        hide_checkbox.SetDisabled(true);
        hide_checkbox.SetChecked(false);
    } else {
        hide_checkbox.SetDisabled(false);
    }
}

fn newScreenshot(_: QPushButton) callconv(.c) void {
    if (hide_checkbox.IsChecked())
        screenshot.Hide();

    const timer = QTimer.New2(screenshot);
    timer.SetSingleShot(true);
    timer.OnTimeout(onTimeout);
    timer.Start3(delay_spinbox.Value() * 1000);
}

fn onTimeout(_: QTimer) callconv(.c) void {
    shootScreenshot();
}

fn saveScreenshot(_: QPushButton) callconv(.c) void {
    var initial_path = QStandardPaths.WritableLocation(
        allocator,
        qstandardpaths_enums.StandardLocation.PicturesLocation,
    );
    defer allocator.free(initial_path);

    if (initial_path.len == 0) {
        allocator.free(initial_path);

        initial_path = QDir.CurrentPath(allocator);
    }

    const out_path = std.fmt.allocPrint(
        allocator,
        "{s}/untitled.{s}",
        .{ initial_path, format },
    ) catch @panic("Failed to allocPrint");
    defer allocator.free(out_path);

    const file_dialog = QFileDialog.New5(screenshot, "Save As", out_path);
    file_dialog.SetAcceptMode(qfiledialog_enums.AcceptMode.AcceptSave);
    file_dialog.SetFileMode(qfiledialog_enums.FileMode.AnyFile);
    file_dialog.SetDirectory(out_path);

    const mimetypes = QImageWriter.SupportedMimeTypes(allocator);
    defer {
        for (mimetypes) |mimetype|
            allocator.free(mimetype);
        allocator.free(mimetypes);
    }

    file_dialog.SetMimeTypeFilters(allocator, mimetypes);
    file_dialog.SelectMimeTypeFilter("image/" ++ format);
    file_dialog.SetDefaultSuffix(format);

    if (file_dialog.Exec() != qdialog_enums.DialogCode.Accepted)
        return;

    const selected_files = file_dialog.SelectedFiles(allocator);
    defer {
        for (selected_files) |file|
            allocator.free(file);
        allocator.free(selected_files);
    }

    if (selected_files.len == 0)
        return;

    if (!original_pixmap.Save(selected_files[0])) {
        const save_path = QDir.ToNativeSeparators(allocator, selected_files[0]);
        defer allocator.free(save_path);

        const error_message = std.fmt.allocPrint(
            allocator,
            "Failed to save screenshot to {s}",
            .{save_path},
        ) catch @panic("Failed to allocPrint");
        defer allocator.free(error_message);

        _ = QMessageBox.Warning(screenshot, "Save Error", error_message);
    }
}

fn onQuit(_: QPushButton) callconv(.c) void {
    QApplication.Quit();
}

fn shootScreenshot() void {
    var screen = QApplication.PrimaryScreen();
    const window = screenshot.WindowHandle();

    if (window.ptr != null)
        screen = window.Screen();

    if (screen.ptr == null)
        return;

    if (delay_spinbox.Value() != 0)
        QApplication.Beep();

    original_pixmap = screen.GrabWindow1(0);
    updateScreenshotLabel();

    new_button.SetDisabled(false);
    if (hide_checkbox.IsChecked())
        screenshot.Show();
}

fn onResizeEvent(_: QWidget, _: QResizeEvent) callconv(.c) void {
    const scaled_size = original_pixmap.Size();
    defer scaled_size.Delete();

    const label_size = screenshot_label.Size();
    defer label_size.Delete();

    scaled_size.Scale2(label_size, qnamespace_enums.AspectRatioMode.KeepAspectRatio);

    const pixmap = screenshot_label.Pixmap2();
    defer pixmap.Delete();

    const size = pixmap.Size();
    defer size.Delete();

    if (scaled_size.ptr != size.ptr)
        updateScreenshotLabel();
}

fn updateScreenshotLabel() void {
    const size = screenshot_label.Size();
    defer size.Delete();

    const pixmap = original_pixmap.Scaled32(
        size,
        qnamespace_enums.AspectRatioMode.KeepAspectRatio,
        qnamespace_enums.TransformationMode.SmoothTransformation,
    );
    defer pixmap.Delete();

    screenshot_label.SetPixmap(pixmap);
}
