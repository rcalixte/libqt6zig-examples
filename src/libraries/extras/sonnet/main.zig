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
    const qapp: QApplication = .new(init.arena.allocator(), &argc, argv);
    defer qapp.delete();

    const widget = QWidget.new2();
    defer widget.deleteLater();

    widget.setWindowTitle("Qt 6 Sonnet Example");

    const combo = Sonnet__DictionaryComboBox.new2();
    const textedit1 = QTextEdit.new2();
    textedit1.setText("This is a sample buffer. Whih this thingg will be checkin for misstakes." ++
        " Whih, Enviroment, covermant. Whih.");

    highlighter1 = Sonnet__SpellCheckDecorator.new(textedit1).highlighter();
    highlighter1.setCurrentLanguage("en_US");

    const textedit2 = QTextEdit.new2();
    textedit2.setText("John Doe said:\n> Hello how aree you?\nI am ffine thanks");

    highlighter2 = Sonnet__SpellCheckDecorator.new(textedit2).highlighter();
    highlighter2.setCurrentLanguage("en_US");

    combo.onDictionaryChanged(onDictionaryChanged);

    const layout = QVBoxLayout.new(widget);
    layout.addWidget(combo);
    layout.addWidget(textedit1);
    layout.addWidget(textedit2);

    widget.show();

    _ = QApplication.exec();
}

fn onDictionaryChanged(_: Sonnet__DictionaryComboBox, dictionary: [*:0]const u8) callconv(.c) void {
    highlighter1.setCurrentLanguage(std.mem.span(dictionary));
    highlighter2.setCurrentLanguage(std.mem.span(dictionary));
}
