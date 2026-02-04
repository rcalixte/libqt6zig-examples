const std = @import("std");
const qt6 = @import("libqt6zig");
const C = qt6.C;
const all_types = qt6.all_types;
const qapplication = qt6.qapplication;
const qdbusconnection = qt6.qdbusconnection;
const qdbusmessage = qt6.qdbusmessage;
const qdbusmessage_enums = qt6.qdbusmessage_enums;
const qvariant = qt6.qvariant;
const map_constu8_qtcqvariant = all_types.map_constu8_qtcqvariant;

var gpa = @import("alloc_config").gpa;
const allocator = gpa.allocator();

var buffer: [32]u8 = undefined;
var stdout_writer = std.fs.File.stdout().writer(&buffer);

const bus_name = "org.freedesktop.Notifications";
const bus_path = "/org/freedesktop/Notifications";

pub fn main() void {
    const argc = std.os.argv.len;
    const argv = std.os.argv.ptr;
    const qapp = qapplication.New(argc, argv);
    defer qapplication.QDelete(qapp);

    defer _ = gpa.deinit();

    const session_bus = qdbusconnection.SessionBus();
    defer qdbusconnection.QDelete(session_bus);

    const message = qdbusmessage.CreateMethodCall(bus_name, bus_path, bus_name, "Notify");
    defer qdbusmessage.QDelete(message);

    const actions: []const []const u8 = &.{};
    const hints: map_constu8_qtcqvariant = .empty;

    var arguments = [_]C.QVariant{
        qvariant.New24("Qt 6 D-Bus Example"),
        qvariant.New5(0),
        qvariant.New24("dialog-information"),
        qvariant.New24("Qt 6 D-Bus Example"),
        qvariant.New24("This is a test notification sent via D-Bus."),
        qvariant.New25(actions, allocator),
        qvariant.New22(hints, allocator),
        qvariant.New4(-1),
    };

    qdbusmessage.SetArguments(message, &arguments);

    const reply = qdbusconnection.Call(session_bus, message);
    defer qdbusmessage.QDelete(reply);

    if (qdbusmessage.Type(reply) != qdbusmessage_enums.MessageType.ReplyMessage) {
        stdout_writer.interface.writeAll("Failed to send message\n") catch @panic("Failed to print to stdout");
        stdout_writer.interface.flush() catch @panic("Failed to flush stdout writer");

        qapplication.Quit();
    }
}
