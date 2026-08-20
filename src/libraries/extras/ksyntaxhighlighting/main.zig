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
    const qapp: QApplication = .new(init.arena.allocator(), &argc, argv);
    defer qapp.delete();

    const window = QMainWindow.new2();
    defer window.delete();

    window.setWindowTitle("Qt 6 KSyntaxHighlighting Example");
    window.setMinimumSize2(1150, 750);

    const file = QFile.new4(src_file, window);

    if (!file.open(qiodevicebase_enums.OpenModeFlag.ReadOnly)) {
        std.log.err("Failed to open file: {s}", .{src_file});
        return;
    }

    const plaintextedit = QPlainTextEdit.new(window);

    const font = QFont.new6("DejaVu Sans Mono", 13);
    defer font.delete();

    plaintextedit.setFont(font);

    window.setCentralWidget(plaintextedit);

    const text = file.readAll(init.gpa);
    defer {
        init.gpa.free(text);
        file.close();
    }

    plaintextedit.setPlainText(text);

    const document = plaintextedit.document();
    defer document.delete();

    const highlighter = KSyntaxHighlighting__SyntaxHighlighter.new2(document);
    defer highlighter.delete();

    const repository = KSyntaxHighlighting__Repository.new();
    defer repository.delete();

    const theme = switch (plaintextedit.palette().color2(qpalette_enums.ColorRole.Base).lightness()) {
        0...127 => repository.defaultTheme1(repository_enums.DefaultTheme.DarkTheme),
        128...255 => repository.defaultTheme1(repository_enums.DefaultTheme.LightTheme),
        else => unreachable,
    };
    defer theme.delete();

    highlighter.setTheme(theme);
    const definition = repository.definitionForFileName(src_file);
    defer definition.delete();

    highlighter.setDefinition(definition);

    window.show();

    _ = QApplication.exec();
}
