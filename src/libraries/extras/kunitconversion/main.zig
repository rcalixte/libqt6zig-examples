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
    const qapp: QApplication = .new(init.arena.allocator(), &argc, argv);
    defer qapp.delete();

    allocator = init.gpa;

    const widget = QWidget.new2();
    defer widget.delete();

    widget.setWindowTitle("Qt 6 KUnitConversion Example");
    widget.setFixedSize2(450, 300);

    const layout = QVBoxLayout.new(widget);
    const converter = KUnitConversion__Converter.new();
    defer converter.delete();

    // Update the category type to change the units!
    const category = converter.category2(unit_enums.CategoryId.LengthCategory);
    defer category.delete();

    from = .new2();
    to = .new2();

    const units = category.units(allocator);
    defer allocator.free(units);

    for (units) |unit| {
        defer unit.delete();

        const description = unit.description(allocator);
        defer allocator.free(description);

        const id = unit.id();
        const data = QVariant.new4(id);
        defer data.delete();

        from.addItem22(description, data);
        to.addItem22(description, data);
    }

    input = .new2();
    input.setPlaceholderText("Enter a value");

    result = .new3("### Result:");
    result.setTextFormat(qnamespace_enums.TextFormat.MarkdownText);
    result.setAlignment(qnamespace_enums.AlignmentFlag.AlignCenter);

    layout.addWidget(QLabel.new3("From:"));
    layout.addWidget(from);
    layout.addWidget(input);
    layout.addStretch();
    layout.addWidget(QLabel.new3("To:"));
    layout.addWidget(to);
    layout.addStretch();
    layout.addWidget(result);

    from.onCurrentIndexChanged(onComboChanged);
    to.onCurrentIndexChanged(onComboChanged);
    input.onTextChanged(onTextChanged);

    input.setFocus();

    widget.show();

    _ = QApplication.exec();
}

fn onComboChanged(_: QComboBox, _: i32) callconv(.c) void {
    onTextChanged(input, "");
}

fn onTextChanged(_: QLineEdit, _: [*:0]const u8) callconv(.c) void {
    const text = input.text(allocator);
    defer allocator.free(text);

    if (std.mem.eql(u8, text, "")) {
        result.setText("### Result:");
        return;
    }

    const value = std.fmt.parseFloat(f64, text) catch {
        result.setText("### Invalid input");
        return;
    };

    const from_data = from.currentData();
    defer from_data.delete();

    const from_id = from_data.toInt();

    const to_data = to.currentData();
    defer to_data.delete();

    const to_id = to_data.toInt();

    const converted_obj = KUnitConversion__Value.new4(value, from_id);
    defer converted_obj.delete();

    const converted_value = converted_obj.convertTo2(to_id);
    defer converted_value.delete();

    const converted_text = converted_value.toString(allocator);
    defer allocator.free(converted_text);

    result.setText(std.fmt.bufPrint(&buffer, "### Result: {s}", .{converted_text}) catch
        @panic("Failed to bufPrint"));
}
