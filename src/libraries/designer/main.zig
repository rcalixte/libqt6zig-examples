const std = @import("std");
const qt6 = @import("libqt6zig");
const qapplication = qt6.qapplication;
const qwidget = qt6.qwidget;
const qvboxlayout = qt6.qvboxlayout;
const qformbuilder = qt6.qformbuilder;
const qfile = qt6.qfile;
const qiodevicebase_enums = qt6.qiodevicebase_enums;
const qlabel = qt6.qlabel;
const qnamespace_enums = qt6.qnamespace_enums;

const form_path = "src/libraries/designer/design.ui";

pub fn main(init: std.process.Init) !void {
    const argv = try qt6.init(init.gpa, init.minimal.args);
    defer qt6.deinit(init.gpa, argv);
    var argc: i32 = @intCast(argv.len);
    const qapp = qapplication.New(&argc, argv, init.arena.allocator());
    defer qapplication.Delete(qapp);

    const widget = qwidget.New2();
    defer qwidget.Delete(widget);

    qwidget.SetWindowTitle(widget, "Qt 6 Designer Example");

    const layout = qvboxlayout.New(widget);

    const builder = qformbuilder.New();
    defer qformbuilder.Delete(builder);

    const file = qfile.New2(form_path);
    defer qfile.Delete(file);

    if (qfile.Open(file, qiodevicebase_enums.OpenModeFlag.ReadOnly)) {
        defer qfile.Close(file);

        const parent = qwidget.New2();
        const form = qformbuilder.Load(builder, file, parent);
        qvboxlayout.AddWidget(layout, form);
        qwidget.Resize(widget, 850, 550);
    } else {
        const label = qlabel.New5("### Failed to open form file: " ++ form_path, widget);
        qlabel.SetTextFormat(label, qnamespace_enums.TextFormat.MarkdownText);
        qlabel.SetAlignment(label, qnamespace_enums.AlignmentFlag.AlignCenter);
        qvboxlayout.AddWidget(layout, label);
        qwidget.Resize(widget, 550, 100);
    }

    qwidget.Show(widget);

    _ = qapplication.Exec();
}
