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
    QApplication.setAttribute(qnamespace_enums.ApplicationAttribute.AA_ShareOpenGLContexts);
    const argv = try qt6.init(init.gpa, init.minimal.args);
    defer qt6.deinit(init.gpa, argv);
    var argc: i32 = @intCast(argv.len);
    const qapp: QApplication = .new(init.arena.allocator(), &argc, argv);
    defer qapp.delete();

    const widget = QWidget.new2();
    defer widget.delete();

    widget.setWindowTitle("Qt 6 UI Tools Example");

    const layout = QVBoxLayout.new(widget);

    const loader = QUiLoader.new();
    defer loader.delete();

    const file = QFile.new2(form_path);
    defer file.delete();

    if (file.open(qiodevicebase_enums.OpenModeFlag.ReadOnly)) {
        defer file.close();

        const parent = QWidget.new(widget);
        const form = loader.load2(file, parent);
        layout.addWidget(form);
        widget.resize(1000, 550);
    } else {
        const label = QLabel.new5("### Failed to open form file: " ++ form_path, widget);
        label.setTextFormat(qnamespace_enums.TextFormat.MarkdownText);
        label.setAlignment(qnamespace_enums.AlignmentFlag.AlignCenter);
        layout.addWidget(label);
        widget.resize(550, 100);
    }

    widget.show();

    _ = QApplication.exec();
}
