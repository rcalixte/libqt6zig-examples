const std = @import("std");
const qt6 = @import("libqt6zig");
const QApplication = qt6.QApplication;
const QWidget = qt6.QWidget;
const QPushButton = qt6.QPushButton;
const QDataWidgetMapper = qt6.QDataWidgetMapper;
const QSqlDatabase = qt6.QSqlDatabase;
const QMessageBox = qt6.QMessageBox;
const qmessagebox_enums = qt6.qmessagebox_enums;
const QSqlQuery = qt6.QSqlQuery;
const QSqlRelationalTableModel = qt6.QSqlRelationalTableModel;
const qsqltablemodel_enums = qt6.qsqltablemodel_enums;
const QSqlRelation = qt6.QSqlRelation;
const QLabel = qt6.QLabel;
const QLineEdit = qt6.QLineEdit;
const QTextEdit = qt6.QTextEdit;
const QComboBox = qt6.QComboBox;
const QStyledItemDelegate = qt6.QStyledItemDelegate;
const QGridLayout = qt6.QGridLayout;
const QModelIndex = qt6.QModelIndex;

var mapper: QDataWidgetMapper = undefined;
var next_button: QPushButton = undefined;
var prev_button: QPushButton = undefined;
var model: QSqlRelationalTableModel = undefined;

pub fn main(init: std.process.Init) !void {
    const argv = try qt6.init(init.gpa, init.minimal.args);
    defer qt6.deinit(init.gpa, argv);
    var argc: i32 = @intCast(argv.len);
    const qapp = QApplication.New(init.arena.allocator(), &argc, argv);
    defer qapp.Delete();

    const widget = QWidget.New2();
    defer widget.Delete();

    const db = QSqlDatabase.AddDatabase("QSQLITE");
    defer db.Delete();

    db.SetDatabaseName(":memory:");
    if (!db.Open()) {
        _ = QMessageBox.Critical42(
            widget,
            "Cannot open database",
            "Unable to establish a database connection.\nThis example needs SQLite support. Please read the Qt SQL driver documentation for information on how to build it.",
            qmessagebox_enums.StandardButton.Cancel,
        );
        std.process.exit(1);
    }

    const query = QSqlQuery.New2();
    defer query.Delete();

    // Setup the main table
    _ = query.Exec("create table person (id int primary key, name varchar(20), address varchar(200), typeid int)");
    _ = query.Exec("insert into person values(1, 'Alice', '<qt>123 Main Street<br/>Market Town</qt>', 101)");
    _ = query.Exec("insert into person values(2, 'Bob', '<qt>PO Box 32<br/>Mail Handling Service<br/>Service City</qt>', 102)");
    _ = query.Exec("insert into person values(3, 'Carol', '<qt>The Lighthouse<br/>Remote Island</qt>', 103)");
    _ = query.Exec("insert into person values(4, 'Donald', '<qt>47338 Park Avenue<br/>Big City</qt>', 101)");
    _ = query.Exec("insert into person values(5, 'Emma', '<qt>Research Station<br/>Base Camp<br/>Big Mountain</qt>', 103)");

    // Setup the address table
    _ = query.Exec("create table addresstype (id int, description varchar(20))");
    _ = query.Exec("insert into addresstype values(101, 'Home')");
    _ = query.Exec("insert into addresstype values(102, 'Work')");
    _ = query.Exec("insert into addresstype values(103, 'Other')");

    model = QSqlRelationalTableModel.New2(widget);
    model.SetTable("person");
    model.SetEditStrategy(qsqltablemodel_enums.EditStrategy.OnManualSubmit);

    const type_index = model.FieldIndex("typeid");
    const relation = QSqlRelation.New2("addresstype", "id", "description");
    defer relation.Delete();

    model.SetRelation(type_index, relation);

    _ = model.Select();

    // Ownership of these widgets will be transferred to the widget via the layout
    const name_label = QLabel.New3("Na&me:");
    const name_edit = QLineEdit.New2();
    const address_label = QLabel.New3("&Address:");
    const address_edit = QTextEdit.New2();
    const type_label = QLabel.New3("&Type:");
    const type_combo = QComboBox.New2();
    next_button = QPushButton.New3("&Next");
    prev_button = QPushButton.New3("&Previous");

    name_label.SetBuddy(name_edit);
    address_label.SetBuddy(address_edit);
    type_label.SetBuddy(type_combo);

    const relModel = model.RelationModel(type_index);
    type_combo.SetModel(relModel);
    type_combo.SetModelColumn(relModel.FieldIndex("description"));

    mapper = QDataWidgetMapper.New2(widget);
    mapper.SetModel(model);
    const relational_delegate = QStyledItemDelegate.New2(mapper);
    mapper.SetItemDelegate(relational_delegate);
    mapper.AddMapping(name_edit, model.FieldIndex("name"));
    mapper.AddMapping(address_edit, model.FieldIndex("address"));
    mapper.AddMapping(type_combo, type_index);

    prev_button.OnClicked(toPrevious);
    next_button.OnClicked(toNext);
    mapper.OnCurrentIndexChanged(updateButtons);

    const layout = QGridLayout.New2();
    layout.AddWidget2(name_label, 0, 0);
    layout.AddWidget2(name_edit, 0, 1);
    layout.AddWidget2(prev_button, 0, 2);
    layout.AddWidget2(address_label, 1, 0);
    layout.AddWidget3(address_edit, 1, 1, 2, 1);
    layout.AddWidget2(next_button, 1, 2);
    layout.AddWidget2(type_label, 3, 0);
    layout.AddWidget2(type_combo, 3, 1);
    widget.SetLayout(layout);

    widget.SetWindowTitle("Qt 6 SQL Widget Mapper");
    mapper.ToFirst();

    widget.Show();

    _ = QApplication.Exec();
}

fn toPrevious(_: QPushButton) callconv(.c) void {
    mapper.ToPrevious();
}

fn toNext(_: QPushButton) callconv(.c) void {
    mapper.ToNext();
}

fn updateButtons(_: QDataWidgetMapper, index: i32) callconv(.c) void {
    prev_button.SetEnabled(index > 0);
    const model_index = QModelIndex.New3();
    defer model_index.Delete();

    next_button.SetEnabled(index < model.RowCount(model_index) - 1);
}
