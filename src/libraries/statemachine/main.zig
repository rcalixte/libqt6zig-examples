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
    color: i32 = 0,
    on: bool = false,
    widget: QWidget = undefined,

    pub fn init(self: *LightWidget, color: i32) void {
        self.color = color;
        self.widget = .new2();
        self.widget.onPaintEvent(onPaintEvent);

        const on_variant = QVariant.new7(@intFromPtr(&self.on));
        defer on_variant.delete();

        const color_variant = QVariant.new4(self.color);
        defer color_variant.delete();

        _ = self.widget.setProperty("on", on_variant);
        _ = self.widget.setProperty("color", color_variant);
    }

    pub fn setOn(self: *LightWidget, on: bool) void {
        if (on == self.on) return;
        self.on = on;
        self.widget.update();
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
    red: LightWidget = .{},
    yellow: LightWidget = .{},
    green: LightWidget = .{},
    widget: QWidget = undefined,

    pub fn init(self: *TrafficWidget) void {
        self.widget = .new2();
        const layout = QVBoxLayout.new(self.widget);

        self.red.init(qnamespace_enums.GlobalColor.Red);
        self.yellow.init(qnamespace_enums.GlobalColor.Yellow);
        self.green.init(qnamespace_enums.GlobalColor.Green);

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
    }

    pub fn deinit(self: *const TrafficWidget) void {
        self.red.widget.delete();
        self.yellow.widget.delete();
        self.green.widget.delete();
        self.widget.delete();
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
    var traffic_widget: TrafficWidget = undefined;
    traffic_widget.init();
    defer traffic_widget.deinit();

    layout.addWidget(traffic_widget.widget);
    layout.setContentsMargins(0, 0, 0, 0);

    const red_going_green = createLightState(&traffic_widget.red, 3000);
    defer red_going_green.delete();

    const green_going_yellow = createLightState(&traffic_widget.green, 3000);
    defer green_going_yellow.delete();

    const yellow_going_red = createLightState(&traffic_widget.yellow, 1000);
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

pub fn createLightState(light: *const LightWidget, duration: i32) QState {
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

    light.setOn(true);
    timer.start2();
}

fn onExited(self: QState) callconv(.c) void {
    const light_variant = self.property("light");
    defer light_variant.delete();

    const light_value = light_variant.toULongLong();
    const light: *LightWidget = @ptrFromInt(@as(usize, @intCast(light_value)));

    light.setOn(false);
}
