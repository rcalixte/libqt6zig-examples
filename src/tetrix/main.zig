const std = @import("std");
const qt6 = @import("libqt6zig");
const QApplication = qt6.QApplication;
const QWidget = qt6.QWidget;
const QLabel = qt6.QLabel;
const QLCDNumber = qt6.QLCDNumber;
const QSignalMapper = qt6.QSignalMapper;
const QPushButton = qt6.QPushButton;
const qframe_enums = qt6.qframe_enums;
const qnamespace_enums = qt6.qnamespace_enums;
const qlcdnumber_enums = qt6.qlcdnumber_enums;
const QShortcut = qt6.QShortcut;
const QKeySequence = qt6.QKeySequence;
const qkeysequence_enums = qt6.qkeysequence_enums;
const QMessageBox = qt6.QMessageBox;
const qmessagebox_enums = qt6.qmessagebox_enums;
const QGridLayout = qt6.QGridLayout;
const QFrame = qt6.QFrame;
const QBasicTimer = qt6.QBasicTimer;
const QRandomGenerator = qt6.QRandomGenerator;
const QPixmap = qt6.QPixmap;
const QPainter = qt6.QPainter;
const QColor = qt6.QColor;
const QSize = qt6.QSize;
const QStylePainter = qt6.QStylePainter;
const QPaintEvent = qt6.QPaintEvent;
const QKeyEvent = qt6.QKeyEvent;
const QTimerEvent = qt6.QTimerEvent;

var score_mapper: QSignalMapper = undefined;
var level_mapper: QSignalMapper = undefined;
var lines_mapper: QSignalMapper = undefined;

var global_board: *TetrixBoard = undefined;
var tetrix_window: *TetrixWindow = undefined;

const board_width: i16 = 10;
const board_height: i16 = 22;

