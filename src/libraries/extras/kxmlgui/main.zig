const std = @import("std");
const qt6 = @import("libqt6zig");
const QApplication = qt6.QApplication;
const KShortcutsDialog = qt6.KShortcutsDialog;
const qnamespace_enums = qt6.qnamespace_enums;

pub fn main(init: std.process.Init) !void {
    const argv = try qt6.init(init.gpa, init.minimal.args);
    defer qt6.deinit(init.gpa, argv);
    var argc: i32 = @intCast(argv.len);
    const qapp = QApplication.New(init.arena.allocator(), &argc, argv);
    defer qapp.Delete();

    const dialog = KShortcutsDialog.New2();
    dialog.SetWindowTitle("Qt 6 KXmlGui Example");
    dialog.SetMinimumSize2(400, 450);
    dialog.SetAttribute(qnamespace_enums.WidgetAttribute.WA_DeleteOnClose);

    // Empty shortcut dialog
    _ = dialog.Configure();
}
