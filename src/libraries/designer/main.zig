const std = @import("std");
const qt6 = @import("libqt6zig");
const QApplication = qt6.QApplication;
const QWidget = qt6.QWidget;
const QVBoxLayout = qt6.QVBoxLayout;
const QFormBuilder = qt6.QFormBuilder;
const QFile = qt6.QFile;
const qiodevicebase_enums = qt6.qiodevicebase_enums;
const QLabel = qt6.QLabel;
const qnamespace_enums = qt6.qnamespace_enums;

const form_path = "src/libraries/designer/design.ui";

pub fn main(init: std.process.Init) !void {
    const argv = try qt6.init(init.gpa, init.minimal.args);
    defer qt6.deinit(init.gpa, argv);
    var argc: i32 = @intCast(argv.len);
    const qapp = QApplication.New(init.arena.allocator(), &argc, argv);
    defer qapp.Delete();

    const widget = QWidget.New2();
    defer widget.Delete();

    widget.SetWindowTitle("Qt 6 Designer Example");

    const layout = QVBoxLayout.New(widget);

    const builder = QFormBuilder.New();
    defer builder.Delete();

    const file = QFile.New2(form_path);
    defer file.Delete();

    if (file.Open(qiodevicebase_enums.OpenModeFlag.ReadOnly)) {
        defer file.Close();

        const parent = QWidget.New2();
        const form = builder.Load(file, parent);
        layout.AddWidget(form);
        widget.Resize(850, 550);
    } else {
        const label = QLabel.New5("### Failed to open form file: " ++ form_path, widget);
        label.SetTextFormat(qnamespace_enums.TextFormat.MarkdownText);
        label.SetAlignment(qnamespace_enums.AlignmentFlag.AlignCenter);
        layout.AddWidget(label);
        widget.Resize(550, 100);
    }

    widget.Show();

    _ = QApplication.Exec();
}
