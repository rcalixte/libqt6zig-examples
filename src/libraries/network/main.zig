const std = @import("std");
const qt6 = @import("libqt6zig");
const qcoreapplication = qt6.qcoreapplication;
const qdnslookup = qt6.qdnslookup;
const qdnslookup_enums = qt6.qdnslookup_enums;
const qdnshostaddressrecord = qt6.qdnshostaddressrecord;
const qhostaddress = qt6.qhostaddress;

var allocator: std.mem.Allocator = undefined;
var io: std.Io = undefined;

pub fn main(init: std.process.Init) !void {
    const argv = try qt6.init(init.gpa, init.minimal.args);
    defer qt6.deinit(init.gpa, argv);
    var argc: i32 = @intCast(argv.len);
    const qapp = qcoreapplication.New(&argc, argv, init.arena.allocator());
    defer qcoreapplication.Delete(qapp);

    allocator = init.gpa;
    io = init.io;

    try std.Io.File.stdout().writeStreamingAll(init.io, "Looking up DNS info, please wait...");

    const dns = qdnslookup.New2(qdnslookup_enums.Type.A, "google.com");

    qdnslookup.OnFinished(dns, onFinished);
    qdnslookup.Lookup(dns);

    _ = qcoreapplication.Exec();
}

fn onFinished(dns: ?*anyopaque) callconv(.c) void {
    qdnslookup.DeleteLater(dns);

    if (qdnslookup.Error(dns) != qdnslookup_enums.Error.NoError) {
        const dns_error = qdnslookup.ErrorString(dns, allocator);
        defer allocator.free(dns_error);

        const errorStr = std.fmt.allocPrint(allocator, "DNS lookup failed: {s}\n", .{dns_error}) catch @panic("Failed to allocPrint error(s)");
        defer allocator.free(errorStr);

        std.Io.File.stdout().writeStreamingAll(io, errorStr) catch @panic("Failed to write error(s)");
        return;
    }

    const results = qdnslookup.HostAddressRecords(dns, allocator);
    defer allocator.free(results);

    const results_str = std.fmt.allocPrint(allocator, "Found {d} results.\n", .{results.len}) catch @panic("Failed to allocPrint results");
    defer allocator.free(results_str);

    std.Io.File.stdout().writeStreamingAll(io, results_str) catch @panic("Failed to write results");

    for (results) |result| {
        const value = qdnshostaddressrecord.Value(result);
        defer qhostaddress.Delete(value);

        const record = qhostaddress.ToString(value, allocator);
        defer allocator.free(record);

        const record_str = std.fmt.allocPrint(allocator, "- {s}\n", .{record}) catch @panic("Failed to allocPrint record(s)");
        defer allocator.free(record_str);

        std.Io.File.stdout().writeStreamingAll(io, record_str) catch @panic("Failed to write record(s)");
    }

    qcoreapplication.Exit();
}
