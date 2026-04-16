const std = @import("std");
const qt6 = @import("libqt6zig");
const QApplication = qt6.QApplication;
const QWidget = qt6.QWidget;
const QBluetoothLocalDevice = qt6.QBluetoothLocalDevice;
const QVBoxLayout = qt6.QVBoxLayout;
const QCheckBox = qt6.QCheckBox;
const QPushButton = qt6.QPushButton;
const QListWidget = qt6.QListWidget;
const QLabel = qt6.QLabel;
const QBluetoothDeviceDiscoveryAgent = qt6.QBluetoothDeviceDiscoveryAgent;
const qnamespace_enums = qt6.qnamespace_enums;
const qbluetoothdevicediscoveryagent_enums = qt6.qbluetoothdevicediscoveryagent_enums;
const QBluetoothDeviceInfo = qt6.QBluetoothDeviceInfo;

var allocator: std.mem.Allocator = undefined;

var buffer: [256]u8 = undefined;

var toggle: QCheckBox = undefined;
var button: QPushButton = undefined;
var list: QListWidget = undefined;
var status: QLabel = undefined;
var agent: QBluetoothDeviceDiscoveryAgent = undefined;

pub fn main(init: std.process.Init) !void {
    const argv = try qt6.init(init.gpa, init.minimal.args);
    defer qt6.deinit(init.gpa, argv);
    var argc: i32 = @intCast(argv.len);
    const qapp = QApplication.New(init.arena.allocator(), &argc, argv);
    defer qapp.Delete();

    allocator = init.gpa;

    const widget = QWidget.New2();
    defer widget.Delete();

    widget.SetWindowTitle("Qt 6 Bluetooth Example");
    widget.SetMinimumSize2(400, 400);

    const local_device = QBluetoothLocalDevice.New();
    defer local_device.Delete();

    const layout = QVBoxLayout.New(widget);

    if (local_device.IsValid()) {
        toggle = QCheckBox.New3("Bluetooth enabled");
        toggle.SetChecked(true);

        button = QPushButton.New3("Scan for devices");
        list = QListWidget.New2();
        status = QLabel.New3("Ready.");

        layout.AddWidget(toggle);
        layout.AddWidget(button);
        layout.AddWidget(list);
        layout.AddWidget(status);

        agent = QBluetoothDeviceDiscoveryAgent.New3(widget);
        agent.SetLowEnergyDiscoveryTimeout(3000);

        toggle.OnToggled(onToggled);
        button.OnClicked(onClicked);
        agent.OnDeviceDiscovered(onDeviceDiscovered);
        agent.OnFinished(onFinished);
        agent.OnErrorOccurred(onErrorOccurred);
    } else {
        const label = QLabel.New3(
            \\## No Bluetooth adapter detected.
            \\### Please ensure that your device has a Bluetooth adapter.
        );
        label.SetTextFormat(qnamespace_enums.TextFormat.MarkdownText);
        label.SetAlignment(qnamespace_enums.AlignmentFlag.AlignCenter);
        label.SetWordWrap(true);
        layout.AddWidget(label);
    }

    widget.Show();

    _ = QApplication.Exec();
}

fn onToggled(_: QCheckBox, checked: bool) callconv(.c) void {
    button.SetEnabled(checked);
    list.SetEnabled(checked);

    if (!checked and agent.IsActive())
        agent.Stop();

    const text = switch (checked) {
        true => "Bluetooth enabled.",
        false => "Bluetooth disabled.",
    };
    status.SetText(text);
}

fn onClicked(self: QPushButton) callconv(.c) void {
    if (agent.IsActive())
        return;

    list.Clear();
    status.SetText("Scanning...");
    self.SetEnabled(false);
    agent.Start2(
        qbluetoothdevicediscoveryagent_enums.DiscoveryMethod.ClassicMethod | qbluetoothdevicediscoveryagent_enums.DiscoveryMethod.LowEnergyMethod,
    );
}

fn onDeviceDiscovered(_: QBluetoothDeviceDiscoveryAgent, info: QBluetoothDeviceInfo) callconv(.c) void {
    const name = info.Name(allocator);
    defer allocator.free(name);

    const address = info.Address();

    const address_str = address.ToString(allocator);
    defer allocator.free(address_str);

    const title = switch (name.len) {
        0 => "Unknown",
        else => std.fmt.bufPrint(&buffer, "{s} ({s})", .{ name, address_str }) catch @panic("Failed to bufPrint"),
    };

    list.AddItem(title);
}

fn onFinished(_: QBluetoothDeviceDiscoveryAgent) callconv(.c) void {
    button.SetEnabled(toggle.IsChecked());

    const text = "Scan complete - {d} device(s) found.";
    const formatted = std.fmt.bufPrint(&buffer, text, .{list.Count()}) catch @panic("Failed to bufPrint");
    status.SetText(formatted);
}

fn onErrorOccurred(self: QBluetoothDeviceDiscoveryAgent, _: i32) callconv(.c) void {
    button.SetEnabled(toggle.IsChecked());

    const error_text = self.ErrorString(allocator);
    defer allocator.free(error_text);

    status.SetText(error_text);
}
