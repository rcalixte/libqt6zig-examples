const std = @import("std");
const qt6 = @import("libqt6zig");
const QApplication = qt6.QApplication;
const QMainWindow = qt6.QMainWindow;
const QStatusBar = qt6.QStatusBar;
const QGraphicsScene = qt6.QGraphicsScene;
const QGraphicsView = qt6.QGraphicsView;
const QImage = qt6.QImage;
const qimage_enums = qt6.qimage_enums;
const QColor = qt6.QColor;
const QPixmap = qt6.QPixmap;
const QGraphicsPixmapItem = qt6.QGraphicsPixmapItem;
const QKeyEvent = qt6.QKeyEvent;
const QResizeEvent = qt6.QResizeEvent;
const qnamespace_enums = qt6.qnamespace_enums;
const QGraphicsSceneWheelEvent = qt6.QGraphicsSceneWheelEvent;
const QGraphicsSceneHoverEvent = qt6.QGraphicsSceneHoverEvent;
const QPointF = qt6.QPointF;
const QGraphicsSceneMouseEvent = qt6.QGraphicsSceneMouseEvent;

const zoom_in_scale = 1.25;
const zoom_out_scale = 0.8;
const dx = 32;
const dy = 64;
const replacement_r = 255;
const replacement_g = 255;
const replacement_b = 255;

var buffer: [64]u8 = undefined;

var status_bar: QStatusBar = undefined;
var scene: QGraphicsScene = undefined;
var view: QGraphicsView = undefined;

pub fn main(init: std.process.Init) !void {
    const argv = try qt6.init(init.gpa, init.minimal.args);
    defer qt6.deinit(init.gpa, argv);
    var argc: i32 = @intCast(argv.len);
    const qapp: QApplication = .new(init.arena.allocator(), &argc, argv);
    defer qapp.delete();

    const window = QMainWindow.new2();
    defer window.delete();

    window.setWindowTitle("Qt 6 Pixel Editor Example");
    window.resize(490, 520);
    window.setMinimumSize2(360, 450);

    status_bar = .new(window);
    window.setStatusBar(status_bar);

    scene = .new();
    defer scene.delete();

    view = .new2();
    defer view.delete();

    scene.onKeyPressEvent(sceneKeyPressEvent);
    scene.onWheelEvent(sceneWheelEvent);
    view.onResizeEvent(viewResizeEvent);

    const image = QImage.new3(dx, dy, qimage_enums.Format.Format_ARGB32);
    defer image.delete();

    for (0..dx) |i|
        for (0..dy) |j| {
            const x: i32 = @intCast(i);
            const y: i32 = @intCast(j);

            const color = QColor.new15(x, y * 3, x * 4, 255);
            defer color.delete();

            image.setPixelColor(x, y, color);
        };

    const pixmap = QPixmap.fromImage(image);
    defer pixmap.delete();

    const item = QGraphicsPixmapItem.new2(pixmap);
    defer item.delete();

    item.setAcceptHoverEvents(true);

    item.onMouseMoveEvent(itemMouseEvent);
    item.onMousePressEvent(itemMouseEvent);
    item.onHoverMoveEvent(itemHoverMoveEvent);

    scene.addItem(item);
    view.setScene(scene);
    view.show();

    status_bar.showMessage("Click and drag to draw a pixel. " ++
        "Use Shift+scroll or keys 0 or 9 to zoom in or out.");

    window.setCentralWidget(view);
    window.show();

    _ = QApplication.exec();
}

fn sceneKeyPressEvent(_: QGraphicsScene, event: QKeyEvent) callconv(.c) void {
    const key = event.key();
    switch (key) {
        qnamespace_enums.Key.Key_0 => view.scale(zoom_in_scale, zoom_in_scale),
        qnamespace_enums.Key.Key_9 => view.scale(zoom_out_scale, zoom_out_scale),
        else => {},
    }
}

fn sceneWheelEvent(_: QGraphicsScene, event: QGraphicsSceneWheelEvent) callconv(.c) void {
    if ((QApplication.queryKeyboardModifiers() & qnamespace_enums.KeyboardModifier.ShiftModifier) != 0)
        if (event.delta() > 0)
            view.scale(zoom_in_scale, zoom_in_scale)
        else
            view.scale(zoom_out_scale, zoom_out_scale);
}

fn viewResizeEvent(self: QGraphicsView, _: QResizeEvent) callconv(.c) void {
    const rect = scene.itemsBoundingRect();
    defer rect.delete();

    self.fitInView22(rect, qnamespace_enums.AspectRatioMode.KeepAspectRatio);
}

fn itemMouseEvent(self: QGraphicsPixmapItem, event: QGraphicsSceneMouseEvent) callconv(.c) void {
    const pos = event.pos();
    defer pos.delete();

    drawPixel(self, pos);
}

fn itemHoverMoveEvent(self: QGraphicsPixmapItem, event: QGraphicsSceneHoverEvent) callconv(.c) void {
    const pos = event.pos();
    defer pos.delete();

    const x: i32 = @trunc(pos.x());
    const y: i32 = @trunc(pos.y());

    const pm = self.pixmap();
    defer pm.delete();

    const img = pm.toImage();
    defer img.delete();

    const height = img.height();
    const width = img.width();

    if (x < 0 or y < 0 or x >= width or y >= height) return;

    const color = img.pixelColor(x, y);
    defer color.delete();

    const r = color.red();
    const g = color.green();
    const b = color.blue();

    const msg = std.fmt.bufPrint(&buffer, "x: {d}, y: {d}, r: {d}, g: {d}, b: {d}", .{
        x,
        y,
        r,
        g,
        b,
    }) catch @panic("Failed to bufPrint");

    status_bar.showMessage(msg);
}

fn drawPixel(item: QGraphicsPixmapItem, pos: QPointF) void {
    const x: i32 = @trunc(pos.x());
    const y: i32 = @trunc(pos.y());

    const pm = item.pixmap();
    defer pm.delete();

    const img = pm.toImage();
    defer img.delete();

    const color = QColor.new15(replacement_r, replacement_g, replacement_b, 255);
    defer color.delete();

    const height = img.height();
    const width = img.width();

    if (x < 0 or y < 0 or x >= width or y >= height) return;

    const msg = std.fmt.bufPrint(&buffer, "x: {d}, y: {d}, r: {d}, g: {d}, b: {d}", .{
        x,
        y,
        replacement_r,
        replacement_g,
        replacement_b,
    }) catch @panic("Failed to bufPrint");

    status_bar.showMessage(msg);

    img.setPixelColor(x, y, color);

    const pm2 = QPixmap.fromImage(img);
    defer pm2.delete();

    item.setPixmap(pm2);
}