const TetrixWindow = struct {
    window: QWidget,
    board: *TetrixBoard,
    next_piece_label: QLabel,
    score_lcd: QLCDNumber,
    level_lcd: QLCDNumber,
    lines_lcd: QLCDNumber,
    new_game_button: QPushButton,
    quit_button: QPushButton,
    pause_button: QPushButton,
    game_over_label: QLabel,

    pub fn create(allocator: std.mem.Allocator) !*TetrixWindow {
        var self = try allocator.create(TetrixWindow);
        errdefer allocator.destroy(self);

        self.board = try TetrixBoard.create(allocator);
        self.next_piece_label = QLabel.New2();
        self.next_piece_label.SetFrameStyle(qframe_enums.Shape.Box | qframe_enums.Shadow.Raised);
        self.next_piece_label.SetAlignment(qnamespace_enums.AlignmentFlag.AlignCenter);
        self.board.next_piece_label = self.next_piece_label;

        self.score_lcd = QLCDNumber.New3(5);
        self.score_lcd.SetSegmentStyle(qlcdnumber_enums.SegmentStyle.Filled);
        self.level_lcd = QLCDNumber.New3(2);
        self.level_lcd.SetSegmentStyle(qlcdnumber_enums.SegmentStyle.Filled);
        self.lines_lcd = QLCDNumber.New3(5);
        self.lines_lcd.SetSegmentStyle(qlcdnumber_enums.SegmentStyle.Filled);

        self.new_game_button = QPushButton.New3("&New Game");
        self.new_game_button.SetFocusPolicy(qnamespace_enums.FocusPolicy.NoFocus);

        const new_key_sequence = QKeySequence.New2("Ctrl+N");
        defer new_key_sequence.Delete();
        const new_shortcut = QShortcut.New2(new_key_sequence, self.new_game_button);
        new_shortcut.OnActivated(onNewGameActivated);

        self.quit_button = QPushButton.New3("&Quit");
        self.quit_button.SetFocusPolicy(qnamespace_enums.FocusPolicy.NoFocus);

        const quit_key_sequence = QKeySequence.New6(qkeysequence_enums.StandardKey.Quit);
        defer quit_key_sequence.Delete();
        const quit_shortcut = QShortcut.New2(quit_key_sequence, self.quit_button);
        quit_shortcut.OnActivated(onQuitActivated);

        self.pause_button = QPushButton.New3("&Pause");
        self.pause_button.SetFocusPolicy(qnamespace_enums.FocusPolicy.NoFocus);
        self.pause_button.SetDisabled(true);

        const pause_key_sequence = QKeySequence.New6(qkeysequence_enums.StandardKey.Cancel);
        defer pause_key_sequence.Delete();
        const pause_shortcut = QShortcut.New2(pause_key_sequence, self.pause_button);
        pause_shortcut.OnActivated(onPauseActivated);

        self.new_game_button.OnClicked(newGame);
        self.quit_button.OnClicked(quit);
        self.pause_button.OnClicked(pause);

        self.game_over_label = QLabel.New2();
        self.game_over_label.SetTextFormat(qnamespace_enums.TextFormat.MarkdownText);
        self.game_over_label.SetAlignment(qnamespace_enums.AlignmentFlag.AlignCenter);
        self.game_over_label.SetText("# Game Over");

        const label_policy = self.game_over_label.SizePolicy();
        defer label_policy.Delete();
        label_policy.SetRetainSizeWhenHidden(true);
        self.game_over_label.SetSizePolicy(label_policy);
        self.game_over_label.Hide();

        self.window = QWidget.New2();
        score_mapper = QSignalMapper.New2(self.window);
        score_mapper.SetMapping(self.score_lcd, 0);
        score_mapper.OnMappedInt(onScoreChanged);

        level_mapper = QSignalMapper.New2(self.window);
        level_mapper.SetMapping(self.level_lcd, 0);
        level_mapper.OnMappedInt(onLevelChanged);

        lines_mapper = QSignalMapper.New2(self.window);
        lines_mapper.SetMapping(self.lines_lcd, 0);
        lines_mapper.OnMappedInt(onLinesRemovedChanged);

        const layout = QGridLayout.New(self.window);
        layout.AddWidget2(createLabel("NEXT"), 0, 0);
        layout.AddWidget2(self.next_piece_label, 1, 0);
        layout.AddWidget2(createLabel("LEVEL"), 2, 0);
        layout.AddWidget2(self.level_lcd, 3, 0);
        layout.AddWidget2(self.new_game_button, 4, 0);
        layout.AddWidget2(self.game_over_label, 5, 0);
        layout.AddWidget3(self.board.frame, 0, 1, 6, 1);
        layout.AddWidget2(createLabel("SCORE"), 0, 2);
        layout.AddWidget2(self.score_lcd, 1, 2);
        layout.AddWidget2(createLabel("LINES REMOVED"), 2, 2);
        layout.AddWidget2(self.lines_lcd, 3, 2);
        layout.AddWidget2(self.quit_button, 4, 2);
        layout.AddWidget2(self.pause_button, 5, 2);
        layout.SetColumnStretch(0, 1);
        layout.SetColumnStretch(1, 2);
        layout.SetColumnStretch(2, 2);
        self.window.SetLayout(layout);

        self.window.SetWindowTitle("Qt 6 Tetrix Example");
        self.window.SetFixedSize2(1000, 750);

        const message_box = QMessageBox.New(self.window);
        message_box.SetOption2(qmessagebox_enums.Option.DontUseNativeDialog, true);
        message_box.SetWindowModality(qnamespace_enums.WindowModality.ApplicationModal);
        message_box.SetTextFormat(qnamespace_enums.TextFormat.MarkdownText);
        message_box.SetWindowTitle("Game Controls");
        message_box.SetText(
            \\### * Left/Right: Move piece
            \\### * Down/Up: Rotate piece
            \\### * D: Move piece one line down
            \\### * Space: Drop piece
            \\### * Alt+N/Ctrl+N: New game
            \\### * Alt+Q/Ctrl+Q: Quit
            \\### * Alt+P/Esc: Pause
        );
        message_box.Show();

        return self;
    }

    fn quit(_: QPushButton) callconv(.c) void {
        QApplication.Quit();
    }

    fn newGame(_: QPushButton) callconv(.c) void {
        if (global_board.is_paused) return;

        global_board.is_started = true;
        global_board.is_waiting_after_line = false;
        global_board.num_lines_removed = 0;
        global_board.num_pieces_dropped = 0;
        global_board.score = 0;
        global_board.level = 1;
        tetrix_window.game_over_label.Hide();
        tetrix_window.pause_button.SetDisabled(false);
        global_board.clearBoard();

        lines_mapper.MappedInt(global_board.num_lines_removed);
        score_mapper.MappedInt(global_board.score);
        level_mapper.MappedInt(global_board.level);

        global_board.newPiece();
        global_board.timer.Start(global_board.timeoutTime(), global_board.frame);
    }

    fn pause(_: QPushButton) callconv(.c) void {
        if (!global_board.is_started) return;

        global_board.is_paused = !global_board.is_paused;
        if (global_board.is_paused)
            global_board.timer.Stop()
        else
            global_board.timer.Start(global_board.timeoutTime(), global_board.frame);

        global_board.frame.Update();
    }

    fn onNewGameActivated(_: QShortcut) callconv(.c) void {
        tetrix_window.new_game_button.Click();
    }

    fn onQuitActivated(_: QShortcut) callconv(.c) void {
        tetrix_window.quit_button.Click();
    }

    fn onPauseActivated(_: QShortcut) callconv(.c) void {
        tetrix_window.pause_button.Click();
    }

    pub fn destroy(self: *TetrixWindow, allocator: std.mem.Allocator) void {
        self.board.destroy(allocator);
        self.window.Delete();
        allocator.destroy(self);
    }

    fn createLabel(text: []const u8) QLabel {
        const label = QLabel.New3(text);
        label.SetAlignment(qnamespace_enums.AlignmentFlag.AlignHCenter |
            qnamespace_enums.AlignmentFlag.AlignBottom);
        return label;
    }

    pub fn onScoreChanged(_: QSignalMapper, value: i32) callconv(.c) void {
        tetrix_window.score_lcd.Display2(value);
    }

    pub fn onLevelChanged(_: QSignalMapper, value: i32) callconv(.c) void {
        tetrix_window.level_lcd.Display2(value);
    }

    pub fn onLinesRemovedChanged(_: QSignalMapper, value: i32) callconv(.c) void {
        tetrix_window.lines_lcd.Display2(value);
    }
};

