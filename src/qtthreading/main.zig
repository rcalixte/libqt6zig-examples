const std = @import("std");
const builtin = @import("builtin");
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

pub fn main() void {
    const argc = std.os.argv.len;
    const argv = std.os.argv.ptr;
    _ = qapplication.New(argc, argv);

    const threadcount = std.Thread.getCpuCount() catch 2;

    // This will serve as our parent object. When we deallocate it, all the
    // children will be deallocated as well. Because this is not
    // allocated with memory visible to Zig, we need to be mindful of
    // memory leaks.
    const window = qmainwindow.New2();
    defer qmainwindow.QDelete(window);

    const config = getAllocatorConfig();
    var da: std.heap.DebugAllocator(config) = .init;
    defer _ = da.deinit();
    const allocator = da.allocator();

    qmainwindow.SetFixedSize2(window, 250, 50 * @as(i32, @intCast(threadcount)) + 1);
    qmainwindow.SetWindowTitle(window, "Qt 6 Threading Example");

    const widget = qwidget.New(window);
    const vboxlayout = qvboxlayout.New(widget);
    qmainwindow.SetCentralWidget(window, widget);

    // Create a counter for each thread
    var counters: std.ArrayListUnmanaged(*Counter) = .empty;
    defer {
        // First we stop all counters, then destroy them.
        // We only need to destroy the Counter objects since
        // the QLabel objects are cleaned up by Qt when the
        // parent object is cleaned up.
        for (counters.items) |counter| {
            counter.stop();
            allocator.destroy(counter);
        }
        // Deinitialize the ArrayList
        counters.deinit(allocator);
    }

    for (0..threadcount) |_| {
        const label = qlabel.New(window);
        qlabel.SetAlignment(label, qnamespace_enums.AlignmentFlag.AlignCenter);
        qlabel.SetText(label, "0 0");
        qvboxlayout.AddWidget(vboxlayout, label);

        const counter = allocator.create(Counter) catch @panic("Failed to create Counter");

        counter.* = Counter{
            .label = label,
            .counter = 0,
        };

        counters.append(allocator, counter) catch @panic("Failed to append Counter");
    }

    // Create start button
    const button = qpushbutton.New5("Start!", window);

    var button_data = ButtonData{
        .counters = &counters,
        .button = button,
    };

    // Create a QVariant to store the pointer and use Qt's property system
    // to store it on the button
    const variant = qvariant.New7(@intFromPtr(&button_data));
    defer qvariant.QDelete(variant);
    _ = qpushbutton.SetProperty(button, "buttonData", variant);

    qpushbutton.OnClicked(button, onClicked);
    qvboxlayout.AddWidget(vboxlayout, button);

    qmainwindow.Show(window);

    _ = qapplication.Exec();
}

fn onClicked(self: ?*anyopaque) callconv(.c) void {
    if (qpushbutton.Property(self, "buttonData")) |variant_ptr| {
        const ptr_val = qvariant.ToLongLong(variant_ptr);
        const data_ptr = @as(*ButtonData, @ptrFromInt(@as(usize, @intCast(ptr_val))));

        // Check if any counter is running
        const is_running = for (data_ptr.counters.items) |counter| {
            if (counter.running) break true;
        } else false;

        if (is_running) {
            // Stop all counters
            for (data_ptr.counters.items) |counter| {
                counter.stop();
            }
            qpushbutton.SetText(data_ptr.button, "Start!");
        } else {
            // Start all counters
            for (data_ptr.counters.items) |counter| {
                counter.start();
            }
            qpushbutton.SetText(data_ptr.button, "Stop!");
        }
    }
}

const Counter = struct {
    counter: i32,
    label: C.QLabel,
    running: bool = false,
    thread: ?std.Thread = null,
    mutex: std.Thread.Mutex = .{},
    stop_requested: bool = false,

    fn start(self: *Counter) void {
        self.mutex.lock();
        defer self.mutex.unlock();

        if (!self.running) {
            self.stop_requested = false;
            self.running = true;
            self.thread = std.Thread.spawn(.{}, struct {
                fn run(counter: *Counter) void {
                    counter.run_counter();
                }
            }.run, .{self}) catch @panic("Failed to spawn thread");
        }
    }

    fn stop(self: *Counter) void {
        // First signal the thread to stop
        self.mutex.lock();
        if (self.running) {
            self.stop_requested = true;
            self.running = false;
        }
        self.mutex.unlock();

        // Then wait for it to finish
        if (self.thread) |thread| {
            // Give the thread time to process its last async operation
            thread.join();
            self.thread = null;
        }
    }

    fn async_callback(ctx: ?*anyopaque) callconv(.c) void {
        if (ctx) |ptr| {
            const counter: *Counter = @ptrCast(@alignCast(ptr));
            var text_buf: [64]u8 = undefined;
            const text = std.fmt.bufPrint(&text_buf, "{d} {d}", .{
                counter.counter,
                std.time.timestamp(),
            }) catch @panic("Failed to bufPrint");
            qlabel.SetText(counter.label, text);
        }
    }

    fn run_counter(self: *Counter) void {
        while (true) {
            self.mutex.lock();
            const should_continue = self.running and !self.stop_requested;
            self.mutex.unlock();

            if (!should_continue) break;

            threading.Async(self, async_callback);
            self.counter += 1;
            std.Thread.sleep(1 * std.time.ns_per_ms);
        }
    }
};

fn getAllocatorConfig() std.heap.DebugAllocatorConfig {
    if (builtin.mode == .Debug) {
        return std.heap.DebugAllocatorConfig{
            .safety = true,
            .never_unmap = true,
            .retain_metadata = true,
            .verbose_log = false,
        };
    } else {
        return std.heap.DebugAllocatorConfig{
            .safety = false,
            .never_unmap = false,
            .retain_metadata = false,
            .verbose_log = false,
        };
    }
}
