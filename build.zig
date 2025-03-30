const std = @import("std");

pub fn build(b: *std.Build) !void {
    const target = b.standardTargetOptions(.{});
    const optimize = standardOptimizeOption(b, .{});
    const enable_workaround = b.option(bool, "enable-workaround", "Enable workaround for missing Qt C++ headers") orelse false;
    const skip_restricted = b.option(bool, "skip-restricted", "Skip restricted libraries") orelse false;

    const is_bsd_family = switch (target.result.os.tag) {
        .dragonfly, .freebsd, .netbsd, .openbsd => true,
        else => false,
    };

    var arena = std.heap.ArenaAllocator.init(b.allocator);
    defer arena.deinit();
    const allocator = arena.allocator();

    // Find all main.zig files
    var main_files: std.ArrayListUnmanaged(struct {
        dir: []const u8,
        path: []const u8,
        libraries: []const []const u8,
    }) = .empty;

    var dir = try std.fs.cwd().openDir(".", .{ .iterate = true });
    var walker = try dir.walk(b.allocator);
    defer walker.deinit();

    while (try walker.next()) |entry| {
        if (entry.kind == .file and std.mem.eql(u8, entry.basename, "main.zig")) {
            const parent_dir = std.fs.path.dirname(entry.path) orelse continue;
            const lib_path = try std.fs.path.join(allocator, &.{ parent_dir, "qtlibs" });
            const lib_file = try std.fs.cwd().openFile(lib_path, .{});
            defer lib_file.close();

            var lib_contents: std.ArrayListUnmanaged([]const u8) = .empty;
            while (try lib_file.reader().readUntilDelimiterOrEofAlloc(allocator, '\n', std.math.maxInt(usize))) |line| {
                if (std.mem.startsWith(u8, line, "#")) {
                    continue;
                }
                try lib_contents.append(allocator, try allocator.dupe(u8, line));
            }

            try main_files.append(allocator, .{
                .dir = try b.allocator.dupe(u8, parent_dir),
                .path = try b.allocator.dupe(u8, entry.path),
                .libraries = try lib_contents.toOwnedSlice(allocator),
            });
        }
    }

    if (main_files.items.len == 0)
        @panic("No main.zig files found.\n");

    // Qt system libraries to link
    var qt_libs: std.ArrayListUnmanaged([]const u8) = .empty;

    try qt_libs.appendSlice(allocator, &[_][]const u8{
        "Qt6Core",
        "Qt6Gui",
        "Qt6Widgets",
        "Qt6Multimedia",
        "Qt6MultimediaWidgets",
        "Qt6PrintSupport",
        "Qt6SvgWidgets",
        "Qt6WebEngineCore",
        "Qt6WebEngineWidgets",
    });

    if (!skip_restricted)
        try qt_libs.append(allocator, "qscintilla2_qt6");

    const qt6zig = b.dependency("libqt6zig", .{
        .target = target,
        .optimize = .ReleaseFast,
        .@"enable-workaround" = enable_workaround or is_bsd_family,
        .@"skip-restricted" = skip_restricted,
    });

    // Create an executable for each main.zig
    for (main_files.items) |main| {
        const exe_name = std.fs.path.basename(main.dir);

        if (skip_restricted and std.mem.eql(u8, exe_name, "qscintilla"))
            continue;

        const exe = b.addExecutable(.{
            .name = exe_name,
            .root_module = b.createModule(.{
                .root_source_file = b.path(main.path),
                .target = target,
                .optimize = optimize,
            }),
        });

        exe.root_module.addImport("libqt6zig", qt6zig.module("libqt6zig"));

        // Link Qt system libraries
        if (is_bsd_family)
            exe.root_module.addLibraryPath(std.Build.LazyPath{ .cwd_relative = "/usr/local/lib/qt6" });

        for (qt_libs.items) |lib| {
            exe.root_module.linkSystemLibrary(lib, .{});
        }

        // Link libqt6zig static libraries
        for (main.libraries) |lib| {
            exe.root_module.linkLibrary(qt6zig.artifact(lib));
        }

        // Install the executable
        b.installArtifact(exe);

        // Create a run step
        const exe_install = b.addInstallArtifact(exe, .{});
        const run_cmd = b.addRunArtifact(exe);
        run_cmd.step.dependOn(&exe_install.step);

        const run_description = try std.fmt.allocPrint(allocator, "Run the {s} example", .{exe_name});

        const run_step = b.step(exe_name, run_description);
        run_step.dependOn(&run_cmd.step);
    }
}

fn standardOptimizeOption(b: *std.Build, options: std.Build.StandardOptimizeOptionOptions) std.builtin.OptimizeMode {
    if (options.preferred_optimize_mode) |mode| {
        checkSupportedMode(mode);
        if (b.option(bool, "release", "optimize for end users") orelse (b.release_mode != .off)) {
            return mode;
        } else {
            return .ReleaseFast;
        }
    }

    if (b.option(
        std.builtin.OptimizeMode,
        "optimize",
        "Prioritize performance, safety, or binary size",
    )) |mode| {
        checkSupportedMode(mode);
        return mode;
    }

    return switch (b.release_mode) {
        .off, .any, .fast => .ReleaseFast,
        .safe => .ReleaseSafe,
        .small => .ReleaseSmall,
    };
}

fn checkSupportedMode(mode: std.builtin.OptimizeMode) void {
    if (mode == .Debug) {
        std.debug.print("libqt6zig-examples does not support Debug build mode.\n", .{});
        std.process.exit(1);
    }
}
