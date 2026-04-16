const std = @import("std");
const qt6 = @import("libqt6zig");
const QApplication = qt6.QApplication;
const QWidget = qt6.QWidget;
const Sonnet__DictionaryComboBox = qt6.Sonnet__DictionaryComboBox;
const QTextEdit = qt6.QTextEdit;
const Sonnet__SpellCheckDecorator = qt6.Sonnet__SpellCheckDecorator;
const Sonnet__Highlighter = qt6.Sonnet__Highlighter;
const QVBoxLayout = qt6.QVBoxLayout;

var highlighter1: Sonnet__Highlighter = undefined;
var highlighter2: Sonnet__Highlighter = undefined;

pub fn main(init: std.process.Init) !void {
    const argv = try qt6.init(init.gpa, init.minimal.args);
    defer qt6.deinit(init.gpa, argv);
    var argc: i32 = @intCast(argv.len);
    const qapp = QApplication.New(init.arena.allocator(), &argc, argv);
    defer qapp.Delete();

    const widget = QWidget.New2();
    defer widget.DeleteLater();

    widget.SetWindowTitle("Qt 6 Sonnet Example");

    const combo = Sonnet__DictionaryComboBox.New2();
    const textedit1 = QTextEdit.New2();
    textedit1.SetText("This is a sample buffer. Whih this thingg will be checkin for misstakes. Whih, Enviroment, covermant. Whih.");

    const installer1 = Sonnet__SpellCheckDecorator.New(textedit1);
    highlighter1 = installer1.Highlighter();

    highlighter1.SetCurrentLanguage("en_US");

    const textedit2 = QTextEdit.New2();
    textedit2.SetText("John Doe said:\n> Hello how aree you?\nI am ffine thanks");

    const installer2 = Sonnet__SpellCheckDecorator.New(textedit2);
    highlighter2 = installer2.Highlighter();

    highlighter2.SetCurrentLanguage("en_US");

    combo.OnDictionaryChanged(onDictionaryChanged);

    const layout = QVBoxLayout.New(widget);
    layout.AddWidget(combo);
    layout.AddWidget(textedit1);
    layout.AddWidget(textedit2);

    widget.Show();

    _ = QApplication.Exec();
}

fn onDictionaryChanged(_: Sonnet__DictionaryComboBox, dictionary: [*:0]const u8) callconv(.c) void {
    highlighter1.SetCurrentLanguage(std.mem.span(dictionary));
    highlighter2.SetCurrentLanguage(std.mem.span(dictionary));
}
