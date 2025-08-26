const std = @import("std");
const host_os = @import("builtin").os.tag;
const stdout = std.io.getStdOut().writer();

const ExtraLibrary = struct {
    name: []const u8,
    libraries: []const []const u8,
    prefix: []const u8,
};

// Define the extra libraries
const extra_libraries = [_]ExtraLibrary{
    .{
        .name = "kcodecs",
        .libraries = &.{"KF6Codecs"},
        .prefix = "extras",
    },
    .{
        .name = "kconfig",
        .libraries = &.{ "KF6ConfigCore", "KF6ConfigGui", "KF6ConfigWidgets" },
        .prefix = "extras",
    },
    .{
        .name = "kcoreaddons",
        .libraries = &.{"KF6CoreAddons"},
        .prefix = "extras",
    },
    .{
        .name = "ki18n",
        .libraries = &.{ "KF6I18n", "KF6I18nLocaleData" },
        .prefix = "extras",
    },
    .{
        .name = "kitemviews",
        .libraries = &.{"KF6ItemViews"},
        .prefix = "extras",
    },
    .{
        .name = "kwidgetsaddons",
        .libraries = &.{"KF6WidgetsAddons"},
        .prefix = "extras",
    },
    .{
        .name = "qtermwidget",
        .libraries = &.{"qtermwidget6"},
        .prefix = "posix-restricted-extras",
    },
    .{
        .name = "charts",
        .libraries = &.{"Qt6Charts"},
        .prefix = "restricted-extras",
    },
    .{
        .name = "qscintilla",
        .libraries = &.{"qscintilla2_qt6"},
        .prefix = "restricted-extras",
    },
};

pub fn build(b: *std.Build) !void {
    const target = b.standardTargetOptions(.{});
    const optimize = standardOptimizeOption(b, .{});
    const enable_workaround = b.option(bool, "enable-workaround", "Enable workaround for missing Qt C++ headers") orelse false;

    const is_macos = target.result.os.tag == .macos or host_os == .macos;
    const is_windows = target.result.os.tag == .windows or host_os == .windows;

    const is_bsd_host = switch (host_os) {
        .dragonfly, .freebsd, .netbsd, .openbsd => true,
        else => false,
    };

    const is_bsd_target = switch (target.result.os.tag) {
        .dragonfly, .freebsd, .netbsd, .openbsd => true,
        else => false,
    };

    const is_bsd_family = is_bsd_host or is_bsd_target;

    var arena = std.heap.ArenaAllocator.init(b.allocator);
    defer arena.deinit();
    const allocator = arena.allocator();

    var disabled_paths: std.ArrayListUnmanaged([]const u8) = .empty;

    // System libraries to link
    var system_libs: std.ArrayListUnmanaged([]const u8) = .empty;

    try system_libs.appendSlice(allocator, &[_][]const u8{
        "Qt6Core",
        "Qt6Gui",
        "Qt6Widgets",
        "Qt6Multimedia",
        "Qt6MultimediaWidgets",
        "Qt6Network",
        "Qt6Pdf",
        "Qt6PdfWidgets",
        "Qt6PrintSupport",
        "Qt6Sql",
        "Qt6SvgWidgets",
        "Qt6WebEngineCore",
        "Qt6WebEngineWidgets",
    });

    // If applicable, determine valid build target paths and append the dependent libraries
    inline for (extra_libraries) |extra_lib| {
        const option_name = try std.mem.concat(allocator, u8, &.{ "enable-", extra_lib.name });
        const option_description = try std.mem.concat(allocator, u8, &.{ "Enable ", extra_lib.name, " library" });
        var is_supported = true;
        if (is_windows and (std.mem.startsWith(u8, extra_lib.prefix, "foss-") or std.mem.startsWith(u8, extra_lib.prefix, "posix-"))) {
            is_supported = false;
            try disabled_paths.append(allocator, "foss-");
            try disabled_paths.append(allocator, "posix-");
        }
        if (is_macos and std.mem.startsWith(u8, extra_lib.prefix, "foss-")) {
            is_supported = false;
            try disabled_paths.append(allocator, "foss-");
        }

        var is_enabled = true;
        if ((host_os == .macos or host_os == .windows) and std.mem.eql(u8, extra_lib.prefix, "extras")) {
            is_enabled = false;
        }
        if (host_os == .macos and std.mem.eql(u8, extra_lib.prefix, "posix-"))
            is_enabled = false;
        const option_value = b.option(bool, option_name, option_description);
        const result_value = (if (option_value == null) is_enabled else option_value.?) and is_supported;

        if (result_value) {
            inline for (extra_lib.libraries) |lib| {
                try system_libs.append(allocator, lib);
            }
        } else {
            const path = try std.mem.concat(allocator, u8, &.{ extra_lib.prefix, "/", extra_lib.name });
            try disabled_paths.append(allocator, path);
        }
    }

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
                if (std.mem.startsWith(u8, line, "#"))
                    continue;

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

    var qt_win_paths: std.ArrayListUnmanaged([]const u8) = .empty;

    if (host_os == .windows) {
        const qt_win_versions = &.{
            "6.8.2",
            "6.9.1",
        };

        const win_compilers = &.{
            "mingw_64",
            "msvc2022_64",
        };

        inline for (qt_win_versions) |ver| {
            inline for (win_compilers) |wc| {
                try qt_win_paths.append(allocator, "C:/Qt/" ++ ver ++ "/" ++ wc ++ "/lib");
            }
        }
    }

    const qt6zig = b.dependency("libqt6zig", .{
        .target = target,
        .optimize = optimize,
        .@"enable-workaround" = enable_workaround or is_bsd_family or is_macos,
    });

    // Create a module for the centralized custom allocator configuration
    const alloc_config = b.addModule("alloc_config", .{
        .root_source_file = b.path("src/alloc_config.zig"),
    });

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

        if (host_os == .windows) {
            for (qt_win_paths.items) |path| {
                exe.root_module.addLibraryPath(std.Build.LazyPath{ .cwd_relative = path });
            }
        }

        for (system_libs.items) |lib| {
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

        const run_description = b.fmt("Build and run the {s} example", .{exe_name});

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
        stdout.print("libqt6zig-examples does not support Debug build mode.\n", .{}) catch @panic("Failed to print to stdout");
        std.process.exit(1);
    }
}
