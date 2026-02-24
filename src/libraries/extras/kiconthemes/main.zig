const std = @import("std");
const qt6 = @import("libqt6zig");
const qapplication = qt6.qapplication;
const kiconbutton = qt6.kiconbutton;

pub fn main() void {
    const argc = std.os.argv.len;
    const argv = std.os.argv.ptr;
    const qapp = qapplication.New(argc, argv);
    defer qapplication.Delete(qapp);

    const button = kiconbutton.New2();
    defer kiconbutton.Delete(button);

    kiconbutton.SetWindowTitle(button, "Qt 6 KIconThemes Example");
    kiconbutton.SetText(button, "Click to open the chooser dialog");
    kiconbutton.SetMinimumSize2(button, 320, 70);
    kiconbutton.SetIconSize(button, 64);

    kiconbutton.Show(button);

    _ = qapplication.Exec();
}
