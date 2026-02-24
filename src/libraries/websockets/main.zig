const std = @import("std");
const qt6 = @import("libqt6zig");
const C = qt6.C;
const qapplication = qt6.qapplication;
const qdialog = qt6.qdialog;
const qvboxlayout = qt6.qvboxlayout;
const qtextedit = qt6.qtextedit;
const qhboxlayout = qt6.qhboxlayout;
const qlineedit = qt6.qlineedit;
const qpushbutton = qt6.qpushbutton;
const qurl = qt6.qurl;
const qwebsocketserver = qt6.qwebsocketserver;
const qwebsocketserver_enums = qt6.qwebsocketserver_enums;
const qhostaddress = qt6.qhostaddress;
const qhostaddress_enums = qt6.qhostaddress_enums;
const qwebsocket = qt6.qwebsocket;
const qwidget = qt6.qwidget;

var gpa = @import("alloc_config").gpa;
const allocator = gpa.allocator();

const LOCAL_PORT: u16 = 12345;
const numClients: usize = 3;
const maxClients: usize = 10;
const offsetX: i32 = 200;

var buf: [4]u8 = undefined;
var clients = [_]C.QWebSocket{null} ** maxClients;
var clientNum: usize = 0;
var clientDialogs = [_]*ClientDialog{undefined} ** numClients;

pub const ClientDialog = struct {
    name: []const u8,
    dialog: C.QDialog,
    socket: C.QWebSocket,
    messages: C.QTextEdit,
    input: C.QLineEdit,
    button: C.QPushButton,

    pub fn init(alloc: std.mem.Allocator, name: []const u8, numStr: []const u8) !*ClientDialog {
        var self = try alloc.create(ClientDialog);
        self.name = try std.fmt.allocPrint(alloc, "{s}", .{numStr});

        self.dialog = qdialog.New2();
        qdialog.SetWindowTitle(self.dialog, name);
        qdialog.SetMinimumSize2(self.dialog, 400, 300);

        self.socket = qwebsocket.New();
        qwebsocket.SetParent(self.socket, self.dialog);

        self.messages = qtextedit.New(self.dialog);
        qtextedit.SetReadOnly(self.messages, true);

        self.input = qlineedit.New(self.dialog);
        qlineedit.SetPlaceholderText(self.input, "Enter your message here");
        qlineedit.SetEnabled(self.input, false);

        self.button = qpushbutton.New5("Send", self.dialog);
        qpushbutton.SetEnabled(self.button, false);

        const layout = qvboxlayout.New2();
        const inputLayout = qhboxlayout.New2();

        qvboxlayout.AddWidget(layout, self.messages);
        qhboxlayout.AddWidget(inputLayout, self.input);
        qhboxlayout.AddWidget(inputLayout, self.button);
        qvboxlayout.AddLayout(layout, inputLayout);
        qdialog.SetLayout(self.dialog, layout);

        qwebsocket.OnConnected(self.socket, onClientConnected);
        qwebsocket.OnTextMessageReceived(self.socket, onClientMessageReceived);
        qwebsocket.OnErrorOccurred(self.socket, onClientErrorOccurred);
        qdialog.OnCloseEvent(self.dialog, onClientCloseEvent);
        qpushbutton.OnClicked(self.button, onSendClicked);

        return self;
    }

    pub fn connectToServer(self: *ClientDialog, alloc: std.mem.Allocator) void {
        qtextedit.Append(self.messages, "Connecting...");
        const ws = std.fmt.allocPrint(alloc, "ws://localhost:{d}", .{LOCAL_PORT}) catch @panic("Failed to allocPrint");
        defer alloc.free(ws);

        const url = qurl.New3(ws);
        defer qurl.Delete(url);

        qwebsocket.Open(self.socket, url);
    }

    pub fn sendMessage(self: *ClientDialog, alloc: std.mem.Allocator) void {
        const message = qlineedit.Text(self.input, alloc);
        defer alloc.free(message);
        if (message.len == 0) return;

        const trimmedText = std.mem.trim(u8, message, &std.ascii.whitespace);
        if (trimmedText.len == 0) return;

        const outMessage = std.mem.concat(alloc, u8, &.{ "(", self.name, "): ", trimmedText }) catch @panic("Failed to concat");
        defer alloc.free(outMessage);

        _ = qwebsocket.SendTextMessage(self.socket, outMessage);

        const selfEntry = std.mem.concat(alloc, u8, &.{ ">> ", trimmedText }) catch @panic("Failed to concat");
        defer alloc.free(selfEntry);
        qtextedit.Append(self.messages, selfEntry);
        qlineedit.Clear(self.input);
    }

    pub fn deinit(self: *ClientDialog, alloc: std.mem.Allocator) void {
        qdialog.DeleteLater(self.dialog);
        allocator.free(self.name);
        alloc.destroy(self);
    }

    fn onClientConnected(self: ?*anyopaque) callconv(.c) void {
        for (clientDialogs) |client| {
            if (self == @as(?*anyopaque, client.socket)) {
                qtextedit.Append(client.messages, "Connected!");
                qlineedit.SetEnabled(client.input, true);
                qpushbutton.SetEnabled(client.button, true);
                qlineedit.SetFocus(client.input);
                return;
            }
        }
    }

    fn onClientMessageReceived(self: ?*anyopaque, message: [*:0]const u8) callconv(.c) void {
        for (clientDialogs) |client| {
            if (self == @as(?*anyopaque, client.socket)) {
                qtextedit.Append(client.messages, std.mem.span(message));
                return;
            }
        }
    }

    fn onClientErrorOccurred(self: ?*anyopaque, _: i32) callconv(.c) void {
        const errStr = qwebsocket.ErrorString(self, allocator);
        defer allocator.free(errStr);

        for (clientDialogs) |client| {
            if (self == @as(?*anyopaque, client.socket)) {
                qtextedit.Append(client.messages, "= Error =");
                qtextedit.Append(client.messages, errStr);
                return;
            }
        }
    }

    fn onClientCloseEvent(_: ?*anyopaque, event: ?*anyopaque) callconv(.c) void {
        for (clientDialogs) |client| {
            qwebsocket.Close(client.socket);
            qwebsocket.Delete(client.socket);
            qdialog.SuperCloseEvent(client.dialog, event);
        }
    }

    fn onSendClicked(self: ?*anyopaque) callconv(.c) void {
        for (clientDialogs) |client| {
            if (self == @as(?*anyopaque, client.button)) {
                client.sendMessage(allocator);
                return;
            }
        }
    }
};

