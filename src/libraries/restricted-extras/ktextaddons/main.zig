const std = @import("std");
const qt6 = @import("libqt6zig");
const QApplication = qt6.QApplication;
const QMainWindow = qt6.QMainWindow;
const QWidget = qt6.QWidget;
const QVBoxLayout = qt6.QVBoxLayout;
const QTextEdit = qt6.QTextEdit;
const TextTranslator__TranslatorWidget = qt6.TextTranslator__TranslatorWidget;
const QAction = qt6.QAction;

var allocator: std.mem.Allocator = undefined;

var textedit: QTextEdit = undefined;
var translator: TextTranslator__TranslatorWidget = undefined;

pub fn main(init: std.process.Init) !void {
    const argv = try qt6.init(init.gpa, init.minimal.args);
    defer qt6.deinit(init.gpa, argv);
    var argc: i32 = @intCast(argv.len);
    const qapp: QApplication = .new(init.arena.allocator(), &argc, argv);
    defer qapp.delete();

    allocator = init.gpa;

    const window = QMainWindow.new2();
    defer window.delete();

    window.setWindowTitle("Qt 6 KTextAddons Example");
    window.resize(800, 600);

    const widget = QWidget.new(window);
    const layout = QVBoxLayout.new(widget);
    textedit = .new(widget);
    textedit.setPlaceholderText("Type or paste text here and use the toolbar button to translate");
    layout.addWidget2(textedit, 1);

    translator = .new(widget);
    translator.hide();
    layout.addWidget(translator);

    const toolbar = window.addToolBar3("Tools");
    const action = toolbar.addAction2("Translate");
    action.onTriggered(onTriggered);

    window.setCentralWidget(widget);
    window.show();

    _ = QApplication.exec();
}

fn onTriggered(_: QAction) callconv(.c) void {
    const text = textedit.toPlainText(allocator);
    defer allocator.free(text);

    if (text.len == 0) return;

    translator.setTextToTranslate(text);
    translator.show();
}
