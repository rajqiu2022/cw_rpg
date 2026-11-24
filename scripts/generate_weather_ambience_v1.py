"""Generate a seamless, restrained rain ambience for outdoor field scenes.

The result is deterministic and project-owned. It combines filtered broadband
rain, a low mountain-wind bed and sparse stereo droplets, then crossfades the
loop boundary so Godot can repeat it without a click.
"""

from __future__ import annotations

from array import array
import math
from pathlib import Path
import random
import wave


RATE = 32_000
DURATION_SECONDS = 18
SEED = 20260910
OUTPUT = Path(__file__).resolve().parents[1] / "game/art/audio/ambience/amb_rain_mountain_soft_v1.wav"


def _channel(seed: int, count: int) -> list[float]:
    rng = random.Random(seed)
    values: list[float] = [0.0] * count
    slow = 0.0
    mid = 0.0
    wind = 0.0
    drop = 0.0
    drop_tone = 0.0
    for index in range(count):
        white = rng.uniform(-1.0, 1.0)
        slow += (white - slow) * 0.0024
        mid += (white - mid) * 0.075
        wind += (rng.uniform(-1.0, 1.0) - wind) * 0.00018
        hiss = white * 0.34 + (white - mid) * 0.23 + slow * 0.08
        if rng.random() < 0.00155:
            drop = rng.uniform(0.18, 0.62)
            drop_tone = rng.uniform(0.70, 1.0)
        drop *= 0.935
        drop_tone *= -0.76
        rumble = wind * 0.13 + math.sin(index * math.tau * 43.0 / RATE) * 0.007
        values[index] = hiss + drop * drop_tone + rumble
    return values


def _crossfade_loop(values: list[float], fade_seconds: float = 1.25) -> None:
    fade_count = int(RATE * fade_seconds)
    tail_start = len(values) - fade_count
    start_copy = values[:fade_count]
    for offset in range(fade_count):
        t = offset / max(1, fade_count - 1)
        smooth = t * t * (3.0 - 2.0 * t)
        values[tail_start + offset] = values[tail_start + offset] * (1.0 - smooth) + start_copy[offset] * smooth


def main() -> None:
    count = RATE * DURATION_SECONDS
    left = _channel(SEED, count)
    right = _channel(SEED + 917, count)
    _crossfade_loop(left)
    _crossfade_loop(right)
    peak = max(max(abs(v) for v in left), max(abs(v) for v in right), 1e-6)
    gain = 0.66 / peak
    pcm = array("h")
    for left_value, right_value in zip(left, right):
        pcm.append(int(max(-1.0, min(1.0, left_value * gain)) * 32767))
        pcm.append(int(max(-1.0, min(1.0, right_value * gain)) * 32767))
    OUTPUT.parent.mkdir(parents=True, exist_ok=True)
    with wave.open(str(OUTPUT), "wb") as wav_file:
        wav_file.setnchannels(2)
        wav_file.setsampwidth(2)
        wav_file.setframerate(RATE)
        wav_file.writeframes(pcm.tobytes())
    print(f"wrote {OUTPUT} ({DURATION_SECONDS}s stereo @ {RATE}Hz)")


if __name__ == "__main__":
    main()
