const std = @import("std");
const qt6 = @import("libqt6zig");
const properties_enums = qt6.properties_enums;
const qapplication = qt6.qapplication;
const qlistwidget = qt6.qlistwidget;
const qsize = qt6.qsize;
const qlistview_enums = qt6.qlistview_enums;
const qicon = qt6.qicon;
const qlistwidgetitem = qt6.qlistwidgetitem;
const qnamespace_enums = qt6.qnamespace_enums;
const qobject = qt6.qobject;
const kfilemetadata__extractorplugin = qt6.kfilemetadata__extractorplugin;
const kfilemetadata__simpleextractionresult = qt6.kfilemetadata__simpleextractionresult;
const qvariant = qt6.qvariant;
const kfilemetadata__propertyinfo = qt6.kfilemetadata__propertyinfo;
const qimagereader = qt6.qimagereader;
const kfilemetadata__extractionresult = qt6.kfilemetadata__extractionresult;
const types_enums = qt6.types_enums;
const extractionresult_enums = qt6.extractionresult_enums;

var gpa = @import("alloc_config").gpa;
const allocator = gpa.allocator();
const c_allocator = std.heap.c_allocator;

var buffer: [64]u8 = undefined;
const filename = "assets/Qt.png";

const textMapping = [_]struct {
    key: []const u8,
    property: i32,
}{
    .{ .key = "Comment", .property = properties_enums.Property.Comment },
};

pub fn main() !void {
    const argc = std.os.argv.len;
    const argv = std.os.argv.ptr;
    const qapp = qapplication.New(argc, argv);
    defer qapplication.Delete(qapp);

    defer _ = gpa.deinit();

    const listwidget = qlistwidget.New2();
    defer qlistwidget.Delete(listwidget);

    qlistwidget.SetWindowTitle(listwidget, "Qt 6 KFileMetaData Example");
    qlistwidget.Resize(listwidget, 500, 250);
    qlistwidget.SetSpacing(listwidget, 5);

    const size = qsize.New4(200, 200);
    defer qsize.Delete(size);

    qlistwidget.SetIconSize(listwidget, size);
    qlistwidget.SetViewMode(listwidget, qlistview_enums.ViewMode.IconMode);

    const icon = qicon.New4(filename);
    defer qicon.Delete(icon);

    const item = qlistwidgetitem.New3(icon, "Image Properties");
    defer qlistwidgetitem.Delete(item);

    qlistwidget.AddItem2(listwidget, item);

    const object = qobject.New();
    defer qobject.Delete(object);

    const pngextractor = kfilemetadata__extractorplugin.New(object);
    kfilemetadata__extractorplugin.OnMimetypes(pngextractor, onMimeTypes);
    kfilemetadata__extractorplugin.OnExtract(pngextractor, onExtract);

    const result = kfilemetadata__simpleextractionresult.New(filename);
    defer kfilemetadata__simpleextractionresult.Delete(result);
    kfilemetadata__extractorplugin.Extract(pngextractor, result);

    var properties = kfilemetadata__simpleextractionresult.Properties(result, allocator);
    defer properties.deinit(allocator);

    var it = properties.iterator();
    while (it.next()) |entry| {
        const key = entry.key_ptr.*;
        for (0..entry.value_ptr.*.len) |j| {
            const value_str = qvariant.ToString(entry.value_ptr.*[j], allocator);
            defer {
                allocator.free(value_str);
                qvariant.Delete(entry.value_ptr.*[j]);
                allocator.free(entry.value_ptr.*);
            }

            const info = kfilemetadata__propertyinfo.New2(key);
            defer kfilemetadata__propertyinfo.Delete(info);

            const name = kfilemetadata__propertyinfo.DisplayName(info, allocator);
            defer allocator.free(name);

            const text = try std.mem.concat(allocator, u8, &.{ name, ": ", value_str });
            defer allocator.free(text);

            qlistwidget.AddItem(listwidget, text);
        }
    }

    qlistwidget.Show(listwidget);

    _ = qapplication.Exec();
}

fn onMimeTypes() callconv(.c) ?[*:null]?[*:0]const u8 {
    const list = c_allocator.allocSentinel(?[*:0]const u8, 1, null) catch @panic("Failed to allocate memory");
    list[0] = "image/png";

    return list.ptr;
}

fn onExtract(_: ?*anyopaque, result: ?*anyopaque) callconv(.c) void {
    var stdout_writer = std.fs.File.stdout().writer(&buffer);

    var format = "png".*;
    const reader = qimagereader.New5(filename, &format);
    defer qimagereader.Delete(reader);

    if (!qimagereader.CanRead(reader)) {
        stdout_writer.interface.print("Unable to read input image: '{s}'\n", .{filename}) catch @panic("onExtract stdout error during read");
        stdout_writer.interface.flush() catch @panic("onExtract flush stdout error during read");
        return;
    }

    kfilemetadata__extractionresult.AddType(result, types_enums.Type.Image);

    if ((kfilemetadata__extractionresult.InputFlags(result) & extractionresult_enums.Flag.ExtractMetaData) == 0) {
        stdout_writer.interface.print("Unable to extract metadata from image: '{s}'\n", .{filename}) catch @panic("onExtract stdout error during extraction");
        stdout_writer.interface.flush() catch @panic("onExtract flush stdout error during extraction");
        return;
    }

    for (textMapping) |mapping| {
        const value = qimagereader.Text(reader, mapping.key, allocator);
        defer allocator.free(value);

        if (value.len == 0) continue;

        const variant = qt6.qvariant.New24(value);
        defer qt6.qvariant.Delete(variant);

        kfilemetadata__extractionresult.Add(result, mapping.property, variant);
    }
}
