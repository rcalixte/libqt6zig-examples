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
    const qapp: QApplication = .new(init.arena.allocator(), &argc, argv);
    defer qapp.delete();

    allocator = init.gpa;

    const widget = QWidget.new2();
    defer widget.delete();

    widget.setWindowTitle("Qt 6 Bluetooth Example");
    widget.setMinimumSize2(400, 400);

    const local_device = QBluetoothLocalDevice.new();
    defer local_device.delete();

    const layout = QVBoxLayout.new(widget);

    if (local_device.isValid()) {
        toggle = .new3("Bluetooth enabled");
        toggle.setChecked(true);

        button = .new3("Scan for devices");
        list = .new2();
        status = .new3("Ready.");

        layout.addWidget(toggle);
        layout.addWidget(button);
        layout.addWidget(list);
        layout.addWidget(status);

        agent = .new3(widget);
        agent.setLowEnergyDiscoveryTimeout(3000);

        toggle.onToggled(onToggled);
        button.onClicked(onClicked);
        agent.onDeviceDiscovered(onDeviceDiscovered);
        agent.onFinished(onFinished);
        agent.onErrorOccurred(onErrorOccurred);
    } else {
        const label = QLabel.new3("## No Bluetooth adapter detected.\n" ++
            "### Please ensure that your device has a Bluetooth adapter.");
        label.setTextFormat(qnamespace_enums.TextFormat.MarkdownText);
        label.setAlignment(qnamespace_enums.AlignmentFlag.AlignCenter);
        label.setWordWrap(true);
        layout.addWidget(label);
    }

    widget.show();

    _ = QApplication.exec();
}

fn onToggled(_: QCheckBox, checked: bool) callconv(.c) void {
    button.setEnabled(checked);
    list.setEnabled(checked);

    if (!checked and agent.isActive())
        agent.stop();

    const text = switch (checked) {
        true => "Bluetooth enabled.",
        false => "Bluetooth disabled.",
    };
    status.setText(text);
}

fn onClicked(self: QPushButton) callconv(.c) void {
    if (agent.isActive())
        return;

    list.clear();
    status.setText("Scanning...");
    self.setEnabled(false);
    agent.start2(
        qbluetoothdevicediscoveryagent_enums.DiscoveryMethod.ClassicMethod |
            qbluetoothdevicediscoveryagent_enums.DiscoveryMethod.LowEnergyMethod,
    );
}

fn onDeviceDiscovered(_: QBluetoothDeviceDiscoveryAgent, info: QBluetoothDeviceInfo) callconv(.c) void {
    const name = info.name(allocator);
    defer allocator.free(name);

    const address = info.address();
    defer address.delete();

    const address_str = address.toString(allocator);
    defer allocator.free(address_str);

    const title = switch (name.len) {
        0 => "Unknown",
        else => std.fmt.bufPrint(&buffer, "{s} ({s})", .{ name, address_str }) catch
            @panic("Failed to bufPrint"),
    };

    list.addItem(title);
}

fn onFinished(_: QBluetoothDeviceDiscoveryAgent) callconv(.c) void {
    button.setEnabled(toggle.isChecked());

    const text = "Scan complete - {d} device(s) found.";
    const formatted = std.fmt.bufPrint(&buffer, text, .{list.count()}) catch
        @panic("Failed to bufPrint");
    status.setText(formatted);
}

fn onErrorOccurred(self: QBluetoothDeviceDiscoveryAgent, _: i32) callconv(.c) void {
    button.setEnabled(toggle.isChecked());

    const error_text = self.errorString(allocator);
    defer allocator.free(error_text);

    status.setText(error_text);
}
