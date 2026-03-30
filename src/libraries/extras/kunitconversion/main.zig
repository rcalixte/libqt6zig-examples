const std = @import("std");
const qt6 = @import("libqt6zig");
const C = qt6.C;
const qapplication = qt6.qapplication;
const qwidget = qt6.qwidget;
const qvboxlayout = qt6.qvboxlayout;
const kunitconversion__converter = qt6.kunitconversion__converter;
const unit_enums = qt6.unit_enums;
const qcombobox = qt6.qcombobox;
const kunitconversion__unitcategory = qt6.kunitconversion__unitcategory;
const kunitconversion__unit = qt6.kunitconversion__unit;
const qvariant = qt6.qvariant;
const qlineedit = qt6.qlineedit;
const qlabel = qt6.qlabel;
const qnamespace_enums = qt6.qnamespace_enums;
const kunitconversion__value = qt6.kunitconversion__value;

var gpa = @import("alloc_config").gpa;
const allocator = gpa.allocator();

var buffer: [128]u8 = undefined;

var from: C.QComboBox = null;
var to: C.QComboBox = null;
var input: C.QLineEdit = null;
var result: C.QLabel = null;

pub fn main() !void {
    const argc = std.os.argv.len;
    const argv = std.os.argv.ptr;
    const qapp = qapplication.New(argc, argv);
    defer qapplication.Delete(qapp);

    defer _ = gpa.deinit();

    const widget = qwidget.New2();
    defer qwidget.Delete(widget);

    qwidget.SetWindowTitle(widget, "Qt 6 KunitConversion Example");
    qwidget.SetFixedSize2(widget, 450, 300);

    const layout = qvboxlayout.New(widget);
    const converter = kunitconversion__converter.New();
    defer kunitconversion__converter.Delete(converter);

    // Update the category type to change the units!
    const category = kunitconversion__converter.Category2(converter, unit_enums.CategoryId.LengthCategory);
    defer kunitconversion__unitcategory.Delete(category);

    from = qcombobox.New2();
    to = qcombobox.New2();

    const units = kunitconversion__unitcategory.Units(category, allocator);
    defer allocator.free(units);

    for (units) |unit| {
        const description = kunitconversion__unit.Description(unit, allocator);
        defer allocator.free(description);

        const id = kunitconversion__unit.Id(unit);
        const data = qvariant.New4(id);
        defer qvariant.Delete(data);

        qcombobox.AddItem22(from, description, data);
        qcombobox.AddItem22(to, description, data);
    }

    input = qlineedit.New2();
    qlineedit.SetPlaceholderText(input, "Enter a value");

    result = qlabel.New3("### Result:");
    qlabel.SetTextFormat(result, qnamespace_enums.TextFormat.MarkdownText);
    qlabel.SetAlignment(result, qnamespace_enums.AlignmentFlag.AlignCenter);

    qvboxlayout.AddWidget(layout, qlabel.New3("From:"));
    qvboxlayout.AddWidget(layout, from);
    qvboxlayout.AddWidget(layout, input);
    qvboxlayout.AddStretch(layout);
    qvboxlayout.AddWidget(layout, qlabel.New3("To:"));
    qvboxlayout.AddWidget(layout, to);
    qvboxlayout.AddStretch(layout);
    qvboxlayout.AddWidget(layout, result);

    qcombobox.OnCurrentIndexChanged(from, onComboChanged);
    qcombobox.OnCurrentIndexChanged(to, onComboChanged);
    qlineedit.OnTextChanged(input, onTextChanged);

    qlineedit.SetFocus(input);

    qwidget.Show(widget);

    _ = qapplication.Exec();
}

fn onComboChanged(_: ?*anyopaque, _: i32) callconv(.c) void {
    onTextChanged(input, "");
}

fn onTextChanged(_: ?*anyopaque, _: [*:0]const u8) callconv(.c) void {
    const text = qlineedit.Text(input, allocator);
    defer allocator.free(text);

    if (std.mem.eql(u8, text, "")) {
        qlabel.SetText(result, "### Result:");
        return;
    }

    const value = std.fmt.parseFloat(f64, text) catch {
        qlabel.SetText(result, "### Invalid input");
        return;
    };

    const from_data = qcombobox.CurrentData(from);
    defer qvariant.Delete(from_data);

    const from_id = qvariant.ToInt(from_data);

    const to_data = qcombobox.CurrentData(to);
    defer qvariant.Delete(to_data);

    const to_id = qvariant.ToInt(to_data);

    const converted_obj = kunitconversion__value.New4(value, from_id);
    defer kunitconversion__value.Delete(converted_obj);

    const converted_value = kunitconversion__value.ConvertTo2(converted_obj, to_id);
    defer kunitconversion__value.Delete(converted_value);

    const converted_text = kunitconversion__value.ToString(converted_value, allocator);
    defer allocator.free(converted_text);

    qlabel.SetText(result, std.fmt.bufPrintZ(&buffer, "### Result: {s}", .{converted_text}) catch @panic("Failed to bufPrintz"));
}
