const std = @import("std");
const host_os = @import("builtin").os.tag;

var buffer: [1024]u8 = undefined;
var disabled_paths: std.ArrayList([]const u8) = .empty;
var system_libs: std.ArrayList([]const u8) = .{ .items = &base_libs };

var base_libs = [_][]const u8{
    "Qt6Core",
    "Qt6Gui",
    "Qt6Widgets",
};

var main_files: std.ArrayList(struct {
    dir: []const u8,
    path: []const u8,
    qt_libraries: []const []const u8,
    sys_libraries: []const []const u8,
}) = .empty;

pub fn build(b: *std.Build) !void {
    const target = b.standardTargetOptions(.{});
    const extra_paths = b.option([]const []const u8, "extra-paths", "Extra library header and include search paths") orelse &.{};

    var optimize = b.standardOptimizeOption(.{});
    if (optimize == .Debug) optimize = .ReleaseFast;

    const is_macos = target.result.os.tag == .macos or host_os == .macos;
    const is_windows = target.result.os.tag == .windows or host_os == .windows;

    var arena = std.heap.ArenaAllocator.init(b.allocator);
    defer arena.deinit();
    const allocator = arena.allocator();

    // Find all main.zig files
    const src_dir = try std.fs.path.join(allocator, &.{ b.build_root.path.?, "src" });
    var dir = try std.fs.cwd().openDir(src_dir, .{ .iterate = true });
    defer dir.close();
    var walker = try dir.walk(b.allocator);
    defer walker.deinit();

    while (try walker.next()) |entry| {
        if (entry.kind == .file and std.mem.eql(u8, entry.basename, "main.zig")) {
            const parent_dir = std.fs.path.dirname(entry.path) orelse continue;
            const qtlibs_path = try std.fs.path.join(allocator, &.{ "src", parent_dir, "qtlibs" });
            var qtlibs_file = try std.fs.cwd().openFile(qtlibs_path, .{});
            defer qtlibs_file.close();
            var qtlibs_file_reader = qtlibs_file.reader(&buffer);

            var qtlibs_contents: std.ArrayList([]const u8) = .empty;
            while (qtlibs_file_reader.interface.takeDelimiterInclusive('\n')) |line| {
                if (std.mem.startsWith(u8, line, "#"))
                    continue;

                const lib_name = std.mem.trimRight(u8, line, "\n");
                try qtlibs_contents.append(allocator, try allocator.dupe(u8, lib_name));
            } else |err| {
                if (!qtlibs_file_reader.atEnd()) return err;
            }

            const syslibs_path = try std.fs.path.join(allocator, &.{ "src", parent_dir, "syslibs" });
            const syslibs_file = std.fs.cwd().openFile(syslibs_path, .{}) catch null;
            var syslibs_contents: std.ArrayList([]const u8) = .empty;

            if (syslibs_file) |syslib_file| {
                defer syslib_file.close();
                var syslibs_file_reader = syslib_file.reader(&buffer);

                while (syslibs_file_reader.interface.takeDelimiterInclusive('\n')) |line| {
                    if (std.mem.startsWith(u8, line, "#"))
                        continue;

                    const lib_name = std.mem.trimRight(u8, line, "\n");
                    try syslibs_contents.append(allocator, try allocator.dupe(u8, lib_name));
                } else |err| {
                    if (!syslibs_file_reader.atEnd()) return err;
                }
            }

            try main_files.append(allocator, .{
                .dir = try b.allocator.dupe(u8, parent_dir),
                .path = try std.fs.path.join(allocator, &.{ "src", entry.path }),
                .qt_libraries = try qtlibs_contents.toOwnedSlice(allocator),
                .sys_libraries = try syslibs_contents.toOwnedSlice(allocator),
            });
        } else if (entry.kind == .directory) {
            const is_special_dir = for (special_dirs) |dir_name| {
                if (std.mem.containsAtLeast(u8, entry.path, 1, dir_name)) break true;
            } else false;

            if (!is_special_dir) continue;

            var path_it = std.mem.splitScalar(u8, entry.path, '/');
            _ = path_it.first();
            const prefix = path_it.next().?;

            const name = while (path_it.next()) |name| {
                if (path_it.peek() == null) break name;
            } else continue;

            const option_name = try std.mem.concat(allocator, u8, &.{ "enable-", name });
            const option_description = try std.mem.concat(allocator, u8, &.{ "Enable ", name, " library example" });
            var is_supported = true;
            if (is_windows and (std.mem.startsWith(u8, prefix, "foss-") or std.mem.startsWith(u8, prefix, "posix-"))) {
                is_supported = false;
                try disabled_paths.append(allocator, "foss-");
                try disabled_paths.append(allocator, "posix-");
            }
            if (is_macos and std.mem.startsWith(u8, prefix, "foss-")) {
                is_supported = false;
                try disabled_paths.append(allocator, "foss-");
            }

            var is_enabled = true;
            if ((host_os == .macos or host_os == .windows) and std.mem.eql(u8, prefix, "extras")) {
                is_enabled = false;
            }
            if (host_os == .macos and std.mem.eql(u8, prefix, "posix-"))
                is_enabled = false;
            const option_value = b.option(bool, option_name, option_description);
            const result_value = (if (option_value == null) is_enabled else option_value.?) and is_supported;

            if (!result_value) {
                const path = try std.mem.concat(allocator, u8, &.{ "/", name });
                try disabled_paths.append(allocator, path);
            }
        }
    }

    std.debug.assert(main_files.items.len != 0);

    const qt6zig = b.dependency("libqt6zig", .{
        .target = target,
        .optimize = optimize,
        .@"extra-paths" = extra_paths,
    });

    // Create a module for the centralized custom allocator configuration
    const alloc_config = b.addModule("alloc_config", .{
        .root_source_file = b.path("src/alloc_config.zig"),
    });

    const run_all_step = b.step("run", "Build and run all of the examples");

    // Create an executable for each main.zig
    main_loop: for (main_files.items) |main| {
        const exe_name = std.fs.path.basename(main.dir);

        for (disabled_paths.items) |disabled_path| {
            if (std.mem.containsAtLeast(u8, main.dir, 1, disabled_path)) {
                continue :main_loop;
            }
        }

        const exe = b.addExecutable(.{
            .name = exe_name,
            .root_module = b.createModule(.{
                .root_source_file = b.path(main.path),
                .target = target,
                .optimize = optimize,
            }),
        });

        exe.root_module.addImport("libqt6zig", qt6zig.module("libqt6zig"));
        exe.root_module.addImport("alloc_config", alloc_config);

        // Link Qt system libraries
        if (is_bsd_host)
            exe.root_module.addLibraryPath(std.Build.LazyPath{ .cwd_relative = "/usr/local/lib/qt6" });

        for (extra_paths) |path| {
            std.fs.cwd().access(path, .{}) catch {
                continue;
            };
            exe.root_module.addLibraryPath(std.Build.LazyPath{ .cwd_relative = b.dupe(path) });
        }

        for (system_libs.items) |lib| {
            exe.root_module.linkSystemLibrary(lib, .{});
        }

        for (main.sys_libraries) |lib| {
            exe.root_module.linkSystemLibrary(lib, .{});
        }

        // Link libqt6zig static libraries
        for (main.qt_libraries) |lib| {
            exe.root_module.linkLibrary(qt6zig.artifact(lib));
        }

        // Install the executable
        b.installArtifact(exe);

        // Create a run step
        const exe_install = b.addInstallArtifact(exe, .{});
        const run_cmd = b.addRunArtifact(exe);
        run_cmd.step.dependOn(&exe_install.step);

        const run_description = b.fmt("Build and run the {s} example", .{exe_name});

        const run_step = b.step(exe_name, run_description);
        run_step.dependOn(&run_cmd.step);
        run_all_step.dependOn(&run_cmd.step);
    }
}

const is_bsd_host = switch (host_os) {
    .dragonfly, .freebsd, .netbsd, .openbsd => true,
    else => false,
};

const special_dirs = [_][]const u8{
    "/extras/",
    "/foss-extras/",
    "/foss-restricted/",
    "/posix-extras/",
    "/posix-restricted/",
    "/restricted-extras/",
};
