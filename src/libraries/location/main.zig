const std = @import("std");
const qt6 = @import("libqt6zig");
const C = qt6.C;
const qapplication = qt6.qapplication;
const qlistwidget = qt6.qlistwidget;
const qplace = qt6.qplace;

var gpa = @import("alloc_config").gpa;
const allocator = gpa.allocator();

var listwidget: C.QListWidget = undefined;

pub fn main() void {
    const argc = std.os.argv.len;
    const argv = std.os.argv.ptr;
    const qapp = qapplication.New(argc, argv);
    defer qapplication.QDelete(qapp);

    defer _ = gpa.deinit();

    listwidget = qlistwidget.New2();
    defer qlistwidget.QDelete(listwidget);

    qlistwidget.SetWindowTitle(listwidget, "Qt 6 Location Example");
    qlistwidget.Resize(listwidget, 400, 250);
    qlistwidget.SetSpacing(listwidget, 5);

    const place1 = qplace.New();
    defer qplace.QDelete(place1);

    qplace.SetName(place1, "Eiffel Tower");
    qplace.SetPlaceId(place1, "Champ de Mars, Paris, France");

    const place2 = qplace.New();
    defer qplace.QDelete(place2);

    qplace.SetName(place2, "Space Needle");
    qplace.SetPlaceId(place2, "Seattle, Washington, USA");

    const place3 = qplace.New();
    defer qplace.QDelete(place3);

    qplace.SetName(place3, "Statue of Liberty");
    qplace.SetPlaceId(place3, "New York, USA");

    addPlace(place1);
    addPlace(place2);
    addPlace(place3);

    qlistwidget.Show(listwidget);

    _ = qapplication.Exec();
}

fn addPlace(place: C.QPlace) void {
    const name = qplace.Name(place, allocator);
    defer allocator.free(name);

    const placeid = qplace.PlaceId(place, allocator);
    defer allocator.free(placeid);

    const text = std.mem.concat(allocator, u8, &.{ name, "\n", placeid }) catch @panic("Failed to concat");
    defer allocator.free(text);

    qlistwidget.AddItem(listwidget, text);
}
