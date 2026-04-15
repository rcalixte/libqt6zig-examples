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

const zoom_in_scale = 1.25;
const zoom_out_scale = 0.8;
const dx = 32;
const dy = 64;
const replacement_r = 255;
const replacement_g = 255;
const replacement_b = 255;

var buffer: [64]u8 = undefined;

var status_bar: C.QStatusBar = null;
var scene: C.QGraphicsScene = null;
var view: C.QGraphicsView = null;

pub fn main(init: std.process.Init) !void {
    const argv = try qt6.init(init.gpa, init.minimal.args);
    defer qt6.deinit(init.gpa, argv);
    var argc: i32 = @intCast(argv.len);
    const qapp = qapplication.New(&argc, argv, init.arena.allocator());
    defer qapplication.Delete(qapp);

    const window = qmainwindow.New2();
    defer qmainwindow.Delete(window);

    qmainwindow.SetWindowTitle(window, "Qt 6 Pixel Editor Example");
    qmainwindow.Resize(window, 490, 520);
    qmainwindow.SetMinimumSize2(window, 360, 450);

    status_bar = qstatusbar.New(window);
    qmainwindow.SetStatusBar(window, status_bar);

    scene = qgraphicsscene.New();
    defer qgraphicsscene.Delete(scene);

    view = qgraphicsview.New2();
    defer qgraphicsview.Delete(view);

    qgraphicsscene.OnKeyPressEvent(scene, sceneKeyPressEvent);
    qgraphicsscene.OnWheelEvent(scene, sceneWheelEvent);
    qgraphicsview.OnResizeEvent(view, viewResizeEvent);

    const image = qimage.New3(dx, dy, qimage_enums.Format.Format_ARGB32);
    defer qimage.Delete(image);

    for (0..dx) |i| {
        for (0..dy) |j| {
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

    qstatusbar.ShowMessage(status_bar,
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
        qnamespace_enums.Key.Key_0 => qgraphicsview.Scale(view, zoom_in_scale, zoom_in_scale),
        qnamespace_enums.Key.Key_9 => qgraphicsview.Scale(view, zoom_out_scale, zoom_out_scale),
        else => {},
    }
}

fn sceneWheelEvent(_: ?*anyopaque, event: ?*anyopaque) callconv(.c) void {
    if ((qapplication.QueryKeyboardModifiers() & qnamespace_enums.KeyboardModifier.ShiftModifier) != 0) {
        if (qgraphicsscenewheelevent.Delta(event) > 0) {
            qgraphicsview.Scale(view, zoom_in_scale, zoom_in_scale);
        } else {
            qgraphicsview.Scale(view, zoom_out_scale, zoom_out_scale);
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

    const x: i32 = @trunc(qpointf.X(pos));
    const y: i32 = @trunc(qpointf.Y(pos));

    const pm = qgraphicspixmapitem.Pixmap(self);
    defer qpixmap.Delete(pm);

    const img = qpixmap.ToImage(pm);
    defer qimage.Delete(img);

    const height = qimage.Height(img);
    const width = qimage.Width(img);

    if (x < 0 or y < 0 or x >= width or y >= height) {
        return;
    }

    const color = qimage.PixelColor(img, x, y);
    defer qcolor.Delete(color);

    const r = qcolor.Red(color);
    const g = qcolor.Green(color);
    const b = qcolor.Blue(color);

    const msg = std.fmt.bufPrint(&buffer, "x: {d}, y: {d}, r: {d}, g: {d}, b: {d}", .{
        x,
        y,
        r,
        g,
        b,
    }) catch @panic("Failed to bufPrint");

    qstatusbar.ShowMessage(status_bar, msg);
}

fn drawPixel(item: ?*anyopaque, pos: C.QPointF) void {
    const x: i32 = @trunc(qpointf.X(pos));
    const y: i32 = @trunc(qpointf.Y(pos));

    const pm = qgraphicspixmapitem.Pixmap(item);
    defer qpixmap.Delete(pm);

    const img = qpixmap.ToImage(pm);
    defer qimage.Delete(img);

    const color = qcolor.New13(replacement_r, replacement_g, replacement_b, 255);
    defer qcolor.Delete(color);

    const height = qimage.Height(img);
    const width = qimage.Width(img);

    if (x < 0 or y < 0 or x >= width or y >= height) {
        return;
    }

    const msg = std.fmt.bufPrint(&buffer, "x: {d}, y: {d}, r: {d}, g: {d}, b: {d}", .{
        x,
        y,
        replacement_r,
        replacement_g,
        replacement_b,
    }) catch @panic("Failed to bufPrint");

    qstatusbar.ShowMessage(status_bar, msg);

    qimage.SetPixelColor(img, x, y, color);

    const pm2 = qpixmap.FromImage(img);
    defer qpixmap.Delete(pm2);

    qgraphicspixmapitem.SetPixmap(item, pm2);
}
