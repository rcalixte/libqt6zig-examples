const std = @import("std");
const qt6 = @import("libqt6zig");
const C = qt6.C;
const qapplication = qt6.qapplication;
const qwidget = qt6.qwidget;
const qlineedit = qt6.qlineedit;
const qlabel = qt6.qlabel;
const qnamespace_enums = qt6.qnamespace_enums;
const kdatevalidator = qt6.kdatevalidator;
const qvboxlayout = qt6.qvboxlayout;
const qvalidator_enums = qt6.qvalidator_enums;

var label: C.QLabel = undefined;

pub fn main() void {
    const argc = std.os.argv.len;
    const argv = std.os.argv.ptr;
    const qapp = qapplication.New(argc, argv);
    defer qapplication.QDelete(qapp);

    const widget = qwidget.New2();
    defer qwidget.QDelete(widget);

    qwidget.SetWindowTitle(widget, "Qt 6 KGuiAddons Example");
    qwidget.SetMinimumSize2(widget, 380, 180);

    const titlelabel = qlabel.New3("Enter a date:");

    const input = qlineedit.New2();
    qlineedit.OnTextChanged(input, onTextChanged);

    label = qlabel.New2();
    qlabel.SetAlignment(label, qnamespace_enums.AlignmentFlag.AlignCenter);
    qlabel.SetStyleSheet(label, "font: bold;");

    const validator = kdatevalidator.New();
    qlineedit.SetValidator(input, validator);

    const layout = qvboxlayout.New(widget);
    qvboxlayout.AddWidget(layout, titlelabel);
    qvboxlayout.AddWidget(layout, input);
    qvboxlayout.AddWidget(layout, label);

    qwidget.Show(widget);

    _ = qapplication.Exec();
}

fn onTextChanged(self: ?*anyopaque, text: [*:0]const u8) callconv(.C) void {
    var pos = qlineedit.CursorPosition(self);
    const ret = kdatevalidator.Validate(qlineedit.Validator(self), std.mem.span(text), &pos);

    switch (ret) {
        qvalidator_enums.State.Acceptable => {
            qlabel.SetText(label, "Validation result: Acceptable");
        },
        qvalidator_enums.State.Intermediate => {
            qlabel.SetText(label, "Validation result: Intermediate");
        },
        qvalidator_enums.State.Invalid => {
            qlabel.SetText(label, "Validation result: Invalid");
        },
        else => unreachable,
    }
}
