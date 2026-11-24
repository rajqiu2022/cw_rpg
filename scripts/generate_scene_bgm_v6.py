"""Generate clean, tonal regional wuxia themes for the 2026-09-13 scene pass.

The previous synthetic victory cue leaned on noise-heavy cymbal/gong layers.
V6 deliberately uses only pitched additive voices and soft low drum pulses, so
the short fanfare remains musical even through low-bitrate web/mobile audio.
"""

from __future__ import annotations

import math
import wave
from dataclasses import dataclass
from pathlib import Path

import numpy as np


SR = 22050
ROOT = Path(__file__).resolve().parents[1]
OUT = ROOT / "game" / "art" / "audio" / "bgm"


def hz(midi_note: float) -> float:
    return 440.0 * 2.0 ** ((midi_note - 69.0) / 12.0)


def envelope(length: int, attack: float, release: float) -> np.ndarray:
    env = np.ones(length, dtype=np.float64)
    a = min(length, max(1, round(attack * SR)))
    r = min(length, max(1, round(release * SR)))
    env[:a] = np.sin(np.linspace(0.0, math.pi / 2.0, a)) ** 2
    env[-r:] *= np.cos(np.linspace(0.0, math.pi / 2.0, r)) ** 2
    return env


def voice(note: float, duration: float, kind: str = "flute") -> np.ndarray:
    count = max(1, round(duration * SR))
    t = np.arange(count, dtype=np.float64) / SR
    f = hz(note)
    vibrato = 0.0 if kind == "pluck" else 0.0024 * np.sin(2 * math.pi * 5.1 * t)
    phase = 2 * math.pi * f * t + vibrato
    if kind == "flute":
        tone = np.sin(phase) + 0.16 * np.sin(2 * phase) + 0.05 * np.sin(3 * phase)
        env = envelope(count, 0.12, 0.30)
    elif kind == "erhu":
        tone = np.sin(phase) + 0.28 * np.sin(2 * phase) + 0.12 * np.sin(3 * phase)
        env = envelope(count, 0.16, 0.38)
    elif kind == "bell":
        tone = np.sin(phase) + 0.32 * np.sin(2.01 * phase) + 0.11 * np.sin(3.98 * phase)
        env = np.exp(-4.0 * t / max(duration, 0.1)) * envelope(count, 0.008, 0.12)
    else:  # guqin/pipa-like pluck, still fully pitched
        tone = np.sin(phase) + 0.30 * np.sin(2 * phase) + 0.10 * np.sin(3 * phase)
        env = np.exp(-5.2 * t / max(duration, 0.1)) * envelope(count, 0.006, 0.10)
    return tone * env / 1.42


def soft_drum(duration: float = 0.48) -> np.ndarray:
    count = max(1, round(duration * SR))
    t = np.arange(count, dtype=np.float64) / SR
    phase = 2 * math.pi * (74.0 * t - 22.0 * t * t)
    return np.sin(phase) * np.exp(-9.5 * t) * envelope(count, 0.004, 0.08)


def add(track: np.ndarray, signal: np.ndarray, start: float, gain: float, pan: float = 0.0) -> None:
    begin = max(0, round(start * SR))
    end = min(len(track), begin + len(signal))
    if end <= begin:
        return
    data = signal[: end - begin]
    left = gain * math.sqrt((1.0 - pan) * 0.5)
    right = gain * math.sqrt((1.0 + pan) * 0.5)
    track[begin:end, 0] += data * left
    track[begin:end, 1] += data * right


