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
    const qapp: QApplication = .new(init.arena.allocator(), &argc, argv);
    defer qapp.delete();

    const widget = QWidget.new2();
    defer widget.delete();

    const db = QSqlDatabase.addDatabase("QSQLITE");
    defer db.delete();

    db.setDatabaseName(":memory:");
    if (!db.open()) {
        _ = QMessageBox.critical42(
            widget,
            "Cannot open database",
            "Unable to establish a database connection.\nThis example needs SQLite support. " ++
                "Please read the Qt SQL driver documentation for information on how to build it.",
            qmessagebox_enums.StandardButton.Cancel,
        );
        std.process.exit(1);
    }

    const query = QSqlQuery.new2();
    defer query.delete();

    // Setup the main table
    _ = query.exec("create table person (id int primary key, name varchar(20), address varchar(200), typeid int)");
    _ = query.exec("insert into person values(1, 'Alice', '<qt>123 Main Street<br/>Market Town</qt>', 101)");
    _ = query.exec("insert into person values(2, 'Bob', '<qt>PO Box 32<br/>Mail Handling Service<br/>Service City</qt>', 102)");
    _ = query.exec("insert into person values(3, 'Carol', '<qt>The Lighthouse<br/>Remote Island</qt>', 103)");
    _ = query.exec("insert into person values(4, 'Donald', '<qt>47338 Park Avenue<br/>Big City</qt>', 101)");
    _ = query.exec("insert into person values(5, 'Emma', '<qt>Research Station<br/>Base Camp<br/>Big Mountain</qt>', 103)");

    // Setup the address table
    _ = query.exec("create table addresstype (id int, description varchar(20))");
    _ = query.exec("insert into addresstype values(101, 'Home')");
    _ = query.exec("insert into addresstype values(102, 'Work')");
    _ = query.exec("insert into addresstype values(103, 'Other')");

    model = .new2(widget);
    model.setTable("person");
    model.setEditStrategy(qsqltablemodel_enums.EditStrategy.OnManualSubmit);

    const type_index = model.fieldIndex("typeid");
    const relation = QSqlRelation.new2("addresstype", "id", "description");
    defer relation.delete();

    model.setRelation(type_index, relation);

    _ = model.select();

    // Ownership of these widgets will be transferred to the widget via the layout
    const name_label = QLabel.new3("Na&me:");
    const name_edit = QLineEdit.new2();
    const address_label = QLabel.new3("&Address:");
    const address_edit = QTextEdit.new2();
    const type_label = QLabel.new3("&Type:");
    const type_combo = QComboBox.new2();
    next_button = .new3("&Next");
    prev_button = .new3("&Previous");

    name_label.setBuddy(name_edit);
    address_label.setBuddy(address_edit);
    type_label.setBuddy(type_combo);

    const rel_model = model.relationModel(type_index);
    defer rel_model.delete();

    type_combo.setModel(rel_model);
    type_combo.setModelColumn(rel_model.fieldIndex("description"));

    mapper = .new2(widget);
    mapper.setModel(model);
    const relational_delegate = QStyledItemDelegate.new2(mapper);
    defer relational_delegate.delete();

    mapper.setItemDelegate(relational_delegate);
    mapper.addMapping(name_edit, model.fieldIndex("name"));
    mapper.addMapping(address_edit, model.fieldIndex("address"));
    mapper.addMapping(type_combo, type_index);

    prev_button.onClicked(toPrevious);
    next_button.onClicked(toNext);
    mapper.onCurrentIndexChanged(updateButtons);

    const layout = QGridLayout.new2();
    layout.addWidget2(name_label, 0, 0);
    layout.addWidget2(name_edit, 0, 1);
    layout.addWidget2(prev_button, 0, 2);
    layout.addWidget2(address_label, 1, 0);
    layout.addWidget3(address_edit, 1, 1, 2, 1);
    layout.addWidget2(next_button, 1, 2);
    layout.addWidget2(type_label, 3, 0);
    layout.addWidget2(type_combo, 3, 1);
    widget.setLayout(layout);

    widget.setWindowTitle("Qt 6 SQL Widget Mapper");
    mapper.toFirst();

    widget.show();

    _ = QApplication.exec();
}

fn toPrevious(_: QPushButton) callconv(.c) void {
    mapper.toPrevious();
}

fn toNext(_: QPushButton) callconv(.c) void {
    mapper.toNext();
}

fn updateButtons(_: QDataWidgetMapper, index: i32) callconv(.c) void {
    prev_button.setEnabled(index > 0);
    const model_index = QModelIndex.new3();
    defer model_index.delete();

    next_button.setEnabled(index < model.rowCount(model_index) - 1);
}
