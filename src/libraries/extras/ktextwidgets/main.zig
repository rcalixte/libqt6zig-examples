const std = @import("std");
const qt6 = @import("libqt6zig");
const qapplication = qt6.qapplication;
const krichtextedit = qt6.krichtextedit;
const qfile = qt6.qfile;
const qiodevicebase_enums = qt6.qiodevicebase_enums;

var gpa = @import("alloc_config").gpa;
const allocator = gpa.allocator();

pub fn main() void {
    const argc = std.os.argv.len;
    const argv = std.os.argv.ptr;
    const qapp = qapplication.New(argc, argv);
    defer qapplication.Delete(qapp);

    defer _ = gpa.deinit();

    const textedit = krichtextedit.New3();
    defer krichtextedit.Delete(textedit);

    krichtextedit.SetWindowTitle(textedit, "Qt 6 KTextWidgets Example");
    krichtextedit.SetMinimumSize2(textedit, 900, 850);
    krichtextedit.SetFontFamily(textedit, "DejaVu Sans Mono");
    krichtextedit.SetFontSize(textedit, 13);

    // Use Ctrl+F to search the file or right-click for a rich menu
    const file = qfile.New4("src/libraries/extras/ktextwidgets/main.zig", textedit);

    if (qfile.Open(file, qiodevicebase_enums.OpenModeFlag.ReadOnly)) {
        const text = qfile.ReadAll(file, allocator);
        defer allocator.free(text);
        krichtextedit.SetTextOrHtml(textedit, text);
        qfile.Close(file);
    }

    krichtextedit.Show(textedit);

    _ = qapplication.Exec();
}
