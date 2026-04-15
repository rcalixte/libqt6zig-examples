const std = @import("std");
const qt6 = @import("libqt6zig");
const qcoreapplication = qt6.qcoreapplication;
const qmediaplayer = qt6.qmediaplayer;
const qmediaplayer_enums = qt6.qmediaplayer_enums;
const qaudiooutput = qt6.qaudiooutput;
const qurl = qt6.qurl;

var buffer: [32]u8 = undefined;
var io: std.Io = undefined;

pub fn main(init: std.process.Init) !void {
    const argv = try qt6.init(init.gpa, init.minimal.args);
    defer qt6.deinit(init.gpa, argv);
    var argc: i32 = @intCast(argv.len);
    const qapp = qcoreapplication.New(&argc, argv, init.arena.allocator());
    defer qcoreapplication.Delete(qapp);

    io = init.io;

    const player = qmediaplayer.New();
    defer qmediaplayer.Delete(player);

    if (qmediaplayer.Error(player) != qmediaplayer_enums.Error.NoError) {
        try std.Io.File.stdout().writeStreamingAll(init.io, "Failed to create player.\n");
        return;
    }

    const output = qaudiooutput.New();
    defer qaudiooutput.Delete(output);

    qmediaplayer.SetAudioOutput(player, output);
    const url = qurl.New3("src/libraries/multimedia/pixabay-public-domain-strong-hit-36455.mp3");
    defer qurl.Delete(url);
    qmediaplayer.SetSource(player, url);
    qaudiooutput.SetVolume(output, 50);

    qmediaplayer.OnPlaybackStateChanged(player, onPlaybackStateChanged);

    try std.Io.File.stdout().writeStreamingAll(init.io, "Playback starting...\n");
    qmediaplayer.Play(player);

    _ = qcoreapplication.Exec();
}

fn onPlaybackStateChanged(_: ?*anyopaque, state: i32) callconv(.c) void {
    const play_str = std.fmt.bufPrint(&buffer, "Playback state: {d}\n", .{state}) catch @panic("Playback state stdout error");
    std.Io.File.stdout().writeStreamingAll(io, play_str) catch @panic("Failed to write playback state");

    if (state == qmediaplayer_enums.PlaybackState.StoppedState) {
        std.Io.File.stdout().writeStreamingAll(io, "Playback complete.\n") catch @panic("Playback complete stdout error");
        qcoreapplication.Exit();
    }
}
