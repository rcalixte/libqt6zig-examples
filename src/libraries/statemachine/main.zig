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

    pub fn init(alloc: std.mem.Allocator, color: i32) !*LightWidget {
        var self = try alloc.create(LightWidget);

        self.color = color;
        self.on = false;
        self.widget = QWidget.New2();
        self.widget.OnPaintEvent(onPaintEvent);

        const on_variant = QVariant.New7(@intFromPtr(&self.on));
        defer on_variant.Delete();

        const color_variant = QVariant.New4(self.color);
        defer color_variant.Delete();

        _ = self.widget.SetProperty("on", on_variant);
        _ = self.widget.SetProperty("color", color_variant);

        return self;
    }

    pub fn isOn(self: *LightWidget) bool {
        return self.on;
    }

    pub fn setOn(self: *LightWidget, on: bool) void {
        if (on == self.on) return;
        self.on = on;
        self.widget.Update();
    }

    pub fn turnOff(self: *LightWidget) void {
        self.setOn(false);
    }

    pub fn turnOn(self: *LightWidget) void {
        self.setOn(true);
    }

    pub fn deinit(self: *LightWidget, alloc: std.mem.Allocator) void {
        self.widget.DeleteLater();
        alloc.destroy(self);
    }

    fn onPaintEvent(self: QWidget, _: QPaintEvent) callconv(.c) void {
        const on_variant = self.Property("on");
        const onValue = on_variant.ToLongLong();
        const on: *bool = @ptrFromInt(@as(usize, @intCast(onValue)));

        if (!on.*) return;

        const color_variant = self.Property("color");
        const color_value = color_variant.ToInt();

        const painter = QStylePainter.New(self);
        defer painter.Delete();

        const brush = QBrush.New4(color_value);
        defer brush.Delete();

        painter.SetRenderHint(qpainter_enums.RenderHint.Antialiasing);
        painter.SetBrush(brush);

        const height = self.Height();
        const width = self.Width();
        const min = @min(height, width);
        const size = @divFloor(min * 2, 3);
        const x = @divFloor(width - size, 2);
        const y = @divFloor(height - size, 2);
        painter.DrawEllipse3(x, y, size, size);
    }
};

pub const TrafficWidget = struct {
    red: *LightWidget,
    yellow: *LightWidget,
    green: *LightWidget,
    widget: QWidget,

    pub fn init(alloc: std.mem.Allocator) !*TrafficWidget {
        var self = try alloc.create(TrafficWidget);

        self.widget = QWidget.New2();
        const layout = QVBoxLayout.New(self.widget);

        self.red = try LightWidget.init(alloc, qnamespace_enums.GlobalColor.Red);
        self.yellow = try LightWidget.init(alloc, qnamespace_enums.GlobalColor.Yellow);
        self.green = try LightWidget.init(alloc, qnamespace_enums.GlobalColor.Green);

        layout.AddWidget(self.red.widget);
        layout.AddWidget(self.yellow.widget);
        layout.AddWidget(self.green.widget);

        const palette = QPalette.New();
        defer palette.Delete();

        const color = QColor.New4(qnamespace_enums.GlobalColor.Black);
        defer color.Delete();

        palette.SetColor2(qpalette_enums.ColorRole.Window, color);
        self.widget.SetPalette(palette);
        self.widget.SetAutoFillBackground(true);

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

    pub fn deinit(self: *TrafficWidget, alloc: std.mem.Allocator) void {
        self.red.deinit(alloc);
        self.yellow.deinit(alloc);
        self.green.deinit(alloc);
        self.widget.DeleteLater();
        alloc.destroy(self);
    }
};

pub fn main(init: std.process.Init) !void {
    const argv = try qt6.init(init.gpa, init.minimal.args);
    defer qt6.deinit(init.gpa, argv);
    var argc: i32 = @intCast(argv.len);
    const qapp = QApplication.New(init.arena.allocator(), &argc, argv);
    defer qapp.Delete();

    const traffic_light = QWidget.New2();
    defer traffic_light.Delete();

    traffic_light.SetWindowTitle("Qt 6 State Machine Example");
    traffic_light.Resize(380, 800);
    traffic_light.SetMinimumHeight(450);
    traffic_light.SetMinimumWidth(200);

    const layout = QVBoxLayout.New(traffic_light);
    const traffic_widget = try TrafficWidget.init(init.gpa);
    defer traffic_widget.deinit(init.gpa);

    layout.AddWidget(traffic_widget.widget);
    layout.SetContentsMargins(0, 0, 0, 0);

    const red_going_green = createLightState(traffic_widget.redLight(), 3000);
    const green_going_yellow = createLightState(traffic_widget.greenLight(), 3000);
    const yellow_going_red = createLightState(traffic_widget.yellowLight(), 1000);

    _ = red_going_green.AddTransition2(red_going_green, "finished()", green_going_yellow);
    _ = green_going_yellow.AddTransition2(green_going_yellow, "finished()", yellow_going_red);
    _ = yellow_going_red.AddTransition2(yellow_going_red, "finished()", red_going_green);

    const machine = QStateMachine.New3(traffic_light);
    machine.AddState(red_going_green);
    machine.AddState(green_going_yellow);
    machine.AddState(yellow_going_red);
    machine.SetInitialState(red_going_green);
    machine.Start();

    traffic_light.Show();

    _ = QApplication.Exec();
}

pub fn createLightState(light: *LightWidget, duration: i32) QState {
    const light_state = QState.New();
    const timing = QState.New3(light_state);

    const timer = QTimer.New2(light_state);
    timer.SetInterval(duration);
    timer.SetSingleShot(true);

    const light_variant = QVariant.New7(@intFromPtr(light));
    defer light_variant.Delete();

    const timer_variant = QVariant.New7(@intFromPtr(timer.ptr));
    defer timer_variant.Delete();

    _ = timing.SetProperty("light", light_variant);
    _ = timing.SetProperty("timer", timer_variant);
    timing.OnEntered(onEntered);
    timing.OnExited(onExited);

    const done = QFinalState.New2(light_state);
    _ = timing.AddTransition2(timer, "timeout()", done);

    light_state.SetInitialState(timing);

    return light_state;
}

fn onEntered(self: QState) callconv(.c) void {
    const light_variant = self.Property("light");
    const light_value = light_variant.ToULongLong();
    const light: *LightWidget = @ptrFromInt(@as(usize, @intCast(light_value)));

    const timer_variant = self.Property("timer");
    const timer_value = timer_variant.ToULongLong();
    const timer: QTimer = .{ .ptr = @ptrFromInt(@as(usize, @intCast(timer_value))) };

    light.turnOn();
    timer.Start2();
}

fn onExited(self: QState) callconv(.c) void {
    const light_variant = self.Property("light");
    const light_value = light_variant.ToULongLong();
    const light: *LightWidget = @ptrFromInt(@as(usize, @intCast(light_value)));

    light.turnOff();
}
