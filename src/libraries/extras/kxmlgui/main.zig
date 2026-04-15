const std = @import("std");
const qt6 = @import("libqt6zig");
const qapplication = qt6.qapplication;
const kshortcutsdialog = qt6.kshortcutsdialog;
const qnamespace_enums = qt6.qnamespace_enums;

pub fn main(init: std.process.Init) !void {
    const argv = try qt6.init(init.gpa, init.minimal.args);
    defer qt6.deinit(init.gpa, argv);
    var argc: i32 = @intCast(argv.len);
    const qapp = qapplication.New(&argc, argv, init.arena.allocator());
    defer qapplication.Delete(qapp);

    const dialog = kshortcutsdialog.New2();
    kshortcutsdialog.SetWindowTitle(dialog, "Qt 6 KXmlGui Example");
    kshortcutsdialog.SetMinimumSize2(dialog, 400, 450);
    kshortcutsdialog.SetAttribute(dialog, qnamespace_enums.WidgetAttribute.WA_DeleteOnClose);

    // Empty shortcut dialog
    _ = kshortcutsdialog.Configure(dialog);
}
