"""Render the original title theme with the project's pinned instrument samples."""

import json
from pathlib import Path
from functools import lru_cache
import wave

import numpy as np
from scipy import signal

from compose_wuxia_original_trial import ROOT, SR, decode, sha


BPM = 108
OUTPUT = ROOT / "game/art/audio/bgm/bgm_title_sword_journey_20261113.wav"
RAW = ROOT / "assets/raw/audio"
# D pentatonic. Each row is one bar, expressed as (MIDI note, beats).
# Zero denotes a breath. The first four bars form the recurring title motif.
MELODY = (
    ((74, 1.5), (76, .5), (78, 1), (81, 1)),
    ((83, 1.5), (81, .5), (78, 1), (76, .5), (0, .5)),
    ((78, .75), (81, .25), (83, 1), (86, 1.5), (83, .5)),
    ((81, 1.5), (78, .5), (76, .5), (74, 1), (0, .5)),
    ((69, 1), (71, .5), (74, .5), (76, 1), (78, 1)),
    ((81, 2), (78, .5), (76, .5), (74, .5), (0, .5)),
    ((76, .75), (78, .25), (81, 1), (83, 1), (81, 1)),
    ((78, 1.5), (76, .5), (74, 1.5), (0, .5)),
    ((0, .5), (71, .5), (74, 1.5), (76, .5), (78, 1)),
    ((76, 1.5), (74, .5), (71, 1), (69, .5), (0, .5)),
    ((71, .5), (74, .5), (78, 1), (76, .5), (78, .5), (81, 1)),
    ((83, 2), (81, .5), (78, .5), (76, .5), (0, .5)),
    ((74, 1.5), (76, .5), (78, .5), (81, .5), (83, 1)),
    ((86, 1.5), (83, .5), (81, 1), (78, .5), (0, .5)),
    ((81, .75), (83, .25), (86, 1), (88, 1), (86, .5), (83, .5)),
    ((81, 1), (78, .5), (76, .5), (74, 1.5), (0, .5)),
    ((83, 1), (81, 1), (78, .75), (81, .25), (83, 1)),
    ((86, 2), (83, .5), (81, .5), (78, .5), (0, .5)),
    ((76, .75), (78, .25), (81, 1), (78, .75), (76, .25), (74, 1)),
    ((74, 2.5), (0, 1), (69, .5)),
)
HARMONY = (
    (50, 57, 62), (47, 54, 62), (43, 50, 59), (45, 52, 57),
    (50, 57, 66), (47, 54, 62), (43, 50, 59), (45, 52, 57),
    (47, 54, 62), (47, 54, 59), (43, 50, 59), (45, 52, 64),
    (50, 57, 66), (47, 54, 62), (43, 50, 59), (45, 52, 64),
    (47, 54, 62), (43, 50, 59), (45, 52, 64), (50, 57, 62),
)


@lru_cache(maxsize=None)
def sample(path, expected_sha):
    assert sha(path) == expected_sha, path
    return decode(path)


def frames(beats):
    return round(beats * SR * 60 / BPM)


def pitch_shift(audio, semitones):
    rate = 2 ** (semitones / 12)
    positions = np.arange(0, audio.shape[1] - 1, rate)
    return np.stack([np.interp(positions, np.arange(len(channel)), channel) for channel in audio])


