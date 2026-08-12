const std = @import("std");
const qt6 = @import("libqt6zig");
const QApplication = qt6.QApplication;
const QListWidget = qt6.QListWidget;
const QPlace = qt6.QPlace;

var listwidget: QListWidget = undefined;

pub fn main(init: std.process.Init) !void {
    const argv = try qt6.init(init.gpa, init.minimal.args);
    defer qt6.deinit(init.gpa, argv);
    var argc: i32 = @intCast(argv.len);
    const qapp: QApplication = .new(init.arena.allocator(), &argc, argv);
    defer qapp.delete();

    listwidget = .new2();
    defer listwidget.delete();

    listwidget.setWindowTitle("Qt 6 Location Example");
    listwidget.resize(400, 250);
    listwidget.setSpacing(5);

    const place1 = QPlace.new();
    defer place1.delete();

    place1.setName("Eiffel Tower");
    place1.setPlaceId("Champ de Mars, Paris, France");

    const place2 = QPlace.new();
    defer place2.delete();

    place2.setName("Space Needle");
    place2.setPlaceId("Seattle, Washington, USA");

    const place3 = QPlace.new();
    defer place3.delete();

    place3.setName("Statue of Liberty");
    place3.setPlaceId("New York, USA");

    addPlace(place1, init.gpa);
    addPlace(place2, init.gpa);
    addPlace(place3, init.gpa);

    listwidget.show();

    _ = QApplication.exec();
}

fn addPlace(place: QPlace, allocator: std.mem.Allocator) void {
    const name = place.name(allocator);
    defer allocator.free(name);

    const placeid = place.placeId(allocator);
    defer allocator.free(placeid);

    const text = std.mem.concat(allocator, u8, &.{ name, "\n", placeid }) catch
        @panic("Failed to concat");
    defer allocator.free(text);

    listwidget.addItem(text);
}
