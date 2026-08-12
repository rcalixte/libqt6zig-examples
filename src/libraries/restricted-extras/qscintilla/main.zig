const std = @import("std");
const qt6 = @import("libqt6zig");
const QApplication = qt6.QApplication;
const QsciScintilla = qt6.QsciScintilla;

pub fn main(init: std.process.Init) !void {
    const argv = try qt6.init(init.gpa, init.minimal.args);
    defer qt6.deinit(init.gpa, argv);
    var argc: i32 = @intCast(argv.len);
    const qapp: QApplication = .new(init.arena.allocator(), &argc, argv);
    defer qapp.delete();

    const area = QsciScintilla.new2();
    defer area.delete();

    area.setFixedSize2(640, 480);
    area.show();

    _ = QApplication.exec();
}