def normalized(audio, attack, release):
    peak = np.max(np.abs(audio))
    if peak > 0:
        audio = audio / peak
    for seconds, fade_in in ((attack, True), (release, False)):
        count = min(round(SR * seconds), audio.shape[1] // 2)
        fade = np.sin(np.linspace(0, np.pi / 2, count)) ** 2
        if fade_in:
            audio[:, :count] *= fade
        else:
            audio[:, -count:] *= fade[::-1]
    return audio


def render():
    instruments = json.loads((RAW / "wuxia_original_trial_v2_20261009/sample_sources.json").read_text(encoding="utf8"))["records"]
    dizi = json.loads((RAW / "wuxia_original_samples_20261009/dizi/manifest.json").read_text(encoding="utf8"))["samples"]
    strings = [item for item in instruments if item["style"] == "pluck"]
    tremolo = [item for item in instruments if item["style"] == "tremolo"]
    hits = {item["id"]: item for item in instruments if item["style"] == "hit"}
    length = frames(len(MELODY) * 4)
    mix = np.zeros((2, length))

    def add(audio, beat, gain, pan):
        # Wrap instrument and room tails across the loop boundary.
        start = frames(beat) % length
        audio = audio * np.array([1 - pan, 1 + pan])[:, None] * gain
        first = min(length - start, audio.shape[1])
        mix[:, start:start + first] += audio[:, :first]
        mix[:, :audio.shape[1] - first] += audio[:, first:]

    def pluck(note, beat, gain, sustain=False):
        row = min(tremolo if sustain else strings, key=lambda item: abs(item["estimated_midi_float"] - note))
        take = sample(ROOT / row["path"], row["sha256"])
        audio = pitch_shift(take, note - row["estimated_midi_float"])
        duration = 1.85 if sustain else .78
        add(normalized(audio[:, :round(SR * duration)], .025 if sustain else .003, .28), beat, gain, -.26 if sustain else .22)

    for bar, notes in enumerate(MELODY):
        beat = bar * 4
        for index, (note, duration) in enumerate(notes):
            if note:
                row = min(dizi, key=lambda item: abs(item["root_midi"] - note))
                take = sample(Path(row["preview_path"]), row["preview_sha256"])
                audio = pitch_shift(take[:, 35280:145530], note - row["root_midi"])
                segment = audio[:, :frames(duration) + round(SR * .075)]
                add(normalized(segment, .035, .095), beat, .32 + .016 * (index % 3), -.12)
            beat += duration

        root, fifth, upper = HARMONY[bar]
        pluck(root, bar * 4, .20)
        pluck(fifth, bar * 4, .082, sustain=True)
        for index, (offset, note) in enumerate(((.5, fifth), (1.0, upper), (1.75, fifth), (2.5, root + 12), (3.25, upper))):
            if bar not in (8, 9, 19) or index % 2 == 0:
                pluck(note, bar * 4 + offset, .085 + (index % 2) * .045)
        pattern = ((0, "drum_medium1", .24), (1.5, "wood_soft1", .075), (2, "drum_soft", .16), (3.25, "wood_soft2", .055))
        if bar in (3, 7, 11, 15, 18):
            pattern += ((3.5, "drum_soft", .10), (3.75, "drum_medium2", .14))
        if bar in (0, 12, 16):
            pattern += ((0, "gong_soft", .085),)
        for offset, key, gain in pattern:
            if bar in (8, 9, 19) and offset > 0:
                continue
            row = hits[key]
            take = sample(ROOT / row["path"], row["sha256"])
            add(normalized(take[:, :round(SR * (1.65 if key.startswith("gong") else .7))], .002, .19), bar * 4 + offset, gain, -.22 if key.startswith("wood") else 0)

    room = mix.copy()
    for delay, gain in ((.043, .13), (.079, .094), (.13, .069), (.205, .038)):
        mix += gain * np.roll(room[::-1], round(SR * delay), axis=1)
    mix = signal.sosfiltfilt(signal.butter(2, [36, 11800], fs=SR, btype="bandpass", output="sos"),
                            np.pad(mix, ((0, 0), (SR, SR)), mode="wrap"), axis=1)[:, SR:-SR]
    rms = np.sqrt(np.mean(mix ** 2))
    mix *= min(10 ** (-16 / 20) / rms, 10 ** (-1.5 / 20) / np.max(np.abs(mix)))
    with wave.open(str(OUTPUT), "wb") as wav:
        wav.setparams((2, 2, SR, 0, "NONE", "not compressed"))
        wav.writeframes(np.round(mix.T * 32767).astype("<i2").tobytes())
    print(f"{OUTPUT.name} {length / SR:.3f}s, {length} frames, RMS {20*np.log10(np.sqrt(np.mean(mix**2))):.1f} dBFS")


if __name__ == "__main__":
    render()
