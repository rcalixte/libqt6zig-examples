const std = @import("std");
const qt6 = @import("libqt6zig");
const QHBoxLayout = qt6.QHBoxLayout;
const QTabWidget = qt6.QTabWidget;
const QFileDialog = qt6.QFileDialog;
const QTextEdit = qt6.QTextEdit;
const QIcon = qt6.QIcon;
const QListWidget = qt6.QListWidget;
const QListWidgetItem = qt6.QListWidgetItem;
const QVariant = qt6.QVariant;
const QTextCursor = qt6.QTextCursor;
const qnamespace_enums = qt6.qnamespace_enums;
const QWidget = qt6.QWidget;
const QSplitter = qt6.QSplitter;
const QApplication = qt6.QApplication;
const QMainWindow = qt6.QMainWindow;
const QKeySequence = qt6.QKeySequence;
const QAction = qt6.QAction;
const QMenuBar = qt6.QMenuBar;

var allocator: std.mem.Allocator = undefined;
var io: std.Io = undefined;

const line_number_role = qnamespace_enums.ItemDataRole.UserRole + 1;

const AppTabMap = std.AutoHashMapUnmanaged(QWidget, *AppTab);
const AppWindowMap = std.AutoHashMapUnmanaged(QTabWidget, *AppWindow);

var app_tab_map: AppTabMap = undefined;
var app_window_tab_map: AppWindowMap = undefined;
var main_window: *AppWindow = undefined;

pub const AppTab = struct {
    tab: QWidget,
    outline: QListWidget,
    text_area: QTextEdit,

    pub fn updateOutlineForContent(self: *AppTab, content: []const u8) void {
        self.outline.Clear();

        var lines = std.mem.splitScalar(u8, content, '\n');
        var in_code_block = false;
        var line_number: i32 = 0;
        var prev_line: []const u8 = undefined;
        var buf: [32]u8 = undefined;

        while (lines.next()) |line| {
            if (!in_code_block)
                if (std.mem.startsWith(u8, line, "#")) {
                    const bookmark = QListWidgetItem.New7(line, self.outline);
                    const tooltip = std.fmt.bufPrint(&buf, "Line {d}", .{line_number + 1}) catch continue;

                    bookmark.SetToolTip(tooltip);
                    const line_num = QVariant.New4(line_number);
                    defer line_num.Delete();
                    bookmark.SetData(line_number_role, line_num);
                } else if ((std.mem.startsWith(u8, line, "---") or std.mem.startsWith(u8, line, "===")) and !std.mem.eql(u8, prev_line, "")) {
                    const bookmark = QListWidgetItem.New7(prev_line, self.outline);
                    const tooltip = std.fmt.bufPrint(&buf, "Line {d}", .{line_number}) catch continue;

                    bookmark.SetToolTip(tooltip);
                    const line_num = QVariant.New4(line_number - 1);
                    defer line_num.Delete();
                    bookmark.SetData(line_number_role, line_num);
                };

            if (std.mem.startsWith(u8, line, "```"))
                in_code_block = !in_code_block;

            prev_line = line;
            line_number += 1;
        }
    }

    pub fn deinit(self: *AppTab) void {
        // Clean up tab widget which will clean up the child objects too
        self.tab.Delete();
        self.tab.ptr = null;
    }

    pub fn handleJumpToBookmark(self: QListWidget, _: QListWidgetItem, _: QListWidgetItem) callconv(.c) void {
        if (app_tab_map.get(.{ .ptr = @ptrCast(self.ptr) })) |apptab| {
            const itm = apptab.outline.CurrentItem();
            if (itm.ptr == null) return;

            const line_number_qvariant = itm.Data(line_number_role);
            const line_number = line_number_qvariant.ToInt();
            defer line_number_qvariant.Delete();

            const text_area_document = apptab.text_area.Document();
            if (text_area_document.ptr == null) return;

            const target_block = text_area_document.FindBlockByLineNumber(line_number);
            if (target_block.ptr == null) return;

            const cursor = QTextCursor.New4(target_block);
            defer cursor.Delete();

            cursor.SetPosition(target_block.Position());
            apptab.text_area.SetTextCursor(cursor);
            apptab.text_area.SetFocus();
        }
    }

    pub fn handleTextChanged(self: QTextEdit) callconv(.c) void {
        if (app_tab_map.get(.{ .ptr = @ptrCast(self.ptr) })) |apptab| {
            const content = self.ToPlainText(allocator);
            defer allocator.free(content);

            if (content.len == 0) return;

            apptab.updateOutlineForContent(content);
        }
    }
};

