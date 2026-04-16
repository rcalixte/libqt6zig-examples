const std = @import("std");
const qt6 = @import("libqt6zig");
const QApplication = qt6.QApplication;
const KGuiItem = qt6.KGuiItem;
const KMessageBox = qt6.KMessageBox;
const kmessagebox_enums = qt6.kmessagebox_enums;
const QWidget = qt6.QWidget;

pub fn main(init: std.process.Init) !void {
    const argv = try qt6.init(init.gpa, init.minimal.args);
    defer qt6.deinit(init.gpa, argv);
    var argc: i32 = @intCast(argv.len);
    const qapp = QApplication.New(init.arena.allocator(), &argc, argv);
    defer qapp.Delete();

    const primary_item = KGuiItem.New7(
        "Hello",
        "view-filter",
        "This is a tooltip",
        "This is a WhatsThis help text.",
    );

    const secondary_item = KGuiItem.New2("Bye");

    const res = KMessageBox.QuestionTwoActions(
        QWidget{ .ptr = null },
        "Description to tell you to click<br />on <b>either</b> button",
        "Qt 6 KMessageBox Example",
        primary_item,
        secondary_item,
        "",
        kmessagebox_enums.Option.Notify,
    );

    switch (res) {
        kmessagebox_enums.ButtonCode.PrimaryAction => try std.Io.File.stdout().writeStreamingAll(init.io, "You clicked Hello\n"),
        else => try std.Io.File.stdout().writeStreamingAll(init.io, "You clicked Bye\n"),
    }
}
