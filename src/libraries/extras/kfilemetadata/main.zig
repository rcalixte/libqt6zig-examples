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
    const qapp: QApplication = .new(init.arena.allocator(), &argc, argv);
    defer qapp.delete();

    allocator = init.gpa;
    io = init.io;

    const listwidget = QListWidget.new2();
    defer listwidget.delete();

    listwidget.setWindowTitle("Qt 6 KFileMetaData Example");
    listwidget.resize(500, 250);
    listwidget.setSpacing(5);

    const size = QSize.new4(200, 200);
    defer size.delete();

    listwidget.setIconSize(size);
    listwidget.setViewMode(qlistview_enums.ViewMode.IconMode);

    const icon = QIcon.new4(filename);
    defer icon.delete();

    const item = QListWidgetItem.new3(icon, "Image Properties");
    defer item.delete();

    listwidget.addItem2(item);

    const object = QObject.new();
    defer object.delete();

    const pngextractor = KFileMetaData__ExtractorPlugin.new(object);
    pngextractor.onMimetypes(onMimeTypes);
    pngextractor.onExtract(onExtract);

    const result = KFileMetaData__SimpleExtractionResult.new(filename);
    defer result.delete();

    pngextractor.extract(result);

    var properties = result.properties(allocator);
    defer properties.deinit(allocator);

    var it = properties.iterator();
    while (it.next()) |entry| {
        const key = entry.key_ptr.*;
        for (0..entry.value_ptr.*.len) |j| {
            const value_str = entry.value_ptr.*[j].toString(allocator);
            defer {
                allocator.free(value_str);
                entry.value_ptr.*[j].delete();
                allocator.free(entry.value_ptr.*);
            }

            const info = KFileMetaData__PropertyInfo.new2(key);
            defer info.delete();

            const name = info.displayName(allocator);
            defer allocator.free(name);

            const text = try std.mem.concat(allocator, u8, &.{ name, ": ", value_str });
            defer allocator.free(text);

            listwidget.addItem(text);
        }
    }

    listwidget.show();

    _ = QApplication.exec();
}

fn onMimeTypes() callconv(.c) ?[*:null]?[*:0]const u8 {
    const n: usize = 1;
    const list: [*:null]?[*:0]const u8 = switch (builtin.os.tag == .windows) {
        true => @ptrCast(@alignCast(std.c.malloc((n + 1) * @sizeOf(?[*:0]const u8)) orelse return null)),
        false => std.heap.c_allocator.allocSentinel(?[*:0]const u8, n, null) catch
            @panic("Failed to allocate memory"),
    };

    list[0] = "image/png";
    list[n] = null;

    return list;
}

fn onExtract(_: KFileMetaData__ExtractorPlugin, result: KFileMetaData__ExtractionResult) callconv(.c) void {
    var format = "png".*;
    const reader = QImageReader.new5(filename, &format);
    defer reader.delete();

    if (!reader.canRead()) {
        std.Io.File.stdout().writeStreamingAll(
            io,
            "Unable to read input image: '" ++ filename ++ "'\n",
        ) catch @panic("onExtract stdout error during read");
        return;
    }

    result.addType(types_enums.Type.Image);

    if ((result.inputFlags() & extractionresult_enums.Flag.ExtractMetaData) == 0) {
        std.Io.File.stdout().writeStreamingAll(
            io,
            "Unable to extract metadata from image: '" ++ filename ++ "'\n",
        ) catch @panic("onExtract stdout error during extraction");
        return;
    }

    for (text_mapping) |mapping| {
        const value = reader.text(
            allocator,
            mapping.key,
        );
        defer allocator.free(value);

        if (value.len == 0) continue;

        const variant = QVariant.new24(value);
        defer variant.delete();

        result.add(mapping.property, variant);
    }
}