pub fn NewAppTab() !*AppTab {
    var ret = try allocator.create(AppTab);

    ret.tab = QWidget.New2();

    const layout = QHBoxLayout.New(ret.tab);
    const panes = QSplitter.New2();
    layout.AddWidget(panes);

    ret.outline = QListWidget.New(ret.tab);
    panes.AddWidget(ret.outline);
    ret.outline.OnCurrentItemChanged(AppTab.handleJumpToBookmark);

    ret.text_area = QTextEdit.New(ret.tab);
    try app_tab_map.put(allocator, .{ .ptr = @ptrCast(ret.text_area.ptr) }, ret);
    try app_tab_map.put(allocator, .{ .ptr = @ptrCast(ret.outline.ptr) }, ret);

    ret.text_area.OnTextChanged(AppTab.handleTextChanged);
    panes.AddWidget(ret.text_area);

    var sizes = [_]i32{ 250, 550 };
    panes.SetSizes(&sizes);

    return ret;
}

pub const AppWindow = struct {
    w: QMainWindow,
    tabs: QTabWidget,

    pub fn createTabWithContents(self: *AppWindow, tab_title: []const u8, tab_content: []const u8) void {
        const tab = NewAppTab() catch @panic("Failed to create tab");
        // the new tab is cleaned up during handleTabClose

        tab.text_area.SetText(tab_content);

        const icon = QIcon.FromTheme("text-markdown");
        defer icon.Delete();

        const tab_idx = self.tabs.AddTab2(tab.tab, icon, tab_title);
        self.tabs.SetCurrentIndex(tab_idx);
    }

    pub fn handleTabClose(tab: QTabWidget, index: i32) callconv(.c) void {
        if (app_window_tab_map.get(tab)) |appwindow| {
            // Get the widget at this index before removing it
            const widget = appwindow.tabs.Widget(index);
            if (widget.ptr != null) {
                // Keep track of the AppTab we need to free
                var tab_to_free: ?*AppTab = null;

                // Find and remove the AppTab instance
                var it = app_tab_map.iterator();
                while (it.next()) |entry| {
                    const apptab = entry.value_ptr.*;
                    if (apptab.tab.ptr == widget.ptr) {
                        tab_to_free = apptab;
                        // Remove from map before freeing
                        _ = app_tab_map.fetchRemove(.{ .ptr = @ptrCast(apptab.text_area.ptr) });
                        _ = app_tab_map.fetchRemove(.{ .ptr = @ptrCast(apptab.outline.ptr) });
                        break;
                    }
                }
                // Remove the tab from the tab widget first
                appwindow.tabs.RemoveTab(index);

                // Then clean up the memory
                if (tab_to_free) |apptab| {
                    apptab.deinit();
                    allocator.destroy(apptab);
                }
            }
        }
    }

    pub fn handleCloseCurrentTab(_: QAction) callconv(.c) void {
        if (main_window.tabs.ptr != null) {
            const current_index = main_window.tabs.CurrentIndex();
            if (current_index >= 0)
                handleTabClose(main_window.tabs, current_index);
        }
    }

    pub fn handleNewTab(_: QAction) callconv(.c) void {
        main_window.createTabWithContents("New Document", "");
    }

    pub fn handleFileOpen(_: QAction) callconv(.c) void {
        const fname = QFileDialog.GetOpenFileName4(
            allocator,
            main_window.w,
            "Open markdown file...",
            "",
            "Markdown files (*.md *.txt);;All Files (*)",
        );
        defer allocator.free(fname);

        if (fname.len == 0) return;

        const file = std.Io.Dir.cwd().openFile(io, fname, .{}) catch @panic("Failed to open file");
        defer file.close(io);

        var buffer: [4096]u8 = undefined;
        var file_reader = file.reader(io, &buffer);
        const contents = file_reader.interface.allocRemaining(allocator, .unlimited) catch @panic("Failed to read file");
        defer allocator.free(contents);

        main_window.createTabWithContents(std.fs.path.basename(fname), contents);
    }

    pub fn handleExit(_: QAction) callconv(.c) void {
        QApplication.Quit();
    }

    pub fn handleAbout(_: QAction) callconv(.c) void {
        QApplication.AboutQt();
    }
};

