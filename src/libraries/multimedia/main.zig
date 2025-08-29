const std = @import("std");
const qt6 = @import("libqt6zig");
const qapplication = qt6.qapplication;
const qmediaplayer = qt6.qmediaplayer;
const qmediaplayer_enums = qt6.qmediaplayer_enums;
const qaudiooutput = qt6.qaudiooutput;
const qurl = qt6.qurl;
const qcoreapplication = qt6.qcoreapplication;

var buffer: [32]u8 = undefined;
var stdout_writer = std.fs.File.stdout().writer(&buffer);

pub fn main() !void {
    const argc = std.os.argv.len;
    const argv = std.os.argv.ptr;
    _ = qapplication.New(argc, argv);

    const player = qmediaplayer.New();
    defer qmediaplayer.QDelete(player);

    const output = qaudiooutput.New();
    defer qaudiooutput.QDelete(output);

    qmediaplayer.SetAudioOutput(player, output);
    const url = qurl.New3("src/libraries/multimedia/pixabay-public-domain-strong-hit-36455.mp3");
    defer qurl.QDelete(url);
    qmediaplayer.SetSource(player, url);
    qaudiooutput.SetVolume(output, 50);

    qmediaplayer.OnPlaybackStateChanged(player, onPlaybackStateChanged);

    try stdout_writer.interface.writeAll("Playback starting...\n");
    try stdout_writer.interface.flush();
    qmediaplayer.Play(player);

    _ = qapplication.Exec();
}

fn onPlaybackStateChanged(_: ?*anyopaque, state: i32) callconv(.c) void {
    stdout_writer.interface.print("Playback state: {any}\n", .{state}) catch @panic("Playback state stdout error");
    stdout_writer.interface.flush() catch @panic("Failed to flush stdout writer");

    if (state == qmediaplayer_enums.PlaybackState.StoppedState) {
        stdout_writer.interface.writeAll("Playback complete.\n") catch @panic("Playback complete stdout error");
        stdout_writer.interface.flush() catch @panic("Failed to flush stdout writer");
        qcoreapplication.Exit();
    }
}
