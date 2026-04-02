const std = @import("std");
const qt6 = @import("libqt6zig");
const C = qt6.C;
const qapplication = qt6.qapplication;
const qwidget = qt6.qwidget;
const qlabel = qt6.qlabel;
const qsizepolicy_enums = qt6.qsizepolicy_enums;
const qnamespace_enums = qt6.qnamespace_enums;
const qscreen = qt6.qscreen;
const qrect = qt6.qrect;
const qvboxlayout = qt6.qvboxlayout;
const qgroupbox = qt6.qgroupbox;
const qspinbox = qt6.qspinbox;
const qcheckbox = qt6.qcheckbox;
const qgridlayout = qt6.qgridlayout;
const qpushbutton = qt6.qpushbutton;
const qkeysequence = qt6.qkeysequence;
const qhboxlayout = qt6.qhboxlayout;
const qtimer = qt6.qtimer;
const qpoint = qt6.qpoint;
const qsize = qt6.qsize;
const qpixmap = qt6.qpixmap;
const qwindow = qt6.qwindow;
const qstandardpaths = qt6.qstandardpaths;
const qstandardpaths_enums = qt6.qstandardpaths_enums;
const qdir = qt6.qdir;
const qfiledialog = qt6.qfiledialog;
const qfiledialog_enums = qt6.qfiledialog_enums;
const qimagewriter = qt6.qimagewriter;
const qdialog_enums = qt6.qdialog_enums;
const qmessagebox = qt6.qmessagebox;

var gpa = @import("alloc_config").gpa;
const allocator = gpa.allocator();

var screenshot: C.QWidget = null;
var screenshot_label: C.QLabel = null;
var delay_spinbox: C.QSpinBox = null;
var hide_checkbox: C.QCheckBox = null;
var new_button: C.QPushButton = null;
var original_pixmap: C.QPixmap = null;

const format = "png";

pub fn main() !void {
    const argc = std.os.argv.len;
    const argv = std.os.argv.ptr;
    const qapp = qapplication.New(argc, argv);
    defer qapplication.Delete(qapp);

    defer _ = gpa.deinit();

    screenshot = qwidget.New2();
    defer qwidget.Delete(screenshot);

    qwidget.SetWindowTitle(screenshot, "Qt 6 Screenshot Example");
    qwidget.SetMinimumSize2(screenshot, 400, 300);

    screenshot_label = qlabel.New5("Take a screenshot", screenshot);
    qlabel.SetSizePolicy2(
        screenshot_label,
        qsizepolicy_enums.Policy.Expanding,
        qsizepolicy_enums.Policy.Expanding,
    );
    qlabel.SetAlignment(screenshot_label, qnamespace_enums.AlignmentFlag.AlignCenter);

    const screen = qwidget.Screen(screenshot);

    const rect = qscreen.Geometry(screen);
    defer qrect.Delete(rect);

    qlabel.SetMinimumSize2(
        screenshot_label,
        @divTrunc(qrect.Width(rect), 8),
        @divTrunc(qrect.Height(rect), 8),
    );

    const main_layout = qvboxlayout.New(screenshot);
    qvboxlayout.AddWidget(main_layout, screenshot_label);

    const options_groupbox = qgroupbox.New4("Options", screenshot);

    delay_spinbox = qspinbox.New(options_groupbox);
    qspinbox.SetSuffix(delay_spinbox, " s");
    qspinbox.SetMaximum(delay_spinbox, 60);
    qspinbox.SetMinimum(delay_spinbox, 0);
    qspinbox.OnValueChanged(delay_spinbox, onDelayChanged);

    hide_checkbox = qcheckbox.New4("Hide This Window", options_groupbox);

    const options_layout = qgridlayout.New(options_groupbox);
    qgridlayout.AddWidget2(
        options_layout,
        qlabel.New5("Screenshot Delay:", screenshot),
        0,
        0,
    );
    qgridlayout.AddWidget2(options_layout, delay_spinbox, 0, 1);
    qgridlayout.AddWidget3(options_layout, hide_checkbox, 1, 0, 1, 2);

    qvboxlayout.AddWidget(main_layout, options_groupbox);

    new_button = qpushbutton.New5("New Screenshot", screenshot);
    qpushbutton.OnClicked(new_button, newScreenshot);

    const save_button = qpushbutton.New5("Save Screenshot", screenshot);
    qpushbutton.OnClicked(save_button, saveScreenshot);

    const quit_shortcut = qkeysequence.New3(
        qnamespace_enums.KeyboardModifier.ControlModifier | qnamespace_enums.Key.Key_Q,
    );
    defer qkeysequence.Delete(quit_shortcut);

    const quit_button = qpushbutton.New5("Quit", screenshot);
    qpushbutton.OnClicked(quit_button, onQuit);
    qpushbutton.SetShortcut(quit_button, quit_shortcut);

    const buttons_layout = qhboxlayout.New2();
    qhboxlayout.AddWidget(buttons_layout, new_button);
    qhboxlayout.AddWidget(buttons_layout, save_button);
    qhboxlayout.AddWidget(buttons_layout, quit_button);
    qhboxlayout.AddStretch(buttons_layout);

    qvboxlayout.AddLayout(main_layout, buttons_layout);

    shootScreenshot();

    qspinbox.SetValue(delay_spinbox, 5);

    const available_geometry = qscreen.AvailableGeometry(screen);
    defer qrect.Delete(available_geometry);

    const top_left_point = qrect.TopLeft(available_geometry);
    defer qpoint.Delete(top_left_point);

    const offset = qpoint.New4(50, 50);
    defer qpoint.Delete(offset);

    _ = qpoint.OperatorPlusAssign(top_left_point, offset);

    qwidget.Move2(screenshot, top_left_point);
    qwidget.OnResizeEvent(screenshot, onResizeEvent);

    qwidget.Show(screenshot);

    _ = qapplication.Exec();
}

