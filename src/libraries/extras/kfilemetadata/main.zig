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
    const qapp = qapplication.New(&argc, argv, init.arena.allocator());
    defer qapplication.Delete(qapp);

    allocator = init.gpa;
    io = init.io;

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
    const list = std.heap.c_allocator.allocSentinel(?[*:0]const u8, 1, null) catch @panic("Failed to allocate memory");
    list[0] = "image/png";

    return list.ptr;
}

fn onExtract(_: ?*anyopaque, result: ?*anyopaque) callconv(.c) void {
    var format = "png".*;
    const reader = qimagereader.New5(filename, &format);
    defer qimagereader.Delete(reader);

    if (!qimagereader.CanRead(reader)) {
        std.Io.File.stdout().writeStreamingAll(io, "Unable to read input image: '" ++ filename ++ "'\n") catch @panic("onExtract stdout error during read");
        return;
    }

    kfilemetadata__extractionresult.AddType(result, types_enums.Type.Image);

    if ((kfilemetadata__extractionresult.InputFlags(result) & extractionresult_enums.Flag.ExtractMetaData) == 0) {
        std.Io.File.stdout().writeStreamingAll(io, "Unable to extract metadata from image: '" ++ filename ++ "'\n") catch @panic("onExtract stdout error during extraction");
        return;
    }

    for (text_mapping) |mapping| {
        const value = qimagereader.Text(reader, mapping.key, allocator);
        defer allocator.free(value);

        if (value.len == 0) continue;

        const variant = qt6.qvariant.New24(value);
        defer qt6.qvariant.Delete(variant);

        kfilemetadata__extractionresult.Add(result, mapping.property, variant);
    }
}
