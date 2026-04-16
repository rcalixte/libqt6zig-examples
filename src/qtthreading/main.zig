const std = @import("std");
const qt6 = @import("libqt6zig");
const QApplication = qt6.QApplication;
const QMainWindow = qt6.QMainWindow;
const QWidget = qt6.QWidget;
const QVBoxLayout = qt6.QVBoxLayout;
const QLabel = qt6.QLabel;
const qnamespace_enums = qt6.qnamespace_enums;
const QPushButton = qt6.QPushButton;
const QVariant = qt6.QVariant;
const threading = qt6.threading;

// Data for each button, attached via Qt's property system
const ButtonData = struct {
    counters: *std.ArrayListUnmanaged(*Counter),
    button: QPushButton,
};

pub fn main(init: std.process.Init) !void {
    const argv = try qt6.init(init.gpa, init.minimal.args);
    defer qt6.deinit(init.gpa, argv);
    var argc: i32 = @intCast(argv.len);
    const qapp = QApplication.New(init.arena.allocator(), &argc, argv);
    defer qapp.Delete();

    const thread_count: u16 = @min(std.Thread.getCpuCount() catch 2, 16);

    // This will serve as our parent object. When we deallocate it, all the
    // children will be deallocated as well. Because this is not
    // allocated with memory visible to Zig, we need to be mindful of
    // memory leaks.
    const window = QMainWindow.New2();
    defer window.Delete();

    window.SetFixedSize2(250, 50 * (thread_count + 1));
    window.SetWindowTitle("Qt 6 Threading Example");

    const widget = QWidget.New(window);
    const layout = QVBoxLayout.New(widget);
    window.SetCentralWidget(widget);

    // Create a counter and state for each thread
    var counters: std.ArrayListUnmanaged(*Counter) = .empty;
    var group: std.Io.Group = .init;

    for (0..thread_count) |_| {
        const label = QLabel.New(widget);
        label.SetAlignment(qnamespace_enums.AlignmentFlag.AlignCenter);
        label.SetText("0 0");
        layout.AddWidget(label);

        const counter = try init.gpa.create(Counter);

        counter.* = .{
            .label = label,
            .counter = 0,
            .io = init.io,
            .group = &group,
        };

        try counters.append(init.gpa, counter);
    }
    defer {
        // First we stop all counters, then destroy them.
        // We only need to destroy the Counter objects since
        // the QLabel objects are cleaned up by Qt when the
        // parent object is cleaned up.
        for (counters.items) |counter| {
            counter.stop();
            init.gpa.destroy(counter);
        }
        // Deinitialize the ArrayList
        counters.deinit(init.gpa);
    }

    const button = QPushButton.New5("Start!", widget);
    button.OnClicked(onClicked);
    layout.AddWidget(button);

    var button_data = ButtonData{
        .counters = &counters,
        .button = button,
    };

    // Create a QVariant to store the pointer and use Qt's property system
    // to store it on the button
    const variant = QVariant.New7(@intFromPtr(&button_data));
    defer variant.Delete();

    _ = button.SetProperty("buttonData", variant);

    window.Show();

    _ = QApplication.Exec();
}

fn onClicked(self: QPushButton) callconv(.c) void {
    const variant = self.Property("buttonData");
    defer variant.Delete();

    const ptr_val = variant.ToLongLong();
    const data_ptr: *ButtonData = @ptrFromInt(@as(usize, @intCast(ptr_val)));

    // Check if any counter is running
    const is_running = for (data_ptr.counters.items) |counter| {
        if (counter.running) break true;
    } else false;

    if (is_running) {
        // Stop all counters
        for (data_ptr.counters.items) |counter|
            counter.stop();
        data_ptr.button.SetText("Start!");
    } else {
        // Start all counters
        for (data_ptr.counters.items) |counter| {
            counter.running = true;
            counter.group.concurrent(counter.io, Counter.run, .{counter}) catch @panic("Failed to concurrently run counter");
        }
        data_ptr.button.SetText("Stop!");
    }
}

const Counter = struct {
    counter: i32,
    label: QLabel,
    running: bool = false,
    buffer: [32]u8 = undefined,
    io: std.Io,
    group: *std.Io.Group,

    fn run(self: *Counter) !void {
        while (self.running) {
            threading.Async(self, asyncUpdate);
            self.counter += 1;
            try self.io.sleep(.fromMicroseconds(100), .awake);
        }
    }

    fn stop(self: *Counter) void {
        self.running = false;
        self.group.cancel(self.io);
    }

    fn asyncUpdate(context: ?*anyopaque) callconv(.c) void {
        const counter: *Counter = @ptrCast(@alignCast(context));
        const text = std.fmt.bufPrint(&counter.buffer, "{d} {d}", .{
            counter.counter,
            std.Io.Clock.real.now(counter.io).toSeconds(),
        }) catch @panic("Failed to bufPrint");
        counter.label.SetText(text);
    }
};
