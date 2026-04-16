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
    const qapp = QApplication.New(init.arena.allocator(), &argc, argv);
    defer qapp.Delete();

    const document = QPdfDocument.New();
    defer document.Delete();

    const err = document.Load(file_path);
    if (err != qpdfdocument_enums.Error.None) {
        std.log.err("Failed to load document: {s}", .{file_path});
        return;
    }

    const pdfview = QPdfView.New2();
    defer pdfview.Delete();

    pdfview.SetWindowTitle("Qt 6 PDF Example");
    pdfview.SetMinimumSize2(650, 600);
    pdfview.SetPageMode(qpdfview_enums.PageMode.MultiPage);
    pdfview.SetZoomMode(qpdfview_enums.ZoomMode.FitInView);
    pdfview.SetDocument(document);

    pdfview.Show();

    _ = QApplication.Exec();
}