def finish(track: np.ndarray, loop_fade: float = 1.8) -> np.ndarray:
    # Short, low-gain echoes add room without hiss or metallic noise.
    wet = track.copy()
    for delay, gain in ((0.115, 0.13), (0.235, 0.075), (0.410, 0.04)):
        shift = round(delay * SR)
        wet[shift:] += track[:-shift] * gain
    edge = min(len(wet) // 3, round(loop_fade * SR))
    if edge > 1:
        ramp = np.linspace(0.0, 1.0, edge)[:, None]
        mixed = wet[:edge] * ramp + wet[-edge:] * (1.0 - ramp)
        wet[:edge] = mixed
        wet[-edge:] = mixed
    peak = float(np.max(np.abs(wet))) or 1.0
    return np.tanh(wet / peak * 1.15) * 0.72


def write(path: Path, track: np.ndarray) -> None:
    pcm = np.asarray(np.clip(track, -1.0, 1.0) * 32767.0, dtype="<i2")
    with wave.open(str(path), "wb") as wav:
        wav.setnchannels(2)
        wav.setsampwidth(2)
        wav.setframerate(SR)
        wav.writeframes(pcm.tobytes())


@dataclass(frozen=True)
class Theme:
    filename: str
    bpm: int
    root: int
    motif: tuple[int, ...]
    answer: tuple[int, ...]
    lead: str
    pulse: str


def region_theme(spec: Theme) -> np.ndarray:
    beat = 60.0 / spec.bpm
    bars = 12
    duration = bars * 4.0 * beat
    track = np.zeros((round(duration * SR), 2), dtype=np.float64)
    scale = (0, 2, 4, 7, 9, 12)
    for bar in range(bars):
        base = bar * 4 * beat
        add(track, voice(spec.root - 12, beat * 3.6, "pluck"), base, 0.38, -0.22)
        add(track, voice(spec.root - 5, beat * 2.0, "pluck"), base + 2 * beat, 0.24, 0.18)
        if spec.pulse == "grand" and bar % 2 == 0:
            add(track, soft_drum(), base, 0.26, -0.05)
        elif spec.pulse == "busy":
            add(track, voice(spec.root + 12 + scale[bar % len(scale)], beat * 0.7, "pluck"), base + beat, 0.22, 0.32)
            add(track, voice(spec.root + 19, beat * 0.55, "pluck"), base + 3 * beat, 0.16, -0.30)
        elif spec.pulse == "water" and bar % 3 == 1:
            add(track, voice(spec.root + 24, beat * 1.2, "bell"), base + 2.5 * beat, 0.14, 0.40)

    for phrase, bar in enumerate((0, 4, 8)):
        motif = spec.motif if phrase != 1 else spec.answer
        start = bar * 4 * beat + 0.45 * beat
        for index, degree in enumerate(motif):
            length = beat * (1.35 if index not in (0, len(motif) - 1) else 1.8)
            add(track, voice(spec.root + 12 + degree, length, spec.lead), start + index * 1.45 * beat, 0.42, 0.18)
        reply = start + 8.2 * beat
        for index, degree in enumerate(reversed(motif[1:5])):
            add(track, voice(spec.root + 7 + degree, beat * 1.4, "erhu"), reply + index * 1.25 * beat, 0.25, -0.18)
    return finish(track)


def victory_theme() -> np.ndarray:
    duration = 7.6
    track = np.zeros((round(duration * SR), 2), dtype=np.float64)
    # D-major pentatonic ascent, answer, and a clean held cadence.
    notes = ((0.00, 62, 0.46), (0.48, 66, 0.46), (0.96, 69, 0.62),
             (1.65, 74, 0.92), (2.72, 69, 0.44), (3.20, 71, 0.44),
             (3.68, 74, 0.68), (4.48, 78, 1.45), (6.02, 74, 1.20))
    for index, (start, note, length) in enumerate(notes):
        add(track, voice(note, length, "flute"), start, 0.52, 0.18)
        if index in (0, 3, 7):
            add(track, voice(note - 12, length * 1.35, "pluck"), start, 0.32, -0.28)
    for start in (0.0, 1.65, 3.68, 4.48):
        add(track, soft_drum(0.52), start, 0.24, -0.08)
    for note in (50, 57, 62, 66):
        add(track, voice(note, 2.35, "bell"), 4.46, 0.10, (note - 58) / 25.0)
    peak = float(np.max(np.abs(track))) or 1.0
    return np.tanh(track / peak * 1.12) * 0.70


def main() -> None:
    OUT.mkdir(parents=True, exist_ok=True)
    specs = (
        Theme("bgm_linxi_village_v6.wav", 76, 50, (0, 4, 7, 9, 7), (4, 2, 0, 4, 7), "flute", "soft"),
        Theme("bgm_luoyang_gate_v6.wav", 68, 43, (0, 7, 12, 9, 7), (5, 9, 7, 4, 0), "erhu", "grand"),
        Theme("bgm_luoyang_yamen_v6.wav", 60, 45, (0, 2, 7, 5, 2), (7, 5, 2, 0, -3), "erhu", "soft"),
        Theme("bgm_luoyang_market_v6.wav", 88, 50, (0, 4, 7, 9, 12), (9, 7, 4, 2, 4), "flute", "busy"),
        Theme("bgm_luoyang_docks_v6.wav", 72, 48, (0, 7, 9, 4, 2), (4, 9, 7, 2, 0), "flute", "water"),
        Theme("bgm_bailu_ferry_v6.wav", 66, 43, (0, 4, 9, 7, 4), (7, 11, 9, 4, 0), "erhu", "water"),
        Theme("bgm_wudang_clouds_v6.wav", 56, 45, (0, 5, 9, 12, 9), (7, 5, 0, 2, 5), "flute", "grand"),
        Theme("bgm_huashan_swordwind_v6.wav", 70, 47, (0, 7, 9, 12, 7), (4, 9, 7, 2, 0), "erhu", "grand"),
        Theme("bgm_lingyue_moonwater_v6.wav", 58, 50, (0, 4, 9, 7, 4), (12, 9, 7, 4, 0), "flute", "water"),
        Theme("bgm_gufeng_drums_v6.wav", 74, 41, (0, 5, 7, 9, 5), (9, 7, 5, 2, 0), "erhu", "grand"),
        Theme("bgm_mingwu_shadow_v6.wav", 54, 38, (0, 2, 7, 4, -3), (4, 2, 0, -5, -3), "erhu", "soft"),
    )
    for spec in specs:
        write(OUT / spec.filename, region_theme(spec))
        print(spec.filename)
    write(OUT / "bgm_victory_v2.wav", victory_theme())
    print("bgm_victory_v2.wav")


if __name__ == "__main__":
    main()
