const std = @import("std");
const qt6 = @import("libqt6zig");
const qapplication = qt6.qapplication;
const kplotwidget = qt6.kplotwidget;
const kplotobject = qt6.kplotobject;
const kplotobject_enums = qt6.kplotobject_enums;
const qcolor = qt6.qcolor;
const qnamespace_enums = qt6.qnamespace_enums;

pub fn main() void {
    const argc = std.os.argv.len;
    const argv = std.os.argv.ptr;
    _ = qapplication.New(argc, argv);

    const kplot = kplotwidget.New2();
    defer kplotwidget.QDelete(kplot);

    kplotwidget.SetWindowTitle(kplot, "Qt 6 KPlotting Example");
    kplotwidget.SetMinimumSize2(kplot, 400, 400);

    const color1 = qcolor.New4(qnamespace_enums.GlobalColor.Red);
    defer qcolor.QDelete(color1);
    const plotobject1 = kplotobject.New3(color1, kplotobject_enums.PlotType.Bars);
    kplotobject.AddPoint3(plotobject1, 0.1, 0.1);
    kplotobject.AddPoint3(plotobject1, 0.3, 0.3);
    kplotobject.AddPoint3(plotobject1, 0.5, 0.5);

    const color2 = qcolor.New4(qnamespace_enums.GlobalColor.Blue);
    defer qcolor.QDelete(color2);
    const plotobject2 = kplotobject.New3(color2, kplotobject_enums.PlotType.Bars);
    kplotobject.AddPoint3(plotobject2, 0.6, 0.8);
    kplotobject.AddPoint3(plotobject2, 0.7, 0.7);
    kplotobject.AddPoint3(plotobject2, 0.8, 0.6);

    kplotwidget.AddPlotObject(kplot, plotobject1);
    kplotwidget.AddPlotObject(kplot, plotobject2);

    kplotwidget.Show(kplot);

    _ = qapplication.Exec();
}
