const std = @import("std");
const qt6 = @import("libqt6zig");
const qapplication = qt6.qapplication;
const kguiitem = qt6.kguiitem;
const kmessagebox = qt6.kmessagebox;
const kmessagebox_enums = qt6.kmessagebox_enums;

pub fn main(init: std.process.Init) !void {
    const argv = try qt6.init(init.gpa, init.minimal.args);
    defer qt6.deinit(init.gpa, argv);
    var argc: i32 = @intCast(argv.len);
    const qapp = qapplication.New(&argc, argv, init.arena.allocator());
    defer qapplication.Delete(qapp);

    const primary_item = kguiitem.New7(
        "Hello",
        "view-filter",
        "This is a tooltip",
        "This is a WhatsThis help text.",
    );

    const secondary_item = kguiitem.New2("Bye");

    const res = kmessagebox.QuestionTwoActions(
        null,
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
