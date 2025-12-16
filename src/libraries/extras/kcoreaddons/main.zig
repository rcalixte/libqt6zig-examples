const std = @import("std");
const qt6 = @import("libqt6zig");
const C = qt6.C;
const qapplication = qt6.qapplication;
const qmainwindow = qt6.qmainwindow;
const qwidget = qt6.qwidget;
const qhboxlayout = qt6.qhboxlayout;
const qtextedit = qt6.qtextedit;
const qtextbrowser = qt6.qtextbrowser;
const qtimer = qt6.qtimer;
const ktexttohtml = qt6.ktexttohtml;

var gpa = @import("alloc_config").gpa;
const allocator = gpa.allocator();

var plainTextEditor: C.QTextEdit = undefined;
var htmlview: C.QTextBrowser = undefined;
var timer: C.QTimer = undefined;

pub fn main() void {
    const argc = std.os.argv.len;
    const argv = std.os.argv.ptr;
    const qapp = qapplication.New(argc, argv);
    defer qapplication.QDelete(qapp);

    defer _ = gpa.deinit();

    const window = qmainwindow.New2();
    defer qmainwindow.QDelete(window);

    const widget = qwidget.New2();
    const layout = qhboxlayout.New2();

    qmainwindow.SetWindowTitle(window, "Qt 6 KCoreAddons Example");
    qmainwindow.SetCentralWidget(window, widget);
    qwidget.SetLayout(widget, layout);

    plainTextEditor = qtextedit.New2();
    qtextedit.SetAcceptRichText(plainTextEditor, false);

    qhboxlayout.AddWidget(layout, plainTextEditor);

    htmlview = qtextbrowser.New2();
    qhboxlayout.AddWidget(layout, htmlview);

    timer = qtimer.New2(qapp);
    qtimer.SetSingleShot(timer, true);
    qtimer.SetInterval(timer, 1000);
    qtimer.OnTimeout(timer, onTimeout);
    qtextedit.OnTextChanged(plainTextEditor, onTextChanged);

    qmainwindow.Show(window);

    _ = qapplication.Exec();
}

fn onTimeout(_: ?*anyopaque) callconv(.c) void {
    const plaintext = qtextedit.ToPlainText(plainTextEditor, allocator);
    defer allocator.free(plaintext);
    const html = ktexttohtml.ConvertToHtml(plaintext, &0, 4096, 255, allocator);
    defer allocator.free(html);
    qtextbrowser.SetHtml(htmlview, html);
}

fn onTextChanged(_: ?*anyopaque) callconv(.c) void {
    qtimer.Start2(timer);
}
