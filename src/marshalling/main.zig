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
const qhttpheaders = qt6.qhttpheaders;
const qeasingcurve = qt6.qeasingcurve;

var buffer: [256]u8 = undefined;
const c_allocator = std.heap.c_allocator;

const arraymap_constu8_qtcqvariant = all_types.arraymap_constu8_qtcqvariant;
const arraymap_u8_sliceu8 = all_types.arraymap_u8_sliceu8;

pub fn main(init: std.process.Init) !void {
    const argv = try qt6.init(init.gpa, init.minimal.args);
    defer qt6.deinit(init.gpa, argv);
    var argc: i32 = @intCast(argv.len);
    const qapp = qapplication.New(&argc, argv, init.arena.allocator());
    defer qapplication.Delete(qapp);

    // Bool
    const b = qcheckbox.New2();
    defer qcheckbox.Delete(b);
    qcheckbox.SetChecked(b, true);
    try std.Io.File.stdout().writeStreamingAll(
        init.io,
        try std.fmt.bufPrint(&buffer, "Checked: {any}\n", .{qcheckbox.IsChecked(b)}),
    );

    // Int
    const s = qsize.New3();
    defer qsize.Delete(s);
    qsize.SetWidth(s, 128);
    try std.Io.File.stdout().writeStreamingAll(
        init.io,
        try std.fmt.bufPrint(&buffer, "Width: {d}\n", .{qsize.Width(s)}),
    );

    // Int by reference
    const size = qsize.New4(32, 32);
    defer qsize.Delete(size);
    const r = qsize.Rheight(size);
    r.?.* = 64;
    try std.Io.File.stdout().writeStreamingAll(
        init.io,
        try std.fmt.bufPrint(&buffer, "Height: {d}\n", .{qsize.Height(size)}),
    );

    // QString
    const w = qwidget.New2();
    defer qwidget.Delete(w);
    qwidget.SetToolTip(w, "Sample text");
    const tooltip = qwidget.ToolTip(w, init.gpa);
    defer init.gpa.free(tooltip);
    try std.Io.File.stdout().writeStreamingAll(
        init.io,
        try std.fmt.bufPrint(&buffer, "ToolTip: {s}\n", .{tooltip}),
    );

    // QList<int>
    var seq = [_]i32{ 10, 20, 30, 40, 50 };
    const li = qversionnumber.New2(&seq);
    defer qversionnumber.Delete(li);
    const segs = qversionnumber.Segments(li, init.gpa);
    defer init.gpa.free(segs);
    try std.Io.File.stdout().writeStreamingAll(
        init.io,
        try std.fmt.bufPrint(&buffer, "Segments: {any}\n", .{segs}),
    );

    // QStringList
    const c = qinputdialog.New2();
    defer qinputdialog.Delete(c);
    const items = [_][]const u8{ "foo", "bar", "baz", "quux" };
    qinputdialog.SetComboBoxItems(c, &items, init.gpa);
    const combo_items = qinputdialog.ComboBoxItems(c, init.gpa);
    defer init.gpa.free(combo_items);
    for (combo_items, 0..) |item, i| {
        defer init.gpa.free(item);
        try std.Io.File.stdout().writeStreamingAll(
            init.io,
            try std.fmt.bufPrint(&buffer, "ComboBoxItems[{d}]: {s}\n", .{ i, item }),
        );
    }

    // QStringList callback
    const table = qtablewidget.New2();
    defer qtablewidget.Delete(table);
    qtablewidget.OnMimeTypes(table, onMimeTypes);
    const table_mimetypes = qtablewidget.MimeTypes(table, init.gpa);
    defer init.gpa.free(table_mimetypes);
    for (table_mimetypes, 0..) |item, i| {
        defer init.gpa.free(item);
        try std.Io.File.stdout().writeStreamingAll(
            init.io,
            try std.fmt.bufPrint(&buffer, "MimeTypes[{d}]: {s}\n", .{ i, item }),
        );
    }

    // QList<Qt type>
    var keyarray = [_]C.QKeySequence{
        qkeysequence.FromString("F1"),
        qkeysequence.FromString("F2"),
        qkeysequence.FromString("F3"),
    };
    const qa = qaction.New();
    defer qaction.Delete(qa);
    qaction.SetShortcuts(qa, &keyarray);
    const shortcuts = qaction.Shortcuts(qa, init.gpa);
    defer init.gpa.free(shortcuts);
    for (shortcuts, 0..) |shortcut, i| {
        const qkey_tostring = qkeysequence.ToString(shortcut, init.gpa);
        defer init.gpa.free(qkey_tostring);
        try std.Io.File.stdout().writeStreamingAll(
            init.io,
            try std.fmt.bufPrint(&buffer, "Shortcuts[{d}]: {s}\n", .{ i, qkey_tostring }),
        );
    }

    // QByteArray
    const f_input = "foo bar baz";
    const bat = qfile.EncodeName(f_input, init.gpa);
    defer init.gpa.free(bat);
    const f_output = qfile.DecodeName(bat, init.gpa);
    defer init.gpa.free(f_output);
    try std.Io.File.stdout().writeStreamingAll(
        init.io,
        try std.fmt.bufPrint(&buffer, "QByteArray: {s}\n", .{f_output}),
    );

    // QAnyStringView
    const object = qobject.New();
    defer qobject.Delete(object);
    qobject.SetObjectName(object, "QAnyStringView Name");
    const value = qobject.ObjectName(object, init.gpa);
    defer init.gpa.free(value);
    try std.Io.File.stdout().writeStreamingAll(
        init.io,
        try std.fmt.bufPrint(&buffer, "Value: {s}\n", .{value}),
    );

    // QMap<QString, QVariant>
    var input_map: arraymap_constu8_qtcqvariant = .empty;
    defer input_map.deinit(init.gpa);
    try input_map.put(init.gpa, "foo", qvariant.New24("FOO"));
    try input_map.put(init.gpa, "bar", qvariant.New24("BAR"));
    try input_map.put(init.gpa, "baz", qvariant.New24("BAZ"));
    const qtobj = qjsonobject.FromVariantMap(input_map, init.gpa);
    defer qjsonobject.Delete(qtobj);
    var output_map = qjsonobject.ToVariantMap(qtobj, init.gpa);
    defer output_map.deinit(init.gpa);
    var it = output_map.iterator();
    while (it.next()) |entry| {
        const key = entry.key_ptr.*;
        defer init.gpa.free(key);
        const val = entry.value_ptr.*;
        defer qvariant.Delete(val);
        const value_str = qvariant.ToString(val, init.gpa);
        defer init.gpa.free(value_str);
        try std.Io.File.stdout().writeStreamingAll(
            init.io,
            try std.fmt.bufPrint(&buffer, "QMap[{s}]: {s}\n", .{ key, value_str }),
        );
    }

    // QMultiMap<QString, QString>
    var multi_map: arraymap_u8_sliceu8 = .empty;
    const map_value = try init.gpa.alloc([]u8, 3);
    defer init.gpa.free(map_value);
    var val0 = "text/html".*;
    var val1 = "application/xhtml+xml".*;
    var val2 = "application/xml;".*;
    map_value[0] = &val0;
    map_value[1] = &val1;
    map_value[2] = &val2;
    const key = "Accept";
    try multi_map.put(init.gpa, key, map_value);
    defer multi_map.deinit(init.gpa);
    const qheaders = qhttpheaders.FromMultiMap(multi_map, init.gpa);
    defer qhttpheaders.Delete(qheaders);
    var headers = qhttpheaders.ToMultiMap(qheaders, init.gpa);
    defer headers.deinit(init.gpa);
    var value_it = headers.iterator();
    while (value_it.next()) |entry| {
        const _key = entry.key_ptr.*;
        defer init.gpa.free(_key);
        try std.Io.File.stdout().writeStreamingAll(
            init.io,
            try std.fmt.bufPrint(&buffer, "HTTP Header: {s}: ", .{_key}),
        );
        const value_list = entry.value_ptr.*;
        defer init.gpa.free(value_list);
        for (0..value_list.len) |j| {
            const value_string = value_list[j];
            defer init.gpa.free(value_string);
            try std.Io.File.stdout().writeStreamingAll(
                init.io,
                try std.fmt.bufPrint(&buffer, "{s}", .{value_string}),
            );
            if (j < value_list.len - 1)
                try std.Io.File.stdout().writeStreamingAll(init.io, ",");
        }
        try std.Io.File.stdout().writeStreamingAll(
            init.io,
            "\n",
        );
    }

    // Qt function pointer
    const easing = qeasingcurve.New();
    defer qeasingcurve.Delete(easing);
    qeasingcurve.SetCustomType(easing, easingFunction);
    const easingFunc = qeasingcurve.CustomType(easing) orelse @panic("Failed to get easing function");
    for (0..3) |i|
        try std.Io.File.stdout().writeStreamingAll(
            init.io,
            try std.fmt.bufPrint(&buffer, "Easing function value: {d}\n", .{easingFunc(@floatFromInt(i))}),
        );
}

fn onMimeTypes() callconv(.c) ?[*:null]?[*:0]const u8 {
    // Use of the C allocator is required here
    const list = c_allocator.allocSentinel(?[*:0]const u8, 3, null) catch @panic("Failed to allocate memory");
    list[0] = "image/gif";
    list[1] = "image/jpeg";
    list[2] = "image/png";

    return list.ptr;
}

fn easingFunction(f: f64) callconv(.c) f64 {
    return f * f;
}
