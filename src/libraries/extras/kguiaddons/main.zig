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
    const qapp = QApplication.New(init.arena.allocator(), &argc, argv);
    defer qapp.Delete();

    const widget = QWidget.New2();
    defer widget.Delete();

    widget.SetWindowTitle("Qt 6 KGuiAddons Example");
    widget.SetMinimumSize2(380, 180);

    const titlelabel = QLabel.New3("Enter a date:");

    const input = QLineEdit.New2();
    input.OnTextChanged(onTextChanged);

    label = QLabel.New2();
    label.SetAlignment(qnamespace_enums.AlignmentFlag.AlignCenter);
    label.SetStyleSheet("font: bold;");

    const validator = KDateValidator.New();
    input.SetValidator(validator);

    const layout = QVBoxLayout.New(widget);
    layout.AddWidget(titlelabel);
    layout.AddWidget(input);
    layout.AddWidget(label);

    widget.Show();

    _ = QApplication.Exec();
}

fn onTextChanged(self: QLineEdit, text: [*:0]const u8) callconv(.c) void {
    var pos = self.CursorPosition();
    const validator: KDateValidator = .{ .ptr = @ptrCast(self.Validator().ptr) };
    const ret = validator.Validate(std.mem.span(text), &pos);

    switch (ret) {
        qvalidator_enums.State.Acceptable => label.SetText("Validation result: Acceptable"),
        qvalidator_enums.State.Intermediate => label.SetText("Validation result: Intermediate"),
        qvalidator_enums.State.Invalid => label.SetText("Validation result: Invalid"),
        else => unreachable,
    }
}
