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
    const qapp: QApplication = .new(init.arena.allocator(), &argc, argv);
    defer qapp.delete();

    const document = Poppler__Document.load(file_path);
    defer document.delete();

    if (document.ptr == null or document.isLocked()) {
        if (document.ptr != null)
            document.delete();
        std.log.err("Failed to load document: {s}", .{file_path});
        return;
    }

    const num_pages = document.numPages();

    const widget = QWidget.new2();
    defer widget.delete();

    widget.setWindowTitle("Qt 6 Poppler Example");
    widget.resize(1200, 700);

    const layout = QVBoxLayout.new(widget);

    const scroll_area = QScrollArea.new(widget);
    scroll_area.setWidgetResizable(true);

    const container = QWidget.new2();

    const page_layout = QVBoxLayout.new(container);
    _ = page_layout.setAlignment(container, qnamespace_enums.AlignmentFlag.AlignHCenter);

    scroll_area.setWidget(container);
    layout.addWidget(scroll_area);

    var i: usize = 0;
    while (i < num_pages) : (i += 1) {
        const page = document.page(@intCast(i));
        defer page.delete();

        if (page.ptr == null) {
            std.log.err("Failed to load page: {d}", .{i});
            return;
        }

        var image = page.renderToImage22(dpi, dpi);
        defer image.delete();

        if (image.hasAlphaChannel()) {
            const size = image.size();
            defer size.delete();

            const background = QImage.new2(size, qimage_enums.Format.Format_RGB32);
            background.fill3(qnamespace_enums.GlobalColor.White);

            const painter = QPainter.new2(background);
            defer painter.delete();

            painter.drawImage9(0, 0, image);

            image.delete();
            image = background;
        }

        const label = QLabel.new2();

        const pixmap = QPixmap.fromImage(image);
        defer pixmap.delete();

        label.setPixmap(pixmap);
        label.setAlignment(qnamespace_enums.AlignmentFlag.AlignCenter);
        label.setStyleSheet("border: 1px solid #ccc; background-color: white;");

        page_layout.addWidget(label);
    }

    widget.show();

    _ = QApplication.exec();
}
