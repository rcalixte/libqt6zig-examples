const std = @import("std");
const qt6 = @import("libqt6zig");
const QCoreApplication = qt6.QCoreApplication;
const QDnsLookup = qt6.QDnsLookup;
const qdnslookup_enums = qt6.qdnslookup_enums;

var allocator: std.mem.Allocator = undefined;
var io: std.Io = undefined;

pub fn main(init: std.process.Init) !void {
    const argv = try qt6.init(init.gpa, init.minimal.args);
    defer qt6.deinit(init.gpa, argv);
    var argc: i32 = @intCast(argv.len);
    const qapp = QCoreApplication.New(init.arena.allocator(), &argc, argv);
    defer qapp.Delete();

    allocator = init.gpa;
    io = init.io;

    try std.Io.File.stdout().writeStreamingAll(init.io, "Looking up DNS info, please wait...");

    const dns = QDnsLookup.New2(qdnslookup_enums.Type.A, "google.com");

    dns.OnFinished(onFinished);
    dns.Lookup();

    _ = QCoreApplication.Exec();
}

fn onFinished(dns: QDnsLookup) callconv(.c) void {
    defer dns.DeleteLater();

    if (dns.Error() != qdnslookup_enums.Error.NoError) {
        const dns_error = dns.ErrorString(allocator);
        defer allocator.free(dns_error);

        const errorStr = std.fmt.allocPrint(allocator, "DNS lookup failed: {s}\n", .{dns_error}) catch @panic("Failed to allocPrint error(s)");
        defer allocator.free(errorStr);

        std.Io.File.stdout().writeStreamingAll(io, errorStr) catch @panic("Failed to write error(s)");
        return;
    }

    const results = dns.HostAddressRecords(allocator);
    defer allocator.free(results);

    const results_str = std.fmt.allocPrint(allocator, "Found {d} results.\n", .{results.len}) catch @panic("Failed to allocPrint results");
    defer allocator.free(results_str);

    std.Io.File.stdout().writeStreamingAll(io, results_str) catch @panic("Failed to write results");

    for (results) |result| {
        const value = result.Value();
        defer value.Delete();

        const record = value.ToString(allocator);
        defer allocator.free(record);

        const record_str = std.fmt.allocPrint(allocator, "- {s}\n", .{record}) catch @panic("Failed to allocPrint record(s)");
        defer allocator.free(record_str);

        std.Io.File.stdout().writeStreamingAll(io, record_str) catch @panic("Failed to write record(s)");
    }

    QCoreApplication.Exit();
}
