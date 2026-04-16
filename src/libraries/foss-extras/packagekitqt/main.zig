const std = @import("std");
const qt6 = @import("libqt6zig");
const QApplication = qt6.QApplication;
const QWidget = qt6.QWidget;
const QVBoxLayout = qt6.QVBoxLayout;
const QPushButton = qt6.QPushButton;
const QLabel = qt6.QLabel;
const qnamespace_enums = qt6.qnamespace_enums;
const PackageKit__Daemon = qt6.PackageKit__Daemon;
const PackageKit__Transaction = qt6.PackageKit__Transaction;
const transaction_enums = qt6.transaction_1_enums;

var status_label: QLabel = undefined;

pub fn main(init: std.process.Init) !void {
    const argv = try qt6.init(init.gpa, init.minimal.args);
    defer qt6.deinit(init.gpa, argv);
    var argc: i32 = @intCast(argv.len);
    const qapp = QApplication.New(init.arena.allocator(), &argc, argv);
    defer qapp.Delete();

    const widget = QWidget.New2();
    defer widget.Delete();

    widget.SetWindowTitle("Qt 6 PackageKit Example");
    widget.Resize(300, 200);

    const layout = QVBoxLayout.New2();
    const button = QPushButton.New3("Check for updates");
    status_label = QLabel.New2();
    status_label.SetAlignment(qnamespace_enums.AlignmentFlag.AlignCenter);

    layout.AddStretch();
    layout.AddWidget(status_label);
    layout.AddStretch();
    layout.AddWidget(button);
    layout.AddStretch();
    widget.SetLayout(layout);

    button.OnClicked(checkForUpdates);

    widget.Show();

    _ = QApplication.Exec();
}

fn checkForUpdates(_: QPushButton) callconv(.c) void {
    status_label.SetText("Checking for updates...");

    const transaction = PackageKit__Daemon.GetUpdates();
    transaction.OnFinished(transactionFinished);
}

fn transactionFinished(_: PackageKit__Transaction, status: i32, _: u32) callconv(.c) void {
    if (status == transaction_enums.Exit.ExitSuccess)
        status_label.SetText("✅ Update check successful!")
    else
        status_label.SetText("❌ Update check failed!");
}
