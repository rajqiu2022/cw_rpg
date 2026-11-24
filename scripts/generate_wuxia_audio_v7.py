"""Generate restrained original wuxia cues without brass-like bass voices.

The v6 themes used additive low sine pulses. On small speakers those pulses
read as a synthetic tuba. V7 uses short physically modelled plucks, an airy
xiao lead and wood clicks; there is no sustained energy below 110 Hz.
"""

from __future__ import annotations

import json
import math
import wave
from pathlib import Path

import numpy as np


SR = 44100
ROOT = Path(__file__).resolve().parents[1]
OUT = ROOT / "game/art/audio/bgm"
REPORT = ROOT / "assets/processed/audio/wuxia_audio_v7_validation.json"
RNG = np.random.default_rng(20260913)


def hz(note: float) -> float:
    return 440.0 * 2.0 ** ((note - 69.0) / 12.0)


def stereo_track(duration: float) -> np.ndarray:
    return np.zeros((round(duration * SR), 2), dtype=np.float64)


def fade_envelope(count: int, attack: float, release: float) -> np.ndarray:
    env = np.ones(count, dtype=np.float64)
    a = min(count, max(1, round(attack * SR)))
    r = min(count, max(1, round(release * SR)))
    env[:a] = np.sin(np.linspace(0.0, math.pi / 2.0, a)) ** 2
    env[-r:] *= np.cos(np.linspace(0.0, math.pi / 2.0, r)) ** 2
    return env


def string_pluck(note: int, duration: float, brightness: float = 0.55) -> np.ndarray:
    """Pipa/guqin-like decaying string: pitched attack, never a sustained horn."""
    count = max(1, round(duration * SR))
    t = np.arange(count, dtype=np.float64) / SR
    f = hz(note)
    signal = np.zeros(count, dtype=np.float64)
    phases = RNG.uniform(-0.08, 0.08, 7)
    for harmonic in range(1, 8):
        amp = (brightness ** (harmonic - 1)) / (harmonic ** 0.48)
        decay = np.exp(-(2.2 + harmonic * 1.35) * t / max(duration, 0.2))
        signal += amp * np.sin(2.0 * math.pi * f * harmonic * t + phases[harmonic - 1]) * decay
    pick = RNG.normal(0.0, 1.0, count)
    pick[1:] -= 0.94 * pick[:-1]
    pick *= np.exp(-52.0 * t) * 0.10
    signal = (signal + pick) * fade_envelope(count, 0.002, 0.10)
    peak = float(np.max(np.abs(signal))) or 1.0
    return signal / peak


def xiao(note: int, duration: float) -> np.ndarray:
    """Breathy bamboo-flute phrase with a soft attack and restrained harmonics."""
    count = max(1, round(duration * SR))
    t = np.arange(count, dtype=np.float64) / SR
    f = hz(note)
    vibrato = 0.010 * np.sin(2.0 * math.pi * 4.7 * t) * np.minimum(1.0, t / 0.45)
    phase = 2.0 * math.pi * f * t + vibrato
    tone = np.sin(phase) + 0.11 * np.sin(2.0 * phase + 0.2) + 0.035 * np.sin(3.0 * phase)
    breath = RNG.normal(0.0, 1.0, count)
    breath[1:] -= 0.82 * breath[:-1]
    tone += breath * 0.026
    return tone * fade_envelope(count, 0.18, min(0.50, duration * 0.32)) / 1.18


def wood_click(duration: float = 0.10) -> np.ndarray:
    count = max(1, round(duration * SR))
    t = np.arange(count, dtype=np.float64) / SR
    tone = np.sin(2 * math.pi * 820 * t) + 0.42 * np.sin(2 * math.pi * 1280 * t)
    return tone * np.exp(-44.0 * t) * fade_envelope(count, 0.001, 0.025) / 1.42


def add(track: np.ndarray, signal: np.ndarray, start: float, gain: float, pan: float = 0.0) -> None:
    begin = max(0, round(start * SR))
    end = min(len(track), begin + len(signal))
    if end <= begin:
        return
    sample = signal[: end - begin]
    track[begin:end, 0] += sample * gain * math.sqrt((1.0 - pan) * 0.5)
    track[begin:end, 1] += sample * gain * math.sqrt((1.0 + pan) * 0.5)


def room(track: np.ndarray, echoes: tuple[tuple[float, float], ...]) -> np.ndarray:
    wet = track.copy()
    for delay, gain in echoes:
        shift = round(delay * SR)
        wet[shift:] += track[:-shift] * gain
    return wet


def normalize(track: np.ndarray, target: float = 0.72) -> np.ndarray:
    # Remove DC and tame sub-bass that can turn into a horn-like drone.
    track -= np.mean(track, axis=0, keepdims=True)
    spectrum = np.fft.rfft(track, axis=0)
    frequencies = np.fft.rfftfreq(len(track), 1.0 / SR)
    spectrum[frequencies < 95.0] = 0.0
    track = np.fft.irfft(spectrum, n=len(track), axis=0)
    peak = float(np.max(np.abs(track))) or 1.0
    return np.tanh(track / peak * 1.05) * target


