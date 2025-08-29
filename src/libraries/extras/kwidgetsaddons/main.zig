const std = @import("std");
const qt6 = @import("libqt6zig");
const qapplication = qt6.qapplication;
const kguiitem = qt6.kguiitem;
const kmessagebox = qt6.kmessagebox;
const kmessagebox_enums = qt6.kmessagebox_enums;

var buffer: [32]u8 = undefined;
var stdout_writer = std.fs.File.stdout().writer(&buffer);

pub fn main() !void {
    const argc = std.os.argv.len;
    const argv = std.os.argv.ptr;
    const qapp = qapplication.New(argc, argv);
    defer qapplication.QDelete(qapp);

    const primaryAction = kguiitem.New7(
        "Hello",
        "view-filter",
        "This is a tooltip",
        "This is a WhatsThis help text.",
    );

    const secondaryAction = kguiitem.New2("Bye");

    const res = kmessagebox.QuestionTwoActions(
        null,
        "Description to tell you to click<br />on <b>either</b> button",
        "Qt 6 KMessageBox Example",
        primaryAction,
        secondaryAction,
        "",
        kmessagebox_enums.Option.Notify,
    );

    switch (res) {
        kmessagebox_enums.ButtonCode.PrimaryAction => {
            try stdout_writer.interface.writeAll("You clicked Hello\n");
        },
        else => {
            try stdout_writer.interface.writeAll("You clicked Bye\n");
        },
    }
    try stdout_writer.interface.flush();
}