const TetrixBoard = struct {
    frame: QFrame,
    board: [board_width * board_height]TetrixShape,
    timer: QBasicTimer,
    next_piece_label: QLabel,
    is_started: bool,
    is_paused: bool,
    is_waiting_after_line: bool,
    cur_piece: *TetrixPiece,
    next_piece: *TetrixPiece,
    cur_x: i16,
    cur_y: i16,
    num_lines_removed: u16,
    num_pieces_dropped: u16,
    score: u17,
    level: u10,

    var frame_width: i32 = undefined;

    pub fn create(allocator: std.mem.Allocator) !*TetrixBoard {
        var self = try allocator.create(TetrixBoard);
        errdefer allocator.destroy(self);

        self.frame = QFrame.New2();
        self.frame.SetFrameStyle(qframe_enums.Shape.Panel | qframe_enums.Shadow.Sunken);
        self.frame.SetFocusPolicy(qnamespace_enums.FocusPolicy.StrongFocus);
        self.clearBoard();

        self.next_piece = try allocator.create(TetrixPiece);
        errdefer allocator.destroy(self.next_piece);

        self.cur_piece = try allocator.create(TetrixPiece);
        self.cur_piece.setShape(.no_shape);
        self.cur_x = 0;
        self.cur_y = 0;
        self.is_started = false;
        self.is_paused = false;

        self.next_piece.setRandomShape();
        self.next_piece_label = .{ .ptr = null };

        frame_width = self.frame.FrameWidth();
        self.timer = QBasicTimer.New();

        self.frame.OnSizeHint(onSizeHint);
        self.frame.OnMinimumSizeHint(onMinimumSizeHint);
        self.frame.OnPaintEvent(onPaintEvent);
        self.frame.OnKeyPressEvent(onKeyPressEvent);
        self.frame.OnTimerEvent(onTimerEvent);

        return self;
    }

    pub fn destroy(self: *TetrixBoard, allocator: std.mem.Allocator) void {
        allocator.destroy(self.next_piece);
        allocator.destroy(self.cur_piece);
        self.timer.Delete();
        self.frame.Delete();
        allocator.destroy(self);
    }

    fn onSizeHint() callconv(.c) QSize {
        return QSize.New4(
            board_width * 15 + frame_width * 2,
            board_height * 15 + frame_width * 2,
        );
    }

    fn onMinimumSizeHint() callconv(.c) QSize {
        return QSize.New4(
            board_width * 5 + frame_width * 2,
            board_height * 5 + frame_width * 2,
        );
    }

    fn onPaintEvent(self: QFrame, event: QPaintEvent) callconv(.c) void {
        self.SuperPaintEvent(event);

        const painter = QStylePainter.New(self);
        defer painter.Delete();

        const rect = self.ContentsRect();
        defer rect.Delete();

        if (global_board.is_paused) {
            painter.DrawText6(rect, qnamespace_enums.AlignmentFlag.AlignCenter, "Pause");
            return;
        }

        const board_top = rect.Bottom() - board_height * global_board.squareHeight();

        for (0..board_height) |i|
            for (0..board_width) |j| {
                const shape = global_board.shapeAt(j, board_height - i - 1);
                if (shape != .no_shape)
                    global_board.drawSquare(
                        .{ .ptr = @ptrCast(painter.ptr) },
                        rect.Left() + @as(i32, @intCast(j)) * global_board.squareWidth(),
                        board_top + @as(i32, @intCast(i)) * global_board.squareHeight(),
                        shape,
                    );
            };

        if (global_board.cur_piece.piece_shape != .no_shape)
            for (0..num_cells) |i| {
                const x = global_board.cur_x + global_board.cur_piece.x(i);
                const y = global_board.cur_y - global_board.cur_piece.y(i);
                global_board.drawSquare(
                    .{ .ptr = @ptrCast(painter.ptr) },
                    rect.Left() + x * global_board.squareWidth(),
                    board_top + (board_height - y - 1) * global_board.squareHeight(),
                    global_board.cur_piece.piece_shape,
                );
            };
    }

    fn onKeyPressEvent(self: QFrame, event: QKeyEvent) callconv(.c) void {
        if (!global_board.is_started or global_board.is_paused or global_board.cur_piece.piece_shape == .no_shape) {
            self.SuperKeyPressEvent(event);
            return;
        }

        switch (event.Key()) {
            qnamespace_enums.Key.Key_Left => _ = global_board.tryMove(
                global_board.cur_piece,
                global_board.cur_x - 1,
                global_board.cur_y,
            ),
            qnamespace_enums.Key.Key_Right => _ = global_board.tryMove(
                global_board.cur_piece,
                global_board.cur_x + 1,
                global_board.cur_y,
            ),
            qnamespace_enums.Key.Key_Down => {
                if (global_board.cur_x == 0 or global_board.cur_x >= board_width - 1) return;
                if (global_board.cur_piece.piece_shape == .line_shape and
                    global_board.cur_x <= 1 or global_board.cur_x >= board_width - 2) return;

                global_board.cur_piece.rotatedRight();
                _ = global_board.tryMove(
                    global_board.cur_piece,
                    global_board.cur_x,
                    global_board.cur_y,
                );
            },
            qnamespace_enums.Key.Key_Up => {
                if (global_board.cur_x == 0 or global_board.cur_x >= board_width - 1) return;
                if (global_board.cur_piece.piece_shape == .line_shape and
                    global_board.cur_x <= 1 or global_board.cur_x >= board_width - 2) return;

                global_board.cur_piece.rotatedLeft();
                _ = global_board.tryMove(
                    global_board.cur_piece,
                    global_board.cur_x,
                    global_board.cur_y,
                );
            },
            qnamespace_enums.Key.Key_Space => global_board.dropDown(),
            qnamespace_enums.Key.Key_D => global_board.oneLineDown(),
            else => self.SuperKeyPressEvent(event),
        }
    }

    fn onTimerEvent(self: QFrame, event: QTimerEvent) callconv(.c) void {
        if (event.TimerId() == global_board.timer.TimerId())
            if (global_board.is_waiting_after_line) {
                global_board.is_waiting_after_line = false;
                global_board.newPiece();
                global_board.timer.Start(global_board.timeoutTime(), self);
            } else global_board.oneLineDown()
        else
            self.SuperTimerEvent(event);
    }

    pub fn clearBoard(self: *TetrixBoard) void {
        for (0..board_height * board_width) |i|
            self.board[i] = .no_shape;
    }

    pub fn timeoutTime(self: *TetrixBoard) i16 {
        return @divTrunc(1000, (self.level + 1));
    }

    pub fn squareWidth(self: *TetrixBoard) i32 {
        const rect = self.frame.ContentsRect();
        defer rect.Delete();

        return @divTrunc(rect.Width(), board_width);
    }

    pub fn squareHeight(self: *TetrixBoard) i32 {
        const rect = self.frame.ContentsRect();
        defer rect.Delete();

        return @divTrunc(rect.Height(), board_height);
    }

    pub fn dropDown(self: *TetrixBoard) void {
        var drop_height: u8 = 0;
        var new_y: i16 = self.cur_y;
        while (new_y > 0) : (new_y -= 1) {
            if (!self.tryMove(self.cur_piece, self.cur_x, new_y - 1))
                break;
            drop_height += 1;
        }
        self.pieceDropped(drop_height);
    }

    pub fn oneLineDown(self: *TetrixBoard) void {
        if (!self.tryMove(self.cur_piece, self.cur_x, self.cur_y - 1))
            self.pieceDropped(0);
    }

    pub fn pieceDropped(self: *TetrixBoard, drop_height: u8) void {
        for (0..num_cells) |i| {
            const x = self.cur_x + self.cur_piece.x(i);
            const y = self.cur_y - self.cur_piece.y(i);
            self.board[@as(usize, @intCast(y)) * board_width + @as(usize, @intCast(x))] = self.cur_piece.piece_shape;
        }

        self.num_pieces_dropped += 1;
        if (@mod(self.num_pieces_dropped, 25) == 0) {
            self.level += 1;
            self.timer.Start(self.timeoutTime(), self.frame);
            level_mapper.MappedInt(self.level);
        }

        self.score += drop_height + 7;
        score_mapper.MappedInt(self.score);
        self.removeFullLines();

        if (!self.is_waiting_after_line) self.newPiece();
    }

    pub fn shapeAt(self: *TetrixBoard, x: usize, y: usize) TetrixShape {
        return self.board[y * board_width + x];
    }

    pub fn removeFullLines(self: *TetrixBoard) void {
        var num_full_lines: u8 = 0;
        var i: i8 = board_height - 1;
        while (i >= 0) : (i -= 1) {
            var line_full = true;
            for (0..board_width) |j|
                if (self.shapeAt(j, @intCast(i)) == .no_shape) {
                    line_full = false;
                    break;
                };
            if (line_full) {
                num_full_lines += 1;
                for (@intCast(i)..board_height - 1) |k| {
                    for (0..board_width) |j|
                        self.board[k * board_width + j] = self.shapeAt(j, k + 1);
                }
                for (0..board_width) |j|
                    self.board[(board_height - 1) * board_width + j] = .no_shape;
            }
        }

        if (num_full_lines > 0) {
            self.num_lines_removed += num_full_lines;
            self.score += 10 * num_full_lines;
            lines_mapper.MappedInt(self.num_lines_removed);
            score_mapper.MappedInt(self.score);

            self.timer.Start(500, self.frame);
            self.is_waiting_after_line = true;
            self.cur_piece.setShape(.no_shape);
            self.frame.Update();
        }
    }

    pub fn newPiece(self: *TetrixBoard) void {
        self.cur_piece.* = self.next_piece.*;
        self.next_piece.setRandomShape();
        self.showNextPiece();
        self.cur_x = board_width / 2 + 1;
        self.cur_y = board_height - 1 + self.cur_piece.minY();

        if (!self.tryMove(self.cur_piece, self.cur_x, self.cur_y)) {
            self.cur_piece.setShape(.no_shape);
            self.timer.Stop();
            self.is_started = false;
            tetrix_window.game_over_label.Show();
            tetrix_window.pause_button.SetDisabled(true);
        }
    }

    pub fn showNextPiece(self: *TetrixBoard) void {
        if (self.next_piece_label.ptr == null) return;

        const dx = self.next_piece.maxX() - self.next_piece.minX() + 1;
        const dy = self.next_piece.maxY() - self.next_piece.minY() + 1;

        const pixmap = QPixmap.New2(dx * self.squareWidth(), dy * self.squareHeight());
        defer pixmap.Delete();

        const painter = QPainter.New2(pixmap);
        defer painter.Delete();

        const rect = pixmap.Rect();
        defer rect.Delete();

        painter.FillRect3(rect, self.next_piece_label.Palette().Window());

        for (0..num_cells) |i| {
            const x = self.next_piece.x(i) - self.next_piece.minX();
            const y = self.next_piece.y(i) - self.next_piece.minY();
            self.drawSquare(
                painter,
                x * self.squareWidth(),
                y * self.squareHeight(),
                self.next_piece.piece_shape,
            );
        }
        self.next_piece_label.SetPixmap(pixmap);
    }

    pub fn drawSquare(self: *TetrixBoard, painter: QPainter, x: i32, y: i32, shape: TetrixShape) void {
        const color_table = [8]u32{
            0x000000, 0xCC6666, 0x66CC66, 0x6666CC,
            0xCCCC66, 0xCC66CC, 0x66CCCC, 0xDAAA00,
        };

        const color = QColor.New6(color_table[@intFromEnum(shape)]);
        defer color.Delete();

        const lighter = color.Lighter();
        defer lighter.Delete();

        const darker = color.Darker();
        defer darker.Delete();

        painter.FillRect5(x + 1, y + 1, self.squareWidth() - 2, self.squareHeight() - 2, color);
        painter.SetPen(lighter);
        painter.DrawLine3(x, y + self.squareHeight() - 1, x, y);
        painter.DrawLine3(x, y, x + self.squareWidth() - 1, y);

        painter.SetPen(darker);
        painter.DrawLine3(x + 1, y + self.squareHeight() - 1, x + self.squareWidth() - 1, y + self.squareHeight() - 1);
        painter.DrawLine3(x + self.squareWidth() - 1, y + self.squareHeight() - 1, x + self.squareWidth() - 1, y + 1);
    }

    pub fn tryMove(self: *TetrixBoard, new_piece: *TetrixPiece, new_x: i16, new_y: i16) bool {
        for (0..num_cells) |i| {
            const x = new_x + new_piece.x(i);
            const y = new_y - new_piece.y(i);
            if (x < 0 or x >= board_width or y < 0 or y >= board_height) return false;
            if (self.shapeAt(@intCast(x), @intCast(y)) != .no_shape) return false;
        }

        self.cur_piece.* = new_piece.*;
        self.cur_x = new_x;
        self.cur_y = new_y;
        self.frame.Update();
        return true;
    }
};

