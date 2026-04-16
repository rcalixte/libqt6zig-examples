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
var client_dialogs = [_]*ClientDialog{undefined} ** num_clients;

pub const ClientDialog = struct {
    name: []const u8,
    dialog: QDialog,
    socket: QWebSocket,
    messages: QTextEdit,
    input: QLineEdit,
    button: QPushButton,

    pub fn init(alloc: std.mem.Allocator, name: []const u8, num_str: []const u8) !*ClientDialog {
        var self = try alloc.create(ClientDialog);
        self.name = try std.fmt.allocPrint(alloc, "{s}", .{num_str});

        self.dialog = QDialog.New2();
        self.dialog.SetWindowTitle(name);
        self.dialog.SetMinimumSize2(400, 300);

        self.socket = QWebSocket.New();
        self.socket.SetParent(self.dialog);

        self.messages = QTextEdit.New(self.dialog);
        self.messages.SetReadOnly(true);

        self.input = QLineEdit.New(self.dialog);
        self.input.SetPlaceholderText("Enter your message here");
        self.input.SetEnabled(false);

        self.button = QPushButton.New5("Send", self.dialog);
        self.button.SetEnabled(false);

        const layout = QVBoxLayout.New2();
        const inputLayout = QHBoxLayout.New2();

        layout.AddWidget(self.messages);
        inputLayout.AddWidget(self.input);
        inputLayout.AddWidget(self.button);
        layout.AddLayout(inputLayout);
        self.dialog.SetLayout(layout);

        self.socket.OnConnected(onClientConnected);
        self.socket.OnTextMessageReceived(onClientMessageReceived);
        self.socket.OnErrorOccurred(onClientErrorOccurred);
        self.dialog.OnCloseEvent(onClientCloseEvent);
        self.button.OnClicked(onSendClicked);

        return self;
    }

    pub fn connectToServer(self: *ClientDialog, alloc: std.mem.Allocator) void {
        self.messages.Append("Connecting...");
        const ws = std.fmt.allocPrint(alloc, "ws://localhost:{d}", .{local_port}) catch @panic("Failed to allocPrint");
        defer alloc.free(ws);

        const url = QUrl.New3(ws);
        defer url.Delete();

        self.socket.Open(url);
    }

    pub fn sendMessage(self: *ClientDialog, alloc: std.mem.Allocator) void {
        const message = self.input.Text(alloc);
        defer alloc.free(message);
        if (message.len == 0) return;

        const trimmed_text = std.mem.trim(u8, message, &std.ascii.whitespace);
        if (trimmed_text.len == 0) return;

        const out_message = std.mem.concat(alloc, u8, &.{ "(", self.name, "): ", trimmed_text }) catch @panic("Failed to concat");
        defer alloc.free(out_message);

        _ = self.socket.SendTextMessage(out_message);

        const self_entry = std.mem.concat(alloc, u8, &.{ ">> ", trimmed_text }) catch @panic("Failed to concat");
        defer alloc.free(self_entry);
        self.messages.Append(self_entry);
        self.input.Clear();
    }

    pub fn deinit(self: *ClientDialog, alloc: std.mem.Allocator) void {
        self.dialog.DeleteLater();
        allocator.free(self.name);
        alloc.destroy(self);
    }

    fn onClientConnected(self: QWebSocket) callconv(.c) void {
        for (client_dialogs) |client|
            if (@as(?*anyopaque, self.ptr) == @as(?*anyopaque, client.socket.ptr)) {
                client.messages.Append("Connected!");
                client.input.SetEnabled(true);
                client.button.SetEnabled(true);
                client.input.SetFocus();
                return;
            };
    }

    fn onClientMessageReceived(self: QWebSocket, message: [*:0]const u8) callconv(.c) void {
        for (client_dialogs) |client|
            if (@as(?*anyopaque, self.ptr) == @as(?*anyopaque, client.socket.ptr)) {
                client.messages.Append(std.mem.span(message));
                return;
            };
    }

    fn onClientErrorOccurred(self: QWebSocket, _: i32) callconv(.c) void {
        const err_str = self.ErrorString(allocator);
        defer allocator.free(err_str);

        for (client_dialogs) |client|
            if (@as(?*anyopaque, self.ptr) == @as(?*anyopaque, client.socket.ptr)) {
                client.messages.Append("= Error =");
                client.messages.Append(err_str);
                return;
            };
    }

    fn onClientCloseEvent(_: QDialog, event: QCloseEvent) callconv(.c) void {
        for (client_dialogs) |client| {
            client.socket.Close();
            client.socket.Delete();
            client.dialog.SuperCloseEvent(event);
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
    const qapp = QApplication.New(init.arena.allocator(), &argc, argv);
    defer qapp.Delete();

    allocator = init.gpa;

    const server = QWebSocketServer.New("Example Qt WebSockets Server", qwebsocketserver_enums.SslMode.NonSecureMode);
    defer server.Delete();

    const localhost = qhostaddress.New7(qhostaddress_enums.SpecialAddress.LocalHostIPv6);
    defer localhost.Delete();

    if (!server.Listen2(localhost, local_port)) {
        const err_str = server.ErrorString(allocator);
        defer allocator.free(err_str);
        std.log.err("Failed to listen on port {d}: {s}\n", .{ local_port, err_str });
        return;
    }

    for (0..num_clients) |i| {
        const num_str = try std.fmt.bufPrint(&buf, "{d}", .{i + 1});
        const name = try std.mem.concat(allocator, u8, &.{ "Qt 6 WebSockets Example Client #", num_str });
        defer allocator.free(name);

        client_dialogs[i] = try ClientDialog.init(allocator, name, num_str);

        client_dialogs[i].connectToServer(allocator);

        client_dialogs[i].dialog.Show();
        const width = client_dialogs[i].dialog.Width();
        const mult: i32 = @intCast(i);
        const y = client_dialogs[i].dialog.Y();
        client_dialogs[i].dialog.Move(offset_x + (width + 10) * mult, y);
    }

    defer {
        for (0..max_clients) |i| {
            if (clients[i].ptr != null)
                clients[i].ptr = null;
        }
        for (client_dialogs) |client|
            client.deinit(allocator);
    }

    server.OnNewConnection(onNewConnection);

    _ = QApplication.Exec();
}

fn onNewConnection(self: QWebSocketServer) callconv(.c) void {
    const client = self.NextPendingConnection();
    if (client_num >= clients.len) {
        client.Close();
        return;
    }

    clients[client_num] = client;
    client_num += 1;

    client.OnTextMessageReceived(onServerMessageReceived);
    client.OnDisconnected(onServerDisconnected);
}

fn onServerMessageReceived(self: QWebSocket, message: [*:0]const u8) callconv(.c) void {
    const msg = std.mem.span(message);

    for (clients) |client| {
        if (client.ptr == null or @as(?*anyopaque, self.ptr) == @as(?*anyopaque, client.ptr)) continue;

        _ = client.SendTextMessage(msg);
    }
}

fn onServerDisconnected(self: QWebSocket) callconv(.c) void {
    self.DeleteLater();
}
