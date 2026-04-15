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

pub fn main(init: std.process.Init) !void {
    const argv = try qt6.init(init.gpa, init.minimal.args);
    defer qt6.deinit(init.gpa, argv);
    var argc: i32 = @intCast(argv.len);
    const qapp = qapplication.New(&argc, argv, init.arena.allocator());
    defer qapplication.Delete(qapp);

    const wizard = qwizard.New2();
    defer qwizard.Delete(wizard);

    const intro_page = createIntroPage();
    _ = qwizard.AddPage(wizard, intro_page);

    const registration_page = createRegistrationPage();
    _ = qwizard.AddPage(wizard, registration_page);

    const conclusion_page = createConclusionPage();
    _ = qwizard.AddPage(wizard, conclusion_page);

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
    const name_label = qlabel.New5(name, page);
    const name_edit = qlineedit.New(page);

    const email = "Email address:";
    const email_label = qlabel.New5(email, page);
    const email_edit = qlineedit.New(page);

    const layout = qgridlayout.New(page);
    qgridlayout.AddWidget2(layout, name_label, 0, 0);
    qgridlayout.AddWidget2(layout, name_edit, 0, 1);
    qgridlayout.AddWidget2(layout, email_label, 1, 0);
    qgridlayout.AddWidget2(layout, email_edit, 1, 1);
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
