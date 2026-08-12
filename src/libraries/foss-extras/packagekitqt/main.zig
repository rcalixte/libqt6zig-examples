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
    const qapp: QApplication = .new(init.arena.allocator(), &argc, argv);
    defer qapp.delete();

    const widget = QWidget.new2();
    defer widget.delete();

    widget.setWindowTitle("Qt 6 PackageKit Example");
    widget.resize(300, 200);

    const layout = QVBoxLayout.new2();
    const button = QPushButton.new3("Check for updates");
    status_label = .new2();
    status_label.setAlignment(qnamespace_enums.AlignmentFlag.AlignCenter);

    layout.addStretch();
    layout.addWidget(status_label);
    layout.addStretch();
    layout.addWidget(button);
    layout.addStretch();
    widget.setLayout(layout);

    button.onClicked(checkForUpdates);

    widget.show();

    _ = QApplication.exec();
}

fn checkForUpdates(_: QPushButton) callconv(.c) void {
    status_label.setText("Checking for updates...");

    const transaction = PackageKit__Daemon.getUpdates();
    transaction.onFinished(transactionFinished);
}

fn transactionFinished(_: PackageKit__Transaction, status: i32, _: u32) callconv(.c) void {
    if (status == transaction_enums.Exit.ExitSuccess)
        status_label.setText("✅ Update check successful!")
    else
        status_label.setText("❌ Update check failed!");
}
