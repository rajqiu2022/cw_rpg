"""Generate original wuxia-style exploration and battle BGM loops.

The v2 placeholder loops were intentionally tiny, but their sine lead and
noise-heavy percussion read as generic synthesis.  V3 keeps the old project's
clear pentatonic melodies while rebuilding the timbre around guqin/pipa-like
plucks, xiao/dizi-like winds, erhu-like bowed tones, woodblock, tanggu and gong.

All output is deterministic, project-owned 22.05 kHz stereo PCM WAV.  Paths are
versioned so the reviewed v2 files remain available for A/B comparison.
"""

from __future__ import annotations

import math
import wave
from dataclasses import dataclass
from pathlib import Path

import numpy as np
from scipy.signal import butter, sosfilt


ROOT = Path(__file__).resolve().parents[1]
OUT = ROOT / "game" / "art" / "audio" / "bgm"
RAW = ROOT / "assets" / "raw" / "audio" / "wuxia_bgm_v3"
SR = 22_050
TAU = math.tau


def midi(note: float) -> float:
    return 440.0 * 2.0 ** ((note - 69.0) / 12.0)


def adsr(t: np.ndarray, duration: float, attack: float, release: float) -> np.ndarray:
    env = np.ones_like(t)
    env *= np.clip(t / max(attack, 1e-4), 0.0, 1.0)
    env *= np.clip((duration - t) / max(release, 1e-4), 0.0, 1.0)
    return env


def pluck(freq: float, duration: float, seed: int, *, dark: bool = False, pipa: bool = False) -> np.ndarray:
    count = max(1, int(duration * SR))
    t = np.arange(count, dtype=np.float64) / SR
    rng = np.random.default_rng(seed)
    phase = rng.uniform(0.0, TAU, 8)
    signal = np.zeros(count, dtype=np.float64)
    harmonics = 8 if pipa else 6
    for harmonic in range(1, harmonics + 1):
        brightness = (1.0 / harmonic**0.78) if pipa else (1.0 / harmonic**1.18)
        if dark:
            brightness /= 1.0 + harmonic * 0.32
        decay = 2.5 + harmonic * (0.72 if pipa else 0.48)
        slight_detune = 1.0 + (harmonic - 1) * 0.00055
        signal += brightness * np.sin(TAU * freq * harmonic * slight_detune * t + phase[harmonic - 1]) * np.exp(-decay * t)
    pick = rng.normal(0.0, 1.0, count)
    pick = np.concatenate(([0.0], np.diff(pick)))
    signal += pick * np.exp(-70.0 * t) * (0.11 if pipa else 0.055)
    signal *= adsr(t, duration, 0.004, min(0.35, duration * 0.42))
    return signal * (0.22 if pipa else 0.20)


