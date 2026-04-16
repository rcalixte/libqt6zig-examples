const builtin = @import("builtin");
const std = @import("std");
const qt6 = @import("libqt6zig");
const properties_enums = qt6.properties_enums;
const QApplication = qt6.QApplication;
const QListWidget = qt6.QListWidget;
const QSize = qt6.QSize;
const qlistview_enums = qt6.qlistview_enums;
const QIcon = qt6.QIcon;
const QListWidgetItem = qt6.QListWidgetItem;
const qnamespace_enums = qt6.qnamespace_enums;
const QObject = qt6.QObject;
const KFileMetaData__ExtractorPlugin = qt6.KFileMetaData__ExtractorPlugin;
const KFileMetaData__SimpleExtractionResult = qt6.KFileMetaData__SimpleExtractionResult;
const QVariant = qt6.QVariant;
const KFileMetaData__PropertyInfo = qt6.KFileMetaData__PropertyInfo;
const QImageReader = qt6.QImageReader;
const KFileMetaData__ExtractionResult = qt6.KFileMetaData__ExtractionResult;
const types_enums = qt6.types_enums;
const extractionresult_enums = qt6.extractionresult_enums;

var allocator: std.mem.Allocator = undefined;
var io: std.Io = undefined;

const filename = "assets/Qt.png";

const text_mapping = [_]struct {
    key: []const u8,
    property: i32,
}{
    .{ .key = "Comment", .property = properties_enums.Property.Comment },
};

pub fn main(init: std.process.Init) !void {
    const argv = try qt6.init(init.gpa, init.minimal.args);
    defer qt6.deinit(init.gpa, argv);
    var argc: i32 = @intCast(argv.len);
    const qapp = QApplication.New(init.arena.allocator(), &argc, argv);
    defer qapp.Delete();

    allocator = init.gpa;
    io = init.io;

    const listwidget = QListWidget.New2();
    defer listwidget.Delete();

    listwidget.SetWindowTitle("Qt 6 KFileMetaData Example");
    listwidget.Resize(500, 250);
    listwidget.SetSpacing(5);

    const size = QSize.New4(200, 200);
    defer size.Delete();

    listwidget.SetIconSize(size);
    listwidget.SetViewMode(qlistview_enums.ViewMode.IconMode);

    const icon = QIcon.New4(filename);
    defer icon.Delete();

    const item = QListWidgetItem.New3(icon, "Image Properties");
    defer item.Delete();

    listwidget.AddItem2(item);

    const object = QObject.New();
    defer object.Delete();

    const pngextractor = KFileMetaData__ExtractorPlugin.New(object);
    pngextractor.OnMimetypes(onMimeTypes);
    pngextractor.OnExtract(onExtract);

    const result = KFileMetaData__SimpleExtractionResult.New(filename);
    defer result.Delete();

    pngextractor.Extract(result);

    var properties = result.Properties(allocator);
    defer properties.deinit(allocator);

    var it = properties.iterator();
    while (it.next()) |entry| {
        const key = entry.key_ptr.*;
        for (0..entry.value_ptr.*.len) |j| {
            const value_str = entry.value_ptr.*[j].ToString(allocator);
            defer {
                allocator.free(value_str);
                entry.value_ptr.*[j].Delete();
                allocator.free(entry.value_ptr.*);
            }

            const info = KFileMetaData__PropertyInfo.New2(key);
            defer info.Delete();

            const name = info.DisplayName(allocator);
            defer allocator.free(name);

            const text = try std.mem.concat(allocator, u8, &.{ name, ": ", value_str });
            defer allocator.free(text);

            listwidget.AddItem(text);
        }
    }

    listwidget.Show();

    _ = QApplication.Exec();
}

fn onMimeTypes() callconv(.c) ?[*:null]?[*:0]const u8 {
    const n: usize = 1;
    const list: [*:null]?[*:0]const u8 = switch (builtin.os.tag == .windows) {
        true => @ptrCast(@alignCast(std.c.malloc((n + 1) * @sizeOf(?[*:0]const u8)) orelse return null)),
        false => std.heap.c_allocator.allocSentinel(?[*:0]const u8, n, null) catch @panic("Failed to allocate memory"),
    };

    list[0] = "image/png";
    list[n] = null;

    return list;
}

fn onExtract(_: KFileMetaData__ExtractorPlugin, result: KFileMetaData__ExtractionResult) callconv(.c) void {
    var format = "png".*;
    const reader = QImageReader.New5(filename, &format);
    defer reader.Delete();

    if (!reader.CanRead()) {
        std.Io.File.stdout().writeStreamingAll(io, "Unable to read input image: '" ++ filename ++ "'\n") catch @panic("onExtract stdout error during read");
        return;
    }

    result.AddType(types_enums.Type.Image);

    if ((result.InputFlags() & extractionresult_enums.Flag.ExtractMetaData) == 0) {
        std.Io.File.stdout().writeStreamingAll(io, "Unable to extract metadata from image: '" ++ filename ++ "'\n") catch @panic("onExtract stdout error during extraction");
        return;
    }

    for (text_mapping) |mapping| {
        const value = reader.Text(
            allocator,
            mapping.key,
        );
        defer allocator.free(value);

        if (value.len == 0) continue;

        const variant = QVariant.New24(value);
        defer variant.Delete();

        result.Add(mapping.property, variant);
    }
}
