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

var app_tab_map: AppTabMap = .empty;
var app_window_tab_map: AppWindowMap = .empty;
var app_window: AppWindow = .{};

pub const AppTab = struct {
    tab: QWidget = undefined,
    outline: QListWidget = undefined,
    text_area: QTextEdit = undefined,

    pub fn init(self: *AppTab, gpa: std.mem.Allocator) !void {
        self.tab = .new2();

        const layout = QHBoxLayout.new(self.tab);
        const panes = QSplitter.new2();
        layout.addWidget(panes);

        self.outline = .new(self.tab);
        panes.addWidget(self.outline);
        self.outline.onCurrentItemChanged(AppTab.handleJumpToBookmark);

        self.text_area = .new(self.tab);
        try app_tab_map.put(gpa, .{ .ptr = @ptrCast(self.text_area.ptr) }, self);
        try app_tab_map.put(gpa, .{ .ptr = @ptrCast(self.outline.ptr) }, self);

        self.text_area.onTextChanged(AppTab.handleTextChanged);
        panes.addWidget(self.text_area);

        var sizes = [_]i32{ 250, 550 };
        panes.setSizes(&sizes);
    }

    pub fn deinit(self: *const AppTab) void {
        self.tab.delete();
    }

    pub fn updateOutlineForContent(self: *const AppTab, content: []const u8) void {
        self.outline.clear();

        var lines = std.mem.splitScalar(u8, content, '\n');
        var in_code_block = false;
        var line_number: i32 = 0;
        var prev_line: []const u8 = undefined;
        var buf: [32]u8 = undefined;

        while (lines.next()) |line| {
            if (!in_code_block)
                if (std.mem.startsWith(u8, line, "#")) {
                    const bookmark = QListWidgetItem.new7(line, self.outline);
                    const tooltip = std.fmt.bufPrint(&buf, "Line {d}", .{line_number + 1}) catch continue;

                    bookmark.setToolTip(tooltip);
                    const line_num = QVariant.new4(line_number);
                    defer line_num.delete();

                    bookmark.setData(line_number_role, line_num);
                } else if ((std.mem.startsWith(u8, line, "---") or
                    std.mem.startsWith(u8, line, "===")) and
                    !std.mem.eql(u8, prev_line, ""))
                {
                    const bookmark = QListWidgetItem.new7(prev_line, self.outline);
                    const tooltip = std.fmt.bufPrint(&buf, "Line {d}", .{line_number}) catch continue;

                    bookmark.setToolTip(tooltip);
                    const line_num = QVariant.new4(line_number - 1);
                    defer line_num.delete();

                    bookmark.setData(line_number_role, line_num);
                };

            if (std.mem.startsWith(u8, line, "```"))
                in_code_block = !in_code_block;

            prev_line = line;
            line_number += 1;
        }
    }

    pub fn handleJumpToBookmark(self: QListWidget, current: QListWidgetItem, _: QListWidgetItem) callconv(.c) void {
        if (app_tab_map.get(.{ .ptr = @ptrCast(self.ptr) })) |apptab| {
            if (current.ptr == null) return;

            const line_number_qvariant = current.data(line_number_role);
            const line_number = line_number_qvariant.toInt();
            defer line_number_qvariant.delete();

            const text_area_document = apptab.text_area.document();
            const target_block = text_area_document.findBlockByLineNumber(line_number);
            defer target_block.delete();

            const cursor = QTextCursor.new4(target_block);
            defer cursor.delete();

            cursor.setPosition(target_block.position());
            apptab.text_area.setTextCursor(cursor);
            apptab.text_area.setFocus();
        }
    }

    pub fn handleTextChanged(self: QTextEdit) callconv(.c) void {
        if (app_tab_map.get(.{ .ptr = @ptrCast(self.ptr) })) |apptab| {
            const content = self.toPlainText(allocator);
            defer allocator.free(content);

            if (content.len == 0) return;

            apptab.updateOutlineForContent(content);
        }
    }
};

