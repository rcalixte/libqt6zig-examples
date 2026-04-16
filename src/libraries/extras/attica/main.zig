const std = @import("std");
const qt6 = @import("libqt6zig");
const QApplication = qt6.QApplication;
const Attica__Project = qt6.Attica__Project;
const QWidget = qt6.QWidget;
const QLabel = qt6.QLabel;
const qnamespace_enums = qt6.qnamespace_enums;
const QLineEdit = qt6.QLineEdit;
const QGridLayout = qt6.QGridLayout;

pub fn main(init: std.process.Init) !void {
    const argv = try qt6.init(init.gpa, init.minimal.args);
    defer qt6.deinit(init.gpa, argv);
    var argc: i32 = @intCast(argv.len);
    const qapp = QApplication.New(init.arena.allocator(), &argc, argv);
    defer qapp.Delete();

    const project = Attica__Project.New();
    defer project.Delete();

    project.SetDescription("Qt 6 for Zig");
    project.SetName("libqt6zig");
    project.SetVersion("6.8.2");
    project.SetUrl("https://github.com/rcalixte/libqt6zig");
    project.SetLicense("MIT");

    const widget = QWidget.New2();
    defer widget.Delete();

    widget.SetWindowTitle("Qt 6 Attica Example");
    widget.SetMinimumSize2(350, 250);

    const desc = QLabel.New3("Description:");
    desc.SetTextInteractionFlags(qnamespace_enums.TextInteractionFlag.NoTextInteraction);
    const desc_text = project.Description(init.gpa);
    defer init.gpa.free(desc_text);
    const desc_edit = QLineEdit.New3(desc_text);
    desc_edit.SetReadOnly(true);

    const name = QLabel.New3("Name:");
    name.SetTextInteractionFlags(qnamespace_enums.TextInteractionFlag.NoTextInteraction);
    const name_text = project.Name(init.gpa);
    defer init.gpa.free(name_text);
    const name_edit = QLineEdit.New3(name_text);
    name_edit.SetReadOnly(true);

    const version = QLabel.New3("Version:");
    version.SetTextInteractionFlags(qnamespace_enums.TextInteractionFlag.NoTextInteraction);
    const version_text = project.Version(init.gpa);
    defer init.gpa.free(version_text);
    const version_edit = QLineEdit.New3(version_text);
    version_edit.SetReadOnly(true);

    const url = QLabel.New3("URL:");
    url.SetTextInteractionFlags(qnamespace_enums.TextInteractionFlag.NoTextInteraction);
    const url_text = project.Url(init.gpa);
    defer init.gpa.free(url_text);
    const url_edit = QLineEdit.New3(url_text);
    url_edit.SetReadOnly(true);

    const lic = QLabel.New3("License:");
    lic.SetTextInteractionFlags(qnamespace_enums.TextInteractionFlag.NoTextInteraction);
    const lic_text = project.License(init.gpa);
    defer init.gpa.free(lic_text);
    const lic_edit = QLineEdit.New3(lic_text);
    lic_edit.SetReadOnly(true);

    const layout = QGridLayout.New2();

    layout.AddWidget2(desc, 0, 0);
    layout.AddWidget2(desc_edit, 0, 1);
    layout.AddWidget2(name, 1, 0);
    layout.AddWidget2(name_edit, 1, 1);
    layout.AddWidget2(version, 2, 0);
    layout.AddWidget2(version_edit, 2, 1);
    layout.AddWidget2(url, 3, 0);
    layout.AddWidget2(url_edit, 3, 1);
    layout.AddWidget2(lic, 4, 0);
    layout.AddWidget2(lic_edit, 4, 1);

    widget.SetLayout(layout);
    widget.Show();

    _ = QApplication.Exec();
}
