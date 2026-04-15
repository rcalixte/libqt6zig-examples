const std = @import("std");
const qt6 = @import("libqt6zig");
const C = qt6.C;
const qapplication = qt6.qapplication;
const qlistwidget = qt6.qlistwidget;
const qplace = qt6.qplace;

var allocator: std.mem.Allocator = undefined;

var listwidget: C.QListWidget = null;

pub fn main(init: std.process.Init) !void {
    const argv = try qt6.init(init.gpa, init.minimal.args);
    defer qt6.deinit(init.gpa, argv);
    var argc: i32 = @intCast(argv.len);
    const qapp = qapplication.New(&argc, argv, init.arena.allocator());
    defer qapplication.Delete(qapp);

    allocator = init.gpa;

    listwidget = qlistwidget.New2();
    defer qlistwidget.Delete(listwidget);

    qlistwidget.SetWindowTitle(listwidget, "Qt 6 Location Example");
    qlistwidget.Resize(listwidget, 400, 250);
    qlistwidget.SetSpacing(listwidget, 5);

    const place1 = qplace.New();
    defer qplace.Delete(place1);

    qplace.SetName(place1, "Eiffel Tower");
    qplace.SetPlaceId(place1, "Champ de Mars, Paris, France");

    const place2 = qplace.New();
    defer qplace.Delete(place2);

    qplace.SetName(place2, "Space Needle");
    qplace.SetPlaceId(place2, "Seattle, Washington, USA");

    const place3 = qplace.New();
    defer qplace.Delete(place3);

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
