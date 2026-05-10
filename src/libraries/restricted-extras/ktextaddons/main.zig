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
    const qapp = QApplication.New(init.arena.allocator(), &argc, argv);
    defer qapp.Delete();

    allocator = init.gpa;

    const window = QMainWindow.New2();
    defer window.Delete();

    window.SetWindowTitle("Qt 6 KTextAddons Example");
    window.Resize(800, 600);

    const widget = QWidget.New(window);
    const layout = QVBoxLayout.New(widget);
    textedit = QTextEdit.New(widget);
    textedit.SetPlaceholderText("Type or paste text here and use the toolbar button to translate");
    layout.AddWidget2(textedit, 1);

    translator = TextTranslator__TranslatorWidget.New(widget);
    translator.Hide();
    layout.AddWidget(translator);

    const toolbar = window.AddToolBar3("Tools");
    const action = toolbar.AddAction2("Translate");
    action.OnTriggered(onTriggered);

    window.SetCentralWidget(widget);
    window.Show();

    _ = QApplication.Exec();
}

fn onTriggered(_: QAction) callconv(.c) void {
    const text = textedit.ToPlainText(allocator);
    defer allocator.free(text);

    if (text.len == 0) return;

    translator.SetTextToTranslate(text);
    translator.Show();
}
