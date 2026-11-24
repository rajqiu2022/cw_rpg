"""Create v4 wuxia BGM from the project's original CC0 music backbone.

V3 relied on clockwork plucked arpeggios, which read like light piano.  V4
keeps the early field/battle tracks the user preferred, then re-orchestrates
them with sparse sustained winds/bowed strings and Chinese percussion.  There
is deliberately no repeating synth-pluck layer.
"""

from __future__ import annotations

import math
from dataclasses import dataclass
from pathlib import Path

import av
import numpy as np
from scipy.signal import butter, sosfilt

from generate_wuxia_bgm_v3 import SR, add, cymbal, erhu, gong, midi, tanggu, wind, woodblock, write_wav


ROOT = Path(__file__).resolve().parents[1]
CC0 = ROOT / "game" / "art" / "audio" / "cc0"
OUT = ROOT / "game" / "art" / "audio" / "bgm"
RAW = ROOT / "assets" / "raw" / "audio" / "wuxia_bgm_v4"


@dataclass(frozen=True)
class FieldTheme:
    name: str
    start: float
    duration: float
    root: int
    motif: tuple[int, ...]
    mood: str


@dataclass(frozen=True)
class BattleTheme:
    name: str
    start: float
    duration: float
    bpm: float
    root: int
    motif: tuple[int, ...]
    mood: str


def decode_mp3(path: Path) -> np.ndarray:
    container = av.open(str(path))
    stream = container.streams.audio[0]
    resampler = av.audio.resampler.AudioResampler(format="fltp", layout="stereo", rate=SR)
    chunks: list[np.ndarray] = []
    for frame in container.decode(stream):
        for converted in resampler.resample(frame):
            chunks.append(converted.to_ndarray().T.astype(np.float64))
    if not chunks:
        raise RuntimeError(f"Could not decode {path}")
    return np.concatenate(chunks, axis=0)


def take(audio: np.ndarray, start: float, duration: float) -> np.ndarray:
    count = round(duration * SR)
    begin = round(start * SR)
    if begin + count <= len(audio):
        return audio[begin : begin + count].copy()
    indexes = (np.arange(count) + begin) % len(audio)
    return audio[indexes].copy()


def lowpass(track: np.ndarray, cutoff: float) -> np.ndarray:
    return sosfilt(butter(3, cutoff, btype="lowpass", fs=SR, output="sos"), track, axis=0)


