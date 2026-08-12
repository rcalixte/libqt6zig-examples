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
    const qapp: QApplication = .new(init.arena.allocator(), &argc, argv);
    defer qapp.delete();

    const window = QMainWindow.new2();
    defer window.delete();

    window.setWindowTitle("Qt 6 OpenGL Example");
    window.setMinimumSize2(400, 400);

    const glwidget = QOpenGLWidget.new2();

    glwidget.onInitializeGL(initializeGL);
    glwidget.onResizeGL(resizeGL);

    window.setCentralWidget(glwidget);

    window.show();

    _ = QApplication.exec();
}

fn initializeGL() callconv(.c) void {
    glfuncs = QOpenGLContext.currentContext().extraFunctions();

    glfuncs.initializeOpenGLFunctions();
    glfuncs.glClearColor(0.92, 0.57, 0.36, 1);
}

fn resizeGL(_: QOpenGLWidget, width: i32, height: i32) callconv(.c) void {
    glfuncs.glViewport(0, 0, width, height);
}
