const std = @import("std");
const qt6 = @import("libqt6zig");
const QApplication = qt6.QApplication;
const QMainWindow = qt6.QMainWindow;
const Q3DBars = qt6.Q3DBars;
const QCategory3DAxis = qt6.QCategory3DAxis;
const QValue3DAxis = qt6.QValue3DAxis;
const QBar3DSeries = qt6.QBar3DSeries;
const QBarDataItem = qt6.QBarDataItem;
const qsizepolicy_enums = qt6.qsizepolicy_enums;
const qnamespace_enums = qt6.qnamespace_enums;

pub fn main(init: std.process.Init) !void {
    const argv = try qt6.init(init.gpa, init.minimal.args);
    defer qt6.deinit(init.gpa, argv);
    var argc: i32 = @intCast(argv.len);
    const qapp: QApplication = .new(init.arena.allocator(), &argc, argv);
    defer qapp.delete();

    const window = QMainWindow.new2();
    defer window.delete();

    const bars = Q3DBars.new();
    const column_axis = QCategory3DAxis.new();
    column_axis.setTitle("Columns");
    column_axis.setTitleVisible(true);
    column_axis.setLabels(init.gpa, &.{ "Column 1", "Column 2" });
    column_axis.setLabelAutoRotation(30);

    const row_axis = QCategory3DAxis.new();
    row_axis.setTitle("Rows");
    row_axis.setTitleVisible(true);
    row_axis.setLabels(init.gpa, &.{ "Row 1", "Row 2" });
    row_axis.setLabelAutoRotation(30);

    const value_axis = QValue3DAxis.new();
    value_axis.setTitle("Values");
    value_axis.setTitleVisible(true);
    value_axis.setRange(0, 5);

    bars.setColumnAxis(column_axis);
    bars.setRowAxis(row_axis);
    bars.setValueAxis(value_axis);

    const series = QBar3DSeries.new();
    var row0 = [_]QBarDataItem{ .new2(1), .new2(2) };
    defer for (row0) |item| item.delete();
    var row1 = [_]QBarDataItem{ .new2(3), .new2(4) };
    defer for (row1) |item| item.delete();
    var bar_items = [_][]QBarDataItem{ &row0, &row1 };
    _ = series.dataProxy().addRows(init.gpa, &bar_items);
    bars.setPrimarySeries(series);

    const container = QMainWindow.createWindowContainer(bars);
    if (!bars.hasContext()) {
        std.log.err("Failed to initialize the OpenGL context", .{});
        return error.FailedToInitializeContext;
    }

    bars.scene().activeCamera().setYRotation(22.5);
    const geometry = QApplication.primaryScreen().geometry();
    defer geometry.delete();
    const size = @divTrunc(geometry.height() * 3, 4);
    container.setMinimumSize2(size, size);
    container.setSizePolicy2(qsizepolicy_enums.Policy.Expanding, qsizepolicy_enums.Policy.Expanding);
    container.setFocusPolicy(qnamespace_enums.FocusPolicy.StrongFocus);

    window.setCentralWidget(container);
    window.setWindowTitle("Qt 6 Data Visualization Example");
    window.resize(800, 600);

    window.show();

    _ = QApplication.exec();
}