def finish(track: np.ndarray, room_amount: float, seam_seconds: float) -> np.ndarray:
    dry = track.copy()
    for delay, gain, swap in [(0.083, 0.12, False), (0.171, 0.075, True), (0.293, 0.045, False)]:
        samples = round(delay * SR)
        source = dry[:-samples, ::-1] if swap else dry[:-samples]
        track[samples:] += source * gain * room_amount
    track = sosfilt(butter(2, 34, btype="highpass", fs=SR, output="sos"), track, axis=0)
    track = np.tanh(track * 1.08)
    fade = min(round(seam_seconds * SR), len(track) // 8)
    if fade > 1:
        alpha = np.linspace(0.0, 1.0, fade)[:, None]
        track[-fade:] = track[-fade:] * (1.0 - alpha) + track[:fade] * alpha
    seam = max(2, round(0.014 * SR))
    track[:seam] *= np.linspace(0.0, 1.0, seam)[:, None]
    track[-seam:] *= np.linspace(1.0, 0.0, seam)[:, None]
    peak = max(1e-8, float(np.max(np.abs(track))))
    return track * (0.84 / peak)


def add_field_lead(track: np.ndarray, theme: FieldTheme) -> None:
    spacing = 9.0 if theme.mood in {"forest", "cave", "mountain", "sect"} else 7.2
    phrase = 0
    start = 3.5
    while start < theme.duration - 3.0:
        motif = theme.motif if phrase % 2 == 0 else tuple(reversed(theme.motif))
        for index, degree in enumerate(motif[:4]):
            note_start = start + index * 1.05
            if note_start >= theme.duration - 1.0:
                break
            note_number = theme.root + 12 + degree
            if theme.mood == "cave":
                note_number -= 12
            lead = wind(
                midi(note_number),
                1.65 if theme.mood not in {"cave", "sect"} else 2.15,
                8100 + phrase * 20 + index,
                xiao=theme.mood in {"journey", "mountain", "forest", "cave", "sect"},
                suona=theme.mood == "city",
            )
            add(track, lead, note_start, 0.24, 0.34 if theme.mood == "cave" else 0.46)
        phrase += 1
        start += spacing


def compose_field(base: np.ndarray, theme: FieldTheme) -> np.ndarray:
    track = take(base, theme.start, theme.duration)
    if theme.mood == "cave":
        track = lowpass(track, 4300.0) * 0.70
    elif theme.mood in {"forest", "mountain"}:
        track = lowpass(track, 7200.0) * 0.76
    else:
        track *= 0.78
    add_field_lead(track, theme)
    if theme.mood == "market":
        for moment in np.arange(1.5, theme.duration, 2.8):
            add(track, woodblock(0.26), float(moment), 0.32)
    elif theme.mood == "city":
        for bar, moment in enumerate(np.arange(0.0, theme.duration, 6.8)):
            add(track, tanggu(0.24, 9000 + bar), float(moment), -0.20)
            if bar % 3 == 0:
                add(track, gong(0.22), float(moment), 0.25)
    elif theme.mood == "sect":
        for moment in np.arange(0.5, theme.duration, 12.0):
            add(track, gong(0.24), float(moment), 0.30)
    elif theme.mood == "cave":
        for moment in np.arange(1.0, theme.duration, 13.0):
            add(track, gong(0.34, low=True), float(moment), 0.10)
    return finish(track, 0.78 if theme.mood in {"cave", "sect"} else 0.48, 2.2)


def compose_battle(base: np.ndarray, theme: BattleTheme) -> np.ndarray:
    track = take(base, theme.start, theme.duration) * (0.68 if theme.mood == "spar" else 0.74)
    beat = 60.0 / theme.bpm
    boss = theme.mood == "boss"
    for bar, bar_start in enumerate(np.arange(0.0, theme.duration, beat * 4.0)):
        pulses = [0.0, 1.5, 2.0, 3.0]
        if theme.mood == "spar":
            pulses = [0.0, 2.0]
        elif boss:
            pulses = [0.0, 0.75, 1.5, 2.0, 2.75, 3.5]
        for hit, pulse in enumerate(pulses):
            add(track, tanggu(0.66 if pulse in {0.0, 2.0} else 0.42, 12000 + bar * 10 + hit), float(bar_start + pulse * beat), -0.12 if hit % 2 == 0 else 0.16)
        if theme.mood == "spar":
            add(track, woodblock(0.32), float(bar_start + beat), 0.36)
        if bar % (2 if boss else 4) == 0:
            add(track, gong(0.52 if boss else 0.24, low=boss), float(bar_start), 0.18)
        if boss and bar % 2 == 1:
            add(track, cymbal(14000 + bar, 0.36), float(bar_start + 3.4 * beat), 0.34)
    phrase_start = beat * 2.0
    phrase = 0
    while phrase_start < theme.duration - beat * 3.0:
        motif = theme.motif if phrase % 2 == 0 else tuple(reversed(theme.motif))
        for index, degree in enumerate(motif[:5]):
            note_start = phrase_start + index * beat * 0.72
            if note_start >= theme.duration - 0.8:
                break
            if boss and index in {0, 4}:
                lead = wind(midi(theme.root + 12 + degree), beat * 1.2, 15000 + phrase * 10 + index, suona=True)
                gain = 0.50
            else:
                lead = erhu(midi(theme.root + 12 + degree), beat * 1.35, 15000 + phrase * 10 + index)
                gain = 0.43 if theme.mood != "spar" else 0.32
            add(track, lead, note_start, 0.22, gain)
        phrase += 1
        phrase_start += beat * 8.0
    return finish(track, 0.38 if theme.mood == "spar" else 0.52, 1.35)


def main() -> None:
    OUT.mkdir(parents=True, exist_ok=True)
    RAW.mkdir(parents=True, exist_ok=True)
    field_base = decode_mp3(CC0 / "bgm_field_bards_tale_cc0.mp3")
    battle_base = decode_mp3(CC0 / "bgm_battle_medieval_cc0.mp3")
    fields = [
        FieldTheme("bgm_jianghu_journey_v4.wav", 8.0, 52.0, 50, (0, 3, 5, 7, 10), "journey"),
        FieldTheme("bgm_village_day_v4.wav", 0.0, 46.0, 50, (0, 3, 7, 5, 3), "village"),
        FieldTheme("bgm_mountain_path_v4.wav", 52.0, 48.0, 50, (0, 7, 5, 3, 0), "mountain"),
        FieldTheme("bgm_forest_mystery_v4.wav", 94.0, 46.0, 50, (0, 3, 5, 3, -2), "forest"),
        FieldTheme("bgm_cave_ominous_v4.wav", 108.0, 42.0, 50, (0, 3, -2, 0, -5), "cave"),
        FieldTheme("bgm_market_lively_v4.wav", 18.0, 44.0, 50, (0, 3, 5, 7, 5), "market"),
        FieldTheme("bgm_city_ceremony_v4.wav", 64.0, 48.0, 50, (0, 7, 10, 7, 5), "city"),
        FieldTheme("bgm_sect_clouds_v4.wav", 102.0, 46.0, 50, (0, 5, 7, 10, 7), "sect"),
    ]
    battles = [
        BattleTheme("bgm_battle_village_v4.wav", 0.0, 36.0, 122.0, 48, (0, 2, 5, 7, 9), "standard"),
        BattleTheme("bgm_battle_mountain_v4.wav", 18.0, 36.0, 128.0, 48, (0, 5, 7, 3, 5), "standard"),
        BattleTheme("bgm_battle_river_v4.wav", 34.0, 36.0, 126.0, 48, (0, 2, 7, 9, 7), "standard"),
        BattleTheme("bgm_battle_spar_v4.wav", 8.0, 32.0, 116.0, 48, (0, 5, 7, 5, 2), "spar"),
        BattleTheme("bgm_battle_boss_v4.wav", 38.0, 38.0, 138.0, 48, (0, 3, 7, 10, 7), "boss"),
    ]
    for theme in fields:
        write_wav(OUT / theme.name, compose_field(field_base, theme))
    for theme in battles:
        write_wav(OUT / theme.name, compose_battle(battle_base, theme))


if __name__ == "__main__":
    main()
