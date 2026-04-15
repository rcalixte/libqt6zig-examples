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
var next_button: C.QPushButton = null;
var prev_button: C.QPushButton = null;
var model: C.QSqlRelationalTableModel = null;

pub fn main(init: std.process.Init) !void {
    const argv = try qt6.init(init.gpa, init.minimal.args);
    defer qt6.deinit(init.gpa, argv);
    var argc: i32 = @intCast(argv.len);
    const qapp = qapplication.New(&argc, argv, init.arena.allocator());
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

    const type_index = qsqlrelationaltablemodel.FieldIndex(model, "typeid");
    const relation = qsqlrelation.New2("addresstype", "id", "description");
    defer qsqlrelation.Delete(relation);
    qsqlrelationaltablemodel.SetRelation(model, type_index, relation);

    _ = qsqlrelationaltablemodel.Select(model);

    // Ownership of these widgets will be transferred to the widget via the layout
    const name_label = qlabel.New3("Na&me:");
    const name_edit = qlineedit.New2();
    const address_label = qlabel.New3("&Address:");
    const address_edit = qtextedit.New2();
    const type_label = qlabel.New3("&Type:");
    const type_combo = qcombobox.New2();
    next_button = qpushbutton.New3("&Next");
    prev_button = qpushbutton.New3("&Previous");

    qlabel.SetBuddy(name_label, name_edit);
    qlabel.SetBuddy(address_label, address_edit);
    qlabel.SetBuddy(type_label, type_combo);

    const relModel = qsqlrelationaltablemodel.RelationModel(model, type_index);
    qcombobox.SetModel(type_combo, relModel);
    qcombobox.SetModelColumn(type_combo, qsqltablemodel.FieldIndex(relModel, "description"));

    mapper = qdatawidgetmapper.New2(widget);
    qdatawidgetmapper.SetModel(mapper, model);
    const relational_delegate = qstyleditemdelegate.New2(mapper);
    qdatawidgetmapper.SetItemDelegate(mapper, relational_delegate);
    qdatawidgetmapper.AddMapping(mapper, name_edit, qsqlrelationaltablemodel.FieldIndex(model, "name"));
    qdatawidgetmapper.AddMapping(mapper, address_edit, qsqlrelationaltablemodel.FieldIndex(model, "address"));
    qdatawidgetmapper.AddMapping(mapper, type_combo, type_index);

    qpushbutton.OnClicked(prev_button, toPrevious);
    qpushbutton.OnClicked(next_button, toNext);
    qdatawidgetmapper.OnCurrentIndexChanged(mapper, updateButtons);

    const layout = qgridlayout.New2();
    qgridlayout.AddWidget2(layout, name_label, 0, 0);
    qgridlayout.AddWidget2(layout, name_edit, 0, 1);
    qgridlayout.AddWidget2(layout, prev_button, 0, 2);
    qgridlayout.AddWidget2(layout, address_label, 1, 0);
    qgridlayout.AddWidget3(layout, address_edit, 1, 1, 2, 1);
    qgridlayout.AddWidget2(layout, next_button, 1, 2);
    qgridlayout.AddWidget2(layout, type_label, 3, 0);
    qgridlayout.AddWidget2(layout, type_combo, 3, 1);
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
    qpushbutton.SetEnabled(prev_button, index > 0);
    const model_index = qmodelindex.New3();
    defer qmodelindex.Delete(model_index);
    qpushbutton.SetEnabled(next_button, index < qsqlrelationaltablemodel.RowCount(model, model_index) - 1);
}
