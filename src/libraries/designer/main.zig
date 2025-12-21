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

const FORMFILE = "src/libraries/designer/design.ui";

pub fn main() void {
    const argc = std.os.argv.len;
    const argv = std.os.argv.ptr;
    const qapp = qapplication.New(argc, argv);
    defer qapplication.QDelete(qapp);

    const widget = qwidget.New2();
    defer qwidget.QDelete(widget);

    qwidget.SetWindowTitle(widget, "Qt 6 Designer Example");

    const layout = qvboxlayout.New(widget);

    const builder = qformbuilder.New();
    defer qformbuilder.QDelete(builder);

    const file = qfile.New2(FORMFILE);
    defer qfile.QDelete(file);

    if (qfile.Open(file, qiodevicebase_enums.OpenModeFlag.ReadOnly)) {
        defer qfile.Close(file);

        const parent = qwidget.New2();
        const form = qformbuilder.Load(builder, file, parent);
        qvboxlayout.AddWidget(layout, form);
        qwidget.Resize(widget, 850, 550);
    } else {
        const label = qlabel.New5("### Failed to open form file: " ++ FORMFILE, widget);
        qlabel.SetTextFormat(label, qnamespace_enums.TextFormat.MarkdownText);
        qlabel.SetAlignment(label, qnamespace_enums.AlignmentFlag.AlignCenter);
        qvboxlayout.AddWidget(layout, label);
        qwidget.Resize(widget, 550, 100);
    }

    qwidget.Show(widget);

    _ = qapplication.Exec();
}
