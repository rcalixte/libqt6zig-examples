const std = @import("std");
const qt6 = @import("libqt6zig");
const C = qt6.C;
const qapplication = qt6.qapplication;
const qmainwindow = qt6.qmainwindow;
const qopenglwidget = qt6.qopenglwidget;
const qopenglcontext = qt6.qopenglcontext;
const qopenglextrafunctions = qt6.qopenglextrafunctions;

var glfuncs: C.QOpenGLExtraFunctions = null;

pub fn main(init: std.process.Init) !void {
    const argv = try qt6.init(init.gpa, init.minimal.args);
    defer qt6.deinit(init.gpa, argv);
    var argc: i32 = @intCast(argv.len);
    const qapp = qapplication.New(&argc, argv, init.arena.allocator());
    defer qapplication.Delete(qapp);

    const window = qmainwindow.New2();
    defer qmainwindow.Delete(window);

    qmainwindow.SetWindowTitle(window, "Qt 6 OpenGL Example");
    qmainwindow.SetMinimumSize2(window, 400, 400);

    const glwidget = qopenglwidget.New2();

    qopenglwidget.OnInitializeGL(glwidget, initializeGL);
    qopenglwidget.OnResizeGL(glwidget, resizeGL);

    qmainwindow.SetCentralWidget(window, glwidget);

    qmainwindow.Show(window);

    _ = qapplication.Exec();
}

fn initializeGL() callconv(.c) void {
    glfuncs = qopenglcontext.ExtraFunctions(qopenglcontext.CurrentContext());

    qopenglextrafunctions.InitializeOpenGLFunctions(glfuncs);
    qopenglextrafunctions.GlClearColor(glfuncs, 0.92, 0.57, 0.36, 1.0);
}

fn resizeGL(_: ?*anyopaque, width: i32, height: i32) callconv(.c) void {
    qopenglextrafunctions.GlViewport(glfuncs, 0, 0, width, height);
}
