"""Render Dawn at the Mountain Pass, an original title score, from instrument samples."""

import json
from pathlib import Path
import wave

import numpy as np
from scipy import signal

from compose_title_sword_journey import RAW, ROOT, SR, normalized, pitch_shift, sample


BPM = 80
OUTPUT = ROOT / "game/art/audio/bgm/bgm_title_mountain_dawn_20261114.wav"
DIZI = RAW / "wuxia_original_samples_20261009/dizi"

# Each row is a four-beat bar. Zero denotes a breath.
MELODY = (
    # Plucked-string opening and low flute statement.
    ((0, 2.5), (69, .5), (72, 1)),
    ((76, 2.25), (74, .75), (72, 1)),
    ((69, 2.5), (0, 1), (67, .5)),
    ((69, .75), (72, .75), (74, 1), (76, 1.5)),
    ((74, 1.5), (72, 1), (69, 1), (0, .5)),
    ((72, 1.5), (74, .5), (76, 2)),
    ((79, 1.5), (76, 1), (74, 1.5)),
    ((72, 2.5), (0, 1.5)),
    # Zither carries the answer before the flute climbs.
    ((0, 4),),
    ((0, 1.5), (72, .75), (74, .75), (76, 1)),
    ((79, 2.25), (76, .75), (74, 1)),
    ((72, 1.75), (74, 1), (76, 1.25)),
    ((79, 2.5), (0, .75), (76, .75)),
    ((74, 1), (72, .75), (74, .75), (76, 1.5)),
    ((72, 1.75), (69, 1.25), (67, 1)),
    ((69, 2.5), (0, 1.5)),
    # A quieter return from the low register.
    ((0, 2), (67, 1), (69, 1)),
    ((72, 2.5), (69, .5), (67, 1)),
    ((69, 1.5), (0, 1), (72, .75), (74, .75)),
    ((76, 1.75), (74, .75), (72, 1.5)),
    ((74, 1), (76, .75), (79, 2.25)),
    ((76, 1.5), (74, .75), (72, 1.25), (0, .5)),
    ((69, 1.5), (72, .75), (74, .75), (76, 1)),
    ((74, 1.5), (72, 2.5)),
    # Reprise and an exposed cadence. String resonance leads back into bar one.
    ((0, 1), (69, .5), (72, .5), (76, 2)),
    ((79, 1.25), (76, 1.25), (74, 1.5)),
    ((72, .75), (74, .75), (76, 2.5)),
    ((74, 1), (72, 1), (69, 1.5), (0, .5)),
    ((69, 2.5), (0, 1.5)),
    ((0, 4),),
)

# Bass, open fifth, and upper response. The second section moves toward C.
HARMONY = (
    (57, 64, 72), (57, 64, 76), (53, 60, 69), (55, 62, 74),
    (57, 64, 72), (60, 67, 76), (55, 62, 79), (53, 60, 72),
    (60, 67, 76), (55, 62, 74), (60, 67, 79), (53, 60, 76),
    (60, 67, 79), (55, 62, 76), (53, 60, 72), (57, 64, 69),
    (55, 62, 67), (53, 60, 72), (57, 64, 72), (60, 67, 76),
    (55, 62, 79), (53, 60, 72), (57, 64, 76), (55, 62, 72),
    (57, 64, 76), (60, 67, 79), (55, 62, 76), (53, 60, 72),
    (57, 64, 69), (57, 64, 72),
)

# A short event list keeps percussion out of the foreground.
PERCUSSION = (
    (3.75, "gong_soft", .034), (16, "drum_soft", .082),
    (31.5, "wood_soft1", .043), (32, "drum_soft", .088),
    (43.5, "wood_soft2", .04), (47.5, "drum_soft", .072),
    (48, "drum_medium1", .11), (52.75, "wood_soft1", .047),
    (60, "gong_soft", .051), (76, "drum_soft", .06),
    (83.5, "wood_soft2", .047), (95.75, "drum_soft", .075),
    (96, "gong_soft", .056), (100, "drum_soft", .089),
    (108, "drum_soft", .076),
)


def frames(beats):
    return round(beats * SR * 60 / BPM)


