const std = @import("std");
const qt6 = @import("libqt6zig");
const QApplication = qt6.QApplication;
const QWidget = qt6.QWidget;
const QLineEdit = qt6.QLineEdit;
const QLabel = qt6.QLabel;
const qnamespace_enums = qt6.qnamespace_enums;
const KDateValidator = qt6.KDateValidator;
const QVBoxLayout = qt6.QVBoxLayout;
const qvalidator_enums = qt6.qvalidator_enums;

var label: QLabel = undefined;

pub fn main(init: std.process.Init) !void {
    const argv = try qt6.init(init.gpa, init.minimal.args);
    defer qt6.deinit(init.gpa, argv);
    var argc: i32 = @intCast(argv.len);
    const qapp: QApplication = .new(init.arena.allocator(), &argc, argv);
    defer qapp.delete();

    const widget = QWidget.new2();
    defer widget.delete();

    widget.setWindowTitle("Qt 6 KGuiAddons Example");
    widget.setMinimumSize2(380, 180);

    const input = QLineEdit.new2();
    input.onTextChanged(onTextChanged);

    label = .new2();
    label.setAlignment(qnamespace_enums.AlignmentFlag.AlignCenter);
    label.setStyleSheet("font: bold;");

    const validator = KDateValidator.new2(input);
    input.setValidator(validator);

    const layout = QVBoxLayout.new(widget);
    layout.addWidget(QLabel.new3("Enter a date:"));
    layout.addWidget(input);
    layout.addWidget(label);

    widget.show();

    _ = QApplication.exec();
}

fn onTextChanged(self: QLineEdit, text: [*:0]const u8) callconv(.c) void {
    var pos = self.cursorPosition();
    const validator: KDateValidator = .{ .ptr = @ptrCast(self.validator().ptr) };
    const ret = validator.validate(std.mem.span(text), &pos);

    switch (ret) {
        qvalidator_enums.State.Acceptable => label.setText("Validation result: Acceptable"),
        qvalidator_enums.State.Intermediate => label.setText("Validation result: Intermediate"),
        qvalidator_enums.State.Invalid => label.setText("Validation result: Invalid"),
        else => unreachable,
    }
}
