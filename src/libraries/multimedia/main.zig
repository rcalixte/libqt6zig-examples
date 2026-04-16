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
    const qapp = QCoreApplication.New(init.arena.allocator(), &argc, argv);
    defer qapp.Delete();

    io = init.io;

    const player = QMediaPlayer.New();
    defer player.Delete();

    if (player.Error() != qmediaplayer_enums.Error.NoError) {
        try std.Io.File.stdout().writeStreamingAll(init.io, "Failed to create player.\n");
        return;
    }

    const output = QAudioOutput.New();
    defer output.Delete();

    player.SetAudioOutput(output);
    const url = QUrl.New3("src/libraries/multimedia/pixabay-public-domain-strong-hit-36455.mp3");
    defer url.Delete();

    player.SetSource(url);
    output.SetVolume(50);

    player.OnPlaybackStateChanged(onPlaybackStateChanged);

    try std.Io.File.stdout().writeStreamingAll(init.io, "Playback starting...\n");
    player.Play();

    _ = QCoreApplication.Exec();
}

fn onPlaybackStateChanged(_: QMediaPlayer, state: i32) callconv(.c) void {
    const play_str = std.fmt.bufPrint(&buffer, "Playback state: {d}\n", .{state}) catch @panic("Playback state stdout error");
    std.Io.File.stdout().writeStreamingAll(io, play_str) catch @panic("Failed to write playback state");

    if (state == qmediaplayer_enums.PlaybackState.StoppedState) {
        std.Io.File.stdout().writeStreamingAll(io, "Playback complete.\n") catch @panic("Playback complete stdout error");
        QCoreApplication.Exit();
    }
}
