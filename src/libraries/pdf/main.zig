const std = @import("std");
const qt6 = @import("libqt6zig");
const QApplication = qt6.QApplication;
const QPdfDocument = qt6.QPdfDocument;
const QPdfView = qt6.QPdfView;
const qpdfview_enums = qt6.qpdfview_enums;
const qpdfdocument_enums = qt6.qpdfdocument_enums;

const file_path = "assets/example.pdf";

pub fn main(init: std.process.Init) !void {
    const argv = try qt6.init(init.gpa, init.minimal.args);
    defer qt6.deinit(init.gpa, argv);
    var argc: i32 = @intCast(argv.len);
    const qapp: QApplication = .new(init.arena.allocator(), &argc, argv);
    defer qapp.delete();

    const document = QPdfDocument.new();
    defer document.delete();

    if (document.load(file_path) != qpdfdocument_enums.Error.None) {
        std.log.err("Failed to load document: {s}", .{file_path});
        return;
    }

    const pdfview = QPdfView.new2();
    defer pdfview.delete();

    pdfview.setWindowTitle("Qt 6 PDF Example");
    pdfview.setMinimumSize2(650, 600);
    pdfview.setPageMode(qpdfview_enums.PageMode.MultiPage);
    pdfview.setZoomMode(qpdfview_enums.ZoomMode.FitInView);
    pdfview.setDocument(document);

    pdfview.show();

    _ = QApplication.exec();
}
