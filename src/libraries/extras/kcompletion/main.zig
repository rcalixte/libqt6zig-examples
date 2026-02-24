const std = @import("std");
const qt6 = @import("libqt6zig");
const qapplication = qt6.qapplication;
const qwidget = qt6.qwidget;
const qlabel = qt6.qlabel;
const qvboxlayout = qt6.qvboxlayout;
const klineedit = qt6.klineedit;
const kcompletion = qt6.kcompletion;
const kcompletion_enums = qt6.kcompletion_enums;

var gpa = @import("alloc_config").gpa;
const allocator = gpa.allocator();

pub fn main() void {
    const argc = std.os.argv.len;
    const argv = std.os.argv.ptr;
    const qapp = qapplication.New(argc, argv);
    defer qapplication.Delete(qapp);

    defer _ = gpa.deinit();

    const widget = qwidget.New2();
    defer qwidget.Delete(widget);

    qwidget.SetWindowTitle(widget, "Qt 6 KCompletion Example");
    qwidget.SetMinimumSize2(widget, 300, 200);

    const label = qlabel.New3("Enter the letter 'H':");

    const vboxlayout = qvboxlayout.New2();

    const lineedit = klineedit.New3();
    // Try different completion modes!
    klineedit.SetCompletionMode(lineedit, kcompletion_enums.CompletionMode.CompletionPopupAuto);

    const completion = kcompletion.New();
    kcompletion.SetSoundsEnabled(completion, false);
    klineedit.SetCompletionObject(lineedit, completion, true);

    const items = [_][]const u8{ "Hello Qt", "Hello Zig", "Hello libqt6zig", "Hello you", "Hello world" };
    kcompletion.SetItems(completion, &items, allocator);

    qvboxlayout.AddStretch(vboxlayout);
    qvboxlayout.AddWidget(vboxlayout, label);
    qvboxlayout.AddWidget(vboxlayout, lineedit);
    qvboxlayout.AddStretch(vboxlayout);
    qwidget.SetLayout(widget, vboxlayout);

    qwidget.Show(widget);

    _ = qapplication.Exec();
}