pub const AppWindow = struct {
    w: QMainWindow = undefined,
    tabs: QTabWidget = undefined,

    pub fn init(self: *AppWindow, gpa: std.mem.Allocator) !void {
        self.w = .new2();
        self.w.setWindowTitle("Markdown Outliner");

        // Menu setup
        const mnu = QMenuBar.new2();

        // File menu
        const file_menu = mnu.addMenu2("&File");

        const newtab = file_menu.addAction2("New Tab");
        const new_tab_key_sequence = QKeySequence.new2("Ctrl+N");
        defer new_tab_key_sequence.delete();
        newtab.setShortcut(new_tab_key_sequence);
        const new_icon = QIcon.fromTheme("document-new");
        defer new_icon.delete();
        newtab.setIcon(new_icon);
        newtab.onTriggered(AppWindow.handleNewTab);

        const open = file_menu.addAction2("Open...");
        const open_key_sequence = QKeySequence.new2("Ctrl+O");
        defer open_key_sequence.delete();
        open.setShortcut(open_key_sequence);
        const open_icon = QIcon.fromTheme("document-open");
        defer open_icon.delete();
        open.setIcon(open_icon);
        open.onTriggered(AppWindow.handleFileOpen);

        _ = file_menu.addSeparator();

        const exit = file_menu.addAction2("Exit");
        const exit_key_sequence = QKeySequence.new2("Ctrl+Q");
        defer exit_key_sequence.delete();
        exit.setShortcut(exit_key_sequence);
        const exit_icon = QIcon.fromTheme("application-exit");
        defer exit_icon.delete();
        exit.setIcon(exit_icon);
        exit.onTriggered(AppWindow.handleExit);

        // Help menu
        const about = mnu.addMenu2("&Help").addAction2("About Qt");
        const about_icon = QIcon.fromTheme("help-about");
        defer about_icon.delete();
        about.setIcon(about_icon);
        const about_shortcut_sequence = QKeySequence.new2("F1");
        defer about_shortcut_sequence.delete();
        about.setShortcut(about_shortcut_sequence);
        about.onTriggered(AppWindow.handleAbout);

        self.w.setMenuBar(mnu);

        // Ctrl+W shortcut
        const close_key_param = "Ctrl+W";
        const close_key_sequence = QKeySequence.new2(close_key_param);
        defer close_key_sequence.delete();
        const close = self.w.addAction4(close_key_param, close_key_sequence);
        close.setShortcut(close_key_sequence);
        close.onTriggered(AppWindow.handleCloseCurrentTab);

        // Main widgets
        self.tabs = .new(self.w);
        self.tabs.setTabsClosable(true);
        self.tabs.setMovable(true);
        self.tabs.onTabCloseRequested(AppWindow.handleTabClose);
        self.w.setCentralWidget(self.tabs);

        // Add initial tab
        self.createTabWithContents(gpa, "README.md", @embedFile("README.md"));

        try app_window_tab_map.put(gpa, self.tabs, self);
    }

    pub fn deinit(self: *const AppWindow) void {
        self.w.delete();
    }

    pub fn createTabWithContents(
        self: *const AppWindow,
        gpa: std.mem.Allocator,
        tab_title: []const u8,
        tab_content: []const u8,
    ) void {
        var tab: AppTab = undefined;
        tab.init(gpa) catch @panic("Failed to create tab");
        // the new tab is cleaned up during handleTabClose

        tab.text_area.setText(tab_content);

        const icon = QIcon.fromTheme("text-markdown");
        defer icon.delete();

        const tab_idx = self.tabs.addTab2(tab.tab, icon, tab_title);
        self.tabs.setCurrentIndex(tab_idx);
    }

    pub fn handleTabClose(tab: QTabWidget, index: i32) callconv(.c) void {
        if (app_window_tab_map.get(tab)) |appwindow| {
            // Get the widget at this index before removing it
            const widget = appwindow.tabs.widget(index);
            if (widget.ptr == null) return;

            // Remove the tab from the tab widget
            appwindow.tabs.removeTab(index);

            // Find and remove the AppTab instance
            var it = app_tab_map.iterator();
            while (it.next()) |entry| {
                const apptab = entry.value_ptr.*;
                if (apptab.tab.ptr == widget.ptr) {
                    _ = app_tab_map.fetchRemove(.{ .ptr = @ptrCast(apptab.text_area.ptr) });
                    _ = app_tab_map.fetchRemove(.{ .ptr = @ptrCast(apptab.outline.ptr) });
                    apptab.deinit();
                    break;
                }
            }
        }
    }

    pub fn handleCloseCurrentTab(_: QAction) callconv(.c) void {
        if (app_window.tabs.ptr != null) {
            const current_index = app_window.tabs.currentIndex();
            if (current_index >= 0)
                handleTabClose(app_window.tabs, current_index);
        }
    }

    pub fn handleNewTab(_: QAction) callconv(.c) void {
        app_window.createTabWithContents(allocator, "New Document", "");
    }

    pub fn handleFileOpen(_: QAction) callconv(.c) void {
        const fname = QFileDialog.getOpenFileName4(
            allocator,
            app_window.w,
            "Open markdown file...",
            "",
            "Markdown files (*.md *.txt);;All Files (*)",
        );
        defer allocator.free(fname);

        if (fname.len == 0) return;

        const file = std.Io.Dir.cwd().openFile(io, fname, .{}) catch
            @panic("Failed to open file");
        defer file.close(io);

        var buffer: [4096]u8 = undefined;
        var file_reader = file.reader(io, &buffer);
        const contents = file_reader.interface.allocRemaining(allocator, .unlimited) catch
            @panic("Failed to read file");
        defer allocator.free(contents);

        app_window.createTabWithContents(allocator, std.Io.Dir.path.basename(fname), contents);
    }

    pub fn handleExit(_: QAction) callconv(.c) void {
        QApplication.quit();
    }

    pub fn handleAbout(_: QAction) callconv(.c) void {
        QApplication.aboutQt();
    }
};

pub fn main(init: std.process.Init) !void {
    const argv = try qt6.init(init.gpa, init.minimal.args);
    defer qt6.deinit(init.gpa, argv);
    var argc: i32 = @intCast(argv.len);
    const qapp: QApplication = .new(init.arena.allocator(), &argc, argv);
    defer qapp.delete();

    allocator = init.gpa;
    io = init.io;

    try app_window.init(init.gpa);
    defer {
        while (app_window.tabs.count() > 0)
            AppWindow.handleTabClose(app_window.tabs, 0);
        app_window.deinit();
        app_tab_map.deinit(init.gpa);
        app_window_tab_map.deinit(init.gpa);
    }

    app_window.w.show();

    _ = QApplication.exec();
}
