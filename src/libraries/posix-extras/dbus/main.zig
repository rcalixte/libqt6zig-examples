const std = @import("std");
const qt6 = @import("libqt6zig");
const C = qt6.C;
const all_types = qt6.all_types;
const qapplication = qt6.qapplication;
const qdbusconnection = qt6.qdbusconnection;
const qdbusmessage = qt6.qdbusmessage;
const qdbusmessage_enums = qt6.qdbusmessage_enums;
const qvariant = qt6.qvariant;
const arraymap_constu8_qtcqvariant = all_types.arraymap_constu8_qtcqvariant;

const bus_name = "org.freedesktop.Notifications";
const bus_path = "/org/freedesktop/Notifications";

pub fn main(init: std.process.Init) !void {
    const argv = try qt6.init(init.gpa, init.minimal.args);
    defer qt6.deinit(init.gpa, argv);
    var argc: i32 = @intCast(argv.len);
    const qapp = qapplication.New(&argc, argv, init.arena.allocator());
    defer qapplication.Delete(qapp);

    const session_bus = qdbusconnection.SessionBus();
    defer qdbusconnection.Delete(session_bus);

    const message = qdbusmessage.CreateMethodCall(bus_name, bus_path, bus_name, "Notify");
    defer qdbusmessage.Delete(message);

    const actions: []const []const u8 = &.{};
    const hints: arraymap_constu8_qtcqvariant = .empty;

    var arguments = [_]C.QVariant{
        qvariant.New24("Qt 6 D-Bus Example"),
        qvariant.New5(0),
        qvariant.New24("dialog-information"),
        qvariant.New24("Qt 6 D-Bus Example"),
        qvariant.New24("This is a test notification sent via D-Bus."),
        qvariant.New25(actions, init.gpa),
        qvariant.New22(hints, init.gpa),
        qvariant.New4(-1),
    };

    qdbusmessage.SetArguments(message, &arguments);

    const reply = qdbusconnection.Call(session_bus, message);
    defer qdbusmessage.Delete(reply);

    if (qdbusmessage.Type(reply) != qdbusmessage_enums.MessageType.ReplyMessage) {
        std.Io.File.stdout().writeStreamingAll(init.io, "Failed to send message\n") catch @panic("Failed to print to stdout");

        qapplication.Quit();
    }
}
