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

const getAllocatorConfig = @import("alloc_config").getAllocatorConfig;
const config = getAllocatorConfig();
var gda: std.heap.DebugAllocator(config) = .init;
const allocator = gda.allocator();

var label: C.QLabel = undefined;
var window: C.QMainWindow = undefined;
var upButton: C.QPushButton = undefined;
var downButton: C.QPushButton = undefined;
var leftButton: C.QPushButton = undefined;
var rightButton: C.QPushButton = undefined;
var exitAction: C.QAction = undefined;
var fileMenu: C.QMenu = undefined;

pub fn main() void {
    const argc = std.os.argv.len;
    const argv = std.os.argv.ptr;
    const qapp = qapplication.New(argc, argv);
    defer qapplication.QDelete(qapp);

    const combo = qcombobox.New2();
    var texts = [_][]const u8{ "en", "es", "fr" };

    qcombobox.AddItems(combo, &texts, allocator);
    qcombobox.OnCurrentTextChanged(combo, onCurrentTextChanged);

    label = qlabel.New3("L&anguage:");
    qlabel.SetBuddy(label, combo);

    window = qmainwindow.New2();
    defer qmainwindow.QDelete(window);

    qmainwindow.SetWindowTitle(window, "Qt 6 Translation Example");
    qmainwindow.SetMinimumSize2(window, 460, 270);

    const widget = qwidget.New2();

    upButton = qpushbutton.New3("&Up");
    downButton = qpushbutton.New3("&Down");
    leftButton = qpushbutton.New3("&Left");
    rightButton = qpushbutton.New3("&Right");

    const gridlayout = qgridlayout.New2();

    qgridlayout.AddWidget2(gridlayout, upButton, 0, 1);
    qgridlayout.AddWidget2(gridlayout, downButton, 2, 1);
    qgridlayout.AddWidget2(gridlayout, leftButton, 1, 0);
    qgridlayout.AddWidget2(gridlayout, rightButton, 1, 2);

    const vboxlayout = qvboxlayout.New2();

    qvboxlayout.AddStretch(vboxlayout);
    qvboxlayout.AddWidget(vboxlayout, label);
    qvboxlayout.AddWidget(vboxlayout, combo);

    qgridlayout.AddLayout(gridlayout, vboxlayout, 3, 0);

    qwidget.SetLayout(widget, gridlayout);
    qmainwindow.SetCentralWidget(window, widget);

    exitAction = qaction.New5("E&xit", window);

    const exitKey = qkeysequence.New2("Ctrl+Q");
    defer qkeysequence.QDelete(exitKey);

    qaction.SetShortcut(exitAction, exitKey);
    qaction.OnTriggered(exitAction, onTriggered);

    fileMenu = qmenubar.AddMenu2(qmainwindow.MenuBar(window), "&File");
    qmenu.AddAction(fileMenu, exitAction);

    qmainwindow.Show(window);

    _ = qapplication.Exec();
}

fn onTriggered(_: ?*anyopaque) callconv(.c) void {
    _ = qmainwindow.Close(window);
}

fn onCurrentTextChanged(_: ?*anyopaque, text: [*:0]const u8) callconv(.c) void {
    const locale = qlocale.New2(std.mem.span(text));
    defer qlocale.QDelete(locale);

    const translator = qtranslator.New();
    defer qtranslator.QDelete(translator);

    if (qtranslator.Load42(translator, locale, "lupdate", "_", "src/lupdate")) {
        _ = qapplication.InstallTranslator(translator);
        retranslate();
    }
}

fn retranslate() void {
    const labelText = qapplication.Translate("Main", "L&anguage:", allocator);
    defer allocator.free(labelText);
    qlabel.SetText(label, labelText);

    const upText = qapplication.Translate("Main", "&Up", allocator);
    defer allocator.free(upText);
    qpushbutton.SetText(upButton, upText);

    const downText = qapplication.Translate("Main", "&Down", allocator);
    defer allocator.free(downText);
    qpushbutton.SetText(downButton, downText);

    const leftText = qapplication.Translate("Main", "&Left", allocator);
    defer allocator.free(leftText);
    qpushbutton.SetText(leftButton, leftText);

    const rightText = qapplication.Translate("Main", "&Right", allocator);
    defer allocator.free(rightText);
    qpushbutton.SetText(rightButton, rightText);

    const exitText = qapplication.Translate("Main", "E&xit", allocator);
    defer allocator.free(exitText);
    qaction.SetText(exitAction, exitText);

    const fileText = qapplication.Translate("Main", "&File", allocator);
    defer allocator.free(fileText);
    qmenu.SetTitle(fileMenu, fileText);

    const quitBind = qapplication.Translate3("Main", "Ctrl+Q", "Quit", allocator);
    defer allocator.free(quitBind);

    const exitKey = qkeysequence.New2(quitBind);
    defer qkeysequence.QDelete(exitKey);

    qaction.SetShortcut(exitAction, exitKey);
}
