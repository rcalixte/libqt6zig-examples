const std = @import("std");
const qt6 = @import("libqt6zig");
const QApplication = qt6.QApplication;
const QWidget = qt6.QWidget;
const QVBoxLayout = qt6.QVBoxLayout;
const KUnitConversion__Converter = qt6.KUnitConversion__Converter;
const unit_enums = qt6.unit_enums;
const QComboBox = qt6.QComboBox;
const QVariant = qt6.QVariant;
const QLineEdit = qt6.QLineEdit;
const QLabel = qt6.QLabel;
const qnamespace_enums = qt6.qnamespace_enums;
const KUnitConversion__Value = qt6.KUnitConversion__Value;

var allocator: std.mem.Allocator = undefined;

var buffer: [128]u8 = undefined;

var from: QComboBox = undefined;
var to: QComboBox = undefined;
var input: QLineEdit = undefined;
var result: QLabel = undefined;

pub fn main(init: std.process.Init) !void {
    const argv = try qt6.init(init.gpa, init.minimal.args);
    defer qt6.deinit(init.gpa, argv);
    var argc: i32 = @intCast(argv.len);
    const qapp = QApplication.New(init.arena.allocator(), &argc, argv);
    defer qapp.Delete();

    allocator = init.gpa;

    const widget = QWidget.New2();
    defer widget.Delete();

    widget.SetWindowTitle("Qt 6 KUnitConversion Example");
    widget.SetFixedSize2(450, 300);

    const layout = QVBoxLayout.New(widget);
    const converter = KUnitConversion__Converter.New();
    defer converter.Delete();

    // Update the category type to change the units!
    const category = converter.Category2(unit_enums.CategoryId.LengthCategory);
    defer category.Delete();

    from = QComboBox.New2();
    to = QComboBox.New2();

    const units = category.Units(allocator);
    defer allocator.free(units);

    for (units) |unit| {
        const description = unit.Description(allocator);
        defer allocator.free(description);

        const id = unit.Id();
        const data = QVariant.New4(id);
        defer data.Delete();

        from.AddItem22(description, data);
        to.AddItem22(description, data);
    }

    input = QLineEdit.New2();
    input.SetPlaceholderText("Enter a value");

    result = QLabel.New3("### Result:");
    result.SetTextFormat(qnamespace_enums.TextFormat.MarkdownText);
    result.SetAlignment(qnamespace_enums.AlignmentFlag.AlignCenter);

    layout.AddWidget(QLabel.New3("From:"));
    layout.AddWidget(from);
    layout.AddWidget(input);
    layout.AddStretch();
    layout.AddWidget(QLabel.New3("To:"));
    layout.AddWidget(to);
    layout.AddStretch();
    layout.AddWidget(result);

    from.OnCurrentIndexChanged(onComboChanged);
    to.OnCurrentIndexChanged(onComboChanged);
    input.OnTextChanged(onTextChanged);

    input.SetFocus();

    widget.Show();

    _ = QApplication.Exec();
}

fn onComboChanged(_: QComboBox, _: i32) callconv(.c) void {
    onTextChanged(input, "");
}

fn onTextChanged(_: QLineEdit, _: [*:0]const u8) callconv(.c) void {
    const text = input.Text(allocator);
    defer allocator.free(text);

    if (std.mem.eql(u8, text, "")) {
        result.SetText("### Result:");
        return;
    }

    const value = std.fmt.parseFloat(f64, text) catch {
        result.SetText("### Invalid input");
        return;
    };

    const from_data = from.CurrentData();
    defer from_data.Delete();

    const from_id = from_data.ToInt();

    const to_data = to.CurrentData();
    defer to_data.Delete();

    const to_id = to_data.ToInt();

    const converted_obj = KUnitConversion__Value.New4(value, from_id);
    defer converted_obj.Delete();

    const converted_value = converted_obj.ConvertTo2(to_id);
    defer converted_value.Delete();

    const converted_text = converted_value.ToString(allocator);
    defer allocator.free(converted_text);

    result.SetText(std.fmt.bufPrint(&buffer, "### Result: {s}", .{converted_text}) catch @panic("Failed to bufPrint"));
}
