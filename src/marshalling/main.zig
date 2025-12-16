const std = @import("std");
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

var gpa = @import("alloc_config").gpa;
const allocator = gpa.allocator();

pub fn main() !void {
    // Initialize Qt application, allocator, and stdout
    const argc = std.os.argv.len;
    const argv = std.os.argv.ptr;
    const qapp = qapplication.New(argc, argv);
    defer qapplication.QDelete(qapp);

    defer _ = gpa.deinit();

    var buffer: [256]u8 = undefined;
    var stdout_writer = std.fs.File.stdout().writer(&buffer);

    // Bool
    const b = qcheckbox.New2();
    defer qcheckbox.QDelete(b);
    qcheckbox.SetChecked(b, true);
    try stdout_writer.interface.print("Checked: {any}\n", .{qcheckbox.IsChecked(b)});
    try stdout_writer.interface.flush();

    // Int
    const s = qsize.New3();
    defer qsize.QDelete(s);
    qsize.SetWidth(s, 128);
    try stdout_writer.interface.print("Width: {d}\n", .{qsize.Width(s)});
    try stdout_writer.interface.flush();

    // Int by reference
    const i = qsize.New4(32, 32);
    defer qsize.QDelete(i);
    const r = qsize.Rheight(i);
    r.?.* = 64;
    try stdout_writer.interface.print("Height: {d}\n", .{qsize.Height(i)});
    try stdout_writer.interface.flush();

    // QString
    const w = qwidget.New2();
    defer qwidget.QDelete(w);
    qwidget.SetToolTip(w, "Sample text");
    const tooltip = qwidget.ToolTip(w, allocator);
    defer allocator.free(tooltip);
    try stdout_writer.interface.print("ToolTip: {s}\n", .{tooltip});
    try stdout_writer.interface.flush();

    // QList<int>
    var seq = [_]i32{ 10, 20, 30, 40, 50 };
    const li = qversionnumber.New2(&seq);
    const segs = qversionnumber.Segments(li, allocator);
    defer allocator.free(segs);
    defer qversionnumber.QDelete(li);
    try stdout_writer.interface.print("Segments: {any}\n", .{segs});
    try stdout_writer.interface.flush();

    // QStringList
    const c = qinputdialog.New2();
    defer qinputdialog.QDelete(c);
    var items = [_][]const u8{ "foo", "bar", "baz", "quux" };
    qinputdialog.SetComboBoxItems(c, &items, allocator);
    const comboItems = qinputdialog.ComboBoxItems(c, allocator);
    defer allocator.free(comboItems);
    for (comboItems, 0..) |item, _i| {
        try stdout_writer.interface.print("ComboBoxItems[{d}]: {s}\n", .{ _i, item });
        try stdout_writer.interface.flush();
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
        try stdout_writer.interface.print("Shortcuts[{d}]: {s}\n", .{ _i, qkey_tostring });
        try stdout_writer.interface.flush();
    }

    // QByteArray
    const f_input = "foo bar baz";
    const bat = qfile.EncodeName(f_input, allocator);
    defer allocator.free(bat);
    const f_output = qfile.DecodeName(bat, allocator);
    defer allocator.free(f_output);
    try stdout_writer.interface.print("QByteArray: {s}\n", .{f_output});
    try stdout_writer.interface.flush();

    // QAnyStringView parameter
    const object = qobject.New();
    defer qobject.QDelete(object);
    qobject.SetObjectName(object, "QAnyStringView Name");
    const value = qobject.ObjectName(object, allocator);
    defer allocator.free(value);
    try stdout_writer.interface.print("Value: {s}\n", .{value});
    try stdout_writer.interface.flush();
}
