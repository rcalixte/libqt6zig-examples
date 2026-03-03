const std = @import("std");
const qt6 = @import("libqt6zig");
const C = qt6.C;
const qapplication = qt6.qapplication;
const qmainwindow = qt6.qmainwindow;
const qstatusbar = qt6.qstatusbar;
const qgraphicsscene = qt6.qgraphicsscene;
const qgraphicsview = qt6.qgraphicsview;
const qimage = qt6.qimage;
const qimage_enums = qt6.qimage_enums;
const qcolor = qt6.qcolor;
const qpixmap = qt6.qpixmap;
const qgraphicspixmapitem = qt6.qgraphicspixmapitem;
const qkeyevent = qt6.qkeyevent;
const qnamespace_enums = qt6.qnamespace_enums;
const qgraphicsscenewheelevent = qt6.qgraphicsscenewheelevent;
const qrectf = qt6.qrectf;
const qgraphicsscenehoverevent = qt6.qgraphicsscenehoverevent;
const qpointf = qt6.qpointf;
const qgraphicsscenemouseevent = qt6.qgraphicsscenemouseevent;

const zoomInScale = 1.25;
const zoomOutScale = 0.8;
const dX = 32;
const dY = 64;
const replacementR = 255;
const replacementG = 255;
const replacementB = 255;

var buffer: [64]u8 = undefined;

var statusBar: C.QStatusBar = null;
var scene: C.QGraphicsScene = null;
var view: C.QGraphicsView = null;

pub fn main() !void {
    const argc = std.os.argv.len;
    const argv = std.os.argv.ptr;
    const qapp = qapplication.New(argc, argv);
    defer qapplication.Delete(qapp);

    const window = qmainwindow.New2();
    defer qmainwindow.Delete(window);

    qmainwindow.SetWindowTitle(window, "Qt 6 Pixel Editor Example");
    qmainwindow.Resize(window, 490, 520);
    qmainwindow.SetMinimumSize2(window, 360, 450);

    statusBar = qstatusbar.New(window);
    qmainwindow.SetStatusBar(window, statusBar);

    scene = qgraphicsscene.New();
    defer qgraphicsscene.Delete(scene);

    view = qgraphicsview.New2();
    defer qgraphicsview.Delete(view);

    qgraphicsscene.OnKeyPressEvent(scene, sceneKeyPressEvent);
    qgraphicsscene.OnWheelEvent(scene, sceneWheelEvent);
    qgraphicsview.OnResizeEvent(view, viewResizeEvent);

    const image = qimage.New3(dX, dY, qimage_enums.Format.Format_ARGB32);
    defer qimage.Delete(image);

    for (0..dX) |i| {
        for (0..dY) |j| {
            const x: i32 = @intCast(i);
            const y: i32 = @intCast(j);

            const color = qcolor.New13(x, y * 3, x * 4, 255);
            defer qcolor.Delete(color);

            qimage.SetPixelColor(image, x, y, color);
        }
    }

    const pixmap = qpixmap.FromImage(image);
    defer qpixmap.Delete(pixmap);

    const item = qgraphicspixmapitem.New2(pixmap);
    defer qgraphicspixmapitem.Delete(item);

    qgraphicspixmapitem.SetAcceptHoverEvents(item, true);

    qgraphicspixmapitem.OnMouseMoveEvent(item, itemMouseEvent);
    qgraphicspixmapitem.OnMousePressEvent(item, itemMouseEvent);
    qgraphicspixmapitem.OnHoverMoveEvent(item, itemHoverMoveEvent);

    qgraphicsscene.AddItem(scene, item);
    qgraphicsview.SetScene(view, scene);
    qgraphicsview.Show(view);

    qstatusbar.ShowMessage(statusBar,
        \\Click and drag to draw a pixel.
        \\Use Shift+scroll or keys 0 or 9 to zoom in or out.
    );

    qmainwindow.SetCentralWidget(window, view);
    qmainwindow.Show(window);

    _ = qapplication.Exec();
}

