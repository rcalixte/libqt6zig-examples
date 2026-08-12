const std = @import("std");
const qt6 = @import("libqt6zig");
const QApplication = qt6.QApplication;
const QWizard = qt6.QWizard;
const QWizardPage = qt6.QWizardPage;
const QLabel = qt6.QLabel;
const QVBoxLayout = qt6.QVBoxLayout;
const QLineEdit = qt6.QLineEdit;
const QGridLayout = qt6.QGridLayout;

pub fn main(init: std.process.Init) !void {
    const argv = try qt6.init(init.gpa, init.minimal.args);
    defer qt6.deinit(init.gpa, argv);
    var argc: i32 = @intCast(argv.len);
    const qapp: QApplication = .new(init.arena.allocator(), &argc, argv);
    defer qapp.delete();

    const wizard = QWizard.new2();
    defer wizard.delete();

    const intro_page = createIntroPage();
    _ = wizard.addPage(intro_page);

    const registration_page = createRegistrationPage();
    _ = wizard.addPage(registration_page);

    const conclusion_page = createConclusionPage();
    _ = wizard.addPage(conclusion_page);

    wizard.setWindowTitle("Qt 6 Trivial Wizard Example");
    wizard.show();

    _ = QApplication.exec();
}

pub fn createIntroPage() QWizardPage {
    const page = QWizardPage.new2();
    page.setTitle("Introduction");

    const text = "This wizard will help you register your copy of Super Product Two";
    const label = QLabel.new5(text, page);
    label.setWordWrap(true);

    const layout = QVBoxLayout.new2();
    layout.addWidget(label);
    page.setLayout(layout);

    return page;
}

pub fn createRegistrationPage() QWizardPage {
    const page = QWizardPage.new2();
    page.setTitle("Registration");
    page.setSubTitle("Please fill both fields");

    const layout = QGridLayout.new(page);
    layout.addWidget2(QLabel.new5("Name:", page), 0, 0);
    layout.addWidget2(QLineEdit.new(page), 0, 1);
    layout.addWidget2(QLabel.new5("Email address:", page), 1, 0);
    layout.addWidget2(QLineEdit.new(page), 1, 1);
    page.setLayout(layout);

    return page;
}

pub fn createConclusionPage() QWizardPage {
    const page = QWizardPage.new2();
    page.setTitle("Conclusion");

    const success = "You are now successfully registered. Have a nice day!";
    const label = QLabel.new5(success, page);
    label.setWordWrap(true);

    const layout = QVBoxLayout.new2();
    layout.addWidget(label);
    page.setLayout(layout);

    return page;
}
