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
    const qapp: QApplication = .new(init.arena.allocator(), &argc, argv);
    defer qapp.delete();

    const project = Attica__Project.new();
    defer project.delete();

    project.setDescription("Qt 6 for Zig");
    project.setName("libqt6zig");
    project.setVersion("6.8.2");
    project.setUrl("https://github.com/rcalixte/libqt6zig");
    project.setLicense("MIT");

    const widget = QWidget.new2();
    defer widget.delete();

    widget.setWindowTitle("Qt 6 Attica Example");
    widget.setMinimumSize2(350, 250);

    const desc = QLabel.new3("Description:");
    desc.setTextInteractionFlags(qnamespace_enums.TextInteractionFlag.NoTextInteraction);
    const desc_text = project.description(init.gpa);
    defer init.gpa.free(desc_text);
    const desc_edit = QLineEdit.new3(desc_text);
    desc_edit.setReadOnly(true);

    const name = QLabel.new3("Name:");
    name.setTextInteractionFlags(qnamespace_enums.TextInteractionFlag.NoTextInteraction);
    const name_text = project.name(init.gpa);
    defer init.gpa.free(name_text);
    const name_edit = QLineEdit.new3(name_text);
    name_edit.setReadOnly(true);

    const version = QLabel.new3("Version:");
    version.setTextInteractionFlags(qnamespace_enums.TextInteractionFlag.NoTextInteraction);
    const version_text = project.version(init.gpa);
    defer init.gpa.free(version_text);
    const version_edit = QLineEdit.new3(version_text);
    version_edit.setReadOnly(true);

    const url = QLabel.new3("URL:");
    url.setTextInteractionFlags(qnamespace_enums.TextInteractionFlag.NoTextInteraction);
    const url_text = project.url(init.gpa);
    defer init.gpa.free(url_text);
    const url_edit = QLineEdit.new3(url_text);
    url_edit.setReadOnly(true);

    const lic = QLabel.new3("License:");
    lic.setTextInteractionFlags(qnamespace_enums.TextInteractionFlag.NoTextInteraction);
    const lic_text = project.license(init.gpa);
    defer init.gpa.free(lic_text);
    const lic_edit = QLineEdit.new3(lic_text);
    lic_edit.setReadOnly(true);

    const layout = QGridLayout.new2();

    layout.addWidget2(desc, 0, 0);
    layout.addWidget2(desc_edit, 0, 1);
    layout.addWidget2(name, 1, 0);
    layout.addWidget2(name_edit, 1, 1);
    layout.addWidget2(version, 2, 0);
    layout.addWidget2(version_edit, 2, 1);
    layout.addWidget2(url, 3, 0);
    layout.addWidget2(url_edit, 3, 1);
    layout.addWidget2(lic, 4, 0);
    layout.addWidget2(lic_edit, 4, 1);

    widget.setLayout(layout);
    widget.show();

    _ = QApplication.exec();
}
