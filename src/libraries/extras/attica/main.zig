const std = @import("std");
const qt6 = @import("libqt6zig");
const qapplication = qt6.qapplication;
const attica__project = qt6.attica__project;
const qwidget = qt6.qwidget;
const qlabel = qt6.qlabel;
const qnamespace_enums = qt6.qnamespace_enums;
const qlineedit = qt6.qlineedit;
const qgridlayout = qt6.qgridlayout;

var gpa = @import("alloc_config").gpa;
const allocator = gpa.allocator();

pub fn main() void {
    const argc = std.os.argv.len;
    const argv = std.os.argv.ptr;
    const qapp = qapplication.New(argc, argv);
    defer qapplication.QDelete(qapp);

    defer _ = gpa.deinit();

    const project = attica__project.New();
    defer attica__project.QDelete(project);

    attica__project.SetDescription(project, "Qt 6 for Zig");
    attica__project.SetName(project, "libqt6zig");
    attica__project.SetVersion(project, "6.8.2");
    attica__project.SetUrl(project, "https://github.com/rcalixte/libqt6zig");
    attica__project.SetLicense(project, "MIT");

    const widget = qwidget.New2();
    defer qwidget.QDelete(widget);

    qwidget.SetWindowTitle(widget, "Qt 6 Example for Attica");
    qwidget.SetMinimumSize2(widget, 350, 250);

    const desc = qlabel.New3("Description:");
    qlabel.SetTextInteractionFlags(desc, qnamespace_enums.TextInteractionFlag.NoTextInteraction);
    const descText = attica__project.Description(project, allocator);
    defer allocator.free(descText);
    const descEdit = qlineedit.New3(descText);
    qlineedit.SetReadOnly(descEdit, true);

    const name = qlabel.New3("Name:");
    qlabel.SetTextInteractionFlags(name, qnamespace_enums.TextInteractionFlag.NoTextInteraction);
    const nameText = attica__project.Name(project, allocator);
    defer allocator.free(nameText);
    const nameEdit = qlineedit.New3(nameText);
    qlineedit.SetReadOnly(nameEdit, true);

    const version = qlabel.New3("Version:");
    qlabel.SetTextInteractionFlags(version, qnamespace_enums.TextInteractionFlag.NoTextInteraction);
    const versionText = attica__project.Version(project, allocator);
    defer allocator.free(versionText);
    const versionEdit = qlineedit.New3(versionText);
    qlineedit.SetReadOnly(versionEdit, true);

    const url = qlabel.New3("URL:");
    qlabel.SetTextInteractionFlags(url, qnamespace_enums.TextInteractionFlag.NoTextInteraction);
    const urlText = attica__project.Url(project, allocator);
    defer allocator.free(urlText);
    const urlEdit = qlineedit.New3(urlText);
    qlineedit.SetReadOnly(urlEdit, true);

    const lic = qlabel.New3("License:");
    qlabel.SetTextInteractionFlags(lic, qnamespace_enums.TextInteractionFlag.NoTextInteraction);
    const licText = attica__project.License(project, allocator);
    defer allocator.free(licText);
    const licEdit = qlineedit.New3(licText);
    qlineedit.SetReadOnly(licEdit, true);

    const layout = qgridlayout.New2();

    qgridlayout.AddWidget2(layout, desc, 0, 0);
    qgridlayout.AddWidget2(layout, descEdit, 0, 1);
    qgridlayout.AddWidget2(layout, name, 1, 0);
    qgridlayout.AddWidget2(layout, nameEdit, 1, 1);
    qgridlayout.AddWidget2(layout, version, 2, 0);
    qgridlayout.AddWidget2(layout, versionEdit, 2, 1);
    qgridlayout.AddWidget2(layout, url, 3, 0);
    qgridlayout.AddWidget2(layout, urlEdit, 3, 1);
    qgridlayout.AddWidget2(layout, lic, 4, 0);
    qgridlayout.AddWidget2(layout, licEdit, 4, 1);

    qwidget.SetLayout(widget, layout);
    qwidget.Show(widget);

    _ = qapplication.Exec();
}
