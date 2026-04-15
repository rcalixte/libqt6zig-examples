const std = @import("std");
const qt6 = @import("libqt6zig");
const C = qt6.C;
const qapplication = qt6.qapplication;
const qwidget = qt6.qwidget;
const qvariant = qt6.qvariant;
const qstylepainter = qt6.qstylepainter;
const qbrush = qt6.qbrush;
const qnamespace_enums = qt6.qnamespace_enums;
const qpainter_enums = qt6.qpainter_enums;
const qvboxlayout = qt6.qvboxlayout;
const qpalette = qt6.qpalette;
const qcolor = qt6.qcolor;
const qpalette_enums = qt6.qpalette_enums;
const qstate = qt6.qstate;
const qtimer = qt6.qtimer;
const qobject = qt6.qobject;
const qfinalstate = qt6.qfinalstate;
const qstatemachine = qt6.qstatemachine;

pub const LightWidget = struct {
    color: i32,
    on: bool,
    widget: C.QWidget,

    pub fn init(alloc: std.mem.Allocator, color: i32) !*LightWidget {
        var self = try alloc.create(LightWidget);

        self.color = color;
        self.on = false;
        self.widget = qwidget.New2();
        qwidget.OnPaintEvent(self.widget, onPaintEvent);

        const on_variant = qvariant.New7(@intFromPtr(&self.on));
        defer qvariant.Delete(on_variant);

        const color_variant = qvariant.New4(self.color);
        defer qvariant.Delete(color_variant);

        _ = qwidget.SetProperty(self.widget, "on", on_variant);
        _ = qwidget.SetProperty(self.widget, "color", color_variant);

        return self;
    }

    pub fn isOn(self: *LightWidget) bool {
        return self.on;
    }

    pub fn setOn(self: *LightWidget, on: bool) void {
        if (on == self.on) return;
        self.on = on;
        qwidget.Update(self.widget);
    }

    pub fn turnOff(self: *LightWidget) void {
        self.setOn(false);
    }

    pub fn turnOn(self: *LightWidget) void {
        self.setOn(true);
    }

    pub fn deinit(self: *LightWidget, alloc: std.mem.Allocator) void {
        qwidget.DeleteLater(self.widget);
        alloc.destroy(self);
    }

    fn onPaintEvent(self: ?*anyopaque, _: ?*anyopaque) callconv(.c) void {
        const on_variant = qwidget.Property(self, "on");
        const onValue = qvariant.ToLongLong(on_variant);
        const on = @as(*bool, @ptrFromInt(@as(usize, @intCast(onValue))));

        if (!on.*) return;

        const color_variant = qwidget.Property(self, "color");
        const color_value = qvariant.ToInt(color_variant);

        const painter = qstylepainter.New(self);
        defer qstylepainter.Delete(painter);

        const brush = qbrush.New4(color_value);
        defer qbrush.Delete(brush);

        qstylepainter.SetRenderHint(painter, qpainter_enums.RenderHint.Antialiasing);
        qstylepainter.SetBrush(painter, brush);

        const height = qwidget.Height(self);
        const width = qwidget.Width(self);
        const min = @min(height, width);
        const size = @divFloor(min * 2, 3);
        const x = @divFloor(width - size, 2);
        const y = @divFloor(height - size, 2);
        qstylepainter.DrawEllipse3(painter, x, y, size, size);
    }
};

pub const TrafficWidget = struct {
    red: *LightWidget,
    yellow: *LightWidget,
    green: *LightWidget,
    widget: C.QWidget,

    pub fn init(alloc: std.mem.Allocator) !*TrafficWidget {
        var self = try alloc.create(TrafficWidget);

        self.widget = qwidget.New2();
        const layout = qvboxlayout.New(self.widget);

        self.red = try LightWidget.init(alloc, qnamespace_enums.GlobalColor.Red);
        self.yellow = try LightWidget.init(alloc, qnamespace_enums.GlobalColor.Yellow);
        self.green = try LightWidget.init(alloc, qnamespace_enums.GlobalColor.Green);

        qvboxlayout.AddWidget(layout, self.red.widget);
        qvboxlayout.AddWidget(layout, self.yellow.widget);
        qvboxlayout.AddWidget(layout, self.green.widget);

        const palette = qpalette.New();
        defer qpalette.Delete(palette);

        const color = qcolor.New4(qnamespace_enums.GlobalColor.Black);
        defer qcolor.Delete(color);

        qpalette.SetColor2(palette, qpalette_enums.ColorRole.Window, color);
        qwidget.SetPalette(self.widget, palette);
        qwidget.SetAutoFillBackground(self.widget, true);

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
        qwidget.DeleteLater(self.widget);
        alloc.destroy(self);
    }
};

