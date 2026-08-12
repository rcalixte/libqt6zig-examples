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
    const qapp: QApplication = .new(init.arena.allocator(), &argc, argv);
    defer qapp.delete();

    allocator = init.gpa;

    const window = QMainWindow.new2();
    defer window.delete();

    const widget = QWidget.new2();
    const layout = QHBoxLayout.new2();

    window.setWindowTitle("Qt 6 KCoreAddons Example");
    window.setCentralWidget(widget);
    widget.setLayout(layout);

    edit = .new2();
    edit.setAcceptRichText(false);

    layout.addWidget(edit);

    htmlview = .new2();
    layout.addWidget(htmlview);

    timer = .new2(qapp);
    timer.setSingleShot(true);
    timer.setInterval(1000);
    timer.onTimeout(onTimeout);
    edit.onTextChanged(onTextChanged);

    window.show();

    _ = QApplication.exec();
}

fn onTimeout(_: QTimer) callconv(.c) void {
    const plaintext = edit.toPlainText(allocator);
    defer allocator.free(plaintext);
    const options = ktexttohtml_enums.Option.HighlightText;
    const html = KTextToHTML.convertToHtml(allocator, plaintext, &options, 4096, 255);
    defer allocator.free(html);
    htmlview.setHtml(html);
}

fn onTextChanged(_: QTextEdit) callconv(.c) void {
    timer.start2();
}
