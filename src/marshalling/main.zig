const std = @import("std");
const qt6 = @import("libqt6zig");
const C = qt6.C;
const all_types = qt6.all_types;
const qapplication = qt6.qapplication;
const qcheckbox = qt6.qcheckbox;
const qsize = qt6.qsize;
const qwidget = qt6.qwidget;
const qversionnumber = qt6.qversionnumber;
const qinputdialog = qt6.qinputdialog;
const qtablewidget = qt6.qtablewidget;
const qkeysequence = qt6.qkeysequence;
const qaction = qt6.qaction;
const qfile = qt6.qfile;
const qobject = qt6.qobject;
const qvariant = qt6.qvariant;
const qjsonobject = qt6.qjsonobject;

var gpa = @import("alloc_config").gpa;
const allocator = gpa.allocator();
const c_allocator = std.heap.raw_c_allocator;

const map_u8_sliceu8 = all_types.map_u8_sliceu8;

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
    const size = qsize.New4(32, 32);
    defer qsize.QDelete(size);
    const r = qsize.Rheight(size);
    r.?.* = 64;
    try stdout_writer.interface.print("Height: {d}\n", .{qsize.Height(size)});
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
    for (comboItems, 0..) |item, i| {
        try stdout_writer.interface.print("ComboBoxItems[{d}]: {s}\n", .{ i, item });
        try stdout_writer.interface.flush();
        defer allocator.free(item);
    }

    // QStringList callback
    const table = qtablewidget.New2();
    defer qtablewidget.QDelete(table);
    qtablewidget.OnMimeTypes(table, onMimeTypes);
    const tableMimeTypes = qtablewidget.MimeTypes(table, allocator);
    defer allocator.free(tableMimeTypes);
    for (tableMimeTypes, 0..) |item, i| {
        try stdout_writer.interface.print("MimeTypes[{d}]: {s}\n", .{ i, item });
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
    for (shortcuts, 0..) |shortcut, i| {
        const qkey_tostring = qkeysequence.ToString(shortcut, allocator);
        defer allocator.free(qkey_tostring);
        try stdout_writer.interface.print("Shortcuts[{d}]: {s}\n", .{ i, qkey_tostring });
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

    // QMap<QString, QVariant>
    var input_map: std.StringHashMapUnmanaged(C.QVariant) = .empty;
    defer input_map.deinit(allocator);
    try input_map.put(allocator, "foo", qvariant.New24("FOO"));
    try input_map.put(allocator, "bar", qvariant.New24("BAR"));
    try input_map.put(allocator, "baz", qvariant.New24("BAZ"));
    const qtobj = qjsonobject.FromVariantMap(input_map, allocator);
    defer qjsonobject.QDelete(qtobj);
    var output_map = qjsonobject.ToVariantMap(qtobj, allocator);
    defer output_map.deinit(allocator);
    var it = output_map.iterator();
    while (it.next()) |entry| {
        const key = entry.key_ptr.*;
        defer allocator.free(key);
        const val = entry.value_ptr.*;
        defer qvariant.QDelete(val);
        const value_str = qvariant.ToString(val, allocator);
        defer allocator.free(value_str);
        try stdout_writer.interface.print("QMap[{s}]: {s}\n", .{ key, value_str });
        try stdout_writer.interface.flush();
    }

    // QMultiMap<QString, QString>
    var multi_map: map_u8_sliceu8 = .empty;
    const map_value = try allocator.alloc([]u8, 3);
    defer allocator.free(map_value);
    var val0 = "text/html".*;
    var val1 = "application/xhtml+xml".*;
    var val2 = "application/xml;".*;
    map_value[0] = &val0;
    map_value[1] = &val1;
    map_value[2] = &val2;
    const key = "Accept";
    try multi_map.put(allocator, key, map_value);
    defer multi_map.deinit(allocator);
    const qheaders = qt6.qhttpheaders.FromMultiMap(multi_map, allocator);
    defer qt6.qhttpheaders.QDelete(qheaders);
    var headers = qt6.qhttpheaders.ToMultiMap(qheaders, allocator);
    defer headers.deinit(allocator);
    var value_it = headers.iterator();
    while (value_it.next()) |entry| {
        const _key = entry.key_ptr.*;
        defer allocator.free(_key);
        try stdout_writer.interface.print("HTTP Header: {s}: ", .{_key});
        try stdout_writer.interface.flush();
        const value_list = entry.value_ptr.*;
        defer allocator.free(value_list);
        for (0..value_list.len) |j| {
            const value_string = value_list[j];
            defer allocator.free(value_string);
            try stdout_writer.interface.print("{s}", .{value_string});
            try stdout_writer.interface.flush();
            if (j < value_list.len - 1) {
                _ = try stdout_writer.interface.write(",");
                try stdout_writer.interface.flush();
            }
        }
        _ = try stdout_writer.interface.write("\n");
        try stdout_writer.interface.flush();
    }
}

fn onMimeTypes() callconv(.c) ?[*:null]?[*:0]const u8 {
    // Use of the C allocator is required here
    const list = c_allocator.allocSentinel(?[*:0]const u8, 3, null) catch @panic("Failed to allocate memory");
    list[0] = "image/gif";
    list[1] = "image/jpeg";
    list[2] = "image/png";

    return list.ptr;
}
