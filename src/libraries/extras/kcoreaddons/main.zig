const std = @import("std");
const qt6 = @import("libqt6zig");
const QApplication = qt6.QApplication;
const QMainWindow = qt6.QMainWindow;
const QWidget = qt6.QWidget;
const QHBoxLayout = qt6.QHBoxLayout;
const QTextEdit = qt6.QTextEdit;
const QTextBrowser = qt6.QTextBrowser;
const QTimer = qt6.QTimer;
const KTextToHTML = qt6.KTextToHTML;
const ktexttohtml_enums = qt6.ktexttohtml_enums;

var allocator: std.mem.Allocator = undefined;

var edit: QTextEdit = undefined;
var htmlview: QTextBrowser = undefined;
var timer: QTimer = undefined;

pub fn main(init: std.process.Init) !void {
    const argv = try qt6.init(init.gpa, init.minimal.args);
    defer qt6.deinit(init.gpa, argv);
    var argc: i32 = @intCast(argv.len);
    const qapp = QApplication.New(init.arena.allocator(), &argc, argv);
    defer qapp.Delete();

    allocator = init.gpa;

    const window = QMainWindow.New2();
    defer window.Delete();

    const widget = QWidget.New2();
    const layout = QHBoxLayout.New2();

    window.SetWindowTitle("Qt 6 KCoreAddons Example");
    window.SetCentralWidget(widget);
    widget.SetLayout(layout);

    edit = QTextEdit.New2();
    edit.SetAcceptRichText(false);

    layout.AddWidget(edit);

    htmlview = QTextBrowser.New2();
    layout.AddWidget(htmlview);

    timer = QTimer.New2(qapp);
    timer.SetSingleShot(true);
    timer.SetInterval(1000);
    timer.OnTimeout(onTimeout);
    edit.OnTextChanged(onTextChanged);

    window.Show();

    _ = QApplication.Exec();
}

fn onTimeout(_: QTimer) callconv(.c) void {
    const plaintext = edit.ToPlainText(allocator);
    defer allocator.free(plaintext);
    const options = ktexttohtml_enums.Option.HighlightText;
    const html = KTextToHTML.ConvertToHtml(allocator, plaintext, &options, 4096, 255);
    defer allocator.free(html);
    htmlview.SetHtml(html);
}

fn onTextChanged(_: QTextEdit) callconv(.c) void {
    timer.Start2();
}