def seamless(track: np.ndarray, seconds: float = 2.4) -> np.ndarray:
    edge = min(len(track) // 4, round(seconds * SR))
    if edge <= 1:
        return track
    ramp = (0.5 - 0.5 * np.cos(np.linspace(0.0, math.pi, edge)))[:, None]
    blend = track[-edge:] * (1.0 - ramp) + track[:edge] * ramp
    track[:edge] = blend
    track[-edge:] = blend
    return track


def wudang_theme() -> np.ndarray:
    duration = 48.0
    track = stereo_track(duration)
    # D pentatonic. Sparse phrases leave mountain-air silence between gestures.
    qin = [(0.0, 50), (2.8, 57), (6.0, 62), (9.2, 57),
           (12.0, 52), (15.3, 59), (18.5, 62), (21.5, 57),
           (24.0, 50), (27.2, 54), (30.2, 57), (33.5, 62),
           (36.0, 59), (39.2, 57), (42.5, 54), (45.2, 50)]
    for index, (start, note) in enumerate(qin):
        add(track, string_pluck(note, 2.7, 0.46), start, 0.29, -0.28 if index % 2 == 0 else 0.24)
        if index % 4 == 0:
            add(track, string_pluck(note + 12, 1.35, 0.62), start + 0.08, 0.11, 0.20)

    phrases = [
        (3.5, [(69, 1.8), (71, 1.4), (74, 2.5)]),
        (14.2, [(74, 1.8), (71, 1.5), (69, 2.8)]),
        (26.5, [(66, 1.6), (69, 1.5), (71, 2.7)]),
        (38.5, [(74, 1.8), (71, 1.5), (69, 3.0)]),
    ]
    for phrase_index, (start, notes) in enumerate(phrases):
        cursor = start
        for note, length in notes:
            add(track, xiao(note, length), cursor, 0.22, 0.16 if phrase_index % 2 == 0 else -0.12)
            cursor += length * 0.82
    for start in (0.0, 12.0, 24.0, 36.0):
        add(track, wood_click(), start, 0.055, -0.10)
        add(track, wood_click(), start + 6.0, 0.038, 0.12)
    return normalize(seamless(room(track, ((0.19, 0.10), (0.43, 0.055), (0.77, 0.025)))))


def victory_theme() -> np.ndarray:
    duration = 6.8
    track = stereo_track(duration)
    # Quick pipa answer and a bright dizi cadence; no drum, gong or bass swell.
    arpeggio = [(0.00, 62), (0.16, 66), (0.32, 69), (0.49, 74),
                (1.15, 69), (1.33, 74), (1.51, 78),
                (2.35, 74), (2.52, 78), (2.70, 81)]
    for index, (start, note) in enumerate(arpeggio):
        add(track, string_pluck(note, 1.10, 0.67), start, 0.31, -0.34 + 0.075 * index)
    for start in (0.0, 1.15, 2.35):
        add(track, wood_click(), start, 0.07, -0.18)
    for start, note, length in ((0.60, 74, 0.72), (1.45, 78, 0.82), (2.65, 81, 1.12), (4.05, 78, 1.75), (5.25, 74, 1.30)):
        add(track, xiao(note, length), start, 0.29, 0.16)
    add(track, string_pluck(62, 2.25, 0.44), 4.05, 0.16, -0.25)
    add(track, string_pluck(69, 2.10, 0.48), 4.07, 0.13, 0.22)
    return normalize(room(track, ((0.12, 0.10), (0.28, 0.055), (0.51, 0.025))), 0.74)


def write(path: Path, track: np.ndarray) -> None:
    pcm = np.asarray(np.clip(track, -1.0, 1.0) * 32767.0, dtype="<i2")
    path.parent.mkdir(parents=True, exist_ok=True)
    with wave.open(str(path), "wb") as wav:
        wav.setnchannels(2)
        wav.setsampwidth(2)
        wav.setframerate(SR)
        wav.writeframes(pcm.tobytes())


def metrics(track: np.ndarray) -> dict[str, float]:
    mono = track.mean(axis=1)
    spectrum = np.abs(np.fft.rfft(mono)) ** 2
    frequencies = np.fft.rfftfreq(len(mono), 1.0 / SR)
    total = float(np.sum(spectrum)) or 1.0
    return {
        "duration_seconds": round(len(track) / SR, 3),
        "peak": round(float(np.max(np.abs(track))), 4),
        "sub_110hz_energy_ratio": round(float(np.sum(spectrum[frequencies < 110.0])) / total, 6),
        "mid_180_4000hz_energy_ratio": round(float(np.sum(spectrum[(frequencies >= 180.0) & (frequencies <= 4000.0)])) / total, 6),
    }


def main() -> None:
    tracks = {
        "bgm_wudang_clouds_v7.wav": wudang_theme(),
        "bgm_victory_v3.wav": victory_theme(),
    }
    payload: dict[str, object] = {
        "generator": "original deterministic physical-model synthesis",
        "sample_rate": SR,
        "forbidden_timbres": ["brass", "tuba", "gong swell", "low sine drum"],
        "tracks": {},
    }
    for filename, track in tracks.items():
        write(OUT / filename, track)
        track_metrics = metrics(track)
        if track_metrics["sub_110hz_energy_ratio"] > 0.01:
            raise AssertionError(f"{filename}: excessive sub-bass {track_metrics}")
        payload["tracks"][filename] = track_metrics
        print(filename, track_metrics)
    REPORT.parent.mkdir(parents=True, exist_ok=True)
    REPORT.write_text(json.dumps(payload, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")


if __name__ == "__main__":
    main()
