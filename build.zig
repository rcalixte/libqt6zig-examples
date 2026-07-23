const std = @import("std");
const host_os = @import("builtin").target.os.tag;

const configureQtExeRootModule = @import("libqt6zig").configureQtExeRootModule;

var buffer: [1024]u8 = undefined;
var disabled_paths: std.ArrayList([]const u8) = .empty;

var main_files: std.ArrayList(struct {
    dir: []const u8,
    path: []const u8,
    qt_libraries: []const []const u8,
    sys_libraries: []const []const u8,
    win_gui: bool,
}) = .empty;

pub fn build(b: *std.Build) !void {
    const optimize = b.standardOptimizeOption(.{});
    const target = b.standardTargetOptions(.{});
    const extra_paths = b.option([]const []const u8, "extra-paths", "Extra library header and include search paths") orelse &.{};

    const is_macos = target.result.os.tag == .macos or host_os == .macos;
    const is_windows = target.result.os.tag == .windows or host_os == .windows;

    var qt_dir: []const u8 = "";
    if (is_windows) {
        qt_dir = b.option([]const u8, "QTDIR", "The directory where Qt is installed") orelse win_root;
        std.Io.Dir.cwd().access(b.graph.io, qt_dir, .{}) catch {
            std.log.err("QTDIR '{s}' does not exist\n", .{qt_dir});
            return error.QTDIRNotFound;
        };
    }

    // Find all main.zig files
    var dir = try b.build_root.handle.openDir(b.graph.io, "src", .{ .iterate = true });
    defer dir.close(b.graph.io);

    var walker = try dir.walk(b.allocator);
    defer walker.deinit();

    var ok = true;
    var macos_syslibs: std.ArrayList([]const u8) = .empty;
    var macos_exelibs: std.ArrayList([]const u8) = .empty;

    while (try walker.next(b.graph.io)) |entry|
        if (entry.kind == .file and std.mem.eql(u8, entry.basename, "main.zig")) {
            if (!ok) continue;
            const parent_dir = std.Io.Dir.path.dirname(entry.path) orelse continue;
            if (is_windows and (std.mem.containsAtLeast(u8, parent_dir, 2, "\\") or
                std.mem.containsAtLeast(u8, parent_dir, 1, "webengine"))) continue;
            const qtlibs_path = b.fmt("{s}/{s}/{s}", .{ "src", parent_dir, "qtlibs" });
            var qtlibs_file = try b.build_root.handle.openFile(b.graph.io, qtlibs_path, .{});
            defer qtlibs_file.close(b.graph.io);

            var contents = try std.Io.Dir.cwd().readFileAlloc(b.graph.io, qtlibs_path, b.allocator, .unlimited);
            var qtlibs_contents: std.ArrayList([]const u8) = .empty;

            var it = std.mem.tokenizeAny(u8, contents, "\r\n");
            while (it.next()) |line| {
                if (std.mem.startsWith(u8, line, "#"))
                    continue;
                try qtlibs_contents.append(b.allocator, line);
            }

            const syslibs_path = b.fmt("{s}/{s}/{s}", .{ "src", parent_dir, "syslibs" });
            const syslibs_file = b.build_root.handle.openFile(b.graph.io, syslibs_path, .{}) catch null;
            const macos_syslibs_path = b.fmt("{s}/{s}/{s}", .{ "src", parent_dir, "osx_syslibs" });
            var macos_syslibs_file: ?std.Io.File = null;
            if (is_macos)
                macos_syslibs_file = b.build_root.handle.openFile(b.graph.io, macos_syslibs_path, .{}) catch null;
            var syslibs_contents: std.ArrayList([]const u8) = .empty;

            if (syslibs_file) |syslib_file| {
                defer syslib_file.close(b.graph.io);

                contents = try std.Io.Dir.cwd().readFileAlloc(b.graph.io, syslibs_path, b.allocator, .unlimited);
                it = std.mem.tokenizeAny(u8, contents, "\r\n");
                while (it.next()) |line| {
                    if (std.mem.startsWith(u8, line, "#"))
                        continue;
                    if (is_macos and std.mem.startsWith(u8, line, "Q"))
                        try macos_syslibs.append(b.allocator, line)
                    else
                        try syslibs_contents.append(b.allocator, line);
                }
            }

            if (is_macos) if (macos_syslibs_file) |syslib_file| {
                defer syslib_file.close(b.graph.io);

                contents = try std.Io.Dir.cwd().readFileAlloc(b.graph.io, macos_syslibs_path, b.allocator, .unlimited);
                it = std.mem.tokenizeAny(u8, contents, "\r\n");
                while (it.next()) |line| {
                    if (std.mem.startsWith(u8, line, "#"))
                        continue;
                    try macos_exelibs.append(b.allocator, line);
                }
            };

            var win_gui = true;

            if (is_windows) {
                const screenshot_file = b.fmt("{s}/{s}/{s}", .{ "src", parent_dir, "screenshot.png" });
                b.build_root.handle.access(b.graph.io, screenshot_file, .{}) catch {
                    win_gui = false;
                };
            }

            try main_files.append(b.allocator, .{
                .dir = b.dupe(parent_dir),
                .path = b.fmt("{s}/{s}", .{ "src", entry.path }),
                .qt_libraries = try qtlibs_contents.toOwnedSlice(b.allocator),
                .sys_libraries = try syslibs_contents.toOwnedSlice(b.allocator),
                .win_gui = win_gui,
            });
        } else if (entry.kind == .directory) {
            for (special_dirs) |dir_name| {
                if (std.mem.containsAtLeast(u8, entry.path, 1, dir_name)) break;
            } else {
                ok = true;
                continue;
            }

            var path_it = std.mem.splitScalar(u8, entry.path, '/');
            _ = path_it.first();
            const prefix = path_it.next().?;

            const name = while (path_it.next()) |name| {
                if (path_it.peek() == null) break name;
            } else continue;

            var is_supported = true;
            if (is_windows and (std.mem.startsWith(u8, prefix, "foss-") or std.mem.startsWith(u8, prefix, "posix-"))) {
                is_supported = false;
                try disabled_paths.append(b.allocator, "foss-");
                try disabled_paths.append(b.allocator, "posix-");
            }
            if (is_macos and std.mem.startsWith(u8, prefix, "foss-")) {
                is_supported = false;
                try disabled_paths.append(b.allocator, "foss-");
            }

            var is_enabled = true;
            if ((host_os == .macos or host_os == .windows) and (std.mem.eql(u8, prefix, "extras") or std.mem.eql(u8, prefix, "restricted-extras")))
                is_enabled = false;
            if (host_os == .macos and std.mem.startsWith(u8, prefix, "posix-"))
                is_enabled = false;

            const option_value = opt: switch (is_supported) {
                true => {
                    const option_name = b.fmt("enable-{s}", .{name});
                    const option_description = b.fmt("Enable {s} example", .{name});
                    break :opt b.option(bool, option_name, option_description);
                },
                false => null,
            };

            ok = is_supported and if (option_value) |option| option else is_enabled;

            if (!ok)
                try disabled_paths.append(b.allocator, b.fmt("/{s}", .{name}));
        };

    std.debug.assert(main_files.items.len != 0);

    const qt6zig = b.dependency("libqt6zig", .{
        .target = target,
        .optimize = optimize,
        .@"extra-paths" = extra_paths,
        .@"macos-libraries" = try macos_syslibs.toOwnedSlice(b.allocator),
    });

    const run_all_step = b.step("run", "Build and run all of the examples");

    const win_sys_libs: []const []const u8 = if (is_windows) &.{
        "avcodec-61",
        "avformat-61",
        "avutil-59",
        "libc++",
        "libunwind",
        "opengl32sw",
        "swresample-5",
        "swscale-8",
    } else &.{};

    // Create an executable for each main.zig
    main_loop: for (main_files.items) |main| {
        const exe_name = std.Io.Dir.path.basename(main.dir);

        for (disabled_paths.items) |disabled_path|
            if (std.mem.containsAtLeast(u8, main.dir, 1, disabled_path))
                continue :main_loop;

        const exe = b.addExecutable(.{
            .name = exe_name,
            .root_module = b.createModule(.{
                .root_source_file = b.path(main.path),
                .target = target,
                .optimize = optimize,
                .link_libc = true,
            }),
        });

        exe.root_module.addImport("libqt6zig", qt6zig.module("libqt6zig"));

        if (is_windows and main.win_gui) exe.subsystem = .windows;

        for (main.sys_libraries) |lib|
            if (is_macos and std.mem.startsWith(u8, lib, "Q"))
                exe.root_module.linkFramework(lib, .{})
            else
                exe.root_module.linkSystemLibrary(lib, .{});

        // Link libqt6zig static libraries
        for (main.qt_libraries) |lib|
            exe.root_module.linkLibrary(qt6zig.artifact(lib));

        // Create a run step
        const exe_install = b.addInstallArtifact(exe, .{});
        const run_cmd = b.addRunArtifact(exe);
        run_cmd.step.dependOn(&exe_install.step);

        const run_description = b.fmt("Build and run the {s} example", .{exe_name});

        const run_step = b.step(exe_name, run_description);
        run_step.dependOn(&run_cmd.step);
        run_all_step.dependOn(&run_cmd.step);

        var win_steps = [_]*std.Build.Step{&run_cmd.step};
        var win_libs: std.ArrayList([]const u8) = .empty;
        if (is_windows) {
            try win_libs.ensureTotalCapacityPrecise(b.allocator, main.sys_libraries.len + win_sys_libs.len);
            for (win_sys_libs) |lib|
                win_libs.appendAssumeCapacity(lib);
            for (main.sys_libraries) |lib|
                win_libs.appendAssumeCapacity(lib);
        }

        // Configure Qt system libraries
        try configureQtExeRootModule(b, exe, .{
            .extra_paths = extra_paths,
            .macos_libraries = macos_exelibs.items,
            .win_libs = if (is_windows) win_libs.items else &.{},
            .win_qt_dir = qt_dir,
            .win_root = qt_dir,
            .win_steps = if (is_windows) &win_steps else &.{},
        });

        // Install the executable
        b.installArtifact(exe);
    }
}

const win_root = "C:/Qt/6.8.3/llvm-mingw_64";

const special_dirs = [_][]const u8{
    "/extras/",
    "/foss-extras/",
    "/foss-restricted/",
    "/posix-extras/",
    "/posix-restricted/",
    "/restricted-extras/",
};
