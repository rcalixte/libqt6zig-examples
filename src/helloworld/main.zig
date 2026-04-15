const std = @import("std");
const qt6 = @import("libqt6zig");
// Import specific Qt modules for convenience
const qapplication = qt6.qapplication;
const qpushbutton = qt6.qpushbutton;
const qwidget = qt6.qwidget;

var counter: usize = 0;
var buffer: [64]u8 = undefined;

pub fn main(init: std.process.Init) !void {
    // Initialize the Qt application and defer cleanup
    const argv = try qt6.init(init.gpa, init.minimal.args);
    defer qt6.deinit(init.gpa, argv);
    var argc: i32 = @intCast(argv.len);
    // The c_allocator is an option here too, but the debug allocator is not recommended for this instance
    const qapp = qapplication.New(&argc, argv, init.arena.allocator());
    defer qapplication.Delete(qapp);

    // Create a new widget and defer cleanup
    const widget = qwidget.New2();
    defer qwidget.Delete(widget);

    // We don't need to free/delete the button, it's a child of the widget
    const button = qpushbutton.New5("Hello world!", widget);
    qpushbutton.SetFixedWidth(button, 320);
    // Connect the button to the callback function
    qpushbutton.OnClicked(button, onClicked);

    // Display the widget
    qwidget.Show(widget);

    // Start the event loop
    _ = qapplication.Exec();

    try std.Io.File.stdout().writeStreamingAll(init.io, "OK!\n");
}

fn onClicked(self: ?*anyopaque) callconv(.c) void {
    counter += 1;
    const formatted = std.fmt.bufPrint(
        &buffer,
        "You have clicked the button {d} time(s)",
        .{counter},
    ) catch @panic("Failed to bufPrint");
    qpushbutton.SetText(self, formatted);
}
