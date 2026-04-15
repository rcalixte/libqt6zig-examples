const std = @import("std");
const qt6 = @import("libqt6zig");
const qapplication = qt6.qapplication;
const attica__project = qt6.attica__project;
const qwidget = qt6.qwidget;
const qlabel = qt6.qlabel;
const qnamespace_enums = qt6.qnamespace_enums;
const qlineedit = qt6.qlineedit;
const qgridlayout = qt6.qgridlayout;

pub fn main(init: std.process.Init) !void {
    const argv = try qt6.init(init.gpa, init.minimal.args);
    defer qt6.deinit(init.gpa, argv);
    var argc: i32 = @intCast(argv.len);
    const qapp = qapplication.New(&argc, argv, init.arena.allocator());
    defer qapplication.Delete(qapp);

    const project = attica__project.New();
    defer attica__project.Delete(project);

    attica__project.SetDescription(project, "Qt 6 for Zig");
    attica__project.SetName(project, "libqt6zig");
    attica__project.SetVersion(project, "6.8.2");
    attica__project.SetUrl(project, "https://github.com/rcalixte/libqt6zig");
    attica__project.SetLicense(project, "MIT");

    const widget = qwidget.New2();
    defer qwidget.Delete(widget);

    qwidget.SetWindowTitle(widget, "Qt 6 Example for Attica");
    qwidget.SetMinimumSize2(widget, 350, 250);

    const desc = qlabel.New3("Description:");
    qlabel.SetTextInteractionFlags(desc, qnamespace_enums.TextInteractionFlag.NoTextInteraction);
    const desc_text = attica__project.Description(project, init.gpa);
    defer init.gpa.free(desc_text);
    const desc_edit = qlineedit.New3(desc_text);
    qlineedit.SetReadOnly(desc_edit, true);

    const name = qlabel.New3("Name:");
    qlabel.SetTextInteractionFlags(name, qnamespace_enums.TextInteractionFlag.NoTextInteraction);
    const name_text = attica__project.Name(project, init.gpa);
    defer init.gpa.free(name_text);
    const name_edit = qlineedit.New3(name_text);
    qlineedit.SetReadOnly(name_edit, true);

    const version = qlabel.New3("Version:");
    qlabel.SetTextInteractionFlags(version, qnamespace_enums.TextInteractionFlag.NoTextInteraction);
    const version_text = attica__project.Version(project, init.gpa);
    defer init.gpa.free(version_text);
    const version_edit = qlineedit.New3(version_text);
    qlineedit.SetReadOnly(version_edit, true);

    const url = qlabel.New3("URL:");
    qlabel.SetTextInteractionFlags(url, qnamespace_enums.TextInteractionFlag.NoTextInteraction);
    const url_text = attica__project.Url(project, init.gpa);
    defer init.gpa.free(url_text);
    const url_edit = qlineedit.New3(url_text);
    qlineedit.SetReadOnly(url_edit, true);

    const lic = qlabel.New3("License:");
    qlabel.SetTextInteractionFlags(lic, qnamespace_enums.TextInteractionFlag.NoTextInteraction);
    const lic_text = attica__project.License(project, init.gpa);
    defer init.gpa.free(lic_text);
    const lic_edit = qlineedit.New3(lic_text);
    qlineedit.SetReadOnly(lic_edit, true);

    const layout = qgridlayout.New2();

    qgridlayout.AddWidget2(layout, desc, 0, 0);
    qgridlayout.AddWidget2(layout, desc_edit, 0, 1);
    qgridlayout.AddWidget2(layout, name, 1, 0);
    qgridlayout.AddWidget2(layout, name_edit, 1, 1);
    qgridlayout.AddWidget2(layout, version, 2, 0);
    qgridlayout.AddWidget2(layout, version_edit, 2, 1);
    qgridlayout.AddWidget2(layout, url, 3, 0);
    qgridlayout.AddWidget2(layout, url_edit, 3, 1);
    qgridlayout.AddWidget2(layout, lic, 4, 0);
    qgridlayout.AddWidget2(layout, lic_edit, 4, 1);

    qwidget.SetLayout(widget, layout);
    qwidget.Show(widget);

    _ = qapplication.Exec();
}
