const std = @import("std");
const qt6 = @import("libqt6zig");
const QApplication = qt6.QApplication;
const QComboBox = qt6.QComboBox;
const QLabel = qt6.QLabel;
const QMainWindow = qt6.QMainWindow;
const QWidget = qt6.QWidget;
const QPushButton = qt6.QPushButton;
const QGridLayout = qt6.QGridLayout;
const QVBoxLayout = qt6.QVBoxLayout;
const QAction = qt6.QAction;
const QKeySequence = qt6.QKeySequence;
const QMenuBar = qt6.QMenuBar;
const QMenu = qt6.QMenu;
const QLocale = qt6.QLocale;
const QTranslator = qt6.QTranslator;

var allocator: std.mem.Allocator = undefined;

var label: QLabel = undefined;
var window: QMainWindow = undefined;

var up_button: QPushButton = undefined;
var down_button: QPushButton = undefined;
var left_button: QPushButton = undefined;
var right_button: QPushButton = undefined;
var exit_action: QAction = undefined;
var file_menu: QMenu = undefined;

pub fn main(init: std.process.Init) !void {
    const argv = try qt6.init(init.gpa, init.minimal.args);
    defer qt6.deinit(init.gpa, argv);
    var argc: i32 = @intCast(argv.len);
    const qapp = QApplication.New(init.arena.allocator(), &argc, argv);
    defer qapp.Delete();

    allocator = init.gpa;

    const combo = QComboBox.New2();
    const texts = [_][]const u8{ "en", "es", "fr" };

    combo.AddItems(allocator, &texts);
    combo.OnCurrentTextChanged(onCurrentTextChanged);

    label = QLabel.New3("L&anguage:");
    label.SetBuddy(combo);

    window = QMainWindow.New2();
    defer window.Delete();

    window.SetWindowTitle("Qt 6 Translation Example");
    window.SetMinimumSize2(460, 270);

    const widget = QWidget.New2();

    up_button = QPushButton.New3("&Up");
    down_button = QPushButton.New3("&Down");
    left_button = QPushButton.New3("&Left");
    right_button = QPushButton.New3("&Right");

    const gridlayout = QGridLayout.New2();

    gridlayout.AddWidget2(up_button, 0, 1);
    gridlayout.AddWidget2(down_button, 2, 1);
    gridlayout.AddWidget2(left_button, 1, 0);
    gridlayout.AddWidget2(right_button, 1, 2);

    const vboxlayout = QVBoxLayout.New2();

    vboxlayout.AddStretch();
    vboxlayout.AddWidget(label);
    vboxlayout.AddWidget(combo);

    gridlayout.AddLayout(vboxlayout, 3, 0);

    widget.SetLayout(gridlayout);
    window.SetCentralWidget(widget);

    exit_action = QAction.New5("E&xit", window);

    const exit_key = QKeySequence.New2("Ctrl+Q");
    defer exit_key.Delete();

    exit_action.SetShortcut(exit_key);
    exit_action.OnTriggered(onTriggered);

    file_menu = window.MenuBar().AddMenu2("&File");
    file_menu.AddAction(exit_action);

    window.Show();

    _ = QApplication.Exec();
}

fn onTriggered(_: QAction) callconv(.c) void {
    _ = window.Close();
}

fn onCurrentTextChanged(_: QComboBox, text: [*:0]const u8) callconv(.c) void {
    const locale = QLocale.New2(std.mem.span(text));
    defer locale.Delete();

    const translator = QTranslator.New();
    defer translator.Delete();

    if (translator.Load42(locale, "lupdate", "_", "src/lupdate")) {
        _ = QApplication.InstallTranslator(translator);
        retranslate();
    }
}

fn retranslate() void {
    const label_text = QApplication.Translate(allocator, "Main", "L&anguage:");
    defer allocator.free(label_text);
    label.SetText(label_text);

    const up_text = QApplication.Translate(allocator, "Main", "&Up");
    defer allocator.free(up_text);
    up_button.SetText(up_text);

    const down_text = QApplication.Translate(allocator, "Main", "&Down");
    defer allocator.free(down_text);
    down_button.SetText(down_text);

    const left_text = QApplication.Translate(allocator, "Main", "&Left");
    defer allocator.free(left_text);
    left_button.SetText(left_text);

    const right_text = QApplication.Translate(allocator, "Main", "&Right");
    defer allocator.free(right_text);
    right_button.SetText(right_text);

    const exit_text = QApplication.Translate(allocator, "Main", "E&xit");
    defer allocator.free(exit_text);
    exit_action.SetText(exit_text);

    const file_text = QApplication.Translate(allocator, "Main", "&File");
    defer allocator.free(file_text);
    file_menu.SetTitle(file_text);

    const quit_bind = QApplication.Translate3(allocator, "Main", "Ctrl+Q", "Quit");
    defer allocator.free(quit_bind);

    const exit_key = QKeySequence.New2(quit_bind);
    defer exit_key.Delete();

    exit_action.SetShortcut(exit_key);
}
