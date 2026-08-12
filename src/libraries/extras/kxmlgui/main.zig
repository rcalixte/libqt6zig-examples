const std = @import("std");
const qt6 = @import("libqt6zig");
const QApplication = qt6.QApplication;
const KShortcutsDialog = qt6.KShortcutsDialog;
const qnamespace_enums = qt6.qnamespace_enums;

pub fn main(init: std.process.Init) !void {
    const argv = try qt6.init(init.gpa, init.minimal.args);
    defer qt6.deinit(init.gpa, argv);
    var argc: i32 = @intCast(argv.len);
    const qapp: QApplication = .new(init.arena.allocator(), &argc, argv);
    defer qapp.delete();

    const dialog = KShortcutsDialog.new2();
    dialog.setWindowTitle("Qt 6 KXmlGui Example");
    dialog.setMinimumSize2(400, 450);
    dialog.setAttribute(qnamespace_enums.WidgetAttribute.WA_DeleteOnClose);

    // Empty shortcut dialog
    _ = dialog.configure();
}
