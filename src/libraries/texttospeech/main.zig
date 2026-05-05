const std = @import("std");
const qt6 = @import("libqt6zig");
const MainWindow = @import("mainwindow.zig");
const MainWindowUi = MainWindow.MainWindowUi;
const QApplication = qt6.QApplication;
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

var ui: *MainWindowUi = undefined;
var speech: QTextToSpeech = .{ .ptr = null };
var voices: []QVoice = &.{};

pub fn main(init: std.process.Init) !void {
    const argv = try qt6.init(init.gpa, init.minimal.args);
    defer qt6.deinit(init.gpa, argv);
    var argc: i32 = @intCast(argv.len);
    const qapp = QApplication.New(init.arena.allocator(), &argc, argv);
    defer qapp.Delete();

    allocator = init.gpa;

    ui = try MainWindow.create(init.gpa);
    defer ui.destroy(init.gpa);

    const engines = QTextToSpeech.AvailableEngines(init.gpa);
    defer {
        for (engines) |engine|
            init.gpa.free(engine);
        init.gpa.free(engines);
    }

    for (engines) |engine| {
        const engine_variant = QVariant.New24(engine);
        defer engine_variant.Delete();

        ui.engine.AddItem22(engine, engine_variant);
    }

    ui.engine.SetCurrentIndex(0);
    onEngineSelected(ui.engine, 0);

    ui.pitch.OnValueChanged(onPitchChanged);
    ui.rate.OnValueChanged(onRateChanged);
    ui.volume.OnValueChanged(onVolumeChanged);
    ui.engine.OnCurrentIndexChanged(onEngineSelected);
    ui.language.OnCurrentIndexChanged(onLanguageSelected);
    ui.voice.OnCurrentIndexChanged(onVoiceSelected);

    ui.MainWindow.Show();

    _ = QApplication.Exec();

    defer {
        if (voices.len > 0) {
            for (voices) |voice|
                voice.Delete();
            init.gpa.free(voices);
        }
    }
}

fn onEngineSelected(self: QComboBox, index: i32) callconv(.c) void {
    const variant = self.ItemData(index);
    defer variant.Delete();

    const engine_name = variant.ToString(allocator);
    defer allocator.free(engine_name);

    if (speech.ptr != null) speech.Delete();

    speech = QTextToSpeech.New5(engine_name, ui.MainWindow);

    if (speech.State() == qtexttospeech_enums.State.Ready)
        onEngineReady()
    else
        speech.OnStateChanged(onStateChanged);
}

fn onEngineReady() void {
    if (speech.State() != qtexttospeech_enums.State.Ready) {
        onStateChanged(speech, speech.State());
        return;
    }

    ui.pauseButton.SetEnabled(false);
    ui.resumeButton.SetEnabled(false);

    const blocker = QSignalBlocker.New(ui.language);
    defer blocker.Delete();

    ui.language.Clear();
    const locales = speech.AvailableLocales(allocator);
    defer allocator.free(locales);

    var current = speech.Locale();
    defer current.Delete();

    const current_name = current.Name(allocator);
    defer allocator.free(current_name);

    for (locales) |locale| {
        defer locale.Delete();

        const language = QLocale.LanguageToString(allocator, locale.Language());
        defer allocator.free(language);

        const territory = QLocale.TerritoryToString(allocator, locale.Territory());
        defer allocator.free(territory);

        const name = std.mem.concat(allocator, u8, &.{ language, " (", territory, ")" }) catch @panic("Failed to concat");
        defer allocator.free(name);

        const variant = QVariant.New21(locale);
        defer variant.Delete();

        ui.language.AddItem22(name, variant);

        const locale_name = locale.Name(allocator);
        defer allocator.free(locale_name);

        if (std.mem.eql(u8, locale_name, current_name))
            current.OperatorAssign(locale);
    }

    onRateChanged(ui.rate, ui.rate.Value());
    onPitchChanged(ui.pitch, ui.pitch.Value());
    onVolumeChanged(ui.volume, ui.volume.Value());

    ui.speakButton.OnClicked(onSpeakClicked);
    ui.stopButton.OnClicked(onStopClicked);
    ui.pauseButton.OnClicked(onPauseClicked);
    ui.resumeButton.OnClicked(onResumeClicked);

    speech.OnStateChanged(onStateChanged);
    speech.OnLocaleChanged(onLocaleChanged);

    blocker.Unblock();
    onLocaleChanged(speech, current);
}

