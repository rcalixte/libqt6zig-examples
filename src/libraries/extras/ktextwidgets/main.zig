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
    const qapp = QApplication.New(init.arena.allocator(), &argc, argv);
    defer qapp.Delete();

    const textedit = KRichTextEdit.New3();
    defer textedit.Delete();

    textedit.SetWindowTitle("Qt 6 KTextWidgets Example");
    textedit.SetMinimumSize2(900, 750);
    textedit.SetFontFamily("DejaVu Sans Mono");
    textedit.SetFontSize(13);

    // Use Ctrl+F to search the file or right-click for a rich menu
    const file = QFile.New4("src/libraries/extras/ktextwidgets/main.zig", textedit);

    if (file.Open(qiodevicebase_enums.OpenModeFlag.ReadOnly)) {
        const text = file.ReadAll(init.gpa);
        defer init.gpa.free(text);
        textedit.SetTextOrHtml(text);
        file.Close();
    }

    textedit.Show();

    _ = QApplication.Exec();
}
