const std = @import("std");
const qt6 = @import("libqt6zig");
const QApplication = qt6.QApplication;
const QDialog = qt6.QDialog;
const QVBoxLayout = qt6.QVBoxLayout;
const QTextEdit = qt6.QTextEdit;
const QHBoxLayout = qt6.QHBoxLayout;
const QLineEdit = qt6.QLineEdit;
const QPushButton = qt6.QPushButton;
const QUrl = qt6.QUrl;
const QWebSocketServer = qt6.QWebSocketServer;
const qwebsocketserver_enums = qt6.qwebsocketserver_enums;
const qhostaddress = qt6.QHostAddress;
const qhostaddress_enums = qt6.qhostaddress_enums;
const QWebSocket = qt6.QWebSocket;
const QCloseEvent = qt6.QCloseEvent;

var allocator: std.mem.Allocator = undefined;

const local_port: u16 = 12345;
const num_clients: usize = 3;
const max_clients: usize = 10;
const offset_x: i32 = 200;

var buf: [4]u8 = undefined;
var clients: [max_clients]QWebSocket = @splat(.{ .ptr = null });
var client_num: usize = 0;
var client_dialogs: [num_clients]*ClientDialog = @splat(undefined);

pub const ClientDialog = struct {
    name: []const u8,
    dialog: QDialog,
    socket: QWebSocket,
    messages: QTextEdit,
    input: QLineEdit,
    button: QPushButton,

    pub fn create(alloc: std.mem.Allocator, name: []const u8, num_str: []const u8) !*ClientDialog {
        var self = try alloc.create(ClientDialog);
        errdefer alloc.destroy(self);

        self.name = try alloc.dupe(u8, num_str);

        self.dialog = .new2();
        self.dialog.setWindowTitle(name);
        self.dialog.setMinimumSize2(400, 300);

        self.socket = .new();
        self.socket.setParent(self.dialog);

        self.messages = .new(self.dialog);
        self.messages.setReadOnly(true);

        self.input = .new(self.dialog);
        self.input.setPlaceholderText("Enter your message here");
        self.input.setEnabled(false);

        self.button = .new5("Send", self.dialog);
        self.button.setEnabled(false);

        const layout = QVBoxLayout.new2();
        const inputLayout = QHBoxLayout.new2();

        layout.addWidget(self.messages);
        inputLayout.addWidget(self.input);
        inputLayout.addWidget(self.button);
        layout.addLayout(inputLayout);
        self.dialog.setLayout(layout);

        self.socket.onConnected(onClientConnected);
        self.socket.onTextMessageReceived(onClientMessageReceived);
        self.socket.onErrorOccurred(onClientErrorOccurred);
        self.dialog.onCloseEvent(onClientCloseEvent);
        self.button.onClicked(onSendClicked);

        return self;
    }

    pub fn connectToServer(self: *ClientDialog, alloc: std.mem.Allocator) void {
        self.messages.append("Connecting...");
        const ws = std.fmt.allocPrint(alloc, "ws://localhost:{d}", .{local_port}) catch
            @panic("Failed to allocPrint");
        defer alloc.free(ws);

        const url = QUrl.new3(ws);
        defer url.delete();

        self.socket.open(url);
    }

    fn sendMessage(self: *ClientDialog, alloc: std.mem.Allocator) void {
        const message = self.input.text(alloc);
        defer alloc.free(message);
        if (message.len == 0) return;

        const trimmed_text = std.mem.trim(u8, message, &std.ascii.whitespace);
        if (trimmed_text.len == 0) return;

        const out_message = std.fmt.allocPrint(alloc, "({s}): {s}", .{ self.name, trimmed_text }) catch
            @panic("Failed to allocPrint");
        defer alloc.free(out_message);

        _ = self.socket.sendTextMessage(out_message);

        const self_entry = std.fmt.allocPrint(alloc, ">> {s}", .{trimmed_text}) catch
            @panic("Failed to allocPrint");
        defer alloc.free(self_entry);
        self.messages.append(self_entry);
        self.input.clear();
    }

    pub fn destroy(self: *ClientDialog, alloc: std.mem.Allocator) void {
        self.dialog.deleteLater();
        allocator.free(self.name);
        alloc.destroy(self);
    }

    fn onClientConnected(self: QWebSocket) callconv(.c) void {
        for (client_dialogs) |client|
            if (@as(?*anyopaque, self.ptr) == @as(?*anyopaque, client.socket.ptr)) {
                client.messages.append("Connected!");
                client.input.setEnabled(true);
                client.button.setEnabled(true);
                client.input.setFocus();
                return;
            };
    }

    fn onClientMessageReceived(self: QWebSocket, message: [*:0]const u8) callconv(.c) void {
        for (client_dialogs) |client|
            if (@as(?*anyopaque, self.ptr) == @as(?*anyopaque, client.socket.ptr)) {
                client.messages.append(std.mem.span(message));
                return;
            };
    }

    fn onClientErrorOccurred(self: QWebSocket, _: i32) callconv(.c) void {
        const err_str = self.errorString(allocator);
        defer allocator.free(err_str);

        for (client_dialogs) |client|
            if (@as(?*anyopaque, self.ptr) == @as(?*anyopaque, client.socket.ptr)) {
                client.messages.append("= Error =");
                client.messages.append(err_str);
                return;
            };
    }

    fn onClientCloseEvent(_: QDialog, event: QCloseEvent) callconv(.c) void {
        for (client_dialogs) |client| {
            client.socket.close();
            client.socket.delete();
            client.dialog.superCloseEvent(event);
        }
    }

    fn onSendClicked(self: QPushButton) callconv(.c) void {
        for (client_dialogs) |client|
            if (@as(?*anyopaque, self.ptr) == @as(?*anyopaque, client.button.ptr)) {
                client.sendMessage(allocator);
                return;
            };
    }
};

