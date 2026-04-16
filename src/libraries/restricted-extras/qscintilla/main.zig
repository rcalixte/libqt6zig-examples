const std = @import("std");
const qt6 = @import("libqt6zig");
const QApplication = qt6.QApplication;
const QsciScintilla = qt6.QsciScintilla;

pub fn main(init: std.process.Init) !void {
    const argv = try qt6.init(init.gpa, init.minimal.args);
    defer qt6.deinit(init.gpa, argv);
    var argc: i32 = @intCast(argv.len);
    const qapp = QApplication.New(init.arena.allocator(), &argc, argv);
    defer qapp.Delete();

    const area = QsciScintilla.New2();
    defer area.Delete();

    area.SetFixedSize2(640, 480);
    area.Show();

    _ = QApplication.Exec();
}
