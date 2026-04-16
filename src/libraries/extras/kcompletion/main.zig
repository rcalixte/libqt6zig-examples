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
    const qapp = QApplication.New(init.arena.allocator(), &argc, argv);
    defer qapp.Delete();

    const widget = QWidget.New2();
    defer widget.Delete();

    widget.SetWindowTitle("Qt 6 KCompletion Example");
    widget.SetMinimumSize2(300, 200);

    const label = QLabel.New3("Enter the letter 'H':");

    const vboxlayout = QVBoxLayout.New2();

    const lineedit = KLineEdit.New3();
    // Try different completion modes!
    lineedit.SetCompletionMode(kcompletion_enums.CompletionMode.CompletionPopupAuto);

    const completion = KCompletion.New();
    completion.SetSoundsEnabled(false);
    lineedit.SetCompletionObject(completion, true);

    const items = [_][]const u8{ "Hello Qt", "Hello Zig", "Hello libqt6zig", "Hello you", "Hello world" };
    completion.SetItems(init.gpa, &items);

    vboxlayout.AddStretch();
    vboxlayout.AddWidget(label);
    vboxlayout.AddWidget(lineedit);
    vboxlayout.AddStretch();
    widget.SetLayout(vboxlayout);

    widget.Show();

    _ = QApplication.Exec();
}