pub fn main(init: std.process.Init) !void {
    const argv = try qt6.init(init.gpa, init.minimal.args);
    defer qt6.deinit(init.gpa, argv);
    var argc: i32 = @intCast(argv.len);
    const qapp: QApplication = .new(init.arena.allocator(), &argc, argv);
    defer qapp.delete();

    allocator = init.gpa;

    const server = QWebSocketServer.new(
        "Example Qt WebSockets Server",
        qwebsocketserver_enums.SslMode.NonSecureMode,
    );
    defer server.delete();

    const localhost = qhostaddress.new7(qhostaddress_enums.SpecialAddress.LocalHostIPv6);
    defer localhost.delete();

    if (!server.listen2(localhost, local_port)) {
        const err_str = server.errorString(allocator);
        defer allocator.free(err_str);
        std.log.err("Failed to listen on port {d}: {s}\n", .{ local_port, err_str });
        return;
    }

    for (0..num_clients) |i| {
        const num_str = try std.fmt.bufPrint(&buf, "{d}", .{i + 1});
        const name = try std.fmt.allocPrint(allocator, "Qt 6 WebSockets Example Client #{s}", .{num_str});
        defer allocator.free(name);

        client_dialogs[i] = try .create(allocator, name, num_str);

        client_dialogs[i].connectToServer(allocator);

        client_dialogs[i].dialog.show();
        const width = client_dialogs[i].dialog.width();
        const mult: i32 = @intCast(i);
        const y = client_dialogs[i].dialog.y();
        client_dialogs[i].dialog.move(offset_x + (width + 10) * mult, y);
    }

    defer {
        for (0..max_clients) |i| {
            if (clients[i].ptr != null)
                clients[i].ptr = null;
        }
        for (client_dialogs) |client|
            client.destroy(allocator);
    }

    server.onNewConnection(onNewConnection);

    _ = QApplication.exec();
}

fn onNewConnection(self: QWebSocketServer) callconv(.c) void {
    const client = self.nextPendingConnection();
    if (client_num >= clients.len) {
        client.close();
        return;
    }

    clients[client_num] = client;
    client_num += 1;

    client.onTextMessageReceived(onServerMessageReceived);
    client.onDisconnected(onServerDisconnected);
}

fn onServerMessageReceived(self: QWebSocket, message: [*:0]const u8) callconv(.c) void {
    const msg = std.mem.span(message);

    for (clients) |client| {
        if (client.ptr == null or @as(?*anyopaque, self.ptr) == @as(?*anyopaque, client.ptr)) continue;

        _ = client.sendTextMessage(msg);
    }
}

fn onServerDisconnected(self: QWebSocket) callconv(.c) void {
    self.deleteLater();
}
