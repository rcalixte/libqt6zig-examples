const std = @import("std");
const qt6 = @import("libqt6zig");
const qapplication = qt6.qapplication;
const qmediaplayer = qt6.qmediaplayer;
const qmediaplayer_enums = qt6.qmediaplayer_enums;
const qaudiooutput = qt6.qaudiooutput;
const qurl = qt6.qurl;
const qcoreapplication = qt6.qcoreapplication;

const allocator = std.heap.page_allocator;
const stdout = std.io.getStdOut().writer();

pub fn main() !void {
    const argc = std.os.argv.len;
    const argv = std.os.argv.ptr;
    _ = qapplication.New(argc, argv);

    const mp3 = try std.fs.cwd().realpathAlloc(allocator, "src/libraries/multimedia/pixabay-public-domain-strong-hit-36455.mp3");
    defer allocator.free(mp3);

    const player = qmediaplayer.New();
    defer qmediaplayer.QDelete(player);

    const output = qaudiooutput.New();
    defer qaudiooutput.QDelete(output);

    qmediaplayer.SetAudioOutput(player, output);
    const url = qurl.New3(mp3);
    defer qurl.QDelete(url);
    qmediaplayer.SetSource(player, url);
    qaudiooutput.SetVolume(output, 50);

    qmediaplayer.OnPlaybackStateChanged(player, onPlaybackStateChanged);

    try stdout.print("Playback starting...\n", .{});
    qmediaplayer.Play(player);

    _ = qapplication.Exec();
}

fn onPlaybackStateChanged(_: ?*anyopaque, state: i64) callconv(.c) void {
    stdout.print("Playback state: {any}\n", .{state}) catch @panic("Playback state stdout error");

    if (state == qmediaplayer_enums.PlaybackState.StoppedState) {
        stdout.print("Playback complete.\n", .{}) catch @panic("Playback complete stdout error");
        qcoreapplication.Exit();
    }
}
