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
    const qapp: QApplication = .new(init.arena.allocator(), &argc, argv);
    defer qapp.delete();

    allocator = init.gpa;

    const combo = QComboBox.new2();
    const texts = [_][]const u8{ "en", "es", "fr" };

    combo.addItems(allocator, &texts);
    combo.onCurrentTextChanged(onCurrentTextChanged);

    label = .new3("L&anguage:");
    label.setBuddy(combo);

    window = .new2();
    defer window.delete();

    window.setWindowTitle("Qt 6 Translation Example");
    window.setMinimumSize2(460, 270);

    const widget = QWidget.new2();

    up_button = .new3("&Up");
    down_button = .new3("&Down");
    left_button = .new3("&Left");
    right_button = .new3("&Right");

    const gridlayout = QGridLayout.new2();

    gridlayout.addWidget2(up_button, 0, 1);
    gridlayout.addWidget2(down_button, 2, 1);
    gridlayout.addWidget2(left_button, 1, 0);
    gridlayout.addWidget2(right_button, 1, 2);

    const vboxlayout = QVBoxLayout.new2();

    vboxlayout.addStretch();
    vboxlayout.addWidget(label);
    vboxlayout.addWidget(combo);

    gridlayout.addLayout(vboxlayout, 3, 0);

    widget.setLayout(gridlayout);
    window.setCentralWidget(widget);

    exit_action = .new5("E&xit", window);

    const exit_key = QKeySequence.new2("Ctrl+Q");
    defer exit_key.delete();

    exit_action.setShortcut(exit_key);
    exit_action.onTriggered(onTriggered);

    file_menu = window.menuBar().addMenu2("&File");
    file_menu.addAction(exit_action);

    window.show();

    _ = QApplication.exec();
}

fn onTriggered(_: QAction) callconv(.c) void {
    _ = window.close();
}

fn onCurrentTextChanged(_: QComboBox, text: [*:0]const u8) callconv(.c) void {
    const locale = QLocale.new2(std.mem.span(text));
    defer locale.delete();

    const translator = QTranslator.new();
    defer translator.delete();

    if (translator.load42(locale, "lupdate", "_", "src/lupdate")) {
        _ = QApplication.installTranslator(translator);
        retranslate();
    }
}

fn retranslate() void {
    const label_text = QApplication.translate(allocator, "Main", "L&anguage:");
    defer allocator.free(label_text);
    label.setText(label_text);

    const up_text = QApplication.translate(allocator, "Main", "&Up");
    defer allocator.free(up_text);
    up_button.setText(up_text);

    const down_text = QApplication.translate(allocator, "Main", "&Down");
    defer allocator.free(down_text);
    down_button.setText(down_text);

    const left_text = QApplication.translate(allocator, "Main", "&Left");
    defer allocator.free(left_text);
    left_button.setText(left_text);

    const right_text = QApplication.translate(allocator, "Main", "&Right");
    defer allocator.free(right_text);
    right_button.setText(right_text);

    const exit_text = QApplication.translate(allocator, "Main", "E&xit");
    defer allocator.free(exit_text);
    exit_action.setText(exit_text);

    const file_text = QApplication.translate(allocator, "Main", "&File");
    defer allocator.free(file_text);
    file_menu.setTitle(file_text);

    const quit_bind = QApplication.translate3(allocator, "Main", "Ctrl+Q", "Quit");
    defer allocator.free(quit_bind);

    const exit_key = QKeySequence.new2(quit_bind);
    defer exit_key.delete();

    exit_action.setShortcut(exit_key);
}
