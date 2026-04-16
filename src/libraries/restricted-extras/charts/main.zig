const std = @import("std");
const qt6 = @import("libqt6zig");
const QApplication = qt6.QApplication;
const QLineSeries = qt6.QLineSeries;
const QChart = qt6.QChart;
const QChartView = qt6.QChartView;
const qpainter_enums = qt6.qpainter_enums;

pub fn main(init: std.process.Init) !void {
    const argv = try qt6.init(init.gpa, init.minimal.args);
    defer qt6.deinit(init.gpa, argv);
    var argc: i32 = @intCast(argv.len);
    const qapp = QApplication.New(init.arena.allocator(), &argc, argv);
    defer qapp.Delete();

    const series = QLineSeries.New();
    defer series.Delete();

    series.SetName("Sine Wave");

    var x: f64 = 0;
    var y: f64 = 0;

    var i: f16 = -500;
    while (i <= 500) : (i += 1) {
        x = i / 10000;
        y = @sin(1 / x) * x;
        if (std.math.isNan(y)) y = 0;
        series.Append(x, y);
    }

    const chart = QChart.New();
    chart.AddSeries(series);
    chart.CreateDefaultAxes();

    const chart_view = QChartView.New3(chart);
    chart_view.SetWindowTitle("Qt 6 Charts Example");
    chart_view.Resize(650, 400);
    chart_view.SetRenderHint(qpainter_enums.RenderHint.Antialiasing);
    chart_view.Show();

    _ = QApplication.Exec();
}
