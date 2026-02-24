const std = @import("std");
const qt6 = @import("libqt6zig");
const C = qt6.C;
const qapplication = qt6.qapplication;
const kcountry = qt6.kcountry;
const qwidget = qt6.qwidget;
const qvboxlayout = qt6.qvboxlayout;
const qlabel = qt6.qlabel;
const qfont = qt6.qfont;
const qcombobox = qt6.qcombobox;
const qnamespace_enums = qt6.qnamespace_enums;

var gpa = @import("alloc_config").gpa;
const allocator = gpa.allocator();

var buffer: [24]u8 = undefined;

var all_countries: []C.KCountry = undefined;
var emoji_flag_label: C.QLabel = null;
var currency_label: C.QLabel = null;

pub fn main() void {
    const argc = std.os.argv.len;
    const argv = std.os.argv.ptr;
    const qapp = qapplication.New(argc, argv);
    defer qapplication.Delete(qapp);

    defer _ = gpa.deinit();

    all_countries = kcountry.AllCountries(allocator);
    defer {
        for (all_countries) |country| {
            kcountry.Delete(country);
        }
        allocator.free(all_countries);
    }

    const widget = qwidget.New2();
    defer qwidget.Delete(widget);

    qwidget.SetWindowTitle(widget, "Qt 6 KCountry Example");
    qwidget.SetFixedSize2(widget, 400, 250);

    // Ownership of the created widgets will be transferred to the widget via the layout
    const vboxlayout = qvboxlayout.New2();
    const label = qlabel.New3("Select a country:");
    const country_combo = qcombobox.New2();
    emoji_flag_label = qlabel.New2();
    const font = qfont.New2("Noto Color Emoji");
    defer qfont.Delete(font);
    const style_sheet = "font-size: 28px;";
    qlabel.SetFont(emoji_flag_label, font);
    qlabel.SetStyleSheet(emoji_flag_label, style_sheet);
    qlabel.SetAlignment(emoji_flag_label, qnamespace_enums.AlignmentFlag.AlignCenter);
    currency_label = qlabel.New2();
    qlabel.SetFont(currency_label, font);
    qlabel.SetStyleSheet(currency_label, style_sheet);
    qlabel.SetAlignment(currency_label, qnamespace_enums.AlignmentFlag.AlignCenter);

    for (all_countries) |country| {
        const name = kcountry.Name(country, allocator);
        defer allocator.free(name);
        qcombobox.AddItem(country_combo, name);
    }

    qcombobox.OnCurrentIndexChanged(country_combo, onCurrentIndexChanged);

    qvboxlayout.AddWidget(vboxlayout, label);
    qvboxlayout.AddWidget(vboxlayout, country_combo);
    qvboxlayout.AddStretch(vboxlayout);
    qvboxlayout.AddWidget(vboxlayout, emoji_flag_label);
    qvboxlayout.AddWidget(vboxlayout, currency_label);
    qvboxlayout.AddStretch(vboxlayout);
    qwidget.SetLayout(widget, vboxlayout);

    qwidget.Show(widget);

    _ = qapplication.Exec();
}

fn onCurrentIndexChanged(_: ?*anyopaque, index: i32) callconv(.c) void {
    const country = all_countries[@intCast(index)];
    const emoji_flag = kcountry.EmojiFlag(country, allocator);
    defer allocator.free(emoji_flag);
    const emoji_text = std.fmt.bufPrintZ(&buffer, "Emoji flag: {s}", .{emoji_flag}) catch @panic("Failed to bufPrintZ emoji flag");
    qlabel.SetText(emoji_flag_label, emoji_text);

    const currency = kcountry.CurrencyCode(country, allocator);
    defer allocator.free(currency);
    const currency_text = std.fmt.bufPrintZ(&buffer, "Currency code: {s}", .{currency}) catch @panic("Failed to bufPrintZ currency code");
    qlabel.SetText(currency_label, currency_text);
}