pub fn main(init: std.process.Init) !void {
    const argv = try qt6.init(init.gpa, init.minimal.args);
    defer qt6.deinit(init.gpa, argv);
    var argc: i32 = @intCast(argv.len);
    const qapp = qapplication.New(&argc, argv, init.arena.allocator());
    defer qapplication.Delete(qapp);

    const traffic_light = qwidget.New2();
    defer qwidget.Delete(traffic_light);

    qwidget.SetWindowTitle(traffic_light, "Qt 6 State Machine Example");
    qwidget.Resize(traffic_light, 380, 800);
    qwidget.SetMinimumHeight(traffic_light, 450);
    qwidget.SetMinimumWidth(traffic_light, 200);

    const layout = qvboxlayout.New(traffic_light);
    const traffic_widget = try TrafficWidget.init(init.gpa);
    defer traffic_widget.deinit(init.gpa);

    qvboxlayout.AddWidget(layout, traffic_widget.widget);
    qvboxlayout.SetContentsMargins(layout, 0, 0, 0, 0);

    const red_going_green = createLightState(traffic_widget.redLight(), 3000);
    const green_going_yellow = createLightState(traffic_widget.greenLight(), 3000);
    const yellow_going_red = createLightState(traffic_widget.yellowLight(), 1000);

    _ = qstate.AddTransition2(red_going_green, red_going_green, "finished()", green_going_yellow);
    _ = qstate.AddTransition2(green_going_yellow, green_going_yellow, "finished()", yellow_going_red);
    _ = qstate.AddTransition2(yellow_going_red, yellow_going_red, "finished()", red_going_green);

    const machine = qstatemachine.New3(traffic_light);
    qstatemachine.AddState(machine, red_going_green);
    qstatemachine.AddState(machine, green_going_yellow);
    qstatemachine.AddState(machine, yellow_going_red);
    qstatemachine.SetInitialState(machine, red_going_green);
    qstatemachine.Start(machine);

    qwidget.Show(traffic_light);

    _ = qapplication.Exec();
}

pub fn createLightState(light: *LightWidget, duration: i32) C.QState {
    const light_state = qstate.New();
    const timing = qstate.New3(light_state);

    const timer = qtimer.New2(light_state);
    qtimer.SetInterval(timer, duration);
    qtimer.SetSingleShot(timer, true);

    const light_variant = qvariant.New7(@intFromPtr(light));
    defer qvariant.Delete(light_variant);

    const timer_variant = qvariant.New7(@intFromPtr(timer));
    defer qvariant.Delete(timer_variant);

    _ = qstate.SetProperty(timing, "light", light_variant);
    _ = qstate.SetProperty(timing, "timer", timer_variant);
    qstate.OnEntered(timing, onEntered);
    qstate.OnExited(timing, onExited);

    const done = qfinalstate.New2(light_state);
    _ = qstate.AddTransition2(timing, timer, "timeout()", done);

    qstate.SetInitialState(light_state, timing);

    return light_state;
}

fn onEntered(self: ?*anyopaque) callconv(.c) void {
    const light_variant = qstate.Property(self, "light");
    const light_value = qvariant.ToULongLong(light_variant);
    const light = @as(*LightWidget, @ptrFromInt(@as(usize, @intCast(light_value))));

    const timer_variant = qstate.Property(self, "timer");
    const timer_value = qvariant.ToULongLong(timer_variant);
    const timer = @as(C.QTimer, @ptrFromInt(@as(usize, @intCast(timer_value))));

    light.turnOn();
    qtimer.Start2(timer);
}

fn onExited(self: ?*anyopaque) callconv(.c) void {
    const light_variant = qstate.Property(self, "light");
    const light_value = qvariant.ToULongLong(light_variant);
    const light = @as(*LightWidget, @ptrFromInt(@as(usize, @intCast(light_value))));

    light.turnOff();
}
