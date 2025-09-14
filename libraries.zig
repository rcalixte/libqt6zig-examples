const ExtraLibrary = struct {
    name: []const u8,
    libraries: []const []const u8,
    prefix: []const u8,
};

// Define the extra libraries
pub const extra_libraries = [_]ExtraLibrary{
    .{
        .name = "kcodecs",
        .libraries = &.{"KF6Codecs"},
        .prefix = "extras",
    },
    .{
        .name = "kcompletion",
        .libraries = &.{"KF6Completion"},
        .prefix = "extras",
    },
    .{
        .name = "kconfig",
        .libraries = &.{ "KF6ConfigCore", "KF6ConfigGui" },
        .prefix = "extras",
    },
    .{
        .name = "kcoreaddons",
        .libraries = &.{"KF6CoreAddons"},
        .prefix = "extras",
    },
    .{
        .name = "kguiaddons",
        .libraries = &.{"KF6GuiAddons"},
        .prefix = "extras",
    },
    .{
        .name = "ki18n",
        .libraries = &.{ "KF6I18n", "KF6I18nLocaleData" },
        .prefix = "extras",
    },
    .{
        .name = "kitemviews",
        .libraries = &.{"KF6ItemViews"},
        .prefix = "extras",
    },
    .{
        .name = "kplotting",
        .libraries = &.{"KF6Plotting"},
        .prefix = "extras",
    },
    .{
        .name = "sonnet",
        .libraries = &.{ "KF6SonnetCore", "KF6SonnetUi" },
        .prefix = "extras",
    },
    .{
        .name = "ktextwidgets",
        .libraries = &.{"KF6TextWidgets"},
        .prefix = "extras",
    },
    .{
        .name = "kwidgetsaddons",
        .libraries = &.{"KF6WidgetsAddons"},
        .prefix = "extras",
    },
    .{
        .name = "kcolorscheme",
        .libraries = &.{"KF6ColorScheme"},
        .prefix = "extras",
    },
    .{
        .name = "kconfigwidgets",
        .libraries = &.{"KF6ConfigWidgets"},
        .prefix = "extras",
    },
    .{
        .name = "kbookmarks",
        .libraries = &.{ "KF6Bookmarks", "KF6BookmarksWidgets" },
        .prefix = "extras",
    },
    .{
        .name = "kiconthemes",
        .libraries = &.{ "KF6IconThemes", "KF6IconWidgets" },
        .prefix = "extras",
    },
    .{
        .name = "kxmlgui",
        .libraries = &.{ "KF6XmlGui", "KF6Crash" },
        .prefix = "extras",
    },
    .{
        .name = "kio",
        .libraries = &.{ "KF6KIOCore", "KF6KIOFileWidgets", "KF6KIOGui", "KF6KIOWidgets" },
        .prefix = "extras",
    },
    .{
        .name = "globalaccel",
        .libraries = &.{"KF6GlobalAccel"},
        .prefix = "foss-extras",
    },
    .{
        .name = "dbus",
        .libraries = &.{"Qt6DBus"},
        .prefix = "posix-extras",
    },
    .{
        .name = "qtermwidget",
        .libraries = &.{"qtermwidget6"},
        .prefix = "posix-restricted",
    },
    .{
        .name = "charts",
        .libraries = &.{"Qt6Charts"},
        .prefix = "restricted-extras",
    },
    .{
        .name = "qscintilla",
        .libraries = &.{"qscintilla2_qt6"},
        .prefix = "restricted-extras",
    },
};
