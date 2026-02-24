const std = @import("std");
const qt6 = @import("libqt6zig");
const C = qt6.C;
const qapplication = qt6.qapplication;
const qwidget = qt6.qwidget;
const qpushbutton = qt6.qpushbutton;
const qdatawidgetmapper = qt6.qdatawidgetmapper;
const qsqldatabase = qt6.qsqldatabase;
const qmessagebox = qt6.qmessagebox;
const qmessagebox_enums = qt6.qmessagebox_enums;
const qsqlquery = qt6.qsqlquery;
const qsqlrelationaltablemodel = qt6.qsqlrelationaltablemodel;
const qsqltablemodel_enums = qt6.qsqltablemodel_enums;
const qsqlrelation = qt6.qsqlrelation;
const qlabel = qt6.qlabel;
const qlineedit = qt6.qlineedit;
const qtextedit = qt6.qtextedit;
const qcombobox = qt6.qcombobox;
const qsqltablemodel = qt6.qsqltablemodel;
const qstyleditemdelegate = qt6.qstyleditemdelegate;
const qgridlayout = qt6.qgridlayout;
const qmodelindex = qt6.qmodelindex;

var mapper: C.QDataWidgetMapper = null;
var nextButton: C.QPushButton = null;
var previousButton: C.QPushButton = null;
var model: C.QSqlRelationalTableModel = null;

