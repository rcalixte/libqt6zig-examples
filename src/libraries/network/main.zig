const std = @import("std");
const qt6 = @import("libqt6zig");
const qapplication = qt6.qapplication;
const qdnslookup = qt6.qdnslookup;
const qdnslookup_enums = qt6.qdnslookup_enums;
const qdnshostaddressrecord = qt6.qdnshostaddressrecord;
const qhostaddress = qt6.qhostaddress;

const getAllocatorConfig = @import("alloc_config").getAllocatorConfig;
const config = getAllocatorConfig();
var gda: std.heap.DebugAllocator(config) = .init;
const allocator = gda.allocator();

var buffer: [1024]u8 = undefined;
var stdout_writer = std.fs.File.stdout().writer(&buffer);

pub fn main() void {
    const argc = std.os.argv.len;
    const argv = std.os.argv.ptr;
    _ = qapplication.New(argc, argv);

    defer _ = gda.deinit();

    stdout_writer.interface.writeAll("Looking up DNS info, please wait...") catch @panic("Failed to print to stdout");
    stdout_writer.interface.flush() catch @panic("Failed to flush stdout writer");

    const dns = qdnslookup.New2(qdnslookup_enums.Type.A, "google.com");

    qdnslookup.OnFinished(dns, onFinished);
    qdnslookup.Lookup(dns);

    _ = qapplication.Exec();
}

fn onFinished(dns: ?*anyopaque) callconv(.c) void {
    qdnslookup.DeleteLater(dns);

    if (qdnslookup.Error(dns) != qdnslookup_enums.Error.NoError) {
        const dns_error = qdnslookup.ErrorString(dns, allocator);
        defer allocator.free(dns_error);
        stdout_writer.interface.print("DNS lookup failed: {s}\n", .{dns_error}) catch @panic("Failed to print to stdout");
        stdout_writer.interface.flush() catch @panic("Failed to flush stdout writer");
        return;
    }

    const results = qdnslookup.HostAddressRecords(dns, allocator);
    defer allocator.free(results);
    stdout_writer.interface.print("Found {d} results.\n", .{results.len}) catch @panic("Failed to print to stdout");
    stdout_writer.interface.flush() catch @panic("Failed to flush stdout writer");

    for (results) |result| {
        const value = qdnshostaddressrecord.Value(result);
        defer qhostaddress.QDelete(value);

        const record = qhostaddress.ToString(value, allocator);
        defer allocator.free(record);

        stdout_writer.interface.print("- {s}\n", .{record}) catch @panic("Failed to print record to stdout");
        stdout_writer.interface.flush() catch @panic("Failed to flush stdout writer");
    }

    qapplication.Exit();
}
