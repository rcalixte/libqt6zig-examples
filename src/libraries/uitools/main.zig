const std = @import("std");
const qt6 = @import("libqt6zig");
const QApplication = qt6.QApplication;
const qnamespace_enums = qt6.qnamespace_enums;
const QWidget = qt6.QWidget;
const QVBoxLayout = qt6.QVBoxLayout;
const QUiLoader = qt6.QUiLoader;
const QFile = qt6.QFile;
const qiodevicebase_enums = qt6.qiodevicebase_enums;
const QLabel = qt6.QLabel;

const form_path = "src/libraries/uitools/design.ui";

pub fn main(init: std.process.Init) !void {
    QApplication.SetAttribute(qnamespace_enums.ApplicationAttribute.AA_ShareOpenGLContexts);
    const argv = try qt6.init(init.gpa, init.minimal.args);
    defer qt6.deinit(init.gpa, argv);
    var argc: i32 = @intCast(argv.len);
    const qapp = QApplication.New(init.arena.allocator(), &argc, argv);
    defer qapp.Delete();

    const widget = QWidget.New2();
    defer widget.Delete();

    widget.SetWindowTitle("Qt 6 UI Tools Example");

    const layout = QVBoxLayout.New(widget);

    const loader = QUiLoader.New();
    defer loader.Delete();

    const file = QFile.New2(form_path);
    defer file.Delete();

    if (file.Open(qiodevicebase_enums.OpenModeFlag.ReadOnly)) {
        defer file.Close();

        const parent = QWidget.New2();
        const form = loader.Load2(file, parent);
        layout.AddWidget(form);
        widget.Resize(1000, 550);
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
