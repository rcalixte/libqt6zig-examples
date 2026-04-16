const std = @import("std");
const qt6 = @import("libqt6zig");
const QApplication = qt6.QApplication;
const Poppler__Document = qt6.Poppler__Document;
const QWidget = qt6.QWidget;
const QVBoxLayout = qt6.QVBoxLayout;
const QScrollArea = qt6.QScrollArea;
const qnamespace_enums = qt6.qnamespace_enums;
const QImage = qt6.QImage;
const qimage_enums = qt6.qimage_enums;
const QPainter = qt6.QPainter;
const QLabel = qt6.QLabel;
const QPixmap = qt6.QPixmap;

const file_path = "assets/example.pdf";
const dpi = 150;

pub fn main(init: std.process.Init) !void {
    const argv = try qt6.init(init.gpa, init.minimal.args);
    defer qt6.deinit(init.gpa, argv);
    var argc: i32 = @intCast(argv.len);
    const qapp = QApplication.New(init.arena.allocator(), &argc, argv);
    defer qapp.Delete();

    const document = Poppler__Document.Load(file_path);
    defer document.Delete();

    if (document.ptr == null or document.IsLocked()) {
        if (document.ptr != null)
            document.Delete();
        std.log.err("Failed to load document: {s}", .{file_path});
        return;
    }

    const num_pages = document.NumPages();

    const widget = QWidget.New2();
    defer widget.Delete();

    widget.SetWindowTitle("Qt 6 Poppler Example");
    widget.Resize(1200, 700);

    const layout = QVBoxLayout.New(widget);

    const scroll_area = QScrollArea.New(widget);
    scroll_area.SetWidgetResizable(true);

    const container = QWidget.New2();

    const page_layout = QVBoxLayout.New(container);
    _ = page_layout.SetAlignment(container, qnamespace_enums.AlignmentFlag.AlignHCenter);

    scroll_area.SetWidget(container);
    layout.AddWidget(scroll_area);

    var i: usize = 0;
    while (i < num_pages) : (i += 1) {
        const page = document.Page(@intCast(i));
        defer page.Delete();

        if (page.ptr == null) {
            std.log.err("Failed to load page: {d}", .{i});
            return;
        }

        var image = page.RenderToImage22(dpi, dpi);
        defer image.Delete();

        if (image.HasAlphaChannel()) {
            const size = image.Size();
            defer size.Delete();

            const background = QImage.New2(size, qimage_enums.Format.Format_RGB32);
            background.Fill3(qnamespace_enums.GlobalColor.White);

            const painter = QPainter.New2(background);
            defer painter.Delete();

            painter.DrawImage9(0, 0, image);

            image.Delete();
            image = background;
        }

        const label = QLabel.New2();

        const pixmap = QPixmap.FromImage(image);
        defer pixmap.Delete();

        label.SetPixmap(pixmap);
        label.SetAlignment(qnamespace_enums.AlignmentFlag.AlignCenter);
        label.SetStyleSheet("border: 1px solid #ccc; background-color: white;");

        page_layout.AddWidget(label);
    }

    widget.Show();

    _ = QApplication.Exec();
}
