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

const getAllocatorConfig = @import("alloc_config").getAllocatorConfig;
const config = getAllocatorConfig();
var gda: std.heap.DebugAllocator(config) = .init;
const allocator = gda.allocator();

var all_countries: []C.KCountry = undefined;
var emoji_flag_label: C.QLabel = undefined;
var currency_label: C.QLabel = undefined;

pub fn main() void {
    const argc = std.os.argv.len;
    const argv = std.os.argv.ptr;
    _ = qapplication.New(argc, argv);

    all_countries = kcountry.AllCountries(allocator);
    defer {
        for (all_countries) |country| {
            kcountry.QDelete(country);
        }
        allocator.free(all_countries);
    }

    const widget = qwidget.New2();
    defer qwidget.QDelete(widget);

    qwidget.SetWindowTitle(widget, "Qt 6 KCountry Example");
    qwidget.SetFixedSize2(widget, 400, 250);

    // Ownership of the created widgets will be transferred to the widget via the layout
    const vboxlayout = qvboxlayout.New2();
    const label = qlabel.New3("Select a country:");
    const country_combo = qcombobox.New2();
    emoji_flag_label = qlabel.New2();
    const font = qfont.New2("Noto Color Emoji");
    defer qfont.QDelete(font);
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
    const emoji_text = std.mem.concat(allocator, u8, &.{ "Emoji flag: ", emoji_flag }) catch @panic("Failed to concat emoji flag");
    defer allocator.free(emoji_text);
    qlabel.SetText(emoji_flag_label, emoji_text);

    const currency = kcountry.CurrencyCode(country, allocator);
    defer allocator.free(currency);
    const currency_text = std.mem.concat(allocator, u8, &.{ "Currency code: ", currency }) catch @panic("Failed to concat currency code");
    defer allocator.free(currency_text);
    qlabel.SetText(currency_label, currency_text);
}
