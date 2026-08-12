const std = @import("std");
const qt6 = @import("libqt6zig");
const QApplication = qt6.QApplication;
const QWidget = qt6.QWidget;
const QVariant = qt6.QVariant;
const QPaintEvent = qt6.QPaintEvent;
const QStylePainter = qt6.QStylePainter;
const QBrush = qt6.QBrush;
const qnamespace_enums = qt6.qnamespace_enums;
const qpainter_enums = qt6.qpainter_enums;
const QVBoxLayout = qt6.QVBoxLayout;
const QPalette = qt6.QPalette;
const QColor = qt6.QColor;
const qpalette_enums = qt6.qpalette_enums;
const QState = qt6.QState;
const QTimer = qt6.QTimer;
const QFinalState = qt6.QFinalState;
const QStateMachine = qt6.QStateMachine;

pub const LightWidget = struct {
    color: i32,
    on: bool,
    widget: QWidget,

    pub fn create(alloc: std.mem.Allocator, color: i32) !*LightWidget {
        var self = try alloc.create(LightWidget);

        self.color = color;
        self.on = false;
        self.widget = .new2();
        self.widget.onPaintEvent(onPaintEvent);

        const on_variant = QVariant.new7(@intFromPtr(&self.on));
        defer on_variant.delete();

        const color_variant = QVariant.new4(self.color);
        defer color_variant.delete();

        _ = self.widget.setProperty("on", on_variant);
        _ = self.widget.setProperty("color", color_variant);

        return self;
    }

    pub fn isOn(self: *LightWidget) bool {
        return self.on;
    }

    pub fn setOn(self: *LightWidget, on: bool) void {
        if (on == self.on) return;
        self.on = on;
        self.widget.update();
    }

    pub fn turnOff(self: *LightWidget) void {
        self.setOn(false);
    }

    pub fn turnOn(self: *LightWidget) void {
        self.setOn(true);
    }

    pub fn destroy(self: *LightWidget, alloc: std.mem.Allocator) void {
        self.widget.delete();
        alloc.destroy(self);
    }

    fn onPaintEvent(self: QWidget, _: QPaintEvent) callconv(.c) void {
        const on_variant = self.property("on");
        defer on_variant.delete();

        const onValue = on_variant.toLongLong();
        const on: *bool = @ptrFromInt(@as(usize, @intCast(onValue)));

        if (!on.*) return;

        const color_variant = self.property("color");
        defer color_variant.delete();

        const color_value = color_variant.toInt();

        const painter = QStylePainter.new(self);
        defer painter.delete();

        const brush = QBrush.new4(color_value);
        defer brush.delete();

        painter.setRenderHint(qpainter_enums.RenderHint.Antialiasing);
        painter.setBrush(brush);

        const height = self.height();
        const width = self.width();
        const min = @min(height, width);
        const size = @divFloor(min * 2, 3);
        const x = @divFloor(width - size, 2);
        const y = @divFloor(height - size, 2);
        painter.drawEllipse3(x, y, size, size);
    }
};

pub const TrafficWidget = struct {
    red: *LightWidget,
    yellow: *LightWidget,
    green: *LightWidget,
    widget: QWidget,

    pub fn create(alloc: std.mem.Allocator) !*TrafficWidget {
        var self = try alloc.create(TrafficWidget);
        errdefer alloc.destroy(self);

        self.widget = .new2();
        const layout = QVBoxLayout.new(self.widget);

        self.red = try .create(alloc, qnamespace_enums.GlobalColor.Red);
        errdefer self.red.destroy(alloc);

        self.yellow = try .create(alloc, qnamespace_enums.GlobalColor.Yellow);
        errdefer self.yellow.destroy(alloc);

        self.green = try .create(alloc, qnamespace_enums.GlobalColor.Green);

        layout.addWidget(self.red.widget);
        layout.addWidget(self.yellow.widget);
        layout.addWidget(self.green.widget);

        const palette = QPalette.new();
        defer palette.delete();

        const color = QColor.new4(qnamespace_enums.GlobalColor.Black);
        defer color.delete();

        palette.setColor2(qpalette_enums.ColorRole.Window, color);
        self.widget.setPalette(palette);
        self.widget.setAutoFillBackground(true);

        return self;
    }

    pub fn redLight(self: *TrafficWidget) *LightWidget {
        return self.red;
    }

    pub fn yellowLight(self: *TrafficWidget) *LightWidget {
        return self.yellow;
    }

    pub fn greenLight(self: *TrafficWidget) *LightWidget {
        return self.green;
    }

    pub fn destroy(self: *TrafficWidget, alloc: std.mem.Allocator) void {
        self.red.destroy(alloc);
        self.yellow.destroy(alloc);
        self.green.destroy(alloc);
        self.widget.delete();
        alloc.destroy(self);
    }
};

