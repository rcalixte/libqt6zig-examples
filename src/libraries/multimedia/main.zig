const std = @import("std");
const qt6 = @import("libqt6zig");
const QCoreApplication = qt6.QCoreApplication;
const QMediaPlayer = qt6.QMediaPlayer;
const qmediaplayer_enums = qt6.qmediaplayer_enums;
const QAudioOutput = qt6.QAudioOutput;
const QUrl = qt6.QUrl;

var buffer: [32]u8 = undefined;
var io: std.Io = undefined;

pub fn main(init: std.process.Init) !void {
    const argv = try qt6.init(init.gpa, init.minimal.args);
    defer qt6.deinit(init.gpa, argv);
    var argc: i32 = @intCast(argv.len);
    const qapp: QCoreApplication = .new(init.arena.allocator(), &argc, argv);
    defer qapp.delete();

    io = init.io;

    const player = QMediaPlayer.new();
    defer player.delete();

    if (player.error0() != qmediaplayer_enums.Error.NoError) {
        std.log.err("Failed to create player.", .{});
        return;
    }

    const output = QAudioOutput.new();
    defer output.delete();

    player.setAudioOutput(output);
    const url = QUrl.fromLocalFile("src/libraries/multimedia/pixabay-public-domain-strong-hit-36455.mp3");
    defer url.delete();

    player.setSource(url);
    output.setVolume(50);

    player.onPlaybackStateChanged(onPlaybackStateChanged);

    try std.Io.File.stdout().writeStreamingAll(init.io, "Playback starting...\n");
    player.play();

    _ = QCoreApplication.exec();
}

fn onPlaybackStateChanged(_: QMediaPlayer, state: i32) callconv(.c) void {
    const play_str = std.fmt.bufPrint(&buffer, "Playback state: {d}\n", .{state}) catch
        @panic("Playback state stdout error");
    std.Io.File.stdout().writeStreamingAll(io, play_str) catch
        @panic("Failed to write playback state");

    if (state == qmediaplayer_enums.PlaybackState.StoppedState) {
        std.Io.File.stdout().writeStreamingAll(io, "Playback complete.\n") catch
            @panic("Playback complete stdout error");
        QCoreApplication.exit();
    }
}