pub fn main() void {
    const argc = std.os.argv.len;
    const argv = std.os.argv.ptr;
    const qapp = qapplication.New(argc, argv);
    defer qapplication.Delete(qapp);

    const widget = qwidget.New2();
    defer qwidget.Delete(widget);

    const db = qsqldatabase.AddDatabase("QSQLITE");
    defer qsqldatabase.Delete(db);

    qsqldatabase.SetDatabaseName(db, ":memory:");
    if (!qsqldatabase.Open(db)) {
        _ = qmessagebox.Critical42(
            widget,
            "Cannot open database",
            "Unable to establish a database connection.\nThis example needs SQLite support. Please read the Qt SQL driver documentation for information on how to build it.",
            qmessagebox_enums.StandardButton.Cancel,
        );
        std.process.exit(1);
    }

    const query = qsqlquery.New2();
    defer qsqlquery.Delete(query);

    // Setup the main table
    _ = qsqlquery.Exec(
        query,
        "create table person (id int primary key, name varchar(20), address varchar(200), typeid int)",
    );
    _ = qsqlquery.Exec(
        query,
        "insert into person values(1, 'Alice', '<qt>123 Main Street<br/>Market Town</qt>', 101)",
    );
    _ = qsqlquery.Exec(
        query,
        "insert into person values(2, 'Bob', '<qt>PO Box 32<br/>Mail Handling Service<br/>Service City</qt>', 102)",
    );
    _ = qsqlquery.Exec(
        query,
        "insert into person values(3, 'Carol', '<qt>The Lighthouse<br/>Remote Island</qt>', 103)",
    );
    _ = qsqlquery.Exec(
        query,
        "insert into person values(4, 'Donald', '<qt>47338 Park Avenue<br/>Big City</qt>', 101)",
    );
    _ = qsqlquery.Exec(
        query,
        "insert into person values(5, 'Emma', '<qt>Research Station<br/>Base Camp<br/>Big Mountain</qt>', 103)",
    );

    // Setup the address table
    _ = qsqlquery.Exec(
        query,
        "create table addresstype (id int, description varchar(20))",
    );
    _ = qsqlquery.Exec(
        query,
        "insert into addresstype values(101, 'Home')",
    );
    _ = qsqlquery.Exec(
        query,
        "insert into addresstype values(102, 'Work')",
    );
    _ = qsqlquery.Exec(
        query,
        "insert into addresstype values(103, 'Other')",
    );

    model = qsqlrelationaltablemodel.New2(widget);
    qsqlrelationaltablemodel.SetTable(model, "person");
    qsqlrelationaltablemodel.SetEditStrategy(model, qsqltablemodel_enums.EditStrategy.OnManualSubmit);

    const typeIndex = qsqlrelationaltablemodel.FieldIndex(model, "typeid");
    const relation = qsqlrelation.New2("addresstype", "id", "description");
    defer qsqlrelation.Delete(relation);
    qsqlrelationaltablemodel.SetRelation(model, typeIndex, relation);

    _ = qsqlrelationaltablemodel.Select(model);

    // Ownership of these widgets will be transferred to the widget via the layout
    const nameLabel = qlabel.New3("Na&me:");
    const nameEdit = qlineedit.New2();
    const addressLabel = qlabel.New3("&Address:");
    const addressEdit = qtextedit.New2();
    const typeLabel = qlabel.New3("&Type:");
    const typeComboBox = qcombobox.New2();
    nextButton = qpushbutton.New3("&Next");
    previousButton = qpushbutton.New3("&Previous");

    qlabel.SetBuddy(nameLabel, nameEdit);
    qlabel.SetBuddy(addressLabel, addressEdit);
    qlabel.SetBuddy(typeLabel, typeComboBox);

    const relModel = qsqlrelationaltablemodel.RelationModel(model, typeIndex);
    qcombobox.SetModel(typeComboBox, relModel);
    qcombobox.SetModelColumn(typeComboBox, qsqltablemodel.FieldIndex(relModel, "description"));

    mapper = qdatawidgetmapper.New2(widget);
    qdatawidgetmapper.SetModel(mapper, model);
    const relationalDelegate = qstyleditemdelegate.New2(mapper);
    qdatawidgetmapper.SetItemDelegate(mapper, relationalDelegate);
    qdatawidgetmapper.AddMapping(mapper, nameEdit, qsqlrelationaltablemodel.FieldIndex(model, "name"));
    qdatawidgetmapper.AddMapping(mapper, addressEdit, qsqlrelationaltablemodel.FieldIndex(model, "address"));
    qdatawidgetmapper.AddMapping(mapper, typeComboBox, typeIndex);

    qpushbutton.OnClicked(previousButton, toPrevious);
    qpushbutton.OnClicked(nextButton, toNext);
    qdatawidgetmapper.OnCurrentIndexChanged(mapper, updateButtons);

    const layout = qgridlayout.New2();
    qgridlayout.AddWidget2(layout, nameLabel, 0, 0);
    qgridlayout.AddWidget2(layout, nameEdit, 0, 1);
    qgridlayout.AddWidget2(layout, previousButton, 0, 2);
    qgridlayout.AddWidget2(layout, addressLabel, 1, 0);
    qgridlayout.AddWidget3(layout, addressEdit, 1, 1, 2, 1);
    qgridlayout.AddWidget2(layout, nextButton, 1, 2);
    qgridlayout.AddWidget2(layout, typeLabel, 3, 0);
    qgridlayout.AddWidget2(layout, typeComboBox, 3, 1);
    qwidget.SetLayout(widget, layout);

    qwidget.SetWindowTitle(widget, "Qt 6 SQL Widget Mapper");
    qdatawidgetmapper.ToFirst(mapper);

    qwidget.Show(widget);

    _ = qapplication.Exec();
}

fn toPrevious(_: ?*anyopaque) callconv(.c) void {
    qdatawidgetmapper.ToPrevious(mapper);
}

fn toNext(_: ?*anyopaque) callconv(.c) void {
    qdatawidgetmapper.ToNext(mapper);
}

fn updateButtons(_: ?*anyopaque, index: i32) callconv(.c) void {
    qpushbutton.SetEnabled(previousButton, index > 0);
    const modelIndex = qmodelindex.New3();
    defer qmodelindex.Delete(modelIndex);
    qpushbutton.SetEnabled(nextButton, index < qsqlrelationaltablemodel.RowCount(model, modelIndex) - 1);
}
