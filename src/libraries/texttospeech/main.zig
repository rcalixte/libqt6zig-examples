const std = @import("std");
const qt6 = @import("libqt6zig");
const MainWindow = @import("mainwindow.zig");
const MainWindowUi = MainWindow.MainWindowUi;
const QApplication = qt6.QApplication;
const QWidget = qt6.QWidget;
const QVoice = qt6.QVoice;
const QVariant = qt6.QVariant;
const QTextToSpeech = qt6.QTextToSpeech;
const QSignalBlocker = qt6.QSignalBlocker;
const QComboBox = qt6.QComboBox;
const qtexttospeech_enums = qt6.qtexttospeech_enums;
const QLocale = qt6.QLocale;
const QSlider = qt6.QSlider;
const QPushButton = qt6.QPushButton;

var allocator: std.mem.Allocator = undefined;

var ui: MainWindowUi = undefined;
var speech: QTextToSpeech = .{ .ptr = null };
var voices: []QVoice = &.{};

pub fn main(init: std.process.Init) !void {
    const argv = try qt6.init(init.gpa, init.minimal.args);
    defer qt6.deinit(init.gpa, argv);
    var argc: i32 = @intCast(argv.len);
    const qapp: QApplication = .new(init.arena.allocator(), &argc, argv);
    defer qapp.delete();

    allocator = init.gpa;

    ui.init(init.gpa, QWidget{ .ptr = null });
    defer ui.deinit();

    const engines = QTextToSpeech.availableEngines(init.gpa);
    defer {
        for (engines) |engine|
            init.gpa.free(engine);
        init.gpa.free(engines);
    }

    for (engines) |engine| {
        const engine_variant = QVariant.new24(engine);
        defer engine_variant.delete();

        ui.engine.addItem22(engine, engine_variant);
    }

    ui.engine.setCurrentIndex(0);
    onEngineSelected(ui.engine, 0);

    ui.pitch.onValueChanged(onPitchChanged);
    ui.rate.onValueChanged(onRateChanged);
    ui.volume.onValueChanged(onVolumeChanged);
    ui.engine.onCurrentIndexChanged(onEngineSelected);
    ui.language.onCurrentIndexChanged(onLanguageSelected);
    ui.voice.onCurrentIndexChanged(onVoiceSelected);

    ui.MainWindow.show();

    _ = QApplication.exec();

    defer {
        if (voices.len > 0) {
            for (voices) |voice|
                voice.delete();
            init.gpa.free(voices);
        }
    }
}

fn onEngineSelected(self: QComboBox, index: i32) callconv(.c) void {
    const variant = self.itemData(index);
    defer variant.delete();

    const engine_name = variant.toString(allocator);
    defer allocator.free(engine_name);

    if (speech.ptr != null) speech.delete();

    speech = .new5(engine_name, ui.MainWindow);

    if (speech.state() == qtexttospeech_enums.State.Ready)
        onEngineReady()
    else
        speech.onStateChanged(onStateChanged);
}

fn onEngineReady() void {
    if (speech.state() != qtexttospeech_enums.State.Ready) {
        onStateChanged(speech, speech.state());
        return;
    }

    ui.pauseButton.setEnabled(false);
    ui.resumeButton.setEnabled(false);

    const blocker = QSignalBlocker.new(ui.language);
    defer blocker.delete();

    ui.language.clear();
    const locales = speech.availableLocales(allocator);
    defer allocator.free(locales);

    var current = speech.locale();
    defer current.delete();

    const current_name = current.name(allocator);
    defer allocator.free(current_name);

    for (locales) |locale| {
        defer locale.delete();

        const language = QLocale.languageToString(allocator, locale.language());
        defer allocator.free(language);

        const territory = QLocale.territoryToString(allocator, locale.territory());
        defer allocator.free(territory);

        const name = std.mem.concat(allocator, u8, &.{ language, " (", territory, ")" }) catch
            @panic("Failed to concat");
        defer allocator.free(name);

        const variant = QVariant.new21(locale);
        defer variant.delete();

        ui.language.addItem22(name, variant);

        const locale_name = locale.name(allocator);
        defer allocator.free(locale_name);

        if (std.mem.eql(u8, locale_name, current_name))
            current.operatorAssign(locale);
    }

    onRateChanged(ui.rate, ui.rate.value());
    onPitchChanged(ui.pitch, ui.pitch.value());
    onVolumeChanged(ui.volume, ui.volume.value());

    ui.speakButton.onClicked(onSpeakClicked);
    ui.stopButton.onClicked(onStopClicked);
    ui.pauseButton.onClicked(onPauseClicked);
    ui.resumeButton.onClicked(onResumeClicked);

    speech.onStateChanged(onStateChanged);
    speech.onLocaleChanged(onLocaleChanged);

    blocker.unblock();
    onLocaleChanged(speech, current);
}

