const std = @import("std");
const qt6 = @import("libqt6zig");
const C = qt6.C;
const qapplication = qt6.qapplication;
const qcombobox = qt6.qcombobox;
const qlabel = qt6.qlabel;
const qmainwindow = qt6.qmainwindow;
const qwidget = qt6.qwidget;
const qpushbutton = qt6.qpushbutton;
const qgridlayout = qt6.qgridlayout;
const qvboxlayout = qt6.qvboxlayout;
const qaction = qt6.qaction;
const qkeysequence = qt6.qkeysequence;
const qmenubar = qt6.qmenubar;
const qmenu = qt6.qmenu;
const qlocale = qt6.qlocale;
const qtranslator = qt6.qtranslator;

var allocator: std.mem.Allocator = undefined;

var label: C.QLabel = null;
var window: C.QMainWindow = null;
var up_button: C.QPushButton = null;
var down_button: C.QPushButton = null;
var left_button: C.QPushButton = null;
var right_button: C.QPushButton = null;
var exit_action: C.QAction = null;
var file_menu: C.QMenu = null;

pub fn main(init: std.process.Init) !void {
    const argv = try qt6.init(init.gpa, init.minimal.args);
    defer qt6.deinit(init.gpa, argv);
    var argc: i32 = @intCast(argv.len);
    const qapp = qapplication.New(&argc, argv, init.arena.allocator());
    defer qapplication.Delete(qapp);

    allocator = init.gpa;

    const combo = qcombobox.New2();
    const texts = [_][]const u8{ "en", "es", "fr" };

    qcombobox.AddItems(combo, &texts, allocator);
    qcombobox.OnCurrentTextChanged(combo, onCurrentTextChanged);

    label = qlabel.New3("L&anguage:");
    qlabel.SetBuddy(label, combo);

    window = qmainwindow.New2();
    defer qmainwindow.Delete(window);

    qmainwindow.SetWindowTitle(window, "Qt 6 Translation Example");
    qmainwindow.SetMinimumSize2(window, 460, 270);

    const widget = qwidget.New2();

    up_button = qpushbutton.New3("&Up");
    down_button = qpushbutton.New3("&Down");
    left_button = qpushbutton.New3("&Left");
    right_button = qpushbutton.New3("&Right");

    const gridlayout = qgridlayout.New2();

    qgridlayout.AddWidget2(gridlayout, up_button, 0, 1);
    qgridlayout.AddWidget2(gridlayout, down_button, 2, 1);
    qgridlayout.AddWidget2(gridlayout, left_button, 1, 0);
    qgridlayout.AddWidget2(gridlayout, right_button, 1, 2);

    const vboxlayout = qvboxlayout.New2();

    qvboxlayout.AddStretch(vboxlayout);
    qvboxlayout.AddWidget(vboxlayout, label);
    qvboxlayout.AddWidget(vboxlayout, combo);

    qgridlayout.AddLayout(gridlayout, vboxlayout, 3, 0);

    qwidget.SetLayout(widget, gridlayout);
    qmainwindow.SetCentralWidget(window, widget);

    exit_action = qaction.New5("E&xit", window);

    const exit_key = qkeysequence.New2("Ctrl+Q");
    defer qkeysequence.Delete(exit_key);

    qaction.SetShortcut(exit_action, exit_key);
    qaction.OnTriggered(exit_action, onTriggered);

    file_menu = qmenubar.AddMenu2(qmainwindow.MenuBar(window), "&File");
    qmenu.AddAction(file_menu, exit_action);

    qmainwindow.Show(window);

    _ = qapplication.Exec();
}

fn onTriggered(_: ?*anyopaque) callconv(.c) void {
    _ = qmainwindow.Close(window);
}

fn onCurrentTextChanged(_: ?*anyopaque, text: [*:0]const u8) callconv(.c) void {
    const locale = qlocale.New2(std.mem.span(text));
    defer qlocale.Delete(locale);

    const translator = qtranslator.New();
    defer qtranslator.Delete(translator);

    if (qtranslator.Load42(translator, locale, "lupdate", "_", "src/lupdate")) {
        _ = qapplication.InstallTranslator(translator);
        retranslate();
    }
}

fn retranslate() void {
    const label_text = qapplication.Translate("Main", "L&anguage:", allocator);
    defer allocator.free(label_text);
    qlabel.SetText(label, label_text);

    const up_text = qapplication.Translate("Main", "&Up", allocator);
    defer allocator.free(up_text);
    qpushbutton.SetText(up_button, up_text);

    const down_text = qapplication.Translate("Main", "&Down", allocator);
    defer allocator.free(down_text);
    qpushbutton.SetText(down_button, down_text);

    const left_text = qapplication.Translate("Main", "&Left", allocator);
    defer allocator.free(left_text);
    qpushbutton.SetText(left_button, left_text);

    const right_text = qapplication.Translate("Main", "&Right", allocator);
    defer allocator.free(right_text);
    qpushbutton.SetText(right_button, right_text);

    const exit_text = qapplication.Translate("Main", "E&xit", allocator);
    defer allocator.free(exit_text);
    qaction.SetText(exit_action, exit_text);

    const file_text = qapplication.Translate("Main", "&File", allocator);
    defer allocator.free(file_text);
    qmenu.SetTitle(file_menu, file_text);

    const quit_bind = qapplication.Translate3("Main", "Ctrl+Q", "Quit", allocator);
    defer allocator.free(quit_bind);

    const exit_key = qkeysequence.New2(quit_bind);
    defer qkeysequence.Delete(exit_key);

    qaction.SetShortcut(exit_action, exit_key);
}
