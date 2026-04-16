const builtin = @import("builtin");
const std = @import("std");
const qt6 = @import("libqt6zig");
const types = qt6.types;
const QApplication = qt6.QApplication;
const QCheckBox = qt6.QCheckBox;
const QSize = qt6.QSize;
const QWidget = qt6.QWidget;
const QVersionNumber = qt6.QVersionNumber;
const QInputDialog = qt6.QInputDialog;
const QTableWidget = qt6.QTableWidget;
const QKeySequence = qt6.QKeySequence;
const QAction = qt6.QAction;
const QFile = qt6.QFile;
const QObject = qt6.QObject;
const QVariant = qt6.QVariant;
const QJsonObject = qt6.QJsonObject;
const QHttpHeaders = qt6.QHttpHeaders;
const QEasingCurve = qt6.QEasingCurve;

var buffer: [256]u8 = undefined;
const c_allocator = std.heap.c_allocator;

const ArrayMap_constu8_QVariant = types.ArrayMap_constu8_QVariant;
const ArrayMap_u8_Sliceu8 = types.ArrayMap_u8_Sliceu8;

pub fn main(init: std.process.Init) !void {
    const argv = try qt6.init(init.gpa, init.minimal.args);
    defer qt6.deinit(init.gpa, argv);
    var argc: i32 = @intCast(argv.len);
    const qapp = QApplication.New(init.arena.allocator(), &argc, argv);
    defer qapp.Delete();

    // Bool
    const b = QCheckBox.New2();
    defer b.Delete();
    b.SetChecked(true);
    try std.Io.File.stdout().writeStreamingAll(
        init.io,
        try std.fmt.bufPrint(&buffer, "Checked: {any}\n", .{b.IsChecked()}),
    );

    // Int
    const s = QSize.New3();
    defer s.Delete();
    s.SetWidth(128);
    try std.Io.File.stdout().writeStreamingAll(
        init.io,
        try std.fmt.bufPrint(&buffer, "Width: {d}\n", .{s.Width()}),
    );

    // Int by reference
    const size = QSize.New4(32, 32);
    defer size.Delete();
    const r = size.Rheight();
    r.?.* = 64;
    try std.Io.File.stdout().writeStreamingAll(
        init.io,
        try std.fmt.bufPrint(&buffer, "Height: {d}\n", .{size.Height()}),
    );

    // QString
    const w = QWidget.New2();
    defer w.Delete();
    w.SetToolTip("Sample text");
    const tooltip = w.ToolTip(init.gpa);
    defer init.gpa.free(tooltip);
    try std.Io.File.stdout().writeStreamingAll(
        init.io,
        try std.fmt.bufPrint(&buffer, "ToolTip: {s}\n", .{tooltip}),
    );

    // QList<int>
    var seq = [_]i32{ 10, 20, 30, 40, 50 };
    const li = QVersionNumber.New2(&seq);
    defer li.Delete();
    const segs = li.Segments(init.gpa);
    defer init.gpa.free(segs);
    try std.Io.File.stdout().writeStreamingAll(
        init.io,
        try std.fmt.bufPrint(&buffer, "Segments: {any}\n", .{segs}),
    );

    // QStringList
    const c = QInputDialog.New2();
    defer c.Delete();
    const items = [_][]const u8{ "foo", "bar", "baz", "quux" };
    c.SetComboBoxItems(init.gpa, &items);
    const combo_items = c.ComboBoxItems(init.gpa);
    defer init.gpa.free(combo_items);
    for (combo_items, 0..) |item, i| {
        defer init.gpa.free(item);
        try std.Io.File.stdout().writeStreamingAll(
            init.io,
            try std.fmt.bufPrint(&buffer, "ComboBoxItems[{d}]: {s}\n", .{ i, item }),
        );
    }

    // QStringList callback
    const table = QTableWidget.New2();
    defer table.Delete();
    table.OnMimeTypes(onMimeTypes);
    const table_mimetypes = table.MimeTypes(init.gpa);
    defer init.gpa.free(table_mimetypes);
    for (table_mimetypes, 0..) |item, i| {
        defer init.gpa.free(item);
        try std.Io.File.stdout().writeStreamingAll(
            init.io,
            try std.fmt.bufPrint(&buffer, "MimeTypes[{d}]: {s}\n", .{ i, item }),
        );
    }

    // QList<Qt type>
    var keyarray = [_]QKeySequence{
        QKeySequence.FromString("F1"),
        QKeySequence.FromString("F2"),
        QKeySequence.FromString("F3"),
    };
    const qa = QAction.New();
    defer qa.Delete();
    qa.SetShortcuts(&keyarray);
    const shortcuts = qa.Shortcuts(init.gpa);
    defer init.gpa.free(shortcuts);
    for (shortcuts, 0..) |shortcut, i| {
        const qkey_tostring = shortcut.ToString(init.gpa);
        defer init.gpa.free(qkey_tostring);
        try std.Io.File.stdout().writeStreamingAll(
            init.io,
            try std.fmt.bufPrint(&buffer, "Shortcuts[{d}]: {s}\n", .{ i, qkey_tostring }),
        );
    }

    // QByteArray
    const f_input = "foo bar baz";
    const bat = QFile.EncodeName(init.gpa, f_input);
    defer init.gpa.free(bat);
    const f_output = QFile.DecodeName(init.gpa, bat);
    defer init.gpa.free(f_output);
    try std.Io.File.stdout().writeStreamingAll(
        init.io,
        try std.fmt.bufPrint(&buffer, "QByteArray: {s}\n", .{f_output}),
    );

    // QAnyStringView
    const object = QObject.New();
    defer object.Delete();
    object.SetObjectName("QAnyStringView Name");
    const value = object.ObjectName(init.gpa);
    defer init.gpa.free(value);
    try std.Io.File.stdout().writeStreamingAll(
        init.io,
        try std.fmt.bufPrint(&buffer, "Value: {s}\n", .{value}),
    );

    // QMap<QString, QVariant>
    var input_map: ArrayMap_constu8_QVariant = .empty;
    defer input_map.deinit(init.gpa);
    try input_map.put(init.gpa, "foo", QVariant.New24("FOO"));
    try input_map.put(init.gpa, "bar", QVariant.New24("BAR"));
    try input_map.put(init.gpa, "baz", QVariant.New24("BAZ"));
    const qtobj = QJsonObject.FromVariantMap(init.gpa, input_map);
    defer qtobj.Delete();
    var output_map = qtobj.ToVariantMap(init.gpa);
    defer output_map.deinit(init.gpa);
    var it = output_map.iterator();
    while (it.next()) |entry| {
        const key = entry.key_ptr.*;
        defer init.gpa.free(key);
        const val = entry.value_ptr.*;
        defer val.Delete();
        const value_str = val.ToString(init.gpa);
        defer init.gpa.free(value_str);
        try std.Io.File.stdout().writeStreamingAll(
            init.io,
            try std.fmt.bufPrint(&buffer, "QMap[{s}]: {s}\n", .{ key, value_str }),
        );
    }

    // QMultiMap<QString, QString>
    var multi_map: ArrayMap_u8_Sliceu8 = .empty;
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
    const qheaders = QHttpHeaders.FromMultiMap(init.gpa, multi_map);
    defer qheaders.Delete();
    var headers = qheaders.ToMultiMap(init.gpa);
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
        try std.Io.File.stdout().writeStreamingAll(init.io, "\n");
    }

    // Qt function pointer
    const easing = QEasingCurve.New();
    defer easing.Delete();
    easing.SetCustomType(easingFunction);
    const easingFunc = easing.CustomType() orelse @panic("Failed to get easing function");
    for (0..3) |i|
        try std.Io.File.stdout().writeStreamingAll(
            init.io,
            try std.fmt.bufPrint(&buffer, "Easing function value: {d}\n", .{easingFunc(@floatFromInt(i))}),
        );
}

fn onMimeTypes() callconv(.c) ?[*:null]?[*:0]const u8 {
    // Use of the C allocator or std.c.malloc is required here
    const n: usize = 3;
    const list: [*:null]?[*:0]const u8 = switch (builtin.os.tag == .windows) {
        true => @ptrCast(@alignCast(std.c.malloc((n + 1) * @sizeOf(?[*:0]const u8)) orelse return null)),
        false => c_allocator.allocSentinel(?[*:0]const u8, n, null) catch @panic("Failed to allocate memory"),
    };
    list[0] = "image/gif";
    list[1] = "image/jpeg";
    list[2] = "image/png";
    list[n] = null;

    return list;
}

fn easingFunction(f: f64) callconv(.c) f64 {
    return f * f;
}
