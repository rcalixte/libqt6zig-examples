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

var allocator: std.mem.Allocator = undefined;

var edit: C.QTextEdit = null;
var htmlview: C.QTextBrowser = null;
var timer: C.QTimer = null;

pub fn main(init: std.process.Init) !void {
    const argv = try qt6.init(init.gpa, init.minimal.args);
    defer qt6.deinit(init.gpa, argv);
    var argc: i32 = @intCast(argv.len);
    const qapp = qapplication.New(&argc, argv, init.arena.allocator());
    defer qapplication.Delete(qapp);

    allocator = init.gpa;

    const window = qmainwindow.New2();
    defer qmainwindow.Delete(window);

    const widget = qwidget.New2();
    const layout = qhboxlayout.New2();

    qmainwindow.SetWindowTitle(window, "Qt 6 KCoreAddons Example");
    qmainwindow.SetCentralWidget(window, widget);
    qwidget.SetLayout(widget, layout);

    edit = qtextedit.New2();
    qtextedit.SetAcceptRichText(edit, false);

    qhboxlayout.AddWidget(layout, edit);

    htmlview = qtextbrowser.New2();
    qhboxlayout.AddWidget(layout, htmlview);

    timer = qtimer.New2(qapp);
    qtimer.SetSingleShot(timer, true);
    qtimer.SetInterval(timer, 1000);
    qtimer.OnTimeout(timer, onTimeout);
    qtextedit.OnTextChanged(edit, onTextChanged);

    qmainwindow.Show(window);

    _ = qapplication.Exec();
}

fn onTimeout(_: ?*anyopaque) callconv(.c) void {
    const plaintext = qtextedit.ToPlainText(edit, allocator);
    defer allocator.free(plaintext);
    const html = ktexttohtml.ConvertToHtml(plaintext, &0, 4096, 255, allocator);
    defer allocator.free(html);
    qtextbrowser.SetHtml(htmlview, html);
}

fn onTextChanged(_: ?*anyopaque) callconv(.c) void {
    qtimer.Start2(timer);
}
