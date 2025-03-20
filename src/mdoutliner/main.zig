const std = @import("std");
const builtin = @import("builtin");
const qt6 = @import("libqt6zig");
const C = qt6.C;
const qboxlayout = qt6.qboxlayout;
const qboxlayout_enums = qt6.qboxlayout_enums;
const qhboxlayout = qt6.qhboxlayout;
const qtabwidget = qt6.qtabwidget;
const qfiledialog = qt6.qfiledialog;
const qtextedit = qt6.qtextedit;
const qcoreapplication = qt6.qcoreapplication;
const qicon = qt6.qicon;
const qlistwidget = qt6.qlistwidget;
const qlistwidgetitem = qt6.qlistwidgetitem;
const qtextdocument = qt6.qtextdocument;
const qvariant = qt6.qvariant;
const qtextcursor = qt6.qtextcursor;
const qtextblock = qt6.qtextblock;
const qnamespace_enums = qt6.qnamespace_enums;
const qwidget = qt6.qwidget;
const qsplitter = qt6.qsplitter;
const qapplication = qt6.qapplication;
const qmainwindow = qt6.qmainwindow;
const qkeysequence = qt6.qkeysequence;
const qaction = qt6.qaction;
const qmenubar = qt6.qmenubar;
const qmenu = qt6.qmenu;

const lineNumberRole = qnamespace_enums.ItemDataRole.UserRole + 1;

const config = getAllocatorConfig();
var gda: std.heap.DebugAllocator(config) = .init;
const allocator = gda.allocator();

const AppTabMap = std.AutoHashMap(?*anyopaque, *AppTab);
const AppWindowMap = std.AutoHashMap(?*anyopaque, *AppWindow);

var app_tab_map: AppTabMap = undefined;
var app_window_tab_map: AppWindowMap = undefined;
var main_window: *AppWindow = undefined;

pub const AppWindow = struct {
    w: ?*C.QMainWindow,
    cw: ?*C.QWidget,
    tabs: ?*C.QTabWidget,

    pub fn handleTabClose(self: ?*anyopaque, index: c_int) callconv(.c) void {
        if (app_window_tab_map.get(self)) |appwindow| {
            // Get the widget at this index before removing it
            const widget = qtabwidget.Widget(appwindow.tabs, index);
            if (widget != null) {
                // Find and remove the AppTab instance
                var it = app_tab_map.iterator();
                while (it.next()) |entry| {
                    const apptab = entry.value_ptr.*;
                    if (apptab.tab == widget) {
                        // Remove from map before freeing
                        if (apptab.textArea) |textArea| {
                            _ = app_tab_map.remove(textArea);
                        }
                        if (apptab.outline) |outline| {
                            _ = app_tab_map.remove(outline);
                        }
                        apptab.deinit();

                        // Free the AppTab instance
                        allocator.destroy(apptab);
                        break;
                    }
                }
            }
            // Now remove the tab
            qtabwidget.RemoveTab(appwindow.tabs, index);
        }
    }

    pub fn handleNewTab(_: ?*anyopaque) callconv(.c) void {
        createTabWithContents(main_window, "New Document", "");
    }

    pub fn handleFileOpen(_: ?*anyopaque) callconv(.c) void {
        const captionParam = "Open markdown file...";
        const directoryParam = "";
        const filterParam = "Markdown files (*.md *.txt);;All Files (*)";
        const fname = qfiledialog.GetOpenFileName4(main_window.w, captionParam, directoryParam, filterParam, allocator);
        defer allocator.free(fname);

        if (fname.len == 0) {
            return;
        }

        const file = std.fs.cwd().openFile(fname, .{}) catch @panic("Failed to open file");
        defer file.close();

        const fileSize = file.getEndPos() catch @panic("Failed to get file size");
        const contents = file.readToEndAlloc(allocator, fileSize) catch @panic("Failed to read file contents");
        defer allocator.free(contents);

        createTabWithContents(main_window, std.fs.path.basename(fname), contents);
    }

    pub fn createTabWithContents(self: *AppWindow, tabTitle: []const u8, tabContent: []const u8) void {
        const tab = NewAppTab() catch @panic("Failed to create tab");
        // the new tab is cleaned up during handleTabClose

        qtextedit.SetText(tab.textArea, tabContent);

        const tabIdx = qtabwidget.AddTab2(self.tabs, tab.tab, qicon.FromTheme("text-markdown"), tabTitle);
        qtabwidget.SetCurrentIndex(self.tabs, tabIdx);
    }

    pub fn handleExit(_: ?*anyopaque) callconv(.c) void {
        qcoreapplication.Quit();
    }

    pub fn handleAbout(_: ?*anyopaque) callconv(.c) void {
        qapplication.AboutQt();
    }

    pub fn deinit(self: *AppWindow) void {
        if (self.tabs) |tabs| {
            qtabwidget.QDelete(tabs);
            self.tabs = null;
        }
        if (self.cw) |cw| {
            qwidget.QDelete(cw);
            self.cw = null;
        }
        if (self.w) |w| {
            qmainwindow.QDelete(w);
            self.w = null;
        }
    }
};

