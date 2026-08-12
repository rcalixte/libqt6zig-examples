const std = @import("std");
const qt6 = @import("libqt6zig");
const QApplication = qt6.QApplication;
const KCountry = qt6.KCountry;
const QWidget = qt6.QWidget;
const QVBoxLayout = qt6.QVBoxLayout;
const QLabel = qt6.QLabel;
const QFont = qt6.QFont;
const QComboBox = qt6.QComboBox;
const qnamespace_enums = qt6.qnamespace_enums;

var allocator: std.mem.Allocator = undefined;

var buffer: [24]u8 = undefined;

var all_countries: []KCountry = undefined;
var emoji_flag_label: QLabel = undefined;
var currency_label: QLabel = undefined;

pub fn main(init: std.process.Init) !void {
    const argv = try qt6.init(init.gpa, init.minimal.args);
    defer qt6.deinit(init.gpa, argv);
    var argc: i32 = @intCast(argv.len);
    const qapp: QApplication = .new(init.arena.allocator(), &argc, argv);
    defer qapp.delete();

    allocator = init.gpa;

    all_countries = KCountry.allCountries(allocator);
    defer {
        for (all_countries) |country|
            country.delete();
        allocator.free(all_countries);
    }

    const widget = QWidget.new2();
    defer widget.delete();

    widget.setWindowTitle("Qt 6 KCountry Example");
    widget.setFixedSize2(400, 250);

    // Ownership of the created widgets will be transferred to the widget via the layout
    const vboxlayout = QVBoxLayout.new2();
    const country_combo = QComboBox.new2();
    emoji_flag_label = .new2();
    const font = QFont.new2("Noto Color Emoji");
    defer font.delete();
    const style_sheet = "font-size: 28px;";
    emoji_flag_label.setFont(font);
    emoji_flag_label.setStyleSheet(style_sheet);
    emoji_flag_label.setAlignment(qnamespace_enums.AlignmentFlag.AlignCenter);
    currency_label = .new2();
    currency_label.setFont(font);
    currency_label.setStyleSheet(style_sheet);
    currency_label.setAlignment(qnamespace_enums.AlignmentFlag.AlignCenter);

    for (all_countries) |country| {
        const name = country.name(allocator);
        defer allocator.free(name);
        country_combo.addItem(name);
    }

    country_combo.onCurrentIndexChanged(onCurrentIndexChanged);

    vboxlayout.addWidget(QLabel.new3("Select a country:"));
    vboxlayout.addWidget(country_combo);
    vboxlayout.addStretch();
    vboxlayout.addWidget(emoji_flag_label);
    vboxlayout.addWidget(currency_label);
    vboxlayout.addStretch();
    widget.setLayout(vboxlayout);

    widget.show();

    _ = QApplication.exec();
}

fn onCurrentIndexChanged(_: QComboBox, index: i32) callconv(.c) void {
    const country = all_countries[@intCast(index)];
    const emoji_flag = country.emojiFlag(allocator);
    defer allocator.free(emoji_flag);
    const emoji_text = std.fmt.bufPrint(&buffer, "Emoji flag: {s}", .{emoji_flag}) catch
        @panic("Failed to bufPrint emoji flag");
    emoji_flag_label.setText(emoji_text);

    const currency = country.currencyCode(allocator);
    defer allocator.free(currency);
    const currency_text = std.fmt.bufPrint(&buffer, "Currency code: {s}", .{currency}) catch
        @panic("Failed to bufPrint currency code");
    currency_label.setText(currency_text);
}