fn onDelayChanged(_: ?*anyopaque, value: i32) callconv(.c) void {
    if (value == 0) {
        qcheckbox.SetDisabled(hide_checkbox, true);
        qcheckbox.SetChecked(hide_checkbox, false);
    } else {
        qcheckbox.SetDisabled(hide_checkbox, false);
    }
}

fn newScreenshot(_: ?*anyopaque) callconv(.c) void {
    if (qcheckbox.IsChecked(hide_checkbox))
        qwidget.Hide(screenshot);

    const timer = qtimer.New2(screenshot);
    qtimer.SetSingleShot(timer, true);
    qtimer.OnTimeout(timer, onTimeout);
    qtimer.Start3(timer, qspinbox.Value(delay_spinbox) * 1000);
}

fn onTimeout(_: ?*anyopaque) callconv(.c) void {
    shootScreenshot();
}

fn saveScreenshot(_: ?*anyopaque) callconv(.c) void {
    var initial_path = qstandardpaths.WritableLocation(
        qstandardpaths_enums.StandardLocation.PicturesLocation,
        allocator,
    );
    defer allocator.free(initial_path);

    if (initial_path.len == 0) {
        allocator.free(initial_path);

        initial_path = qdir.CurrentPath(allocator);
    }

    const out_path = std.fmt.allocPrint(
        allocator,
        "{s}/untitled.{s}",
        .{ initial_path, format },
    ) catch @panic("Failed to allocPrint");
    defer allocator.free(out_path);

    const file_dialog = qfiledialog.New5(screenshot, "Save As", out_path);
    qfiledialog.SetAcceptMode(file_dialog, qfiledialog_enums.AcceptMode.AcceptSave);
    qfiledialog.SetFileMode(file_dialog, qfiledialog_enums.FileMode.AnyFile);
    qfiledialog.SetDirectory(file_dialog, out_path);

    const mimetypes = qimagewriter.SupportedMimeTypes(allocator);
    defer {
        for (mimetypes) |mimetype|
            allocator.free(mimetype);
        allocator.free(mimetypes);
    }

    qfiledialog.SetMimeTypeFilters(file_dialog, mimetypes, allocator);
    qfiledialog.SelectMimeTypeFilter(file_dialog, "image/" ++ format);
    qfiledialog.SetDefaultSuffix(file_dialog, format);

    if (qfiledialog.Exec(file_dialog) != qdialog_enums.DialogCode.Accepted)
        return;

    const selected_files = qfiledialog.SelectedFiles(file_dialog, allocator);
    defer {
        for (selected_files) |file|
            allocator.free(file);
        allocator.free(selected_files);
    }

    if (selected_files.len == 0)
        return;

    if (!qpixmap.Save(original_pixmap, selected_files[0])) {
        const save_path = qdir.ToNativeSeparators(selected_files[0], allocator);
        defer allocator.free(save_path);

        const error_message = std.fmt.allocPrint(
            allocator,
            "Failed to save screenshot to {s}",
            .{save_path},
        ) catch @panic("Failed to allocPrint");
        defer allocator.free(error_message);

        _ = qmessagebox.Warning(screenshot, "Save Error", error_message);
    }
}

fn onQuit(_: ?*anyopaque) callconv(.c) void {
    qapplication.Quit();
}

fn shootScreenshot() void {
    var screen = qapplication.PrimaryScreen();
    const window = qwidget.WindowHandle(screenshot);

    if (window != null)
        screen = qwindow.Screen(window);

    if (screen == null)
        return;

    if (qspinbox.Value(delay_spinbox) != 0)
        qapplication.Beep();

    original_pixmap = qscreen.GrabWindow1(screen, 0);
    updateScreenshotLabel();

    qpushbutton.SetDisabled(new_button, false);
    if (qcheckbox.IsChecked(hide_checkbox))
        qwidget.Show(screenshot);
}

fn onResizeEvent(_: ?*anyopaque, _: ?*anyopaque) callconv(.c) void {
    const scaled_size = qpixmap.Size(original_pixmap);
    defer qsize.Delete(scaled_size);

    const label_size = qlabel.Size(screenshot_label);
    defer qsize.Delete(label_size);

    qsize.Scale2(scaled_size, label_size, qnamespace_enums.AspectRatioMode.KeepAspectRatio);

    const pixmap = qlabel.Pixmap2(screenshot_label);
    defer qpixmap.Delete(pixmap);

    const size = qpixmap.Size(pixmap);
    defer qsize.Delete(size);

    if (scaled_size != size)
        updateScreenshotLabel();
}

fn updateScreenshotLabel() void {
    const size = qlabel.Size(screenshot_label);
    defer qsize.Delete(size);

    const pixmap = qpixmap.Scaled32(
        original_pixmap,
        size,
        qnamespace_enums.AspectRatioMode.KeepAspectRatio,
        qnamespace_enums.TransformationMode.SmoothTransformation,
    );
    defer qpixmap.Delete(pixmap);

    qlabel.SetPixmap(screenshot_label, pixmap);
}
