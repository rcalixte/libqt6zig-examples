const std = @import("std");
const qt6 = @import("libqt6zig");
const qapplication = qt6.qapplication;
const qlineseries = qt6.qlineseries;
const qchart = qt6.qchart;
const qchartview = qt6.qchartview;
const qpainter_enums = qt6.qpainter_enums;

pub fn main(init: std.process.Init) !void {
    const argv = try qt6.init(init.gpa, init.minimal.args);
    defer qt6.deinit(init.gpa, argv);
    var argc: i32 = @intCast(argv.len);
    const qapp = qapplication.New(&argc, argv, init.arena.allocator());
    defer qapplication.Delete(qapp);

    const series = qlineseries.New();
    defer qlineseries.Delete(series);

    qlineseries.SetName(series, "Sine Wave");

    var x: f64 = 0.0;
    var y: f64 = 0.0;

    var i: i32 = -500;
    while (i <= 500) : (i += 1) {
        x = @as(f64, i) / 10000;
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
