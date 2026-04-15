const std = @import("std");
const qt6 = @import("libqt6zig");
const qapplication = qt6.qapplication;
const kcharsets = qt6.kcharsets;
const qwidget = qt6.qwidget;
const qvboxlayout = qt6.qvboxlayout;
const qlabel = qt6.qlabel;
const qlistwidget = qt6.qlistwidget;

pub fn main(init: std.process.Init) !void {
    const argv = try qt6.init(init.gpa, init.minimal.args);
    defer qt6.deinit(init.gpa, argv);
    var argc: i32 = @intCast(argv.len);
    const qapp = qapplication.New(&argc, argv, init.arena.allocator());
    defer qapplication.Delete(qapp);

    const charsets = kcharsets.Charsets();

    const names = kcharsets.AvailableEncodingNames(charsets, init.gpa);
    defer {
        for (names) |name|
            init.gpa.free(name);
        init.gpa.free(names);
    }

    const widget = qwidget.New2();
    defer qwidget.Delete(widget);

    qwidget.SetWindowTitle(widget, "Qt 6 KCharsets");
    qwidget.SetMinimumSize2(widget, 300, 400);

    const vboxlayout = qvboxlayout.New2();
    const label = qlabel.New3("Available Encodings:");
    const listwidget = qlistwidget.New2();

    qlistwidget.AddItems(listwidget, names, init.gpa);

    qvboxlayout.AddWidget(vboxlayout, label);
    qvboxlayout.AddWidget(vboxlayout, listwidget);
    qwidget.SetLayout(widget, vboxlayout);

    qwidget.Show(widget);

    _ = qapplication.Exec();
}