fn onStateChanged(_: QTextToSpeech, state: i32) callconv(.c) void {
    switch (state) {
        qtexttospeech_enums.State.Speaking => ui.statusbar.ShowMessage("Speech started..."),
        qtexttospeech_enums.State.Ready => ui.statusbar.ShowMessage2("Speech stopped...", 2000),
        qtexttospeech_enums.State.Paused => ui.statusbar.ShowMessage("Speech paused..."),
        else => ui.statusbar.ShowMessage("Speech error!"),
    }

    ui.pauseButton.SetEnabled(state == qtexttospeech_enums.State.Speaking);
    ui.resumeButton.SetEnabled(state == qtexttospeech_enums.State.Paused);
    ui.stopButton.SetEnabled(state == qtexttospeech_enums.State.Speaking or state == qtexttospeech_enums.State.Paused);
}

fn onPitchChanged(_: QSlider, value: i32) callconv(.c) void {
    speech.SetPitch(value);
    reset();
}

fn onRateChanged(_: QSlider, value: i32) callconv(.c) void {
    speech.SetRate(value);
    reset();
}

fn onVolumeChanged(_: QSlider, value: i32) callconv(.c) void {
    speech.SetVolume(value);
    reset();
}

fn onLanguageSelected(self: QComboBox, index: i32) callconv(.c) void {
    const variant = self.ItemData(index);
    defer variant.Delete();

    const locale = variant.ToLocale();
    defer locale.Delete();

    speech.SetLocale(locale);
    reset();
}

fn onVoiceSelected(_: QComboBox, index: i32) callconv(.c) void {
    if (voices.len <= index) return;

    speech.SetVoice(voices[@intCast(index)]);
    reset();
}

fn onSpeakClicked(_: QPushButton) callconv(.c) void {
    const text = ui.plainTextEdit.ToPlainText(allocator);
    defer allocator.free(text);

    speech.Say(text);
}

fn onStopClicked(_: QPushButton) callconv(.c) void {
    speech.Stop();
}

fn onPauseClicked(_: QPushButton) callconv(.c) void {
    speech.Pause();
}

fn onResumeClicked(_: QPushButton) callconv(.c) void {
    speech.Resume();
}

fn onLocaleChanged(_: QTextToSpeech, locale: QLocale) callconv(.c) void {
    const variant = QVariant.New21(locale);
    defer variant.Delete();

    ui.language.SetCurrentIndex(ui.language.FindData(variant));

    const blocker = QSignalBlocker.New(ui.voice);
    defer blocker.Delete();

    reset();
    ui.voice.Clear();

    if (voices.len > 0) {
        for (voices) |voice|
            voice.Delete();
        allocator.free(voices);
    }

    voices = speech.AvailableVoices(allocator);

    const current = speech.Voice();
    defer current.Delete();

    const current_name = current.Name(allocator);
    defer allocator.free(current_name);

    for (voices) |voice| {
        const name = voice.Name(allocator);
        defer allocator.free(name);

        const gender_name = QVoice.GenderName(allocator, voice.Gender());
        defer allocator.free(gender_name);

        const age_name = QVoice.AgeName(allocator, voice.Age());
        defer allocator.free(age_name);

        const item = std.mem.concat(allocator, u8, &.{ name, " - ", gender_name, " - ", age_name }) catch @panic("Failed to concat");
        defer allocator.free(item);

        ui.voice.AddItem(item);

        if (std.mem.eql(u8, name, current_name)) ui.voice.SetCurrentIndex(ui.voice.Count() - 1);
    }
}

fn reset() void {
    ui.pauseButton.SetEnabled(false);
    ui.resumeButton.SetEnabled(false);
    speech.Stop();
}
