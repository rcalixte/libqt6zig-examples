const std = @import("std");
const qt6 = @import("libqt6zig");
const qapplication = qt6.qapplication;
const krichtextedit = qt6.krichtextedit;
const qfile = qt6.qfile;
const qiodevicebase_enums = qt6.qiodevicebase_enums;

pub fn main(init: std.process.Init) !void {
    const argv = try qt6.init(init.gpa, init.minimal.args);
    defer qt6.deinit(init.gpa, argv);
    var argc: i32 = @intCast(argv.len);
    const qapp = qapplication.New(&argc, argv, init.arena.allocator());
    defer qapplication.Delete(qapp);

    const textedit = krichtextedit.New3();
    defer krichtextedit.Delete(textedit);

    krichtextedit.SetWindowTitle(textedit, "Qt 6 KTextWidgets Example");
    krichtextedit.SetMinimumSize2(textedit, 900, 750);
    krichtextedit.SetFontFamily(textedit, "DejaVu Sans Mono");
    krichtextedit.SetFontSize(textedit, 13);

    // Use Ctrl+F to search the file or right-click for a rich menu
    const file = qfile.New4("src/libraries/extras/ktextwidgets/main.zig", textedit);

    if (qfile.Open(file, qiodevicebase_enums.OpenModeFlag.ReadOnly)) {
        const text = qfile.ReadAll(file, init.gpa);
        defer init.gpa.free(text);
        krichtextedit.SetTextOrHtml(textedit, text);
        qfile.Close(file);
    }

    krichtextedit.Show(textedit);

    _ = qapplication.Exec();
}