pub const AppTab = struct {
    tab: ?*C.QWidget,
    outline: ?*C.QListWidget,
    textArea: ?*C.QTextEdit,

    pub fn handleJumpToBookmark(self: ?*anyopaque, _: ?*anyopaque, _: ?*anyopaque) callconv(.c) void {
        if (app_tab_map.get(self)) |apptab| {
            const itm = qlistwidget.CurrentItem(apptab.outline);
            if (itm == null) {
                return;
            }

            const lineNumberQVariant = qlistwidgetitem.Data(itm, lineNumberRole);
            const lineNumber = qvariant.ToInt(lineNumberQVariant);
            const textAreaDocument = qtextedit.Document(apptab.textArea);
            if (textAreaDocument == null) {
                return;
            }
            const targetBlock = qtextdocument.FindBlockByLineNumber(textAreaDocument, lineNumber);
            if (targetBlock == null) {
                return;
            }
            const cursor = qtextcursor.New4(targetBlock);
            if (cursor == null) {
                return;
            }

            qtextcursor.SetPosition(cursor, qtextblock.Position(targetBlock));
            qtextedit.SetTextCursor(apptab.textArea, cursor);
            qtextedit.SetFocus(apptab.textArea);
        }
    }

    pub fn handleTextChanged(self: ?*anyopaque) callconv(.c) void {
        if (app_tab_map.get(self)) |apptab| {
            const content = qtextedit.ToPlainText(self, allocator);
            defer allocator.free(content);

            updateOutlineForContent(apptab, content);
        }
    }

    pub fn updateOutlineForContent(self: *AppTab, content: []const u8) void {
        qlistwidget.Clear(self.outline);

        var lines = std.mem.splitScalar(u8, content, '\n');
        var lineNumber: c_int = 0;

        while (lines.next()) |line| {
            if (std.mem.startsWith(u8, line, "#")) {
                const bookmark = qlistwidgetitem.New7(line, self.outline);
                const tooltip = std.fmt.allocPrint(allocator, "Line {}", .{lineNumber + 1}) catch continue;
                defer allocator.free(tooltip);

                qlistwidgetitem.SetToolTip(bookmark, tooltip);
                const lineNum = qvariant.New4(lineNumber);
                defer qvariant.QDelete(lineNum);
                qlistwidgetitem.SetData(bookmark, lineNumberRole, lineNum);
            }
            lineNumber += 1;
        }
    }

    pub fn deinit(self: *AppTab) void {
        // Clean up Qt widgets in reverse order of creation
        if (self.textArea) |textArea| {
            qtextedit.QDelete(textArea);
            self.textArea = null;
        }
        if (self.outline) |outline| {
            qlistwidget.QDelete(outline);
            self.outline = null;
        }
        if (self.tab) |tab| {
            qwidget.QDelete(tab);
            self.tab = null;
        }
    }
};

pub fn NewAppTab() !*AppTab {
    var ret = try allocator.create(AppTab);

    const tab = qwidget.New2();
    ret.tab = tab;

    const layout = qhboxlayout.New(ret.tab);

    const panes = qsplitter.New2();
    qboxlayout.AddWidget(layout, panes);

    ret.outline = qlistwidget.New(ret.tab);

    qsplitter.AddWidget(panes, ret.outline);
    qlistwidget.OnCurrentItemChanged(ret.outline, AppTab.handleJumpToBookmark);

    ret.textArea = qtextedit.New(ret.tab);
    try app_tab_map.put(ret.textArea, ret);
    try app_tab_map.put(ret.outline, ret);

    qtextedit.OnTextChanged(ret.textArea, AppTab.handleTextChanged);
    qsplitter.AddWidget(panes, ret.textArea);

    const sizes = [_]i32{ 250, 550 };
    qsplitter.SetSizes(panes, @constCast(&sizes));

    return ret;
}

