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
    const qapp = QApplication.New(init.arena.allocator(), &argc, argv);
    defer qapp.Delete();

    allocator = init.gpa;

    all_countries = KCountry.AllCountries(allocator);
    defer {
        for (all_countries) |country|
            country.Delete();
        allocator.free(all_countries);
    }

    const widget = QWidget.New2();
    defer widget.Delete();

    widget.SetWindowTitle("Qt 6 KCountry Example");
    widget.SetFixedSize2(400, 250);

    // Ownership of the created widgets will be transferred to the widget via the layout
    const vboxlayout = QVBoxLayout.New2();
    const label = QLabel.New3("Select a country:");
    const country_combo = QComboBox.New2();
    emoji_flag_label = QLabel.New2();
    const font = QFont.New2("Noto Color Emoji");
    defer font.Delete();
    const style_sheet = "font-size: 28px;";
    emoji_flag_label.SetFont(font);
    emoji_flag_label.SetStyleSheet(style_sheet);
    emoji_flag_label.SetAlignment(qnamespace_enums.AlignmentFlag.AlignCenter);
    currency_label = QLabel.New2();
    currency_label.SetFont(font);
    currency_label.SetStyleSheet(style_sheet);
    currency_label.SetAlignment(qnamespace_enums.AlignmentFlag.AlignCenter);

    for (all_countries) |country| {
        const name = country.Name(allocator);
        defer allocator.free(name);
        country_combo.AddItem(name);
    }

    country_combo.OnCurrentIndexChanged(onCurrentIndexChanged);

    vboxlayout.AddWidget(label);
    vboxlayout.AddWidget(country_combo);
    vboxlayout.AddStretch();
    vboxlayout.AddWidget(emoji_flag_label);
    vboxlayout.AddWidget(currency_label);
    vboxlayout.AddStretch();
    widget.SetLayout(vboxlayout);

    widget.Show();

    _ = QApplication.Exec();
}

fn onCurrentIndexChanged(_: QComboBox, index: i32) callconv(.c) void {
    const country = all_countries[@intCast(index)];
    const emoji_flag = country.EmojiFlag(allocator);
    defer allocator.free(emoji_flag);
    const emoji_text = std.fmt.bufPrint(&buffer, "Emoji flag: {s}", .{emoji_flag}) catch @panic("Failed to bufPrint emoji flag");
    emoji_flag_label.SetText(emoji_text);

    const currency = country.CurrencyCode(allocator);
    defer allocator.free(currency);
    const currency_text = std.fmt.bufPrint(&buffer, "Currency code: {s}", .{currency}) catch @panic("Failed to bufPrint currency code");
    currency_label.SetText(currency_text);
}
