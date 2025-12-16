const std = @import("std");
const qt6 = @import("libqt6zig");
const C = qt6.C;
const qapplication = qt6.qapplication;
const qmainwindow = qt6.qmainwindow;
const qwidget = qt6.qwidget;
const qdoublespinbox = qt6.qdoublespinbox;
const qgeocoordinate = qt6.qgeocoordinate;
const qgeocoordinate_enums = qt6.qgeocoordinate_enums;
const qlabel = qt6.qlabel;
const qnamespace_enums = qt6.qnamespace_enums;
const qformlayout = qt6.qformlayout;

var gpa = @import("alloc_config").gpa;
const allocator = gpa.allocator();

var coord: C.QGeoCoordinate = undefined;
var label: C.QLabel = undefined;

pub fn main() !void {
    const argc = std.os.argv.len;
    const argv = std.os.argv.ptr;
    const qapp = qapplication.New(argc, argv);
    defer qapplication.QDelete(qapp);

    defer _ = gpa.deinit();

    const window = qmainwindow.New2();
    defer qmainwindow.QDelete(window);

    qmainwindow.SetWindowTitle(window, "Qt 6 Positioning Example");
    qmainwindow.Resize(window, 300, 120);

    const widget = qwidget.New2();

    const lat = qdoublespinbox.New2();
    qdoublespinbox.SetObjectName(lat, "lat");
    qdoublespinbox.SetRange(lat, -90.0, 90.0);
    qdoublespinbox.SetDecimals(lat, 5);
    qdoublespinbox.SetValue(lat, 0.0);
    qdoublespinbox.OnValueChanged(lat, onValueChanged);

    const lon = qdoublespinbox.New2();
    qdoublespinbox.SetObjectName(lon, "lon");
    qdoublespinbox.SetRange(lon, -180.0, 180.0);
    qdoublespinbox.SetDecimals(lon, 5);
    qdoublespinbox.SetValue(lon, 0.0);
    qdoublespinbox.OnValueChanged(lon, onValueChanged);

    coord = qgeocoordinate.New2(qdoublespinbox.Value(lat), qdoublespinbox.Value(lon));
    defer qgeocoordinate.QDelete(coord);

    const geotext = qgeocoordinate.ToString1(
        coord,
        qgeocoordinate_enums.CoordinateFormat.DegreesWithHemisphere,
        allocator,
    );
    defer allocator.free(geotext);

    const text = try std.mem.concat(allocator, u8, &.{ "### ", geotext });
    defer allocator.free(text);

    label = qlabel.New3(text);
    qlabel.SetTextFormat(label, qnamespace_enums.TextFormat.MarkdownText);

    const layout = qformlayout.New2();
    qformlayout.SetFormAlignment(layout, qnamespace_enums.AlignmentFlag.AlignHCenter);
    qformlayout.SetSpacing(layout, 10);
    qformlayout.AddRow3(layout, "Latitude:", lat);
    qformlayout.AddRow3(layout, "Longitude:", lon);
    qformlayout.AddWidget(layout, label);

    qwidget.SetLayout(widget, layout);
    qmainwindow.SetCentralWidget(window, widget);
    qmainwindow.Show(window);

    _ = qapplication.Exec();
}

fn onValueChanged(self: ?*anyopaque, value: f64) callconv(.c) void {
    const name = qdoublespinbox.ObjectName(self, allocator);
    defer allocator.free(name);

    if (std.mem.eql(u8, name, "lat")) {
        qgeocoordinate.SetLatitude(coord, value);
    } else if (std.mem.eql(u8, name, "lon")) {
        qgeocoordinate.SetLongitude(coord, value);
    }

    const geotext = qgeocoordinate.ToString1(
        coord,
        qgeocoordinate_enums.CoordinateFormat.DegreesWithHemisphere,
        allocator,
    );
    defer allocator.free(geotext);

    const text = std.mem.concat(allocator, u8, &.{ "### ", geotext }) catch @panic("Failed to concat");
    defer allocator.free(text);

    qlabel.SetText(label, text);
}
