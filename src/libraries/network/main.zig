const std = @import("std");
const qt6 = @import("libqt6zig");
const qapplication = qt6.qapplication;
const qdnslookup = qt6.qdnslookup;
const qdnslookup_enums = qt6.qdnslookup_enums;
const qdnshostaddressrecord = qt6.qdnshostaddressrecord;
const qhostaddress = qt6.qhostaddress;

var gpa = @import("alloc_config").gpa;
const allocator = gpa.allocator();

var buffer: [1024]u8 = undefined;
var messages: std.ArrayList([]const u8) = .empty;

pub fn main() !void {
    const argc = std.os.argv.len;
    const argv = std.os.argv.ptr;
    const qapp = qapplication.New(argc, argv);
    defer qapplication.QDelete(qapp);

    defer _ = gpa.deinit();

    var stdout_writer = std.fs.File.stdout().writer(&buffer);

    try stdout_writer.interface.writeAll("Looking up DNS info, please wait...");
    try stdout_writer.interface.flush();

    const dns = qdnslookup.New2(qdnslookup_enums.Type.A, "google.com");

    qdnslookup.OnFinished(dns, onFinished);
    qdnslookup.Lookup(dns);

    _ = qapplication.Exec();

    defer messages.deinit(allocator);

    for (messages.items) |message| {
        defer allocator.free(message);

        try stdout_writer.interface.writeAll(message);
        try stdout_writer.interface.flush();
    }
}

fn onFinished(dns: ?*anyopaque) callconv(.c) void {
    qdnslookup.DeleteLater(dns);

    if (qdnslookup.Error(dns) != qdnslookup_enums.Error.NoError) {
        const dns_error = qdnslookup.ErrorString(dns, allocator);
        defer allocator.free(dns_error);

        const errorStr = std.fmt.allocPrint(allocator, "DNS lookup failed: {s}\n", .{dns_error}) catch @panic("Failed to allocPrint error(s)");
        messages.append(allocator, errorStr) catch @panic("Failed to append error(s)");
        return;
    }

    const results = qdnslookup.HostAddressRecords(dns, allocator);
    defer allocator.free(results);

    const resultsStr = std.fmt.allocPrint(allocator, "Found {d} results.\n", .{results.len}) catch @panic("Failed to allocPrint results");
    messages.append(allocator, resultsStr) catch @panic("Failed to append results");

    for (results) |result| {
        const value = qdnshostaddressrecord.Value(result);
        defer qhostaddress.QDelete(value);

        const record = qhostaddress.ToString(value, allocator);
        defer allocator.free(record);

        const recordStr = std.fmt.allocPrint(allocator, "- {s}\n", .{record}) catch @panic("Failed to allocPrint record(s)");
        messages.append(allocator, recordStr) catch @panic("Failed to append record(s)");
    }

    qapplication.Exit();
}
