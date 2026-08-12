const std = @import("std");
const qt6 = @import("libqt6zig");
const QApplication = qt6.QApplication;
const KRichTextEdit = qt6.KRichTextEdit;
const QFile = qt6.QFile;
const qiodevicebase_enums = qt6.qiodevicebase_enums;

pub fn main(init: std.process.Init) !void {
    const argv = try qt6.init(init.gpa, init.minimal.args);
    defer qt6.deinit(init.gpa, argv);
    var argc: i32 = @intCast(argv.len);
    const qapp: QApplication = .new(init.arena.allocator(), &argc, argv);
    defer qapp.delete();

    const textedit = KRichTextEdit.new3();
    defer textedit.delete();

    textedit.setWindowTitle("Qt 6 KTextWidgets Example");
    textedit.setMinimumSize2(900, 750);
    textedit.setFontFamily("DejaVu Sans Mono");
    textedit.setFontSize(13);

    // Use Ctrl+F to search the file or right-click for a rich menu
    const file = QFile.new4("src/libraries/extras/ktextwidgets/main.zig", textedit);

    if (file.open(qiodevicebase_enums.OpenModeFlag.ReadOnly)) {
        const text = file.readAll(init.gpa);
        defer init.gpa.free(text);
        textedit.setTextOrHtml(text);
        file.close();
    }

    textedit.show();

    _ = QApplication.exec();
}