const num_shapes: u8 = @typeInfo(TetrixShape).@"enum".fields.len;
const num_cells: u4 = 4;
const pair_cells: u2 = 2;

const TetrixPiece = struct {
    piece_shape: TetrixShape,
    coords: [num_cells][pair_cells]i8,

    pub fn setRandomShape(self: *TetrixPiece) void {
        self.setShape(@enumFromInt(QRandomGenerator.Global().Bounded2(num_shapes - 1) + 1));
    }

    pub fn setShape(self: *TetrixPiece, shape: TetrixShape) void {
        const coords_table = [num_shapes][num_cells][pair_cells]i8{
            .{ .{ 0, 0 }, .{ 0, 0 }, .{ 0, 0 }, .{ 0, 0 } },
            .{ .{ 0, -1 }, .{ 0, 0 }, .{ -1, 0 }, .{ -1, 1 } },
            .{ .{ 0, -1 }, .{ 0, 0 }, .{ 1, 0 }, .{ 1, 1 } },
            .{ .{ 0, -1 }, .{ 0, 0 }, .{ 0, 1 }, .{ 0, 2 } },
            .{ .{ -1, 0 }, .{ 0, 0 }, .{ 1, 0 }, .{ 0, 1 } },
            .{ .{ 0, 0 }, .{ 1, 0 }, .{ 0, 1 }, .{ 1, 1 } },
            .{ .{ -1, -1 }, .{ 0, -1 }, .{ 0, 0 }, .{ 0, 1 } },
            .{ .{ 1, -1 }, .{ 0, -1 }, .{ 0, 0 }, .{ 0, 1 } },
        };

        for (0..num_cells) |i| {
            for (0..pair_cells) |j|
                self.coords[i][j] = coords_table[@intFromEnum(shape)][i][j];
        }

        self.piece_shape = shape;
    }

    pub fn x(self: *TetrixPiece, index: usize) i8 {
        return self.coords[index][0];
    }

    pub fn y(self: *TetrixPiece, index: usize) i8 {
        return self.coords[index][1];
    }

    pub fn minX(self: *TetrixPiece) i8 {
        var min = self.coords[0][0];
        for (1..num_cells) |i|
            min = @min(min, self.coords[i][0]);
        return min;
    }

    pub fn maxX(self: *TetrixPiece) i8 {
        var max = self.coords[0][0];
        for (1..num_cells) |i|
            max = @max(max, self.coords[i][0]);
        return max;
    }

    pub fn minY(self: *TetrixPiece) i8 {
        var min = self.coords[0][1];
        for (1..num_cells) |i|
            min = @min(min, self.coords[i][1]);
        return min;
    }

    pub fn maxY(self: *TetrixPiece) i8 {
        var max = self.coords[0][1];
        for (1..num_cells) |i|
            max = @max(max, self.coords[i][1]);
        return max;
    }

    pub fn rotatedLeft(self: *TetrixPiece) void {
        if (self.piece_shape == .square_shape) return;

        for (0..num_cells) |i| {
            const _x = self.x(i);
            const _y = self.y(i);
            self.setX(i, _y);
            self.setY(i, -_x);
        }
    }

    pub fn rotatedRight(self: *TetrixPiece) void {
        if (self.piece_shape == .square_shape) return;

        for (0..num_cells) |i| {
            const _x = self.x(i);
            const _y = self.y(i);
            self.setX(i, -_y);
            self.setY(i, _x);
        }
    }

    fn setX(self: *TetrixPiece, index: usize, X: i8) void {
        self.coords[index][0] = X;
    }

    fn setY(self: *TetrixPiece, index: usize, Y: i8) void {
        self.coords[index][1] = Y;
    }
};

const TetrixShape = enum(u8) {
    no_shape,
    z_shape,
    s_shape,
    line_shape,
    t_shape,
    square_shape,
    l_shape,
    mirrored_l_shape,
};

pub fn main(init: std.process.Init) !void {
    const argv = try qt6.init(init.gpa, init.minimal.args);
    defer qt6.deinit(init.gpa, argv);
    var argc: i32 = @intCast(argv.len);
    const qapp = QApplication.New(init.arena.allocator(), &argc, argv);
    defer qapp.Delete();

    tetrix_window = try TetrixWindow.create(init.gpa);
    defer tetrix_window.destroy(init.gpa);

    global_board = tetrix_window.board;

    tetrix_window.window.Show();

    _ = QApplication.Exec();
}