pub fn main(init: std.process.Init) !void {
    const argv = try qt6.init(init.gpa, init.minimal.args);
    defer qt6.deinit(init.gpa, argv);
    var argc: i32 = @intCast(argv.len);
    const qapp: QApplication = .new(init.arena.allocator(), &argc, argv);
    defer qapp.delete();

    const traffic_light = QWidget.new2();
    defer traffic_light.delete();

    traffic_light.setWindowTitle("Qt 6 State Machine Example");
    traffic_light.resize(380, 800);
    traffic_light.setMinimumHeight(450);
    traffic_light.setMinimumWidth(200);

    const layout = QVBoxLayout.new(traffic_light);
    const traffic_widget = try TrafficWidget.create(init.gpa);
    defer traffic_widget.destroy(init.gpa);

    layout.addWidget(traffic_widget.widget);
    layout.setContentsMargins(0, 0, 0, 0);

    const red_going_green = createLightState(traffic_widget.redLight(), 3000);
    defer red_going_green.delete();

    const green_going_yellow = createLightState(traffic_widget.greenLight(), 3000);
    defer green_going_yellow.delete();

    const yellow_going_red = createLightState(traffic_widget.yellowLight(), 1000);
    defer yellow_going_red.delete();

    _ = red_going_green.addTransition2(red_going_green, "finished()", green_going_yellow);
    _ = green_going_yellow.addTransition2(green_going_yellow, "finished()", yellow_going_red);
    _ = yellow_going_red.addTransition2(yellow_going_red, "finished()", red_going_green);

    const machine = QStateMachine.new3(traffic_light);
    machine.addState(red_going_green);
    machine.addState(green_going_yellow);
    machine.addState(yellow_going_red);
    machine.setInitialState(red_going_green);
    machine.start();

    traffic_light.show();

    _ = QApplication.exec();
}

pub fn createLightState(light: *LightWidget, duration: i32) QState {
    const light_state = QState.new();
    const timing = QState.new3(light_state);

    const timer = QTimer.new2(light_state);
    timer.setInterval(duration);
    timer.setSingleShot(true);

    const light_variant = QVariant.new7(@intFromPtr(light));
    defer light_variant.delete();

    const timer_variant = QVariant.new7(@intFromPtr(timer.ptr));
    defer timer_variant.delete();

    _ = timing.setProperty("light", light_variant);
    _ = timing.setProperty("timer", timer_variant);
    timing.onEntered(onEntered);
    timing.onExited(onExited);

    const done = QFinalState.new2(light_state);
    _ = timing.addTransition2(timer, "timeout()", done);

    light_state.setInitialState(timing);

    return light_state;
}

fn onEntered(self: QState) callconv(.c) void {
    const light_variant = self.property("light");
    defer light_variant.delete();

    const light_value = light_variant.toULongLong();
    const light: *LightWidget = @ptrFromInt(@as(usize, @intCast(light_value)));

    const timer_variant = self.property("timer");
    defer timer_variant.delete();

    const timer_value = timer_variant.toULongLong();
    const timer: QTimer = .{ .ptr = @ptrFromInt(@as(usize, @intCast(timer_value))) };

    light.turnOn();
    timer.start2();
}

fn onExited(self: QState) callconv(.c) void {
    const light_variant = self.property("light");
    defer light_variant.delete();

    const light_value = light_variant.toULongLong();
    const light: *LightWidget = @ptrFromInt(@as(usize, @intCast(light_value)));

    light.turnOff();
}
