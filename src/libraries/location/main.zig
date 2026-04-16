const std = @import("std");
const qt6 = @import("libqt6zig");
const QApplication = qt6.QApplication;
const QListWidget = qt6.QListWidget;
const QPlace = qt6.QPlace;

var allocator: std.mem.Allocator = undefined;

var listwidget: QListWidget = undefined;

pub fn main(init: std.process.Init) !void {
    const argv = try qt6.init(init.gpa, init.minimal.args);
    defer qt6.deinit(init.gpa, argv);
    var argc: i32 = @intCast(argv.len);
    const qapp = QApplication.New(init.arena.allocator(), &argc, argv);
    defer qapp.Delete();

    allocator = init.gpa;

    listwidget = QListWidget.New2();
    defer listwidget.Delete();

    listwidget.SetWindowTitle("Qt 6 Location Example");
    listwidget.Resize(400, 250);
    listwidget.SetSpacing(5);

    const place1 = QPlace.New();
    defer place1.Delete();

    place1.SetName("Eiffel Tower");
    place1.SetPlaceId("Champ de Mars, Paris, France");

    const place2 = QPlace.New();
    defer place2.Delete();

    place2.SetName("Space Needle");
    place2.SetPlaceId("Seattle, Washington, USA");

    const place3 = QPlace.New();
    defer place3.Delete();

    place3.SetName("Statue of Liberty");
    place3.SetPlaceId("New York, USA");

    addPlace(place1);
    addPlace(place2);
    addPlace(place3);

    listwidget.Show();

    _ = QApplication.Exec();
}

fn addPlace(place: QPlace) void {
    const name = place.Name(allocator);
    defer allocator.free(name);

    const placeid = place.PlaceId(allocator);
    defer allocator.free(placeid);

    const text = std.mem.concat(allocator, u8, &.{ name, "\n", placeid }) catch @panic("Failed to concat");
    defer allocator.free(text);

    listwidget.AddItem(text);
}
