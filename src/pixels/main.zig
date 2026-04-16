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
    const qapp = QApplication.New(init.arena.allocator(), &argc, argv);
    defer qapp.Delete();

    const window = QMainWindow.New2();
    defer window.Delete();

    window.SetWindowTitle("Qt 6 Pixel Editor Example");
    window.Resize(490, 520);
    window.SetMinimumSize2(360, 450);

    status_bar = QStatusBar.New(window);
    window.SetStatusBar(status_bar);

    scene = QGraphicsScene.New();
    defer scene.Delete();

    view = QGraphicsView.New2();
    defer view.Delete();

    scene.OnKeyPressEvent(sceneKeyPressEvent);
    scene.OnWheelEvent(sceneWheelEvent);
    view.OnResizeEvent(viewResizeEvent);

    const image = QImage.New3(dx, dy, qimage_enums.Format.Format_ARGB32);
    defer image.Delete();

    for (0..dx) |i|
        for (0..dy) |j| {
            const x: i32 = @intCast(i);
            const y: i32 = @intCast(j);

            const color = QColor.New13(x, y * 3, x * 4, 255);
            defer color.Delete();

            image.SetPixelColor(x, y, color);
        };

    const pixmap = QPixmap.FromImage(image);
    defer pixmap.Delete();

    const item = QGraphicsPixmapItem.New2(pixmap);
    defer item.Delete();

    item.SetAcceptHoverEvents(true);

    item.OnMouseMoveEvent(itemMouseEvent);
    item.OnMousePressEvent(itemMouseEvent);
    item.OnHoverMoveEvent(itemHoverMoveEvent);

    scene.AddItem(item);
    view.SetScene(scene);
    view.Show();

    status_bar.ShowMessage(
        \\Click and drag to draw a pixel.
        \\Use Shift+scroll or keys 0 or 9 to zoom in or out.
    );

    window.SetCentralWidget(view);
    window.Show();

    _ = QApplication.Exec();
}

fn sceneKeyPressEvent(_: QGraphicsScene, event: QKeyEvent) callconv(.c) void {
    const key = event.Key();
    switch (key) {
        qnamespace_enums.Key.Key_0 => view.Scale(zoom_in_scale, zoom_in_scale),
        qnamespace_enums.Key.Key_9 => view.Scale(zoom_out_scale, zoom_out_scale),
        else => {},
    }
}

fn sceneWheelEvent(_: QGraphicsScene, event: QGraphicsSceneWheelEvent) callconv(.c) void {
    if ((QApplication.QueryKeyboardModifiers() & qnamespace_enums.KeyboardModifier.ShiftModifier) != 0)
        if (event.Delta() > 0)
            view.Scale(zoom_in_scale, zoom_in_scale)
        else
            view.Scale(zoom_out_scale, zoom_out_scale);
}

fn viewResizeEvent(self: QGraphicsView, _: QResizeEvent) callconv(.c) void {
    const rect = scene.ItemsBoundingRect();
    defer rect.Delete();

    self.FitInView22(rect, qnamespace_enums.AspectRatioMode.KeepAspectRatio);
}

fn itemMouseEvent(self: QGraphicsPixmapItem, event: QGraphicsSceneMouseEvent) callconv(.c) void {
    const pos = event.Pos();
    defer pos.Delete();

    drawPixel(self, pos);
}

fn itemHoverMoveEvent(self: QGraphicsPixmapItem, event: QGraphicsSceneHoverEvent) callconv(.c) void {
    const pos = event.Pos();
    defer pos.Delete();

    const x: i32 = @trunc(pos.X());
    const y: i32 = @trunc(pos.Y());

    const pm = self.Pixmap();
    defer pm.Delete();

    const img = pm.ToImage();
    defer img.Delete();

    const height = img.Height();
    const width = img.Width();

    if (x < 0 or y < 0 or x >= width or y >= height) return;

    const color = img.PixelColor(x, y);
    defer color.Delete();

    const r = color.Red();
    const g = color.Green();
    const b = color.Blue();

    const msg = std.fmt.bufPrint(&buffer, "x: {d}, y: {d}, r: {d}, g: {d}, b: {d}", .{
        x,
        y,
        r,
        g,
        b,
    }) catch @panic("Failed to bufPrint");

    status_bar.ShowMessage(msg);
}

fn drawPixel(item: QGraphicsPixmapItem, pos: QPointF) void {
    const x: i32 = @trunc(pos.X());
    const y: i32 = @trunc(pos.Y());

    const pm = item.Pixmap();
    defer pm.Delete();

    const img = pm.ToImage();
    defer img.Delete();

    const color = QColor.New13(replacement_r, replacement_g, replacement_b, 255);
    defer color.Delete();

    const height = img.Height();
    const width = img.Width();

    if (x < 0 or y < 0 or x >= width or y >= height) return;

    const msg = std.fmt.bufPrint(&buffer, "x: {d}, y: {d}, r: {d}, g: {d}, b: {d}", .{
        x,
        y,
        replacement_r,
        replacement_g,
        replacement_b,
    }) catch @panic("Failed to bufPrint");

    status_bar.ShowMessage(msg);

    img.SetPixelColor(x, y, color);

    const pm2 = QPixmap.FromImage(img);
    defer pm2.Delete();

    item.SetPixmap(pm2);
}
