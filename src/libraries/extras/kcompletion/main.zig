const std = @import("std");
const qt6 = @import("libqt6zig");
const QApplication = qt6.QApplication;
const QWidget = qt6.QWidget;
const QLabel = qt6.QLabel;
const QVBoxLayout = qt6.QVBoxLayout;
const KLineEdit = qt6.KLineEdit;
const KCompletion = qt6.KCompletion;
const kcompletion_enums = qt6.kcompletion_enums;

pub fn main(init: std.process.Init) !void {
    const argv = try qt6.init(init.gpa, init.minimal.args);
    defer qt6.deinit(init.gpa, argv);
    var argc: i32 = @intCast(argv.len);
    const qapp: QApplication = .new(init.arena.allocator(), &argc, argv);
    defer qapp.delete();

    const widget = QWidget.new2();
    defer widget.delete();

    widget.setWindowTitle("Qt 6 KCompletion Example");
    widget.setMinimumSize2(300, 200);

    const vboxlayout = QVBoxLayout.new2();

    const lineedit = KLineEdit.new3();
    // Try different completion modes!
    lineedit.setCompletionMode(kcompletion_enums.CompletionMode.CompletionPopupAuto);

    const completion = KCompletion.new();
    defer completion.delete();

    completion.setSoundsEnabled(false);
    lineedit.setCompletionObject(completion, true);

    const items = [_][]const u8{ "Hello Qt", "Hello Zig", "Hello libqt6zig", "Hello you", "Hello world" };
    completion.setItems(init.gpa, &items);

    vboxlayout.addStretch();
    vboxlayout.addWidget(QLabel.new3("Enter the letter 'H':"));
    vboxlayout.addWidget(lineedit);
    vboxlayout.addStretch();
    widget.setLayout(vboxlayout);

    widget.show();

    _ = QApplication.exec();
}
