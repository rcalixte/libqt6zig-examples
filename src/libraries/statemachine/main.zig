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

var gpa = @import("alloc_config").gpa;
const allocator = gpa.allocator();

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

        const onVariant = qvariant.New7(@intFromPtr(&self.on));
        defer qvariant.QDelete(onVariant);

        const colorVariant = qvariant.New4(self.color);
        defer qvariant.QDelete(colorVariant);

        _ = qwidget.SetProperty(self.widget, "on", onVariant);
        _ = qwidget.SetProperty(self.widget, "color", colorVariant);

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
        const onVariant = qwidget.Property(self, "on");
        const onValue = qvariant.ToLongLong(onVariant);
        const on = @as(*bool, @ptrFromInt(@as(usize, @intCast(onValue))));

        if (!on.*) return;

        const colorVariant = qwidget.Property(self, "color");
        const colorValue = qvariant.ToInt(colorVariant);

        const painter = qstylepainter.New(self);
        defer qstylepainter.QDelete(painter);

        const brush = qbrush.New4(colorValue);
        defer qbrush.QDelete(brush);

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
        defer qpalette.QDelete(palette);

        const color = qcolor.New4(qnamespace_enums.GlobalColor.Black);
        defer qcolor.QDelete(color);

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

pub fn main() !void {
    const argc = std.os.argv.len;
    const argv = std.os.argv.ptr;
    const qapp = qapplication.New(argc, argv);
    defer qapplication.QDelete(qapp);

    defer _ = gpa.deinit();

    const trafficLight = qwidget.New2();
    defer qwidget.QDelete(trafficLight);

    qwidget.SetWindowTitle(trafficLight, "Qt 6 State Machine Example");
    qwidget.Resize(trafficLight, 380, 800);
    qwidget.SetMinimumHeight(trafficLight, 450);
    qwidget.SetMinimumWidth(trafficLight, 200);

    const layout = qvboxlayout.New(trafficLight);
    const trafficWidget = try TrafficWidget.init(allocator);
    defer trafficWidget.deinit(allocator);

    qvboxlayout.AddWidget(layout, trafficWidget.widget);
    qvboxlayout.SetContentsMargins(layout, 0, 0, 0, 0);

    const redGoingGreen = createLightState(trafficWidget.redLight(), 3000);
    const greenGoingYellow = createLightState(trafficWidget.greenLight(), 3000);
    const yellowGoingRed = createLightState(trafficWidget.yellowLight(), 1000);

    _ = qstate.AddTransition2(redGoingGreen, redGoingGreen, "finished()", greenGoingYellow);
    _ = qstate.AddTransition2(greenGoingYellow, greenGoingYellow, "finished()", yellowGoingRed);
    _ = qstate.AddTransition2(yellowGoingRed, yellowGoingRed, "finished()", redGoingGreen);

    const machine = qstatemachine.New3(trafficLight);
    qstatemachine.AddState(machine, redGoingGreen);
    qstatemachine.AddState(machine, greenGoingYellow);
    qstatemachine.AddState(machine, yellowGoingRed);
    qstatemachine.SetInitialState(machine, redGoingGreen);
    qstatemachine.Start(machine);

    qwidget.Show(trafficLight);

    _ = qapplication.Exec();
}

pub fn createLightState(light: *LightWidget, duration: i32) C.QState {
    const lightState = qstate.New();
    const timing = qstate.New3(lightState);

    const timer = qtimer.New2(lightState);
    qtimer.SetInterval(timer, duration);
    qtimer.SetSingleShot(timer, true);

    const lightVariant = qvariant.New7(@intFromPtr(light));
    defer qvariant.QDelete(lightVariant);

    const timerVariant = qvariant.New7(@intFromPtr(timer));
    defer qvariant.QDelete(timerVariant);

    _ = qstate.SetProperty(timing, "light", lightVariant);
    _ = qstate.SetProperty(timing, "timer", timerVariant);
    qstate.OnEntered(timing, onEntered);
    qstate.OnExited(timing, onExited);

    const done = qfinalstate.New2(lightState);
    _ = qstate.AddTransition2(timing, timer, "timeout()", done);

    qstate.SetInitialState(lightState, timing);

    return lightState;
}

fn onEntered(self: ?*anyopaque) callconv(.c) void {
    const lightVariant = qstate.Property(self, "light");
    const lightValue = qvariant.ToULongLong(lightVariant);
    const light = @as(*LightWidget, @ptrFromInt(@as(usize, @intCast(lightValue))));

    const timerVariant = qstate.Property(self, "timer");
    const timerValue = qvariant.ToULongLong(timerVariant);
    const timer = @as(C.QTimer, @ptrFromInt(@as(usize, @intCast(timerValue))));

    light.turnOn();
    qtimer.Start2(timer);
}

fn onExited(self: ?*anyopaque) callconv(.c) void {
    const lightVariant = qstate.Property(self, "light");
    const lightValue = qvariant.ToULongLong(lightVariant);
    const light = @as(*LightWidget, @ptrFromInt(@as(usize, @intCast(lightValue))));

    light.turnOff();
}