pub fn main() !void {
    const argc = std.os.argv.len;
    const argv = std.os.argv.ptr;
    const qapp = qapplication.New(argc, argv);
    defer qapplication.Delete(qapp);

    defer _ = gpa.deinit();

    const server = qwebsocketserver.New("Example Qt WebSockets Server", qwebsocketserver_enums.SslMode.NonSecureMode);
    defer qwebsocketserver.Delete(server);

    const localhost = qhostaddress.New7(qhostaddress_enums.SpecialAddress.LocalHostIPv6);
    defer qhostaddress.Delete(localhost);

    if (!qwebsocketserver.Listen2(server, localhost, LOCAL_PORT)) {
        const errStr = qwebsocketserver.ErrorString(server, allocator);
        defer allocator.free(errStr);
        std.log.err("Failed to listen on port {d}: {s}\n", .{ LOCAL_PORT, errStr });
        return;
    }

    for (0..numClients) |i| {
        const numStr = try std.fmt.bufPrintZ(&buf, "{d}", .{i + 1});
        const name = try std.mem.concat(allocator, u8, &.{ "Qt 6 WebSockets Example Client #", numStr });
        defer allocator.free(name);

        clientDialogs[i] = try ClientDialog.init(allocator, name, numStr);

        clientDialogs[i].connectToServer(allocator);

        qdialog.Show(clientDialogs[i].dialog);
        const width = qdialog.Width(clientDialogs[i].dialog);
        const mult: i32 = @intCast(i);
        const y = qdialog.Y(clientDialogs[i].dialog);
        qdialog.Move(clientDialogs[i].dialog, offsetX + (width + 10) * mult, y);
    }

    defer {
        for (0..maxClients) |i| {
            if (clients[i] != null) {
                clients[i] = null;
            }
        }
        for (clientDialogs) |client| {
            client.deinit(allocator);
        }
    }

    qwebsocketserver.OnNewConnection(server, onNewConnection);

    _ = qapplication.Exec();
}

fn onNewConnection(self: ?*anyopaque) callconv(.c) void {
    const client = qwebsocketserver.NextPendingConnection(self);
    if (clientNum >= clients.len) {
        qwebsocket.Close(client);
        return;
    }

    clients[clientNum] = client;
    clientNum += 1;

    qwebsocket.OnTextMessageReceived(client, onServerMessageReceived);
    qwebsocket.OnDisconnected(client, onServerDisconnected);
}

fn onServerMessageReceived(self: ?*anyopaque, message: [*:0]const u8) callconv(.c) void {
    const msg = std.mem.span(message);

    for (clients) |client| {
        if (client == null or self == @as(?*anyopaque, client)) continue;

        _ = qwebsocket.SendTextMessage(client, msg);
    }
}

fn onServerDisconnected(self: ?*anyopaque) callconv(.c) void {
    qwebsocket.DeleteLater(self);
}
