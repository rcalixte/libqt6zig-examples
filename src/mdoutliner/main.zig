const std = @import("std");
const qt6 = @import("libqt6zig");
const C = qt6.C;
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

var gpa = @import("alloc_config").gpa;
const allocator = gpa.allocator();

const lineNumberRole = qnamespace_enums.ItemDataRole.UserRole + 1;

const AppTabMap = std.AutoHashMapUnmanaged(?*anyopaque, *AppTab);
const AppWindowMap = std.AutoHashMapUnmanaged(?*anyopaque, *AppWindow);

var app_tab_map: AppTabMap = undefined;
var app_window_tab_map: AppWindowMap = undefined;
var main_window: *AppWindow = undefined;

pub const AppTab = struct {
    tab: C.QWidget,
    outline: C.QListWidget,
    textArea: C.QTextEdit,

    pub fn handleJumpToBookmark(self: ?*anyopaque, _: ?*anyopaque, _: ?*anyopaque) callconv(.c) void {
        if (app_tab_map.get(self)) |apptab| {
            const itm = qlistwidget.CurrentItem(apptab.outline);
            if (itm == null) {
                return;
            }

            const lineNumberQVariant = qlistwidgetitem.Data(itm, lineNumberRole);
            const lineNumber = qvariant.ToInt(lineNumberQVariant);
            defer qvariant.QDelete(lineNumberQVariant);
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
            defer qtextcursor.QDelete(cursor);

            qtextcursor.SetPosition(cursor, qtextblock.Position(targetBlock));
            qtextedit.SetTextCursor(apptab.textArea, cursor);
            qtextedit.SetFocus(apptab.textArea);
        }
    }

    pub fn updateOutlineForContent(self: *AppTab, content: []const u8) void {
        qlistwidget.Clear(self.outline);

        var lines = std.mem.splitScalar(u8, content, '\n');
        var inCodeBlock = false;
        var lineNumber: i32 = 0;
        var prevLine: []const u8 = undefined;
        var buf: [32]u8 = undefined;

        while (lines.next()) |line| {
            if (!inCodeBlock) {
                if (std.mem.startsWith(u8, line, "#")) {
                    const bookmark = qlistwidgetitem.New7(line, self.outline);
                    const tooltip = std.fmt.bufPrint(&buf, "Line {d}", .{lineNumber + 1}) catch continue;

                    qlistwidgetitem.SetToolTip(bookmark, tooltip);
                    const lineNum = qvariant.New4(lineNumber);
                    defer qvariant.QDelete(lineNum);
                    qlistwidgetitem.SetData(bookmark, lineNumberRole, lineNum);
                } else if ((std.mem.startsWith(u8, line, "---") or std.mem.startsWith(u8, line, "===")) and !std.mem.eql(u8, prevLine, "")) {
                    const bookmark = qlistwidgetitem.New7(prevLine, self.outline);
                    const tooltip = std.fmt.bufPrint(&buf, "Line {d}", .{lineNumber}) catch continue;

                    qlistwidgetitem.SetToolTip(bookmark, tooltip);
                    const lineNum = qvariant.New4(lineNumber - 1);
                    defer qvariant.QDelete(lineNum);
                    qlistwidgetitem.SetData(bookmark, lineNumberRole, lineNum);
                }
            }

            if (std.mem.startsWith(u8, line, "```"))
                inCodeBlock = !inCodeBlock;

            prevLine = line;
            lineNumber += 1;
        }
    }

    pub fn handleTextChanged(self: ?*anyopaque) callconv(.c) void {
        if (app_tab_map.get(self)) |apptab| {
            const content = qtextedit.ToPlainText(self, allocator);
            defer allocator.free(content);

            if (content.len == 0) return;

            updateOutlineForContent(apptab, content);
        }
    }

    pub fn deinit(self: *AppTab) void {
        // Clean up tab widget which will clean up the child objects too
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
    qhboxlayout.AddWidget(layout, panes);

    ret.outline = qlistwidget.New(ret.tab);

    qsplitter.AddWidget(panes, ret.outline);
    qlistwidget.OnCurrentItemChanged(ret.outline, AppTab.handleJumpToBookmark);

    ret.textArea = qtextedit.New(ret.tab);
    try app_tab_map.put(allocator, ret.textArea, ret);
    try app_tab_map.put(allocator, ret.outline, ret);

    qtextedit.OnTextChanged(ret.textArea, AppTab.handleTextChanged);
    qsplitter.AddWidget(panes, ret.textArea);

    var sizes = [_]i32{ 250, 550 };
    qsplitter.SetSizes(panes, &sizes);

    return ret;
}

pub const AppWindow = struct {
    w: C.QMainWindow,
    tabs: C.QTabWidget,

    pub fn handleTabClose(self: ?*anyopaque, index: i32) callconv(.c) void {
        if (app_window_tab_map.get(self)) |appwindow| {
            // Get the widget at this index before removing it
            const widget = qtabwidget.Widget(appwindow.tabs, index);
            if (widget != null) {
                // Keep track of the AppTab we need to free
                var tab_to_free: ?*AppTab = null;

                // Find and remove the AppTab instance
                var it = app_tab_map.iterator();
                while (it.next()) |entry| {
                    const apptab = entry.value_ptr.*;
                    if (apptab.tab == widget) {
                        tab_to_free = apptab;
                        // Remove from map before freeing
                        if (apptab.textArea) |textArea| {
                            _ = app_tab_map.remove(textArea);
                        }
                        if (apptab.outline) |outline| {
                            _ = app_tab_map.remove(outline);
                        }
                        break;
                    }
                }
                // Remove the tab from the tab widget first
                qtabwidget.RemoveTab(appwindow.tabs, index);

                // Then clean up the memory
                if (tab_to_free) |apptab| {
                    apptab.deinit();
                    allocator.destroy(apptab);
                }
            }
        }
    }

    pub fn handleCloseCurrentTab(_: ?*anyopaque) callconv(.c) void {
        if (main_window.tabs != null) {
            const current_index = qtabwidget.CurrentIndex(main_window.tabs);
            if (current_index >= 0) {
                AppWindow.handleTabClose(main_window.tabs, current_index);
            }
        }
    }

    pub fn createTabWithContents(self: *AppWindow, tabTitle: []const u8, tabContent: []const u8) void {
        const tab = NewAppTab() catch @panic("Failed to create tab");
        // the new tab is cleaned up during handleTabClose

        qtextedit.SetText(tab.textArea, tabContent);

        const icon = qicon.FromTheme("text-markdown");
        defer qicon.QDelete(icon);
        const tabIdx = qtabwidget.AddTab2(self.tabs, tab.tab, icon, tabTitle);
        qtabwidget.SetCurrentIndex(self.tabs, tabIdx);
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

        var buffer: [4096]u8 = undefined;
        var file_reader = file.reader(&buffer);
        const fileSize = file.getEndPos() catch @panic("Failed to get file size");
        const contents = file_reader.interface.readAlloc(allocator, fileSize) catch @panic("Failed to read file");
        defer allocator.free(contents);

        createTabWithContents(main_window, std.fs.path.basename(fname), contents);
    }

    pub fn handleExit(_: ?*anyopaque) callconv(.c) void {
        qcoreapplication.Quit();
    }

    pub fn handleAbout(_: ?*anyopaque) callconv(.c) void {
        qapplication.AboutQt();
    }
};

pub fn NewAppWindow() !*AppWindow {
    var ret = try allocator.create(AppWindow);

    ret.w = qmainwindow.New2();
    qmainwindow.SetWindowTitle(ret.w, "Markdown Outliner");

    // Menu setup
    const mnu = qmenubar.New2();

    // File menu
    const fileMenu = qmenubar.AddMenu2(mnu, "&File");

    const newtab = qmenubar.AddAction2(fileMenu, "New Tab");
    const newTabKeySequence = qkeysequence.New2("Ctrl+N");
    defer qkeysequence.QDelete(newTabKeySequence);
    qaction.SetShortcut(newtab, newTabKeySequence);
    const newIcon = qicon.FromTheme("document-new");
    defer qicon.QDelete(newIcon);
    qaction.SetIcon(newtab, newIcon);
    qaction.OnTriggered(newtab, AppWindow.handleNewTab);

    const open = qmenubar.AddAction2(fileMenu, "Open...");
    const openKeySequence = qkeysequence.New2("Ctrl+O");
    defer qkeysequence.QDelete(openKeySequence);
    qaction.SetShortcut(open, openKeySequence);
    const openIcon = qicon.FromTheme("document-open");
    defer qicon.QDelete(openIcon);
    qaction.SetIcon(open, openIcon);
    qaction.OnTriggered(open, AppWindow.handleFileOpen);

    _ = qmenubar.AddSeparator(fileMenu);

    const exit = qmenubar.AddAction2(fileMenu, "Exit");
    const exitKeySequence = qkeysequence.New2("Ctrl+Q");
    defer qkeysequence.QDelete(exitKeySequence);
    qaction.SetShortcut(exit, exitKeySequence);
    const exitIcon = qicon.FromTheme("application-exit");
    defer qicon.QDelete(exitIcon);
    qaction.SetIcon(exit, exitIcon);
    qaction.OnTriggered(exit, AppWindow.handleExit);

    // Help menu
    const helpMenu = qmenubar.AddMenu2(mnu, "&Help");
    const about = qmenubar.AddAction2(helpMenu, "About Qt");
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
    const close = qmainwindow.AddAction4(ret.w, closeKeyParam, closeKeySequence);
    qaction.SetShortcut(close, closeKeySequence);
    qaction.OnTriggered(close, AppWindow.handleCloseCurrentTab);

    // Main widgets
    ret.tabs = qtabwidget.New(ret.w);
    qtabwidget.SetTabsClosable(ret.tabs, true);
    qtabwidget.SetMovable(ret.tabs, true);
    qtabwidget.OnTabCloseRequested(ret.tabs, AppWindow.handleTabClose);
    qmainwindow.SetCentralWidget(ret.w, ret.tabs);

    // Add initial tab
    const sampleContent = @embedFile("README.md");
    AppWindow.createTabWithContents(ret, "README.md", sampleContent);

    try app_window_tab_map.put(allocator, ret.tabs, ret);
    main_window = ret;

    return ret;
}

pub fn main() !void {
    const argc = std.os.argv.len;
    const argv = std.os.argv.ptr;
    const qapp = qapplication.New(argc, argv);
    defer qapplication.QDelete(qapp);

    defer _ = gpa.deinit();

    app_tab_map = .empty;
    app_window_tab_map = .empty;

    defer {
        // Clean up all remaining tabs
        var processed_tabs: std.AutoHashMapUnmanaged(*AppTab, void) = .empty;
        defer processed_tabs.deinit(allocator);

        var it = app_tab_map.iterator();
        while (it.next()) |entry| {
            const apptab = entry.value_ptr.*;
            if (!processed_tabs.contains(apptab)) {
                // Mark as processed first and then cleanup
                _ = processed_tabs.put(allocator, apptab, {}) catch @panic("Failed to put AppTab into processed_tabs");

                // Just free the AppTab since Qt widgets were cleaned up
                allocator.destroy(apptab);
            }
        }
        app_tab_map.deinit(allocator);
        app_window_tab_map.deinit(allocator);
    }

    const app = try NewAppWindow();
    defer allocator.destroy(app);

    qmainwindow.Show(app.w);

    _ = qapplication.Exec();
}
