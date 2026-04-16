const std = @import("std");
const qt6 = @import("libqt6zig");
const types = qt6.types;
const QApplication = qt6.QApplication;
const QDBusConnection = qt6.QDBusConnection;
const QDBusMessage = qt6.QDBusMessage;
const qdbusmessage_enums = qt6.qdbusmessage_enums;
const QVariant = qt6.QVariant;
const ArrayMap_constu8_QVariant = types.ArrayMap_constu8_QVariant;

const bus_name = "org.freedesktop.Notifications";
const bus_path = "/org/freedesktop/Notifications";

pub fn main(init: std.process.Init) !void {
    const argv = try qt6.init(init.gpa, init.minimal.args);
    defer qt6.deinit(init.gpa, argv);
    var argc: i32 = @intCast(argv.len);
    const qapp = QApplication.New(init.arena.allocator(), &argc, argv);
    defer qapp.Delete();

    const session_bus = QDBusConnection.SessionBus();
    defer session_bus.Delete();

    const message = QDBusMessage.CreateMethodCall(bus_name, bus_path, bus_name, "Notify");
    defer message.Delete();

    const actions: []const []const u8 = &.{};
    const hints: ArrayMap_constu8_QVariant = .empty;

    var arguments = [_]QVariant{
        QVariant.New24("Qt 6 D-Bus Example"),
        QVariant.New5(0),
        QVariant.New24("dialog-information"),
        QVariant.New24("Qt 6 D-Bus Example"),
        QVariant.New24("This is a test notification sent via D-Bus."),
        QVariant.New25(init.gpa, actions),
        QVariant.New22(init.gpa, hints),
        QVariant.New4(-1),
    };

    message.SetArguments(&arguments);

    const reply = session_bus.Call(message);
    defer reply.Delete();

    if (reply.Type() != qdbusmessage_enums.MessageType.ReplyMessage) {
        std.Io.File.stdout().writeStreamingAll(init.io, "Failed to send message\n") catch @panic("Failed to print to stdout");

        QApplication.Quit();
    }
}