fn sceneKeyPressEvent(_: ?*anyopaque, event: ?*anyopaque) callconv(.c) void {
    const key = qkeyevent.Key(event);
    switch (key) {
        qnamespace_enums.Key.Key_0 => qgraphicsview.Scale(view, zoomInScale, zoomInScale),
        qnamespace_enums.Key.Key_9 => qgraphicsview.Scale(view, zoomOutScale, zoomOutScale),
        else => {},
    }
}

fn sceneWheelEvent(_: ?*anyopaque, event: ?*anyopaque) callconv(.c) void {
    if ((qapplication.QueryKeyboardModifiers() & qnamespace_enums.KeyboardModifier.ShiftModifier) != 0) {
        if (qgraphicsscenewheelevent.Delta(event) > 0) {
            qgraphicsview.Scale(view, zoomInScale, zoomInScale);
        } else {
            qgraphicsview.Scale(view, zoomOutScale, zoomOutScale);
        }
    }
}

fn viewResizeEvent(self: ?*anyopaque, _: ?*anyopaque) callconv(.c) void {
    const rect = qgraphicsscene.ItemsBoundingRect(scene);
    defer qrectf.Delete(rect);

    qgraphicsview.FitInView22(self, rect, qnamespace_enums.AspectRatioMode.KeepAspectRatio);
}

fn itemMouseEvent(self: ?*anyopaque, event: ?*anyopaque) callconv(.c) void {
    const pos = qgraphicsscenemouseevent.Pos(event);
    defer qpointf.Delete(pos);

    drawPixel(self, pos);
}

fn itemHoverMoveEvent(self: ?*anyopaque, event: ?*anyopaque) callconv(.c) void {
    const pos = qgraphicsscenehoverevent.Pos(event);
    defer qpointf.Delete(pos);

    const x: i32 = @intFromFloat(qpointf.X(pos));
    const y: i32 = @intFromFloat(qpointf.Y(pos));

    const pm = qgraphicspixmapitem.Pixmap(self);
    defer qpixmap.Delete(pm);

    const img = qpixmap.ToImage(pm);
    defer qimage.Delete(img);

    const height = qimage.Height(img);
    const width = qimage.Width(img);

    if (x < 0 or y < 0 or x >= width or y >= height) {
        return;
    }

    const colorValue = qimage.PixelColor(img, x, y);
    defer qcolor.Delete(colorValue);

    const r = qcolor.Red(colorValue);
    const g = qcolor.Green(colorValue);
    const b = qcolor.Blue(colorValue);

    const msg = std.fmt.bufPrintZ(&buffer, "x: {d}, y: {d}, r: {d}, g: {d}, b: {d}", .{
        x,
        y,
        r,
        g,
        b,
    }) catch @panic("Failed to bufPrintZ");

    qstatusbar.ShowMessage(statusBar, msg);
}

fn drawPixel(item: ?*anyopaque, pos: C.QPointF) void {
    const x: i32 = @intFromFloat(qpointf.X(pos));
    const y: i32 = @intFromFloat(qpointf.Y(pos));

    const pm = qgraphicspixmapitem.Pixmap(item);
    defer qpixmap.Delete(pm);

    const img = qpixmap.ToImage(pm);
    defer qimage.Delete(img);

    const color = qcolor.New13(replacementR, replacementG, replacementB, 255);
    defer qcolor.Delete(color);

    const height = qimage.Height(img);
    const width = qimage.Width(img);

    if (x < 0 or y < 0 or x >= width or y >= height) {
        return;
    }

    const msg = std.fmt.bufPrintZ(&buffer, "x: {d}, y: {d}, r: {d}, g: {d}, b: {d}", .{
        x,
        y,
        replacementR,
        replacementG,
        replacementB,
    }) catch @panic("Failed to bufPrintZ");

    qstatusbar.ShowMessage(statusBar, msg);

    qimage.SetPixelColor(img, x, y, color);

    const pm2 = qpixmap.FromImage(img);
    defer qpixmap.Delete(pm2);

    qgraphicspixmapitem.SetPixmap(item, pm2);
}