fn onStateChanged(_: QTextToSpeech, state: i32) callconv(.c) void {
    switch (state) {
        qtexttospeech_enums.State.Speaking => ui.statusbar.showMessage("Speech started..."),
        qtexttospeech_enums.State.Ready => ui.statusbar.showMessage2("Speech stopped...", 2000),
        qtexttospeech_enums.State.Paused => ui.statusbar.showMessage("Speech paused..."),
        else => ui.statusbar.showMessage("Speech error!"),
    }

    ui.pauseButton.setEnabled(state == qtexttospeech_enums.State.Speaking);
    ui.resumeButton.setEnabled(state == qtexttospeech_enums.State.Paused);
    ui.stopButton.setEnabled(state == qtexttospeech_enums.State.Speaking or state == qtexttospeech_enums.State.Paused);
}

fn onPitchChanged(_: QSlider, value: i32) callconv(.c) void {
    speech.setPitch(value);
    reset();
}

fn onRateChanged(_: QSlider, value: i32) callconv(.c) void {
    speech.setRate(value);
    reset();
}

fn onVolumeChanged(_: QSlider, value: i32) callconv(.c) void {
    speech.setVolume(value);
    reset();
}

fn onLanguageSelected(self: QComboBox, index: i32) callconv(.c) void {
    const variant = self.itemData(index);
    defer variant.delete();

    const locale = variant.toLocale();
    defer locale.delete();

    speech.setLocale(locale);
    reset();
}

fn onVoiceSelected(_: QComboBox, index: i32) callconv(.c) void {
    if (voices.len <= index) return;

    speech.setVoice(voices[@intCast(index)]);
    reset();
}

fn onSpeakClicked(_: QPushButton) callconv(.c) void {
    const text = ui.plainTextEdit.toPlainText(allocator);
    defer allocator.free(text);

    speech.say(text);
}

fn onStopClicked(_: QPushButton) callconv(.c) void {
    speech.stop();
}

fn onPauseClicked(_: QPushButton) callconv(.c) void {
    speech.pause();
}

fn onResumeClicked(_: QPushButton) callconv(.c) void {
    speech.resume0();
}

fn onLocaleChanged(_: QTextToSpeech, locale: QLocale) callconv(.c) void {
    const variant = QVariant.new21(locale);
    defer variant.delete();

    ui.language.setCurrentIndex(ui.language.findData(variant));

    const blocker = QSignalBlocker.new(ui.voice);
    defer blocker.delete();

    reset();
    ui.voice.clear();

    if (voices.len > 0) {
        for (voices) |voice|
            voice.delete();
        allocator.free(voices);
    }

    voices = speech.availableVoices(allocator);

    const current = speech.voice();
    defer current.delete();

    const current_name = current.name(allocator);
    defer allocator.free(current_name);

    for (voices) |voice| {
        const name = voice.name(allocator);
        defer allocator.free(name);

        const gender_name = QVoice.genderName(allocator, voice.gender());
        defer allocator.free(gender_name);

        const age_name = QVoice.ageName(allocator, voice.age());
        defer allocator.free(age_name);

        const item = std.mem.concat(allocator, u8, &.{ name, " - ", gender_name, " - ", age_name }) catch
            @panic("Failed to concat");
        defer allocator.free(item);

        ui.voice.addItem(item);

        if (std.mem.eql(u8, name, current_name)) ui.voice.setCurrentIndex(ui.voice.count() - 1);
    }
}

fn reset() void {
    ui.pauseButton.setEnabled(false);
    ui.resumeButton.setEnabled(false);
    speech.stop();
}
