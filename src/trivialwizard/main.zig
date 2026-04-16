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
    const qapp = QApplication.New(init.arena.allocator(), &argc, argv);
    defer qapp.Delete();

    const wizard = QWizard.New2();
    defer wizard.Delete();

    const intro_page = createIntroPage();
    _ = wizard.AddPage(intro_page);

    const registration_page = createRegistrationPage();
    _ = wizard.AddPage(registration_page);

    const conclusion_page = createConclusionPage();
    _ = wizard.AddPage(conclusion_page);

    wizard.SetWindowTitle("TrivialWizard");
    wizard.Show();

    _ = QApplication.Exec();
}

pub fn createIntroPage() QWizardPage {
    const page = QWizardPage.New2();
    page.SetTitle("Introduction");
    const text = "This wizard will help you register your copy of Super Product Two";
    const label = QLabel.New5(text, page);
    label.SetWordWrap(true);

    const layout = QVBoxLayout.New2();
    layout.AddWidget(label);
    page.SetLayout(layout);

    return page;
}

pub fn createRegistrationPage() QWizardPage {
    const page = QWizardPage.New2();
    page.SetTitle("Registration");
    page.SetSubTitle("Please fill both fields");

    const name_label = QLabel.New5("Name:", page);
    const name_edit = QLineEdit.New(page);

    const email_label = QLabel.New5("Email address:", page);
    const email_edit = QLineEdit.New(page);

    const layout = QGridLayout.New(page);
    layout.AddWidget2(name_label, 0, 0);
    layout.AddWidget2(name_edit, 0, 1);
    layout.AddWidget2(email_label, 1, 0);
    layout.AddWidget2(email_edit, 1, 1);
    page.SetLayout(layout);

    return page;
}

pub fn createConclusionPage() QWizardPage {
    const page = QWizardPage.New2();
    page.SetTitle("Conclusion");

    const success = "You are now successfully registered. Have a nice day!";
    const label = QLabel.New5(success, page);
    label.SetWordWrap(true);

    const layout = QVBoxLayout.New2();
    layout.AddWidget(label);
    page.SetLayout(layout);

    return page;
}
