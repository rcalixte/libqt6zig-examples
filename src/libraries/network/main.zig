const std = @import("std");
const builtin = @import("builtin");
const qt6 = @import("libqt6zig");
const qapplication = qt6.qapplication;
const qdnslookup = qt6.qdnslookup;
const qdnslookup_enums = qt6.qdnslookup_enums;
const qdnshostaddressrecord = qt6.qdnshostaddressrecord;
const qhostaddress = qt6.qhostaddress;

const config = getAllocatorConfig();
var gda: std.heap.DebugAllocator(config) = .init;
const allocator = gda.allocator();

pub fn main() void {
    const argc = std.os.argv.len;
    const argv = std.os.argv.ptr;
    _ = qapplication.New(argc, argv);

    defer _ = gda.deinit();
    const stdout = std.io.getStdOut().writer();
    stdout.print("Looking up DNS info, please wait...", .{}) catch @panic("Failed to print to stdout");

    const dns = qdnslookup.New2(qdnslookup_enums.Type.A, "google.com");

    qdnslookup.OnFinished(dns, onFinished);
    qdnslookup.Lookup(dns);

    _ = qapplication.Exec();
}

fn onFinished(dns: ?*anyopaque) callconv(.c) void {
    qdnslookup.DeleteLater(dns);
    const stdout = std.io.getStdOut().writer();

    if (qdnslookup.Error(dns) != qdnslookup_enums.Error.NoError) {
        const dns_error = qdnslookup.ErrorString(dns, allocator);
        defer allocator.free(dns_error);
        stdout.print("DNS lookup failed: {s}\n", .{dns_error}) catch @panic("Failed to print to stdout");
        return;
    }

    const results = qdnslookup.HostAddressRecords(dns, allocator);
    defer allocator.free(results);
    stdout.print("Found {d} results.\n", .{results.len}) catch @panic("Failed to print to stdout");

    for (results) |result| {
        const value = qdnshostaddressrecord.Value(result);
        defer qhostaddress.QDelete(value);

        const record = qhostaddress.ToString(value, allocator);
        defer allocator.free(record);

        stdout.print("- {s}\n", .{record}) catch @panic("Failed to print record to stdout");
    }

    qapplication.Exit();
}

pub fn getAllocatorConfig() std.heap.DebugAllocatorConfig {
    if (builtin.mode == .Debug) {
        return std.heap.DebugAllocatorConfig{
            .safety = true,
            .never_unmap = true,
            .retain_metadata = true,
            .verbose_log = false,
        };
    } else {
        return std.heap.DebugAllocatorConfig{
            .safety = false,
            .never_unmap = false,
            .retain_metadata = false,
            .verbose_log = false,
        };
    }
}
