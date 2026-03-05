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

var gpa = @import("alloc_config").gpa;
const allocator = gpa.allocator();

const FILENAME = "assets/example.pdf";
const DPI = 150.0;

pub fn main() !void {
    const argc = std.os.argv.len;
    const argv = std.os.argv.ptr;
    const qapp = qapplication.New(argc, argv);
    defer qapplication.Delete(qapp);

    defer _ = gpa.deinit();

    const document = poppler__document.Load(FILENAME);
    defer poppler__document.Delete(document);

    if (document == null or poppler__document.IsLocked(document)) {
        if (document != null) {
            poppler__document.Delete(document);
        }
        std.log.err("Failed to load document: {s}", .{FILENAME});
        return;
    }

    const numPages = poppler__document.NumPages(document);

    const widget = qwidget.New2();
    defer qwidget.Delete(widget);

    qwidget.SetWindowTitle(widget, "Qt 6 Poppler Example");
    qwidget.Resize(widget, 1200, 700);

    const layout = qvboxlayout.New(widget);

    const scrollArea = qscrollarea.New(widget);
    qscrollarea.SetWidgetResizable(scrollArea, true);

    const container = qwidget.New2();

    const pageLayout = qvboxlayout.New(container);
    _ = qvboxlayout.SetAlignment(pageLayout, container, qnamespace_enums.AlignmentFlag.AlignHCenter);

    qscrollarea.SetWidget(scrollArea, container);
    qvboxlayout.AddWidget(layout, scrollArea);

    var i: usize = 0;
    while (i < numPages) : (i += 1) {
        const page = poppler__document.Page(document, @intCast(i));
        defer poppler__page.Delete(page);

        if (page == null) {
            std.log.err("Failed to load page: {d}", .{i});
            return;
        }

        var image = poppler__page.RenderToImage22(page, DPI, DPI);
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

        qvboxlayout.AddWidget(pageLayout, label);
    }

    qwidget.Show(widget);

    _ = qapplication.Exec();
}
