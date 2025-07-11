const std = @import("std");
const builtin = @import("builtin");
const qt6 = @import("libqt6zig");
const C = qt6.C;
const qapplication = qt6.qapplication;
const qvariant = qt6.qvariant;
const qsettings = qt6.qsettings;
const qcheckbox = qt6.qcheckbox;
const qsize = qt6.qsize;
const qwidget = qt6.qwidget;
const qversionnumber = qt6.qversionnumber;
const qinputdialog = qt6.qinputdialog;
const qkeysequence = qt6.qkeysequence;
const qfile = qt6.qfile;
const qjsonobject = qt6.qjsonobject;
const qaction = qt6.qaction;
const qobject = qt6.qobject;

pub fn main() void {
    // Initialize Qt application and allocator
    const argc = std.os.argv.len;
    const argv = std.os.argv.ptr;
    _ = qapplication.New(argc, argv);

    const config = getAllocatorConfig();
    var da: std.heap.DebugAllocator(config) = .init;
    defer _ = da.deinit();
    const allocator = da.allocator();

    const stdout = std.io.getStdOut().writer();

    // Bool
    const b = qcheckbox.New2();
    defer qcheckbox.QDelete(b);
    qcheckbox.SetChecked(b, true);
    stdout.print("Checked: {any}\n", .{qcheckbox.IsChecked(b)}) catch @panic("Bool stdout\n");

    // Int
    const s = qsize.New3();
    defer qsize.QDelete(s);
    qsize.SetWidth(s, 128);
    stdout.print("Width: {any}\n", .{qsize.Width(s)}) catch @panic("Int stdout\n");

    // QString
    const w = qwidget.New2();
    defer qwidget.QDelete(w);
    qwidget.SetToolTip(w, "Sample text");
    const tooltip = qwidget.ToolTip(w, allocator);
    defer allocator.free(tooltip);
    stdout.print("ToolTip: {s}\n", .{tooltip}) catch @panic("String stdout\n");

    // QList<int>
    var seq = [_]i32{ 10, 20, 30, 40, 50 };
    const li = qversionnumber.New2(&seq);
    const segs = qversionnumber.Segments(li, allocator);
    defer allocator.free(segs);
    defer qversionnumber.QDelete(li);
    stdout.print("Segments: {any}\n", .{segs}) catch @panic("QList<int> stdout\n");

    // QStringList
    const c = qinputdialog.New2();
    defer qinputdialog.QDelete(c);
    var items = [_][]const u8{ "foo", "bar", "baz", "quux" };
    qinputdialog.SetComboBoxItems(c, &items, allocator);
    const comboItems = qinputdialog.ComboBoxItems(c, allocator);
    defer allocator.free(comboItems);
    for (comboItems, 0..) |item, _i| {
        stdout.print("ComboBoxItems[{}]: {s}\n", .{ _i, item }) catch @panic("QStringList stdout\n");
        defer allocator.free(item);
    }

    // QList<Qt type>
    var keyarray = [_]C.QKeySequence{
        qkeysequence.FromString("F1"),
        qkeysequence.FromString("F2"),
        qkeysequence.FromString("F3"),
    };
    const qa = qaction.New();
    defer qaction.QDelete(qa);
    qaction.SetShortcuts(qa, &keyarray);
    const shortcuts = qaction.Shortcuts(qa, allocator);
    defer allocator.free(shortcuts);
    for (shortcuts, 0..) |shortcut, _i| {
        const qkey_tostring = qkeysequence.ToString(shortcut, allocator);
        defer allocator.free(qkey_tostring);
        stdout.print("Shortcuts[{}]: {s}\n", .{ _i, qkey_tostring }) catch @panic("QList<Qt type> stdout\n");
    }

    // QByteArray
    const f_input = "foo bar baz";
    const bat = qfile.EncodeName(f_input, allocator);
    defer allocator.free(bat);
    const f_output = qfile.DecodeName(bat, allocator);
    defer allocator.free(f_output);
    stdout.print("QByteArray: {s}\n", .{f_output}) catch @panic("QByteArray stdout\n");

    // QAnyStringView parameter
    const object = qobject.New();
    defer qobject.QDelete(object);
    qobject.SetObjectName(object, "QAnyStringView Name");
    const value = qobject.ObjectName(object, allocator);
    stdout.print("Value: {s}\n", .{value}) catch @panic("QAnyStringView stdout\n");
}

pub fn getAllocatorConfig() std.heap.DebugAllocatorConfig {
    if (builtin.mode == .Debug) {
        return std.heap.DebugAllocatorConfig{
            .safety = true,
            .never_unmap = true,
            .retain_metadata = true,
            .verbose_log = false,
        };
    } else {
        return std.heap.DebugAllocatorConfig{
            .safety = false,
            .never_unmap = false,
            .retain_metadata = false,
            .verbose_log = false,
        };
    }
}
