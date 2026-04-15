const std = @import("std");
const qt6 = @import("libqt6zig");
const C = qt6.C;
const qapplication = qt6.qapplication;
const qmainwindow = qt6.qmainwindow;
const qwidget = qt6.qwidget;
const qvboxlayout = qt6.qvboxlayout;
const qlabel = qt6.qlabel;
const qnamespace_enums = qt6.qnamespace_enums;
const qpushbutton = qt6.qpushbutton;
const qvariant = qt6.qvariant;
const threading = qt6.threading;

// Data for each button, attached via Qt's property system
const ButtonData = struct {
    counters: *std.ArrayListUnmanaged(*Counter),
    button: C.QPushButton,
};

pub fn main(init: std.process.Init) !void {
    const argv = try qt6.init(init.gpa, init.minimal.args);
    defer qt6.deinit(init.gpa, argv);
    var argc: i32 = @intCast(argv.len);
    const qapp = qapplication.New(&argc, argv, init.arena.allocator());
    defer qapplication.Delete(qapp);

    const thread_count = std.Thread.getCpuCount() catch 2;

    // This will serve as our parent object. When we deallocate it, all the
    // children will be deallocated as well. Because this is not
    // allocated with memory visible to Zig, we need to be mindful of
    // memory leaks.
    const window = qmainwindow.New2();
    defer qmainwindow.Delete(window);

    qmainwindow.SetFixedSize2(window, 250, 50 * @as(i32, @intCast(thread_count)) + 1);
    qmainwindow.SetWindowTitle(window, "Qt 6 Threading Example");

    const widget = qwidget.New(window);
    const layout = qvboxlayout.New(widget);
    qmainwindow.SetCentralWidget(window, widget);

    // Create a counter and state for each thread
    var counters: std.ArrayListUnmanaged(*Counter) = .empty;
    var group: std.Io.Group = .init;

    for (0..thread_count) |_| {
        const label = qlabel.New(widget);
        qlabel.SetAlignment(label, qnamespace_enums.AlignmentFlag.AlignCenter);
        qlabel.SetText(label, "0 0");
        qvboxlayout.AddWidget(layout, label);

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

    const button = qpushbutton.New5("Start!", widget);
    qpushbutton.OnClicked(button, onClicked);
    qvboxlayout.AddWidget(layout, button);

    var button_data = ButtonData{
        .counters = &counters,
        .button = button,
    };

    // Create a QVariant to store the pointer and use Qt's property system
    // to store it on the button
    const variant = qvariant.New7(@intFromPtr(&button_data));
    defer qvariant.Delete(variant);

    _ = qpushbutton.SetProperty(button, "buttonData", variant);

    qmainwindow.Show(window);

    _ = qapplication.Exec();
}

fn onClicked(self: ?*anyopaque) callconv(.c) void {
    const variant = qpushbutton.Property(self, "buttonData");
    defer qvariant.Delete(variant);

    const ptr_val = qvariant.ToLongLong(variant);
    const data_ptr = @as(*ButtonData, @ptrFromInt(@as(usize, @intCast(ptr_val))));

    // Check if any counter is running
    const is_running = for (data_ptr.counters.items) |counter| {
        if (counter.running) break true;
    } else false;

    if (is_running) {
        // Stop all counters
        for (data_ptr.counters.items) |counter|
            counter.stop();
        qpushbutton.SetText(data_ptr.button, "Start!");
    } else {
        // Start all counters
        for (data_ptr.counters.items) |counter| {
            counter.running = true;
            counter.group.concurrent(counter.io, Counter.run, .{counter}) catch @panic("Failed to concurrently run counter");
        }
        qpushbutton.SetText(data_ptr.button, "Stop!");
    }
}

const Counter = struct {
    counter: i32,
    label: C.QLabel,
    running: bool = false,
    buffer: [32]u8 = undefined,
    io: std.Io,
    group: *std.Io.Group = undefined,

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
        qlabel.SetText(counter.label, text);
    }
};
