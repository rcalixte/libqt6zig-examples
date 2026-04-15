const std = @import("std");
const qt6 = @import("libqt6zig");
const C = qt6.C;
const qapplication = qt6.qapplication;
const qwidget = qt6.qwidget;
const qbluetoothlocaldevice = qt6.qbluetoothlocaldevice;
const qvboxlayout = qt6.qvboxlayout;
const qcheckbox = qt6.qcheckbox;
const qpushbutton = qt6.qpushbutton;
const qlistwidget = qt6.qlistwidget;
const qlabel = qt6.qlabel;
const qbluetoothdevicediscoveryagent = qt6.qbluetoothdevicediscoveryagent;
const qnamespace_enums = qt6.qnamespace_enums;
const qbluetoothdevicediscoveryagent_enums = qt6.qbluetoothdevicediscoveryagent_enums;
const qbluetoothdeviceinfo = qt6.qbluetoothdeviceinfo;
const qbluetoothaddress = qt6.qbluetoothaddress;

var allocator: std.mem.Allocator = undefined;

var buffer: [256]u8 = undefined;

var toggle: C.QCheckBox = null;
var button: C.QPushButton = null;
var list: C.QListWidget = null;
var status: C.QLabel = null;
var agent: C.QBluetoothDeviceDiscoveryAgent = null;

pub fn main(init: std.process.Init) !void {
    const argv = try qt6.init(init.gpa, init.minimal.args);
    defer qt6.deinit(init.gpa, argv);
    var argc: i32 = @intCast(argv.len);
    const qapp = qapplication.New(&argc, argv, init.arena.allocator());
    defer qapplication.Delete(qapp);

    allocator = init.gpa;

    const widget = qwidget.New2();
    defer qwidget.Delete(widget);

    qwidget.SetWindowTitle(widget, "Qt 6 Bluetooth Example");
    qwidget.SetMinimumSize2(widget, 400, 400);

    const local_device = qbluetoothlocaldevice.New();
    defer qbluetoothlocaldevice.Delete(local_device);

    const layout = qvboxlayout.New(widget);

    if (qbluetoothlocaldevice.IsValid(local_device)) {
        toggle = qcheckbox.New3("Bluetooth enabled");
        qcheckbox.SetChecked(toggle, true);

        button = qpushbutton.New3("Scan for devices");
        list = qlistwidget.New2();
        status = qlabel.New3("Ready.");

        qvboxlayout.AddWidget(layout, toggle);
        qvboxlayout.AddWidget(layout, button);
        qvboxlayout.AddWidget(layout, list);
        qvboxlayout.AddWidget(layout, status);

        agent = qbluetoothdevicediscoveryagent.New3(widget);
        qbluetoothdevicediscoveryagent.SetLowEnergyDiscoveryTimeout(agent, 3000);

        qcheckbox.OnToggled(toggle, onToggled);
        qpushbutton.OnClicked(button, onClicked);
        qbluetoothdevicediscoveryagent.OnDeviceDiscovered(agent, onDeviceDiscovered);
        qbluetoothdevicediscoveryagent.OnFinished(agent, onFinished);
        qbluetoothdevicediscoveryagent.OnErrorOccurred(agent, onErrorOccurred);
    } else {
        const label = qlabel.New3(
            \\## No Bluetooth adapter detected.
            \\### Please ensure that your device has a Bluetooth adapter.
        );
        qlabel.SetTextFormat(label, qnamespace_enums.TextFormat.MarkdownText);
        qlabel.SetAlignment(label, qnamespace_enums.AlignmentFlag.AlignCenter);
        qlabel.SetWordWrap(label, true);
        qvboxlayout.AddWidget(layout, label);
    }

    qwidget.Show(widget);

    _ = qapplication.Exec();
}

fn onToggled(_: ?*anyopaque, checked: bool) callconv(.c) void {
    qpushbutton.SetEnabled(button, checked);
    qlistwidget.SetEnabled(list, checked);

    if (!checked and qbluetoothdevicediscoveryagent.IsActive(agent))
        qbluetoothdevicediscoveryagent.Stop(agent);

    const text = switch (checked) {
        true => "Bluetooth enabled.",
        false => "Bluetooth disabled.",
    };
    qlabel.SetText(status, text);
}

fn onClicked(self: ?*anyopaque) callconv(.c) void {
    if (qbluetoothdevicediscoveryagent.IsActive(agent))
        return;

    qlistwidget.Clear(list);
    qlabel.SetText(status, "Scanning...");
    qpushbutton.SetEnabled(self, false);
    qbluetoothdevicediscoveryagent.Start2(
        agent,
        qbluetoothdevicediscoveryagent_enums.DiscoveryMethod.ClassicMethod | qbluetoothdevicediscoveryagent_enums.DiscoveryMethod.LowEnergyMethod,
    );
}

fn onDeviceDiscovered(_: ?*anyopaque, info: ?*anyopaque) callconv(.c) void {
    const name = qbluetoothdeviceinfo.Name(info, allocator);
    defer allocator.free(name);

    const address = qbluetoothdeviceinfo.Address(info);

    const address_str = qbluetoothaddress.ToString(address, allocator);
    defer allocator.free(address_str);

    const title = switch (name.len) {
        0 => "Unknown",
        else => std.fmt.bufPrint(&buffer, "{s} ({s})", .{ name, address_str }) catch @panic("Failed to bufPrint"),
    };

    qlistwidget.AddItem(list, title);
}

fn onFinished(_: ?*anyopaque) callconv(.c) void {
    qpushbutton.SetEnabled(button, qcheckbox.IsChecked(toggle));

    const text = "Scan complete - {d} device(s) found.";
    const formatted = std.fmt.bufPrint(&buffer, text, .{qlistwidget.Count(list)}) catch @panic("Failed to bufPrint");
    qlabel.SetText(status, formatted);
}

fn onErrorOccurred(self: ?*anyopaque, _: i32) callconv(.c) void {
    qpushbutton.SetEnabled(button, qcheckbox.IsChecked(toggle));

    const error_text = qbluetoothdevicediscoveryagent.ErrorString(self, allocator);
    defer allocator.free(error_text);

    qlabel.SetText(status, error_text);
}
