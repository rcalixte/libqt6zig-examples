const std = @import("std");
const qt6 = @import("libqt6zig");
const types = qt6.types;
const QCoreApplication = qt6.QCoreApplication;
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
    const qapp: QCoreApplication = .new(init.arena.allocator(), &argc, argv);
    defer qapp.delete();

    const session_bus = QDBusConnection.sessionBus();
    defer session_bus.delete();

    const message = QDBusMessage.createMethodCall(
        bus_name,
        bus_path,
        bus_name,
        "Notify",
    );
    defer message.delete();

    const actions: []const []const u8 = &.{};
    const hints: ArrayMap_constu8_QVariant = .empty;

    const variant_name = QVariant.new24("Qt 6 D-Bus Example");
    defer variant_name.delete();

    const variant_id = QVariant.new5(0);
    defer variant_id.delete();

    const variant_icon = QVariant.new24("dialog-information");
    defer variant_icon.delete();

    const variant_body = QVariant.new24("This is a test notification sent via D-Bus.");
    defer variant_body.delete();

    const variant_actions = QVariant.new25(init.gpa, actions);
    defer variant_actions.delete();

    const variant_hints = QVariant.new22(init.gpa, hints);
    defer variant_hints.delete();

    const variant_timeout = QVariant.new4(-1);
    defer variant_timeout.delete();

    var arguments = [_]QVariant{
        variant_name,
        variant_id,
        variant_icon,
        variant_name,
        variant_body,
        variant_actions,
        variant_hints,
        variant_timeout,
    };

    message.setArguments(&arguments);

    const reply = session_bus.call(message);
    defer reply.delete();

    if (reply.type0() != qdbusmessage_enums.MessageType.ReplyMessage) {
        std.log.err("Failed to send message", .{});
        QCoreApplication.quit();
    }
}
