const std = @import("std");
const qt6 = @import("libqt6zig");
const qapplication = qt6.qapplication;
const qlineseries = qt6.qlineseries;
const qchart = qt6.qchart;
const qchartview = qt6.qchartview;
const qpainter_enums = qt6.qpainter_enums;

pub fn main() void {
    const argc = std.os.argv.len;
    const argv = std.os.argv.ptr;
    _ = qapplication.New(argc, argv);

    const series = qlineseries.New();
    defer qlineseries.QDelete(series);

    qlineseries.SetName(series, "Sine Wave");

    var x: f64 = 0.0;
    var y: f64 = 0.0;

    var i: i32 = -500;
    while (i <= 500) : (i += 1) {
        x = @as(f64, @floatFromInt(i)) / 10000;
        y = @sin(1 / x) * x;
        if (std.math.isNan(y)) y = 0;
        qlineseries.Append(series, x, y);
    }

    const chart = qchart.New();
    qchart.AddSeries(chart, series);
    qchart.CreateDefaultAxes(chart);

    const chart_view = qchartview.New3(chart);
    qchartview.SetWindowTitle(chart_view, "Qt 6 Charts Example");
    qchartview.Resize(chart_view, 650, 400);
    qchartview.SetRenderHint(chart_view, qpainter_enums.RenderHint.Antialiasing);
    qchartview.Show(chart_view);

    _ = qapplication.Exec();
}
