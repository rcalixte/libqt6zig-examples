const std = @import("std");
const qt6 = @import("libqt6zig");
const QApplication = qt6.QApplication;
const QMainWindow = qt6.QMainWindow;
const QPlainTextEdit = qt6.QPlainTextEdit;
const QFont = qt6.QFont;
const QFile = qt6.QFile;
const qiodevicebase_enums = qt6.qiodevicebase_enums;
const KSyntaxHighlighting__SyntaxHighlighter = qt6.KSyntaxHighlighting__SyntaxHighlighter;
const KSyntaxHighlighting__Repository = qt6.KSyntaxHighlighting__Repository;
const qpalette_enums = qt6.qpalette_enums;
const repository_enums = qt6.repository_enums;

const src_file = "src/libraries/extras/ksyntaxhighlighting/main.zig";

pub fn main(init: std.process.Init) !void {
    const argv = try qt6.init(init.gpa, init.minimal.args);
    defer qt6.deinit(init.gpa, argv);
    var argc: i32 = @intCast(argv.len);
    const qapp = QApplication.New(init.arena.allocator(), &argc, argv);
    defer qapp.Delete();

    const window = QMainWindow.New2();
    defer window.Delete();

    window.SetWindowTitle("Qt 6 KSyntaxHighlighting Example");
    window.SetMinimumSize2(1550, 750);

    const file = QFile.New4(src_file, window);

    if (!file.Open(qiodevicebase_enums.OpenModeFlag.ReadOnly)) {
        try std.Io.File.stdout().writeStreamingAll(init.io, "\nFailed to open file: \t" ++ src_file ++ "\n");
        return;
    }

    const plaintextedit = QPlainTextEdit.New2();

    const font = QFont.New6("DejaVu Sans Mono", 13);
    defer font.Delete();

    plaintextedit.SetFont(font);

    window.SetCentralWidget(plaintextedit);

    const text = file.ReadAll(init.gpa);
    defer {
        init.gpa.free(text);
        file.Close();
    }

    plaintextedit.SetPlainText(text);

    const document = plaintextedit.Document();
    const highlighter = KSyntaxHighlighting__SyntaxHighlighter.New2(document);
    defer highlighter.Delete();

    const repository = KSyntaxHighlighting__Repository.New();

    const theme = switch (plaintextedit.Palette().Color2(qpalette_enums.ColorRole.Base).Lightness()) {
        0...127 => repository.DefaultTheme1(repository_enums.DefaultTheme.DarkTheme),
        128...255 => repository.DefaultTheme1(repository_enums.DefaultTheme.LightTheme),
        else => unreachable,
    };

    highlighter.SetTheme(theme);
    highlighter.SetDefinition(repository.DefinitionForFileName(src_file));

    window.Show();

    _ = QApplication.Exec();
}
