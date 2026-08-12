const std = @import("std");
const qt6 = @import("libqt6zig");
const QApplication = qt6.QApplication;
const QMainWindow = qt6.QMainWindow;
const QWidget = qt6.QWidget;
const QDoubleSpinBox = qt6.QDoubleSpinBox;
const QGeoCoordinate = qt6.QGeoCoordinate;
const qgeocoordinate_enums = qt6.qgeocoordinate_enums;
const QLabel = qt6.QLabel;
const qnamespace_enums = qt6.qnamespace_enums;
const QFormLayout = qt6.QFormLayout;

var allocator: std.mem.Allocator = undefined;

var coord: QGeoCoordinate = undefined;
var label: QLabel = undefined;

pub fn main(init: std.process.Init) !void {
    const argv = try qt6.init(init.gpa, init.minimal.args);
    defer qt6.deinit(init.gpa, argv);
    var argc: i32 = @intCast(argv.len);
    const qapp: QApplication = .new(init.arena.allocator(), &argc, argv);
    defer qapp.delete();

    allocator = init.gpa;

    const window = QMainWindow.new2();
    defer window.delete();

    window.setWindowTitle("Qt 6 Positioning Example");
    window.resize(300, 120);

    const widget = QWidget.new2();

    const lat = QDoubleSpinBox.new2();
    lat.setObjectName("lat");
    lat.setRange(-90, 90);
    lat.setDecimals(5);
    lat.setValue(0);
    lat.onValueChanged(onValueChanged);

    const lon = QDoubleSpinBox.new2();
    lon.setObjectName("lon");
    lon.setRange(-180, 180);
    lon.setDecimals(5);
    lon.setValue(0);
    lon.onValueChanged(onValueChanged);

    coord = .new2(lat.value(), lon.value());
    defer coord.delete();

    const geotext = coord.toString1(
        allocator,
        qgeocoordinate_enums.CoordinateFormat.DegreesWithHemisphere,
    );
    defer allocator.free(geotext);

    const text = try std.mem.concat(allocator, u8, &.{ "### ", geotext });
    defer allocator.free(text);

    label = .new3(text);
    label.setTextFormat(qnamespace_enums.TextFormat.MarkdownText);

    const layout = QFormLayout.new2();
    layout.setFormAlignment(qnamespace_enums.AlignmentFlag.AlignHCenter);
    layout.setSpacing(10);
    layout.addRow3("Latitude:", lat);
    layout.addRow3("Longitude:", lon);
    layout.addWidget(label);

    widget.setLayout(layout);
    window.setCentralWidget(widget);
    window.show();

    _ = QApplication.exec();
}

fn onValueChanged(self: QDoubleSpinBox, value: f64) callconv(.c) void {
    const name = self.objectName(allocator);
    defer allocator.free(name);

    if (std.mem.eql(u8, name, "lat"))
        coord.setLatitude(value)
    else if (std.mem.eql(u8, name, "lon"))
        coord.setLongitude(value);

    const geotext = coord.toString1(
        allocator,
        qgeocoordinate_enums.CoordinateFormat.DegreesWithHemisphere,
    );
    defer allocator.free(geotext);

    const text = std.mem.concat(allocator, u8, &.{ "### ", geotext }) catch
        @panic("Failed to concat");
    defer allocator.free(text);

    label.setText(text);
}
