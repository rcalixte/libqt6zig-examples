const std = @import("std");
const qt6 = @import("libqt6zig");
const C = qt6.C;
const qapplication = qt6.qapplication;
const qwidget = qt6.qwidget;
const sonnet__dictionarycombobox = qt6.sonnet__dictionarycombobox;
const qtextedit = qt6.qtextedit;
const sonnet__spellcheckdecorator = qt6.sonnet__spellcheckdecorator;
const sonnet__highlighter = qt6.sonnet__highlighter;
const qvboxlayout = qt6.qvboxlayout;

var highlighter1: C.Sonnet__Highlighter = null;
var highlighter2: C.Sonnet__Highlighter = null;

pub fn main() void {
    const argc = std.os.argv.len;
    const argv = std.os.argv.ptr;
    const qapp = qapplication.New(argc, argv);
    defer qapplication.Delete(qapp);

    const widget = qwidget.New2();
    defer qwidget.Delete(widget);

    qwidget.SetWindowTitle(widget, "Qt 6 Sonnet Example");

    const comboBox = sonnet__dictionarycombobox.New2();
    const textedit1 = qtextedit.New2();
    qtextedit.SetText(
        textedit1,
        "This is a sample buffer. Whih this thingg will be checkin for misstakes. Whih, Enviroment, covermant. Whih.",
    );

    const installer1 = sonnet__spellcheckdecorator.New(textedit1);
    highlighter1 = sonnet__spellcheckdecorator.Highlighter(installer1);

    sonnet__highlighter.SetCurrentLanguage(highlighter1, "en_US");

    const textedit2 = qtextedit.New2();
    qtextedit.SetText(textedit2, "John Doe said:\n> Hello how aree you?\nI am ffine thanks");

    const installer2 = sonnet__spellcheckdecorator.New(textedit2);
    highlighter2 = sonnet__spellcheckdecorator.Highlighter(installer2);

    sonnet__highlighter.SetCurrentLanguage(highlighter2, "en_US");

    sonnet__dictionarycombobox.OnDictionaryChanged(comboBox, onDictionaryChanged);

    const layout = qvboxlayout.New(widget);
    qvboxlayout.AddWidget(layout, comboBox);
    qvboxlayout.AddWidget(layout, textedit1);
    qvboxlayout.AddWidget(layout, textedit2);

    qwidget.Show(widget);

    _ = qapplication.Exec();
}

fn onDictionaryChanged(_: ?*anyopaque, dictionary: [*:0]const u8) callconv(.c) void {
    sonnet__highlighter.SetCurrentLanguage(highlighter1, std.mem.span(dictionary));
    sonnet__highlighter.SetCurrentLanguage(highlighter2, std.mem.span(dictionary));
}
