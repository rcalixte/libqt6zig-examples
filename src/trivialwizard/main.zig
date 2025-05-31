const std = @import("std");
const qt6 = @import("libqt6zig");
const C = qt6.C;
const qapplication = qt6.qapplication;
const qwizard = qt6.qwizard;
const qwizardpage = qt6.qwizardpage;
const qlabel = qt6.qlabel;
const qvboxlayout = qt6.qvboxlayout;
const qlineedit = qt6.qlineedit;
const qgridlayout = qt6.qgridlayout;

pub fn main() void {
    const argc = std.os.argv.len;
    const argv = std.os.argv.ptr;
    _ = qapplication.New(argc, argv);

    const wizard = qwizard.New2();
    defer qwizard.QDelete(wizard);

    const introPage = createIntroPage();
    defer qwizardpage.QDelete(introPage);
    _ = qwizard.AddPage(wizard, introPage);

    const registrationPage = createRegistrationPage();
    defer qwizardpage.QDelete(registrationPage);
    _ = qwizard.AddPage(wizard, registrationPage);

    const conclusionPage = createConclusionPage();
    defer qwizardpage.QDelete(conclusionPage);
    _ = qwizard.AddPage(wizard, conclusionPage);

    qwizard.SetWindowTitle(wizard, "TrivialWizard");
    qwizard.Show(wizard);

    _ = qapplication.Exec();
}

pub fn createIntroPage() C.QWizardPage {
    const page = qwizardpage.New2();
    qwizardpage.SetTitle(page, "Introduction");
    const text = "This wizard will help you register your copy of Super Product Two";
    const label = qlabel.New5(text, page);
    qlabel.SetWordWrap(label, true);

    const layout = qvboxlayout.New2();
    qvboxlayout.AddWidget(layout, label);
    qwizardpage.SetLayout(page, layout);

    return page;
}

pub fn createRegistrationPage() C.QWizardPage {
    const page = qwizardpage.New2();

    const title = "Registration";
    qwizardpage.SetTitle(page, title);

    const subtitle = "Please fill both fields";
    qwizardpage.SetSubTitle(page, subtitle);

    const name = "Name:";
    const nameLabel = qlabel.New5(name, page);
    const nameLineEdit = qlineedit.New(page);

    const email = "Email address:";
    const emailLabel = qlabel.New5(email, page);
    const emailLineEdit = qlineedit.New(page);

    const layout = qgridlayout.New(page);
    qgridlayout.AddWidget2(layout, nameLabel, 0, 0);
    qgridlayout.AddWidget2(layout, nameLineEdit, 0, 1);
    qgridlayout.AddWidget2(layout, emailLabel, 1, 0);
    qgridlayout.AddWidget2(layout, emailLineEdit, 1, 1);
    qwizardpage.SetLayout(page, layout);

    return page;
}

pub fn createConclusionPage() C.QWizardPage {
    const page = qwizardpage.New2();

    const title = "Conclusion";
    qwizardpage.SetTitle(page, title);

    const success = "You are now successfully registered. Have a nice day!";
    const label = qlabel.New5(success, page);
    qlabel.SetWordWrap(label, true);

    const layout = qvboxlayout.New2();
    qvboxlayout.AddWidget(layout, label);
    qwizardpage.SetLayout(page, layout);

    return page;
}