pub fn NewAppWindow() !*AppWindow {
    var ret = try allocator.create(AppWindow);

    ret.w = QMainWindow.New2();
    ret.w.SetWindowTitle("Markdown Outliner");

    // Menu setup
    const mnu = QMenuBar.New2();

    // File menu
    const file_menu = mnu.AddMenu2("&File");

    const newtab = file_menu.AddAction2("New Tab");
    const new_tab_key_sequence = QKeySequence.New2("Ctrl+N");
    defer new_tab_key_sequence.Delete();
    newtab.SetShortcut(new_tab_key_sequence);
    const new_icon = QIcon.FromTheme("document-new");
    defer new_icon.Delete();
    newtab.SetIcon(new_icon);
    newtab.OnTriggered(AppWindow.handleNewTab);

    const open = file_menu.AddAction2("Open...");
    const open_key_sequence = QKeySequence.New2("Ctrl+O");
    defer open_key_sequence.Delete();
    open.SetShortcut(open_key_sequence);
    const open_icon = QIcon.FromTheme("document-open");
    defer open_icon.Delete();
    open.SetIcon(open_icon);
    open.OnTriggered(AppWindow.handleFileOpen);

    _ = file_menu.AddSeparator();

    const exit = file_menu.AddAction2("Exit");
    const exit_key_sequence = QKeySequence.New2("Ctrl+Q");
    defer exit_key_sequence.Delete();
    exit.SetShortcut(exit_key_sequence);
    const exit_icon = QIcon.FromTheme("application-exit");
    defer exit_icon.Delete();
    exit.SetIcon(exit_icon);
    exit.OnTriggered(AppWindow.handleExit);

    // Help menu
    const about = mnu.AddMenu2("&Help").AddAction2("About Qt");
    const about_icon = QIcon.FromTheme("help-about");
    defer about_icon.Delete();
    about.SetIcon(about_icon);
    const about_shortcut_sequence = QKeySequence.New2("F1");
    defer about_shortcut_sequence.Delete();
    about.SetShortcut(about_shortcut_sequence);
    about.OnTriggered(AppWindow.handleAbout);

    ret.w.SetMenuBar(mnu);

    // Ctrl+W shortcut
    const close_key_param = "Ctrl+W";
    const close_key_sequence = QKeySequence.New2(close_key_param);
    defer close_key_sequence.Delete();
    const close = ret.w.AddAction4(close_key_param, close_key_sequence);
    close.SetShortcut(close_key_sequence);
    close.OnTriggered(AppWindow.handleCloseCurrentTab);

    // Main widgets
    ret.tabs = QTabWidget.New(ret.w);
    ret.tabs.SetTabsClosable(true);
    ret.tabs.SetMovable(true);
    ret.tabs.OnTabCloseRequested(AppWindow.handleTabClose);
    ret.w.SetCentralWidget(ret.tabs);

    // Add initial tab
    ret.createTabWithContents("README.md", @embedFile("README.md"));

    try app_window_tab_map.put(allocator, ret.tabs, ret);
    main_window = ret;

    return ret;
}

pub fn main(init: std.process.Init) !void {
    const argv = try qt6.init(init.gpa, init.minimal.args);
    defer qt6.deinit(init.gpa, argv);
    var argc: i32 = @intCast(argv.len);
    const qapp = QApplication.New(init.arena.allocator(), &argc, argv);
    defer qapp.Delete();

    allocator = init.gpa;
    io = init.io;

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

    app.w.Show();

    _ = QApplication.Exec();
}
