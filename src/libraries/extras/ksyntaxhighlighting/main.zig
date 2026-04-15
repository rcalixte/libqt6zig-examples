const std = @import("std");
const qt6 = @import("libqt6zig");
const qapplication = qt6.qapplication;
const qmainwindow = qt6.qmainwindow;
const qplaintextedit = qt6.qplaintextedit;
const qfont = qt6.qfont;
const qfile = qt6.qfile;
const qiodevicebase_enums = qt6.qiodevicebase_enums;
const ksyntaxhighlighting__syntaxhighlighter = qt6.ksyntaxhighlighting__syntaxhighlighter;
const ksyntaxhighlighting__repository = qt6.ksyntaxhighlighting__repository;
const qcolor = qt6.qcolor;
const qpalette = qt6.qpalette;
const qpalette_enums = qt6.qpalette_enums;
const repository_enums = qt6.repository_enums;

const src_file = "src/libraries/extras/ksyntaxhighlighting/main.zig";

pub fn main(init: std.process.Init) !void {
    const argv = try qt6.init(init.gpa, init.minimal.args);
    defer qt6.deinit(init.gpa, argv);
    var argc: i32 = @intCast(argv.len);
    const qapp = qapplication.New(&argc, argv, init.arena.allocator());
    defer qapplication.Delete(qapp);

    const window = qmainwindow.New2();
    defer qmainwindow.Delete(window);

    qmainwindow.SetWindowTitle(window, "Qt 6 KSyntaxHighlighting Example");
    qmainwindow.SetMinimumSize2(window, 1550, 750);

    const file = qfile.New4(src_file, window);

    if (!qfile.Open(file, qiodevicebase_enums.OpenModeFlag.ReadOnly)) {
        try std.Io.File.stdout().writeStreamingAll(init.io, "\nFailed to open file: \t" ++ src_file ++ "\n");
        return;
    }

    const plaintextedit = qplaintextedit.New2();

    const font = qfont.New6("DejaVu Sans Mono", 13);
    defer qfont.Delete(font);

    qplaintextedit.SetFont(plaintextedit, font);

    qmainwindow.SetCentralWidget(window, plaintextedit);

    const text = qfile.ReadAll(file, init.gpa);
    defer {
        init.gpa.free(text);
        qfile.Close(file);
    }

    qplaintextedit.SetPlainText(plaintextedit, text);

    const document = qplaintextedit.Document(plaintextedit);
    const highlighter = ksyntaxhighlighting__syntaxhighlighter.New2(document);
    defer ksyntaxhighlighting__syntaxhighlighter.Delete(highlighter);

    const repository = ksyntaxhighlighting__repository.New();

    const theme = switch (qcolor.Lightness(qpalette.Color2(qplaintextedit.Palette(plaintextedit), qpalette_enums.ColorRole.Base))) {
        0...127 => ksyntaxhighlighting__repository.DefaultTheme1(repository, repository_enums.DefaultTheme.DarkTheme),
        128...255 => ksyntaxhighlighting__repository.DefaultTheme1(repository, repository_enums.DefaultTheme.LightTheme),
        else => unreachable,
    };

    ksyntaxhighlighting__syntaxhighlighter.SetTheme(highlighter, theme);
    ksyntaxhighlighting__syntaxhighlighter.SetDefinition(highlighter, ksyntaxhighlighting__repository.DefinitionForFileName(repository, src_file));

    qmainwindow.Show(window);

    _ = qapplication.Exec();
}
