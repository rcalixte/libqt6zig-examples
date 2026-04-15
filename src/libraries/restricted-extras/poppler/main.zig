const std = @import("std");
const qt6 = @import("libqt6zig");
const qapplication = qt6.qapplication;
const poppler__document = qt6.poppler__document;
const poppler__page = qt6.poppler__page;
const qwidget = qt6.qwidget;
const qvboxlayout = qt6.qvboxlayout;
const qscrollarea = qt6.qscrollarea;
const qnamespace_enums = qt6.qnamespace_enums;
const qimage = qt6.qimage;
const qimage_enums = qt6.qimage_enums;
const qsize = qt6.qsize;
const qpainter = qt6.qpainter;
const qlabel = qt6.qlabel;
const qpixmap = qt6.qpixmap;

const file_path = "assets/example.pdf";
const dpi = 150.0;

pub fn main(init: std.process.Init) !void {
    const argv = try qt6.init(init.gpa, init.minimal.args);
    defer qt6.deinit(init.gpa, argv);
    var argc: i32 = @intCast(argv.len);
    const qapp = qapplication.New(&argc, argv, init.arena.allocator());
    defer qapplication.Delete(qapp);

    const document = poppler__document.Load(file_path);
    defer poppler__document.Delete(document);

    if (document == null or poppler__document.IsLocked(document)) {
        if (document != null)
            poppler__document.Delete(document);
        std.log.err("Failed to load document: {s}", .{file_path});
        return;
    }

    const num_pages = poppler__document.NumPages(document);

    const widget = qwidget.New2();
    defer qwidget.Delete(widget);

    qwidget.SetWindowTitle(widget, "Qt 6 Poppler Example");
    qwidget.Resize(widget, 1200, 700);

    const layout = qvboxlayout.New(widget);

    const scroll_area = qscrollarea.New(widget);
    qscrollarea.SetWidgetResizable(scroll_area, true);

    const container = qwidget.New2();

    const page_layout = qvboxlayout.New(container);
    _ = qvboxlayout.SetAlignment(page_layout, container, qnamespace_enums.AlignmentFlag.AlignHCenter);

    qscrollarea.SetWidget(scroll_area, container);
    qvboxlayout.AddWidget(layout, scroll_area);

    var i: usize = 0;
    while (i < num_pages) : (i += 1) {
        const page = poppler__document.Page(document, @intCast(i));
        defer poppler__page.Delete(page);

        if (page == null) {
            std.log.err("Failed to load page: {d}", .{i});
            return;
        }

        var image = poppler__page.RenderToImage22(page, dpi, dpi);
        defer qimage.Delete(image);

        if (qimage.HasAlphaChannel(image)) {
            const size = qimage.Size(image);
            defer qsize.Delete(size);

            const background = qimage.New2(size, qimage_enums.Format.Format_RGB32);
            qimage.Fill3(background, qnamespace_enums.GlobalColor.White);

            const painter = qpainter.New2(background);
            defer qpainter.Delete(painter);

            qpainter.DrawImage9(painter, 0, 0, image);

            qimage.Delete(image);
            image = background;
        }

        const label = qlabel.New2();

        const pixmap = qpixmap.FromImage(image);
        defer qpixmap.Delete(pixmap);

        qlabel.SetPixmap(label, pixmap);
        qlabel.SetAlignment(label, qnamespace_enums.AlignmentFlag.AlignCenter);
        qlabel.SetStyleSheet(label, "border: 1px solid #ccc; background-color: white;");

        qvboxlayout.AddWidget(page_layout, label);
    }

    qwidget.Show(widget);

    _ = qapplication.Exec();
}
