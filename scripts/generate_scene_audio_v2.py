"""Generate original, royalty-free scene loops and a legendary-title sting.

The project has no external audio-generation dependency.  These deliberately
restrained pentatonic loops provide distinct scene identity and can later be
replaced by commissioned masters without changing scene data paths.
"""

from __future__ import annotations

import math
import random
import struct
import wave
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]
BGM_DIR = ROOT / "game" / "art" / "audio" / "bgm"
SFX_DIR = ROOT / "game" / "art" / "audio" / "free"
RATE = 22050
TAU = math.tau


def note(root: float, semitone: int) -> float:
    return root * (2.0 ** (semitone / 12.0))


def envelope(local: float, duration: float, attack: float = 0.03, release: float = 0.35) -> float:
    if local < 0.0 or local >= duration:
        return 0.0
    a = min(1.0, local / max(attack, 1e-4))
    r = min(1.0, (duration - local) / max(release, 1e-4))
    return a * r


def synth_loop(
    duration: float,
    bpm: float,
    root_hz: float,
    melody: list[int],
    *,
    mood: str,
    seed: int,
) -> list[float]:
    rng = random.Random(seed)
    count = int(duration * RATE)
    data = [0.0] * count
    beat = 60.0 / bpm
    phrase = beat * len(melody)
    drone_fifth = note(root_hz, 7)

    for i in range(count):
        t = i / RATE
        # Slow tanpura-like floor; phase lands near zero at the loop seam.
        drone = math.sin(TAU * root_hz * t) * 0.035
        drone += math.sin(TAU * drone_fifth * t) * 0.018
        air = math.sin(TAU * 0.083 * t) * 0.006
        data[i] = drone + air

    for step, interval in enumerate(melody * int(math.ceil(duration / phrase))):
        start = step * beat
        if start >= duration:
            break
        freq = note(root_hz * 2.0, interval)
        note_len = beat * (0.78 if mood not in {"cave", "forest"} else 1.35)
        start_i = int(start * RATE)
        end_i = min(count, int((start + note_len) * RATE))
        for i in range(start_i, end_i):
            local = i / RATE - start
            env = envelope(local, note_len, 0.025 if mood != "cave" else 0.18, note_len * 0.42)
            phase = TAU * freq * local
            if mood in {"village", "market", "journey"}:
                # Pipa/ruan-like pluck.
                value = math.sin(phase) * 0.105 + math.sin(phase * 2.01) * 0.030
                value += math.sin(phase * 3.99) * 0.012
                env *= math.exp(-2.2 * local)
            elif mood in {"mountain", "sect"}:
                # Airy xiao-like line.
                value = math.sin(phase) * 0.078 + math.sin(phase * 2.0) * 0.012
                value += math.sin(phase * 0.5) * 0.018
            elif mood == "city":
                value = math.sin(phase) * 0.082 + math.sin(phase * 1.5) * 0.018
            else:
                value = math.sin(phase) * 0.052 + math.sin(phase * 0.5) * 0.032
            data[i] += value * env

    # Low, sparse percussion distinguishes busy/suspenseful spaces.
    percussion_rate = beat * (0.5 if mood in {"market", "battle"} else 2.0)
    hit = 0.0
    while hit < duration:
        if mood not in {"cave", "forest"} or int(hit / percussion_rate) % 2 == 0:
            start_i = int(hit * RATE)
            end_i = min(count, start_i + int(0.18 * RATE))
            for i in range(start_i, end_i):
                local = (i - start_i) / RATE
                noise = rng.uniform(-1.0, 1.0)
                body = math.sin(TAU * (76.0 if mood == "battle" else 96.0) * local)
                data[i] += (body * 0.045 + noise * 0.018) * math.exp(-24.0 * local)
        hit += percussion_rate

    # Short crossfade makes loop boundaries inaudible.
    fade = int(0.45 * RATE)
    for i in range(fade):
        mix = i / fade
        head = data[i]
        tail = data[count - fade + i]
        blended = head * mix + tail * (1.0 - mix)
        data[i] = blended
        data[count - fade + i] = blended
    peak = max(max(abs(v) for v in data), 1e-6)
    gain = 0.72 / peak
    return [max(-1.0, min(1.0, value * gain)) for value in data]


def legendary_sting(duration: float = 1.85) -> list[float]:
    rng = random.Random(917)
    count = int(duration * RATE)
    data: list[float] = []
    phase = 0.0
    for i in range(count):
        t = i / RATE
        x = t / duration
        sweep = 125.0 + 1450.0 * (x**1.7)
        phase += TAU * sweep / RATE
        whoosh = (rng.uniform(-1.0, 1.0) * 0.16 + math.sin(phase) * 0.12)
        whoosh *= math.sin(math.pi * min(1.0, x)) ** 0.65
        gong = math.sin(TAU * 98.0 * t) * math.exp(-2.1 * t) * 0.34
        gong += math.sin(TAU * 147.0 * t) * math.exp(-2.7 * t) * 0.20
        chime_t = max(0.0, t - 0.58)
        chime = math.sin(TAU * 784.0 * chime_t) * math.exp(-4.8 * chime_t) * (0.22 if t >= 0.58 else 0.0)
        data.append(max(-1.0, min(1.0, gong + whoosh + chime)))
    return data


def write_wav(path: Path, samples: list[float]) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    with wave.open(str(path), "wb") as wav:
        wav.setnchannels(1)
        wav.setsampwidth(2)
        wav.setframerate(RATE)
        wav.writeframes(b"".join(struct.pack("<h", int(value * 30000.0)) for value in samples))


def main() -> None:
    tracks = {
        "bgm_jianghu_journey_v2.wav": (28.0, 74.0, 110.0, [0, 4, 7, 9, 7, 4, 2, 4], "journey", 101),
        "bgm_village_day_v2.wav": (24.0, 82.0, 123.47, [0, 4, 7, 4, 9, 7, 4, 2], "village", 102),
        "bgm_mountain_path_v2.wav": (28.0, 58.0, 98.0, [0, 7, 9, 7, 4, 2, 4, 0], "mountain", 103),
        "bgm_forest_mystery_v2.wav": (28.0, 52.0, 92.5, [0, 3, 7, 2, 5, 3, -2, 0], "forest", 104),
        "bgm_cave_ominous_v2.wav": (24.0, 46.0, 73.42, [0, 1, 6, 1, -2, 1, 3, 0], "cave", 105),
        "bgm_market_lively_v2.wav": (24.0, 96.0, 130.81, [0, 4, 7, 9, 12, 9, 7, 4], "market", 106),
        "bgm_city_ceremony_v2.wav": (28.0, 68.0, 110.0, [0, 7, 12, 9, 7, 4, 2, 0], "city", 107),
        "bgm_sect_clouds_v2.wav": (28.0, 56.0, 98.0, [0, 4, 9, 7, 12, 9, 4, 2], "sect", 108),
        "bgm_battle_river_v2.wav": (20.0, 108.0, 92.5, [0, 3, 5, 7, 5, 3, 2, 0], "battle", 109),
        "bgm_battle_mountain_v2.wav": (20.0, 100.0, 82.41, [0, 5, 3, 7, 5, 8, 7, 3], "battle", 110),
    }
    for name, args in tracks.items():
        write_wav(BGM_DIR / name, synth_loop(*args[:4], mood=args[4], seed=args[5]))
    write_wav(SFX_DIR / "sfx_legendary_title_reveal_v2.wav", legendary_sting())
    print(f"Generated {len(tracks)} scene loops and 1 legendary-title sting")


if __name__ == "__main__":
    main()