pub fn NewAppWindow() !*AppWindow {
    var ret = try allocator.create(AppWindow);

    ret.w = qmainwindow.New2();
    qwidget.SetWindowTitle(ret.w, "Markdown Outliner");

    // Menu setup
    const mnu = qmenubar.New2();

    // File menu
    const fileMenu = qmenubar.AddMenuWithTitle(mnu, "&File");

    const newtab = qmenubar.AddActionWithText(fileMenu, "New Tab");
    const newTabKeySequence = qkeysequence.New2("Ctrl+N");
    defer qkeysequence.QDelete(newTabKeySequence);
    qaction.SetShortcut(newtab, newTabKeySequence);
    const newIcon = qicon.FromTheme("document-new");
    defer qicon.QDelete(newIcon);
    qaction.SetIcon(newtab, newIcon);
    qaction.OnTriggered(newtab, AppWindow.handleNewTab);

    const open = qmenubar.AddActionWithText(fileMenu, "Open...");
    const openKeySequence = qkeysequence.New2("Ctrl+O");
    defer qkeysequence.QDelete(openKeySequence);
    qaction.SetShortcut(open, openKeySequence);
    const openIcon = qicon.FromTheme("document-open");
    defer qicon.QDelete(openIcon);
    qaction.SetIcon(open, openIcon);
    qaction.OnTriggered(open, AppWindow.handleFileOpen);

    _ = qmenubar.AddSeparator(fileMenu);

    const exit = qmenubar.AddActionWithText(fileMenu, "Exit");
    const exitKeySequence = qkeysequence.New2("Ctrl+Q");
    defer qkeysequence.QDelete(exitKeySequence);
    qaction.SetShortcut(exit, exitKeySequence);
    const exitIcon = qicon.FromTheme("application-exit");
    defer qicon.QDelete(exitIcon);
    qaction.SetIcon(exit, exitIcon);
    qaction.OnTriggered(exit, AppWindow.handleExit);
    const mainMenuActions = [_]?*C.QAction{ newtab, open, exit };
    qmenubar.AddActions(fileMenu, @ptrCast(@constCast(&mainMenuActions)));

    // Help menu
    const helpMenu = qmenubar.AddMenuWithTitle(mnu, "&Help");
    const about = qmenubar.AddActionWithText(helpMenu, "About Qt");
    const aboutIcon = qicon.FromTheme("help-about");
    defer qicon.QDelete(aboutIcon);
    qaction.SetIcon(about, aboutIcon);
    const aboutShortcutSequence = qkeysequence.New2("F1");
    defer qkeysequence.QDelete(aboutShortcutSequence);
    qaction.SetShortcut(about, aboutShortcutSequence);
    qaction.OnTriggered(about, AppWindow.handleAbout);

    qmainwindow.SetMenuBar(ret.w, mnu);

    // Ctrl+W shortcut
    const closeKeyParam = "Ctrl+W";
    const closeKeySequence = qkeysequence.New2(closeKeyParam);
    defer qkeysequence.QDelete(closeKeySequence);
    const close = qmainwindow.AddAction3(ret.w, closeKeyParam, closeKeySequence);
    qaction.SetShortcut(close, closeKeySequence);

    // Main widgets
    ret.tabs = qtabwidget.New(ret.w);
    qtabwidget.SetTabsClosable(ret.tabs, true);
    qtabwidget.OnTabCloseRequested(ret.tabs, AppWindow.handleTabClose);
    qmainwindow.SetCentralWidget(ret.w, ret.tabs);

    // Add initial tab
    const sampleContent = @embedFile("README.md");
    AppWindow.createTabWithContents(ret, "README.md", sampleContent);

    try app_window_tab_map.put(ret.tabs, ret);
    main_window = ret;

    return ret;
}

pub fn main() !void {
    const argc = std.os.argv.len;
    const argv = std.os.argv.ptr;
    _ = qapplication.New(argc, argv);

    defer _ = gda.deinit();

    app_tab_map = AppTabMap.init(allocator);

    defer {
        // Clean up all remaining tabs
        var processed_tabs: std.AutoHashMapUnmanaged(*AppTab, void) = .empty;
        defer processed_tabs.deinit(allocator);

        var it = app_tab_map.iterator();
        while (it.next()) |entry| {
            const apptab = entry.value_ptr.*;
            if (processed_tabs.get(apptab) == null) {
                // Mark as processed first and then cleanup
                _ = processed_tabs.put(allocator, apptab, {}) catch @panic("Failed to put AppTab into processed_tabs");

                apptab.deinit();
                allocator.destroy(apptab);
            }
        }
        app_tab_map.deinit();
    }

    app_window_tab_map = AppWindowMap.init(allocator);
    defer app_window_tab_map.deinit();

    const app = try NewAppWindow();
    defer allocator.destroy(app);

    // since Zig 0.14.0, without this print statement, the segfault (which is
    // also only occurring post-0.14.0) occurs before the application window
    // becomes visible, but _with_ this print statement, as long as it is any
    // non-empty value, the application window shows as expected and the
    // application works as expected, and no segfault occurs (I haven't yet
    // experimented with other types of statements since this original
    // discovery occurred)
    //
    // this smells like a compiler bug, but I'm not sure... there is a chance
    // that the print statement is leading to the correction of a bug in the
    // pointer handling somewhere that is then correctly aligned by the
    // compiler which lets the application window show normally, but without
    // which the application segfaults... and there is a chance that poor
    // coding practices are the root cause, possibly in some of the more
    // complex data structure usages, resulting in this undefined behavior
    std.debug.print("\n", .{});

    qmainwindow.Show(app.w);

    _ = qapplication.Exec();
}

pub fn getAllocatorConfig() std.heap.DebugAllocatorConfig {
    if (builtin.mode == .Debug) {
        return std.heap.DebugAllocatorConfig{
            .safety = true,
            .never_unmap = true,
            .retain_metadata = true,
            .verbose_log = false,
        };
    } else {
        return std.heap.DebugAllocatorConfig{
            .safety = false,
            .never_unmap = false,
            .retain_metadata = false,
            .verbose_log = false,
        };
    }
}
