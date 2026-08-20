const std = @import("std");
const qt6 = @import("libqt6zig");
const QCoreApplication = qt6.QCoreApplication;
const QDnsLookup = qt6.QDnsLookup;
const qdnslookup_enums = qt6.qdnslookup_enums;

var allocator: std.mem.Allocator = undefined;
var io: std.Io = undefined;

pub fn main(init: std.process.Init) !u8 {
    const argv = try qt6.init(init.gpa, init.minimal.args);
    defer qt6.deinit(init.gpa, argv);
    var argc: i32 = @intCast(argv.len);
    const qapp: QCoreApplication = .new(init.arena.allocator(), &argc, argv);
    defer qapp.delete();

    allocator = init.gpa;
    io = init.io;

    try std.Io.File.stdout().writeStreamingAll(init.io, "Looking up DNS info, please wait...");

    const dns = QDnsLookup.new2(qdnslookup_enums.Type.A, "google.com");

    dns.onFinished(onFinished);
    dns.lookup();

    return @intCast(QCoreApplication.exec());
}

fn onFinished(dns: QDnsLookup) callconv(.c) void {
    defer dns.deleteLater();

    if (dns.error0() != qdnslookup_enums.Error.NoError) {
        const dns_error = dns.errorString(allocator);
        defer allocator.free(dns_error);

        const errorStr = std.fmt.allocPrint(allocator, "DNS lookup failed: {s}\n", .{dns_error}) catch
            @panic("Failed to allocPrint error(s)");
        defer allocator.free(errorStr);

        std.log.err("{s}", .{errorStr});
        QCoreApplication.exit1(dns.error0());
        return;
    }

    const results = dns.hostAddressRecords(allocator);
    defer allocator.free(results);

    const results_str = std.fmt.allocPrint(allocator, "Found {d} results.\n", .{results.len}) catch
        @panic("Failed to allocPrint results");
    defer allocator.free(results_str);

    std.Io.File.stdout().writeStreamingAll(io, results_str) catch
        @panic("Failed to write results");

    for (results) |result| {
        defer result.delete();

        const value = result.value();
        defer value.delete();

        const record = value.toString(allocator);
        defer allocator.free(record);

        const record_str = std.fmt.allocPrint(allocator, "- {s}\n", .{record}) catch
            @panic("Failed to allocPrint record(s)");
        defer allocator.free(record_str);

        std.Io.File.stdout().writeStreamingAll(io, record_str) catch
            @panic("Failed to write record(s)");
    }

    QCoreApplication.exit();
}
