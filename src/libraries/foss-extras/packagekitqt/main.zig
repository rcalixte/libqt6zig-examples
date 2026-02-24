const std = @import("std");
const qt6 = @import("libqt6zig");
const C = qt6.C;
const qapplication = qt6.qapplication;
const qwidget = qt6.qwidget;
const qvboxlayout = qt6.qvboxlayout;
const qpushbutton = qt6.qpushbutton;
const qlabel = qt6.qlabel;
const qnamespace_enums = qt6.qnamespace_enums;
const packagekit__daemon = qt6.packagekit__daemon;
const packagekit__transaction = qt6.packagekit__transaction;
const transaction_enums = qt6.transaction_1_enums;

var status_label: C.QLabel = null;

pub fn main() void {
    const argc = std.os.argv.len;
    const argv = std.os.argv.ptr;
    const qapp = qapplication.New(argc, argv);
    defer qapplication.Delete(qapp);

    const widget = qwidget.New2();
    defer qwidget.Delete(widget);

    qwidget.SetWindowTitle(widget, "Qt 6 PackageKit Example");
    qwidget.Resize(widget, 300, 200);

    const layout = qvboxlayout.New2();
    const button = qpushbutton.New3("Check for updates");
    status_label = qlabel.New2();
    qlabel.SetAlignment(status_label, qnamespace_enums.AlignmentFlag.AlignCenter);

    qvboxlayout.AddStretch(layout);
    qvboxlayout.AddWidget(layout, status_label);
    qvboxlayout.AddStretch(layout);
    qvboxlayout.AddWidget(layout, button);
    qvboxlayout.AddStretch(layout);
    qwidget.SetLayout(widget, layout);

    qpushbutton.OnClicked(button, checkForUpdates);

    qwidget.Show(widget);

    _ = qapplication.Exec();
}

fn checkForUpdates(_: ?*anyopaque) callconv(.c) void {
    qlabel.SetText(status_label, "Checking for updates...");

    const transaction = packagekit__daemon.GetUpdates();
    packagekit__transaction.OnFinished(transaction, transactionFinished);
}

fn transactionFinished(_: ?*anyopaque, status: i32, _: u32) callconv(.c) void {
    if (status == transaction_enums.Exit.ExitSuccess) {
        qlabel.SetText(status_label, "✅ Update check successful!");
    } else {
        qlabel.SetText(status_label, "❌ Update check failed!");
    }
}
