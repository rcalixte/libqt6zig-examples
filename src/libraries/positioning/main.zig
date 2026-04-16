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
    const qapp = QApplication.New(init.arena.allocator(), &argc, argv);
    defer qapp.Delete();

    allocator = init.gpa;

    const window = QMainWindow.New2();
    defer window.Delete();

    window.SetWindowTitle("Qt 6 Positioning Example");
    window.Resize(300, 120);

    const widget = QWidget.New2();

    const lat = QDoubleSpinBox.New2();
    lat.SetObjectName("lat");
    lat.SetRange(-90, 90);
    lat.SetDecimals(5);
    lat.SetValue(0);
    lat.OnValueChanged(onValueChanged);

    const lon = QDoubleSpinBox.New2();
    lon.SetObjectName("lon");
    lon.SetRange(-180, 180);
    lon.SetDecimals(5);
    lon.SetValue(0);
    lon.OnValueChanged(onValueChanged);

    coord = QGeoCoordinate.New2(lat.Value(), lon.Value());
    defer coord.Delete();

    const geotext = coord.ToString1(
        allocator,
        qgeocoordinate_enums.CoordinateFormat.DegreesWithHemisphere,
    );
    defer allocator.free(geotext);

    const text = try std.mem.concat(allocator, u8, &.{ "### ", geotext });
    defer allocator.free(text);

    label = QLabel.New3(text);
    label.SetTextFormat(qnamespace_enums.TextFormat.MarkdownText);

    const layout = QFormLayout.New2();
    layout.SetFormAlignment(qnamespace_enums.AlignmentFlag.AlignHCenter);
    layout.SetSpacing(10);
    layout.AddRow3("Latitude:", lat);
    layout.AddRow3("Longitude:", lon);
    layout.AddWidget(label);

    widget.SetLayout(layout);
    window.SetCentralWidget(widget);
    window.Show();

    _ = QApplication.Exec();
}

fn onValueChanged(self: QDoubleSpinBox, value: f64) callconv(.c) void {
    const name = self.ObjectName(allocator);
    defer allocator.free(name);

    if (std.mem.eql(u8, name, "lat"))
        coord.SetLatitude(value)
    else if (std.mem.eql(u8, name, "lon"))
        coord.SetLongitude(value);

    const geotext = coord.ToString1(
        allocator,
        qgeocoordinate_enums.CoordinateFormat.DegreesWithHemisphere,
    );
    defer allocator.free(geotext);

    const text = std.mem.concat(allocator, u8, &.{ "### ", geotext }) catch @panic("Failed to concat");
    defer allocator.free(text);

    label.SetText(text);
}
