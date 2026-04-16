const std = @import("std");
const qt6 = @import("libqt6zig");
const QApplication = qt6.QApplication;
const KPlotWidget = qt6.KPlotWidget;
const KPlotObject = qt6.KPlotObject;
const kplotobject_enums = qt6.kplotobject_enums;
const QColor = qt6.QColor;
const qnamespace_enums = qt6.qnamespace_enums;

pub fn main(init: std.process.Init) !void {
    const argv = try qt6.init(init.gpa, init.minimal.args);
    defer qt6.deinit(init.gpa, argv);
    var argc: i32 = @intCast(argv.len);
    const qapp = QApplication.New(init.arena.allocator(), &argc, argv);
    defer qapp.Delete();

    const kplot = KPlotWidget.New2();
    defer kplot.Delete();

    kplot.SetWindowTitle("Qt 6 KPlotting Example");
    kplot.SetMinimumSize2(400, 400);

    const color1 = QColor.New4(qnamespace_enums.GlobalColor.Red);
    defer color1.Delete();

    const plotobject1 = KPlotObject.New3(color1, kplotobject_enums.PlotType.Bars);
    plotobject1.AddPoint3(0.1, 0.1);
    plotobject1.AddPoint3(0.3, 0.3);
    plotobject1.AddPoint3(0.5, 0.5);

    const color2 = QColor.New4(qnamespace_enums.GlobalColor.Blue);
    defer color2.Delete();

    const plotobject2 = KPlotObject.New3(color2, kplotobject_enums.PlotType.Bars);
    plotobject2.AddPoint3(0.6, 0.8);
    plotobject2.AddPoint3(0.7, 0.7);
    plotobject2.AddPoint3(0.8, 0.6);

    kplot.AddPlotObject(plotobject1);
    kplot.AddPlotObject(plotobject2);

    kplot.Show();

    _ = QApplication.Exec();
}
