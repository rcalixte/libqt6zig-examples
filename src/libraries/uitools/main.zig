const std = @import("std");
const qt6 = @import("libqt6zig");
const qapplication = qt6.qapplication;
const qnamespace_enums = qt6.qnamespace_enums;
const qwidget = qt6.qwidget;
const qvboxlayout = qt6.qvboxlayout;
const quiloader = qt6.quiloader;
const qfile = qt6.qfile;
const qiodevicebase_enums = qt6.qiodevicebase_enums;
const qlabel = qt6.qlabel;

const FORMFILE = "src/libraries/uitools/design.ui";

pub fn main() void {
    qapplication.SetAttribute(qnamespace_enums.ApplicationAttribute.AA_ShareOpenGLContexts);
    const argc = std.os.argv.len;
    const argv = std.os.argv.ptr;
    const qapp = qapplication.New(argc, argv);
    defer qapplication.Delete(qapp);

    const widget = qwidget.New2();
    defer qwidget.Delete(widget);

    qwidget.SetWindowTitle(widget, "Qt 6 UI Tools Example");

    const layout = qvboxlayout.New(widget);

    const loader = quiloader.New();
    defer quiloader.Delete(loader);

    const file = qfile.New2(FORMFILE);
    defer qfile.Delete(file);

    if (qfile.Open(file, qiodevicebase_enums.OpenModeFlag.ReadOnly)) {
        defer qfile.Close(file);

        const parent = qwidget.New2();
        const form = quiloader.Load2(loader, file, parent);
        qvboxlayout.AddWidget(layout, form);
        qwidget.Resize(widget, 1000, 550);
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
