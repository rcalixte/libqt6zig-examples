const std = @import("std");
const qt6 = @import("libqt6zig");
const qapplication = qt6.qapplication;
const kcharsets = qt6.kcharsets;
const qwidget = qt6.qwidget;
const qvboxlayout = qt6.qvboxlayout;
const qlabel = qt6.qlabel;
const qlistwidget = qt6.qlistwidget;

const getAllocatorConfig = @import("alloc_config").getAllocatorConfig;
const config = getAllocatorConfig();
var gda: std.heap.DebugAllocator(config) = .init;
const allocator = gda.allocator();

pub fn main() void {
    const argc = std.os.argv.len;
    const argv = std.os.argv.ptr;
    _ = qapplication.New(argc, argv);

    const charsets = kcharsets.Charsets();

    const names = kcharsets.AvailableEncodingNames(charsets, allocator);
    defer {
        for (names) |name| {
            allocator.free(name);
        }
        allocator.free(names);
    }

    const widget = qwidget.New2();
    defer qwidget.QDelete(widget);

    qwidget.SetWindowTitle(widget, "Qt 6 KCharsets");
    qwidget.SetMinimumSize2(widget, 300, 400);

    // Ownership of these widgets will be transferred to the widget via the layout
    const vboxlayout = qvboxlayout.New2();
    const label = qlabel.New3("Available Encodings:");
    const listwidget = qlistwidget.New2();

    qlistwidget.AddItems(listwidget, names, allocator);

    qvboxlayout.AddWidget(vboxlayout, label);
    qvboxlayout.AddWidget(vboxlayout, listwidget);
    qwidget.SetLayout(widget, vboxlayout);

    qwidget.Show(widget);

    _ = qapplication.Exec();
}
