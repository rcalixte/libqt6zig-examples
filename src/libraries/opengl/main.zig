const std = @import("std");
const qt6 = @import("libqt6zig");
const QApplication = qt6.QApplication;
const QMainWindow = qt6.QMainWindow;
const QOpenGLWidget = qt6.QOpenGLWidget;
const QOpenGLContext = qt6.QOpenGLContext;
const QOpenGLExtraFunctions = qt6.QOpenGLExtraFunctions;

var glfuncs: QOpenGLExtraFunctions = undefined;

pub fn main(init: std.process.Init) !void {
    const argv = try qt6.init(init.gpa, init.minimal.args);
    defer qt6.deinit(init.gpa, argv);
    var argc: i32 = @intCast(argv.len);
    const qapp = QApplication.New(init.arena.allocator(), &argc, argv);
    defer qapp.Delete();

    const window = QMainWindow.New2();
    defer window.Delete();

    window.SetWindowTitle("Qt 6 OpenGL Example");
    window.SetMinimumSize2(400, 400);

    const glwidget = QOpenGLWidget.New2();

    glwidget.OnInitializeGL(initializeGL);
    glwidget.OnResizeGL(resizeGL);

    window.SetCentralWidget(glwidget);

    window.Show();

    _ = QApplication.Exec();
}

fn initializeGL() callconv(.c) void {
    glfuncs = QOpenGLContext.CurrentContext().ExtraFunctions();

    glfuncs.InitializeOpenGLFunctions();
    glfuncs.GlClearColor(0.92, 0.57, 0.36, 1);
}

fn resizeGL(_: QOpenGLWidget, width: i32, height: i32) callconv(.c) void {
    glfuncs.GlViewport(0, 0, width, height);
}