def render():
    instruments = json.loads(
        (RAW / "wuxia_original_trial_v2_20261009/sample_sources.json").read_text(encoding="utf8")
    )["records"]
    flute = json.loads((DIZI / "manifest.json").read_text(encoding="utf8"))["samples"]
    strings = {style: [row for row in instruments if row["style"] == style]
               for style in ("pluck", "tremolo")}
    hits = {row["id"]: row for row in instruments if row["style"] == "hit"}
    length = frames(len(MELODY) * 4)
    mix = np.zeros((2, length), dtype=np.float32)

    def add(audio, beat, gain, pan, attack, release):
        start = frames(beat) % length
        balanced = normalized(audio.copy(), attack, release)
        balanced *= np.array([1 - pan, 1 + pan])[:, None] * gain
        first = min(length - start, balanced.shape[1])
        mix[:, start:start + first] += balanced[:, :first]
        mix[:, :balanced.shape[1] - first] += balanced[:, first:]

    def zither(note, beat, gain, pan, style="pluck", offset=0):
        row = min(strings[style], key=lambda item: abs(item["estimated_midi_float"] - note))
        take = sample(ROOT / row["path"], row["sha256"])
        sustained = style == "tremolo"
        count = round(SR * (2.85 if sustained else 1.85))
        tuned = pitch_shift(take[:, offset:], note - row["estimated_midi_float"])
        add(tuned[:, :count], beat, gain, pan, .36 if sustained else .004, .64 if sustained else .36)

    assert len(MELODY) == len(HARMONY)
    for bar, (phrase, (bass, fifth, top)) in enumerate(zip(MELODY, HARMONY)):
        assert sum(duration for _, duration in phrase) == 4
        start = bar * 4
        position = start
        for index, (note, duration) in enumerate(phrase):
            if note:
                row = min(flute, key=lambda item: abs(item["root_midi"] - note))
                take = sample(DIZI / Path(row["preview_path"]).name, row["preview_sha256"])
                body_start = round(SR * (.77 + .055 * ((bar + index) % 4)))
                tuned = pitch_shift(take[:, body_start:145530], note - row["root_midi"] - .04)
                segment = tuned[:, :frames(duration) + round(SR * .10)]
                gain = (.31 + .020 * np.sin((position + 1) * .48)) * (1.12 if 10 <= bar <= 13 else 1)
                add(segment, position - .05, gain, -.04, .15 if index == 0 else .095, .14)
            position += duration

        zither(bass, start + (.14 if bar != 0 else 0), .14, -.23)
        if bar not in (0, 2, 7, 15, 16, 27, 29):
            zither(fifth, start + .12, .054, -.29, "tremolo", offset=round(SR * ((bar % 4) * .17)))
        if bar in (0, 8, 15, 23, 29):
            offsets = ((.78, fifth), (1.48, top - 12), (2.56, top), (3.46, fifth + 12))
        elif bar in (7, 12, 25, 28):
            offsets = ((1.73, fifth), (3.1, top - 12))
        else:
            offsets = ((.91, fifth), (2.39, top - 12), (3.36, top))
        for index, (offset, note) in enumerate(offsets):
            zither(note, start + offset, (.073 if index == 0 else .058) * (1.55 if bar in (0, 8, 29) else 1), .29)

    for beat, key, gain in PERCUSSION:
        row = hits[key]
        take = sample(ROOT / row["path"], row["sha256"])
        count = round(SR * (2.4 if key == "gong_soft" else 1.05))
        add(take[:, :count], beat, gain, 0, .003, .27)

    # A band-limited stereo room return wraps naturally into the next playthrough.
    room = signal.sosfilt(signal.butter(2, [180, 4600], fs=SR, btype="bandpass", output="sos"), mix)
    for delay, gain in ((.038, .16), (.071, .11), (.113, .08), (.167, .065),
                        (.241, .053), (.317, .05), (.419, .033), (.552, .018)):
        mix += gain * np.roll(room[::-1], round(SR * delay), axis=1)
    mix = signal.sosfiltfilt(signal.butter(2, [44, 12100], fs=SR, btype="bandpass", output="sos"),
                            np.pad(mix, ((0, 0), (SR, SR)), mode="wrap"), axis=1)[:, SR:-SR]
    rms = np.sqrt(np.mean(mix ** 2))
    mix *= min(10 ** (-21 / 20) / rms, 10 ** (-2 / 20) / np.max(np.abs(mix)))
    with wave.open(str(OUTPUT), "wb") as wav:
        wav.setparams((2, 2, SR, 0, "NONE", "not compressed"))
        wav.writeframes(np.round(mix.T * 32767).astype("<i2").tobytes())
    print(f"{OUTPUT.name}: {length / SR:.3f}s, RMS {20 * np.log10(np.sqrt(np.mean(mix ** 2))):.1f} dBFS")


if __name__ == "__main__":
    render()