def wind(freq: float, duration: float, seed: int, *, xiao: bool = False, suona: bool = False) -> np.ndarray:
    count = max(1, int(duration * SR))
    t = np.arange(count, dtype=np.float64) / SR
    rng = np.random.default_rng(seed)
    vibrato_rate = 4.7 if xiao else (5.8 if suona else 5.2)
    vibrato_depth = 0.0024 if xiao else (0.0055 if suona else 0.0035)
    inst_freq = freq * (1.0 + vibrato_depth * np.sin(TAU * vibrato_rate * t))
    phase = np.cumsum(TAU * inst_freq / SR)
    if suona:
        signal = np.sin(phase) + 0.42 * np.sin(2 * phase) + 0.30 * np.sin(3 * phase) + 0.15 * np.sin(5 * phase)
        volume = 0.125
    elif xiao:
        signal = np.sin(phase) + 0.12 * np.sin(2 * phase) + 0.045 * np.sin(3 * phase)
        volume = 0.12
    else:
        signal = np.sin(phase) + 0.20 * np.sin(2 * phase) + 0.08 * np.sin(3 * phase)
        volume = 0.13
    breath = rng.normal(0.0, 1.0, count)
    breath = sosfilt(butter(2, [900, min(7200, SR // 2 - 100)], btype="bandpass", fs=SR, output="sos"), breath)
    breath /= max(1e-6, np.max(np.abs(breath)))
    signal += breath * (0.035 if xiao else 0.022)
    signal *= adsr(t, duration, 0.18 if xiao else 0.09, 0.32)
    return signal * volume


def erhu(freq: float, duration: float, seed: int) -> np.ndarray:
    count = max(1, int(duration * SR))
    t = np.arange(count, dtype=np.float64) / SR
    rng = np.random.default_rng(seed)
    vibrato = 1.0 + 0.006 * np.sin(TAU * 5.35 * t + 0.4)
    phase = np.cumsum(TAU * freq * vibrato / SR)
    signal = np.zeros(count, dtype=np.float64)
    for harmonic in range(1, 9):
        signal += np.sin(phase * harmonic + 0.13 * harmonic) / harmonic**0.92
    bow = rng.normal(0.0, 1.0, count)
    bow = sosfilt(butter(2, [450, 4800], btype="bandpass", fs=SR, output="sos"), bow)
    bow /= max(1e-6, np.max(np.abs(bow)))
    signal = np.tanh(signal * 0.68) + bow * 0.026
    signal *= adsr(t, duration, 0.13, 0.28)
    return signal * 0.12


def tanggu(strength: float = 1.0, seed: int = 1) -> np.ndarray:
    duration = 0.52
    count = int(duration * SR)
    t = np.arange(count, dtype=np.float64) / SR
    rng = np.random.default_rng(seed)
    phase = TAU * (92.0 * t - 30.0 * t * t)
    body = np.sin(phase) * np.exp(-8.8 * t)
    skin = rng.normal(0.0, 1.0, count)
    skin = sosfilt(butter(2, [220, 2900], btype="bandpass", fs=SR, output="sos"), skin)
    skin /= max(1e-6, np.max(np.abs(skin)))
    return (body * 0.44 + skin * np.exp(-24.0 * t) * 0.16) * strength


def woodblock(strength: float = 1.0) -> np.ndarray:
    duration = 0.16
    count = int(duration * SR)
    t = np.arange(count, dtype=np.float64) / SR
    tone = np.sin(TAU * 930.0 * t) + 0.55 * np.sin(TAU * 1420.0 * t)
    return tone * np.exp(-35.0 * t) * 0.18 * strength


def gong(strength: float = 1.0, low: bool = False) -> np.ndarray:
    duration = 4.2 if low else 2.7
    count = int(duration * SR)
    t = np.arange(count, dtype=np.float64) / SR
    base = 68.0 if low else 118.0
    modes = [(1.00, 1.0), (1.47, 0.55), (2.12, 0.35), (2.73, 0.21), (3.86, 0.12)]
    signal = sum(weight * np.sin(TAU * base * ratio * t + ratio) for ratio, weight in modes)
    signal *= (1.0 - np.exp(-38.0 * t)) * np.exp(-(0.75 if low else 1.15) * t)
    return signal * 0.13 * strength


def cymbal(seed: int, strength: float = 1.0) -> np.ndarray:
    duration = 0.8
    count = int(duration * SR)
    t = np.arange(count, dtype=np.float64) / SR
    rng = np.random.default_rng(seed)
    noise = rng.normal(0.0, 1.0, count)
    noise = sosfilt(butter(3, 4300, btype="highpass", fs=SR, output="sos"), noise)
    noise /= max(1e-6, np.max(np.abs(noise)))
    return noise * np.exp(-7.0 * t) * 0.13 * strength


def add(track: np.ndarray, mono: np.ndarray, start: float, pan: float = 0.0, gain: float = 1.0) -> None:
    begin = int(start * SR)
    if begin >= len(track) or begin + len(mono) <= 0:
        return
    src_start = max(0, -begin)
    begin = max(0, begin)
    end = min(len(track), begin + len(mono) - src_start)
    if end <= begin:
        return
    pan = float(np.clip(pan, -1.0, 1.0))
    left = math.sqrt((1.0 - pan) * 0.5)
    right = math.sqrt((1.0 + pan) * 0.5)
    segment = mono[src_start : src_start + end - begin] * gain
    track[begin:end, 0] += segment * left
    track[begin:end, 1] += segment * right


def room(track: np.ndarray, amount: float) -> np.ndarray:
    wet = track.copy()
    for delay, gain, swap in [(0.071, 0.16, False), (0.129, 0.11, True), (0.211, 0.075, False), (0.337, 0.045, True)]:
        samples = int(delay * SR)
        source = track[:-samples, ::-1] if swap else track[:-samples]
        wet[samples:] += source * gain * amount
    return wet


def ambience(track: np.ndarray, seed: int, level: float, dark: bool = False) -> None:
    rng = np.random.default_rng(seed)
    noise = rng.normal(0.0, 1.0, len(track))
    cutoff = 650.0 if dark else 1800.0
    noise = sosfilt(butter(2, cutoff, btype="lowpass", fs=SR, output="sos"), noise)
    noise /= max(1e-6, np.max(np.abs(noise)))
    slow = 0.55 + 0.45 * np.sin(TAU * np.arange(len(track)) / SR / 7.3 + seed)
    track[:, 0] += noise * slow * level
    track[:, 1] += np.roll(noise, 137) * slow * level


PENTA = [0, 2, 4, 7, 9]


@dataclass(frozen=True)
class Theme:
    name: str
    bpm: float
    root: int
    bars: int
    motif: tuple[int, ...]
    mood: str
    seed: int


def compose_exploration(theme: Theme) -> np.ndarray:
    beat = 60.0 / theme.bpm
    duration = theme.bars * 4.0 * beat
    track = np.zeros((int(duration * SR), 2), dtype=np.float64)
    rng = np.random.default_rng(theme.seed)
    root = theme.root

    # Guqin foundation: low root/fifth and occasional harmonics.
    for bar in range(theme.bars):
        bar_t = bar * 4.0 * beat
        add(track, pluck(midi(root - 12), beat * 3.6, theme.seed * 100 + bar, dark=True), bar_t, -0.28, 0.72)
        if bar % 2 == 0:
            add(track, pluck(midi(root - 5), beat * 3.2, theme.seed * 200 + bar, dark=True), bar_t + beat * 0.12, 0.24, 0.50)

    busy = theme.mood in {"village", "market", "journey"}
    ceremonial = theme.mood in {"city", "sect"}
    for bar in range(theme.bars):
        bar_t = bar * 4.0 * beat
        if busy:
            pattern = [0, 2, 4, 2, 7, 4, 2, 0]
            step = beat * 0.5
            for index, degree in enumerate(pattern):
                note = root + 12 + degree + (12 if theme.mood == "market" and index in {3, 7} else 0)
                add(track, pluck(midi(note), beat * 0.72, theme.seed * 1000 + bar * 10 + index, pipa=True), bar_t + index * step, -0.35 + 0.10 * (index % 3), 0.62 if theme.mood == "market" else 0.48)
        else:
            pattern = [0, 4, 2, 7]
            for index, degree in enumerate(pattern):
                add(track, pluck(midi(root + 12 + degree), beat * 1.4, theme.seed * 1000 + bar * 10 + index, dark=theme.mood in {"cave", "forest"}), bar_t + index * beat, -0.22, 0.38)

        if theme.mood == "market":
            for pulse in [0.0, 1.0, 2.0, 3.0]:
                add(track, woodblock(0.75 if pulse in {0.0, 2.0} else 0.48), bar_t + pulse * beat, 0.42)
        elif theme.mood == "city":
            add(track, tanggu(0.48, theme.seed + bar), bar_t, -0.2)
            add(track, tanggu(0.32, theme.seed + bar + 70), bar_t + 2 * beat, 0.2)
            if bar % 4 == 0:
                add(track, gong(0.72), bar_t, 0.28)
        elif theme.mood == "sect" and bar % 4 == 0:
            add(track, gong(0.48), bar_t, 0.35)
        elif theme.mood == "journey":
            add(track, tanggu(0.20, theme.seed + bar), bar_t, -0.45)

    # Wind melody enters after one bar and leaves breathing gaps.
    phrase_bars = 2
    for phrase in range(max(1, theme.bars // phrase_bars)):
        if phrase % 3 == 2 and theme.mood in {"forest", "cave", "mountain"}:
            continue
        start = (phrase * phrase_bars + 0.65) * 4.0 * beat
        if start >= duration:
            break
        for index, degree in enumerate(theme.motif):
            note_start = start + index * beat * 0.5
            if note_start >= duration:
                break
            note_num = root + 12 + degree
            note_duration = beat * (0.88 if busy else 1.28)
            if theme.mood == "cave":
                note_num -= 12
                note_duration = beat * 1.55
            lead = wind(midi(note_num), note_duration, theme.seed * 3000 + phrase * 20 + index, xiao=theme.mood in {"mountain", "forest", "cave", "sect"}, suona=theme.mood == "city")
            add(track, lead, note_start, 0.26, 0.78 if theme.mood != "cave" else 0.54)

    if theme.mood in {"forest", "cave", "mountain"}:
        ambience(track, theme.seed + 9000, 0.010 if theme.mood != "cave" else 0.016, dark=True)
    track = room(track, 1.1 if theme.mood in {"cave", "sect"} else 0.72)
    return master(track, loop_fade=1.25)


def compose_battle(theme: Theme) -> np.ndarray:
    beat = 60.0 / theme.bpm
    duration = theme.bars * 4.0 * beat
    track = np.zeros((int(duration * SR), 2), dtype=np.float64)
    root = theme.root
    boss = theme.mood == "boss"
    spar = theme.mood == "spar"
    river = theme.mood == "river_battle"

    # Driving pipa ostinato: immediate rhythm, no long ambient introduction.
    step = beat * (0.25 if boss else 0.5)
    pattern = [0, 7, 4, 9, 7, 4, 2, 7] if not river else [0, 4, 7, 9, 7, 4, 9, 7]
    total_steps = int(duration / step)
    for index in range(total_steps):
        degree = pattern[index % len(pattern)]
        octave = 12 if (index // len(pattern)) % 2 == 0 else 0
        add(track, pluck(midi(root + 12 + degree + octave), step * 1.25, theme.seed * 10000 + index, pipa=True), index * step, -0.34 if index % 2 == 0 else -0.12, 0.54 if not boss else 0.62)

    for bar in range(theme.bars):
        bar_t = bar * 4.0 * beat
        drum_pattern = [0.0, 1.5, 2.0, 3.25] if not spar else [0.0, 2.0]
        if boss:
            drum_pattern = [0.0, 0.75, 1.5, 2.0, 2.75, 3.5]
        for hit_index, pulse in enumerate(drum_pattern):
            strength = 0.82 if pulse in {0.0, 2.0} else 0.52
            add(track, tanggu(strength, theme.seed * 100 + bar * 10 + hit_index), bar_t + pulse * beat, -0.1 if hit_index % 2 == 0 else 0.18)
        for pulse in [1.0, 3.0]:
            add(track, woodblock(0.42 if spar else 0.62), bar_t + pulse * beat, 0.44)
        if bar % (2 if boss else 4) == 0:
            add(track, gong(0.65 if boss else 0.34, low=boss), bar_t, 0.18)
        if boss and bar % 2 == 1:
            add(track, cymbal(theme.seed + bar, 0.55), bar_t + 3.5 * beat, 0.35)

    # Bowed lead phrases answer the ostinato every two bars.
    for phrase in range(max(1, theme.bars // 2)):
        start = phrase * 8.0 * beat + beat * 0.5
        lead_motif = theme.motif if phrase % 2 == 0 else tuple(reversed(theme.motif))
        for index, degree in enumerate(lead_motif):
            note_start = start + index * beat * 0.5
            if note_start >= duration:
                break
            duration_note = beat * (0.82 if boss else 1.05)
            if spar:
                lead = wind(midi(root + 24 + degree), duration_note, theme.seed * 4000 + phrase * 20 + index)
                gain = 0.60
            elif boss and index in {0, 4}:
                lead = wind(midi(root + 12 + degree), duration_note, theme.seed * 4000 + phrase * 20 + index, suona=True)
                gain = 0.78
            else:
                lead = erhu(midi(root + 12 + degree), duration_note, theme.seed * 4000 + phrase * 20 + index)
                gain = 0.76
            add(track, lead, note_start, 0.28, gain)

    # Low fifth pulse gives the drums weight without a modern electronic bass.
    for pulse in np.arange(0.0, duration, beat):
        add(track, pluck(midi(root - 12 if boss else root - 5), beat * 1.2, theme.seed * 7000 + int(pulse * 100), dark=True), float(pulse), -0.04, 0.52)

    track = room(track, 0.48 if spar else 0.62)
    return master(track, loop_fade=0.75)


def master(track: np.ndarray, loop_fade: float) -> np.ndarray:
    track = sosfilt(butter(2, 32, btype="highpass", fs=SR, output="sos"), track, axis=0)
    track = np.tanh(track * 1.35)
    fade = min(int(loop_fade * SR), len(track) // 6)
    if fade > 1:
        alpha = np.linspace(0.0, 1.0, fade, dtype=np.float64)[:, None]
        track[-fade:] = track[-fade:] * (1.0 - alpha) + track[:fade] * alpha
    # Land both sides of the PCM loop on zero over an inaudibly short window.
    # Godot loops the full WAV range; this removes residual clicks even when the
    # melodic crossfade begins on a different ornament phase.
    seam_fade = max(2, int(0.018 * SR))
    track[:seam_fade] *= np.linspace(0.0, 1.0, seam_fade)[:, None]
    track[-seam_fade:] *= np.linspace(1.0, 0.0, seam_fade)[:, None]
    peak = max(1e-8, float(np.max(np.abs(track))))
    track *= 0.86 / peak
    return track


def write_wav(path: Path, stereo: np.ndarray) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    pcm = np.clip(stereo, -1.0, 1.0)
    pcm = (pcm * 32767.0).astype("<i2")
    with wave.open(str(path), "wb") as wav:
        wav.setnchannels(2)
        wav.setsampwidth(2)
        wav.setframerate(SR)
        wav.writeframes(pcm.tobytes())
    print(f"{path.name}: {len(stereo) / SR:.2f}s stereo")


def main() -> None:
    OUT.mkdir(parents=True, exist_ok=True)
    RAW.mkdir(parents=True, exist_ok=True)
    exploration = [
        Theme("bgm_jianghu_journey_v3.wav", 76, 43, 12, (0, 4, 7, 9, 7, 4, 2, 4), "journey", 3101),
        Theme("bgm_village_day_v3.wav", 82, 48, 12, (0, 4, 7, 4, 9, 7, 4, 2), "village", 3102),
        Theme("bgm_mountain_path_v3.wav", 64, 43, 11, (0, 7, 9, 7, 4, 2, 4, 0), "mountain", 3103),
        Theme("bgm_forest_mystery_v3.wav", 58, 41, 10, (0, 2, 7, 4, 2, -3, 0, 2), "forest", 3104),
        Theme("bgm_cave_ominous_v3.wav", 52, 38, 9, (0, 2, 5, 2, -3, 0, 2, -3), "cave", 3105),
        Theme("bgm_market_lively_v3.wav", 98, 50, 12, (0, 4, 7, 9, 12, 9, 7, 4), "market", 3106),
        Theme("bgm_city_ceremony_v3.wav", 70, 43, 11, (0, 7, 12, 9, 7, 4, 2, 0), "city", 3107),
        Theme("bgm_sect_clouds_v3.wav", 60, 43, 10, (0, 4, 9, 7, 12, 9, 4, 2), "sect", 3108),
    ]
    battles = [
        Theme("bgm_battle_village_v3.wav", 122, 43, 16, (0, 4, 7, 9, 7, 4, 2, 0), "village_battle", 4101),
        Theme("bgm_battle_mountain_v3.wav", 128, 41, 16, (0, 5, 7, 9, 7, 5, 2, 0), "mountain_battle", 4102),
        Theme("bgm_battle_river_v3.wav", 126, 43, 16, (0, 4, 7, 11, 9, 7, 4, 2), "river_battle", 4103),
        Theme("bgm_battle_spar_v3.wav", 116, 48, 14, (0, 4, 7, 9, 7, 4, 9, 7), "spar", 4104),
        Theme("bgm_battle_boss_v3.wav", 138, 38, 18, (0, 5, 7, 10, 7, 5, 3, 0), "boss", 4105),
    ]
    for theme in exploration:
        write_wav(OUT / theme.name, compose_exploration(theme))
    for theme in battles:
        write_wav(OUT / theme.name, compose_battle(theme))


if __name__ == "__main__":
    main()
