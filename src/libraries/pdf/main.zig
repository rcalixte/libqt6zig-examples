const std = @import("std");
const qt6 = @import("libqt6zig");
const qapplication = qt6.qapplication;
const qpdfdocument = qt6.qpdfdocument;
const qpdfview = qt6.qpdfview;
const qpdfview_enums = qt6.qpdfview_enums;
const qpdfdocument_enums = qt6.qpdfdocument_enums;

const pdfFile = "assets/example.pdf";

pub fn main() void {
    const argc = std.os.argv.len;
    const argv = std.os.argv.ptr;
    const qapp = qapplication.New(argc, argv);
    defer qapplication.Delete(qapp);

    const document = qpdfdocument.New();
    defer qpdfdocument.Delete(document);

    const err = qpdfdocument.Load(document, pdfFile);
    if (err != qpdfdocument_enums.Error.None) {
        std.log.err("Failed to load document: {s}", .{pdfFile});
        return;
    }

    const pdfview = qpdfview.New2();
    defer qpdfview.Delete(pdfview);

    qpdfview.SetWindowTitle(pdfview, "Qt 6 PDF Example");
    qpdfview.SetMinimumSize2(pdfview, 650, 600);
    qpdfview.SetPageMode(pdfview, qpdfview_enums.PageMode.MultiPage);
    qpdfview.SetZoomMode(pdfview, qpdfview_enums.ZoomMode.FitInView);
    qpdfview.SetDocument(pdfview, document);

    qpdfview.Show(pdfview);

    _ = qapplication.Exec();
}
