const std = @import("std");
const qt6 = @import("libqt6zig");
// Import specific Qt modules for convenience
const QApplication = qt6.QApplication;
const QWidget = qt6.QWidget;
const QPushButton = qt6.QPushButton;

var counter: usize = 0;
var buffer: [64]u8 = undefined;

pub fn main(init: std.process.Init) !void {
    // Initialize the Qt application and defer cleanup
    const argv = try qt6.init(init.gpa, init.minimal.args);
    defer qt6.deinit(init.gpa, argv);
    var argc: i32 = @intCast(argv.len);
    // The c_allocator is an option here too, but the debug allocator is not recommended for this instance
    const qapp = QApplication.New(init.arena.allocator(), &argc, argv);
    defer qapp.Delete();

    // Create a new widget and defer cleanup
    const widget = QWidget.New2();
    defer widget.Delete();

    // We don't need to free/delete the button, it's a child of the widget
    const button = QPushButton.New5("Hello world!", widget);
    button.SetFixedWidth(320);
    // Connect the button to the callback function
    button.OnClicked(onClicked);

    // Display the widget
    widget.Show();

    // Start the event loop
    _ = QApplication.Exec();

    try std.Io.File.stdout().writeStreamingAll(init.io, "OK!\n");
}

fn onClicked(self: QPushButton) callconv(.c) void {
    counter += 1;
    const formatted = std.fmt.bufPrint(
        &buffer,
        "You have clicked the button {d} time(s)",
        .{counter},
    ) catch @panic("Failed to bufPrint");
    self.SetText(formatted);
}
