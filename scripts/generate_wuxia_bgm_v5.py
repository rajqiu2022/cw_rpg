"""Generate long, distinct wuxia BGM themes without reusing two backing songs.

V5 keeps sparse traditional instrumentation and clear pentatonic melody, but
each scene owns a separate motif, register, cadence and percussion profile.
Exploration loops run roughly 80-110 seconds; battle loops start immediately
and run roughly 55-70 seconds before repeating.
"""

from __future__ import annotations

from dataclasses import dataclass
from pathlib import Path

import numpy as np

from generate_wuxia_bgm_v3 import (
    SR,
    add,
    cymbal,
    erhu,
    gong,
    master,
    midi,
    pluck,
    room,
    tanggu,
    wind,
    woodblock,
    write_wav,
)


ROOT = Path(__file__).resolve().parents[1]
OUT = ROOT / "game" / "art" / "audio" / "bgm"


@dataclass(frozen=True)
class FieldTheme:
    name: str
    bpm: float
    root: int
    bars: int
    motif_a: tuple[int, ...]
    motif_b: tuple[int, ...]
    mood: str
    seed: int


@dataclass(frozen=True)
class BattleTheme:
    name: str
    bpm: float
    root: int
    bars: int
    rhythm: tuple[float, ...]
    motif: tuple[int, ...]
    mood: str
    seed: int


def compose_field(theme: FieldTheme) -> np.ndarray:
    beat = 60.0 / theme.bpm
    duration = theme.bars * 4.0 * beat
    track = np.zeros((round(duration * SR), 2), dtype=np.float64)
    dark = theme.mood in {"forest", "cave", "mountain"}

    # Low guqin punctuation establishes tonality without a clockwork arpeggio.
    for bar in range(0, theme.bars, 2):
        start = bar * 4.0 * beat
        add(track, pluck(midi(theme.root - 12), beat * 5.8, theme.seed * 100 + bar, dark=True), start, -0.24, 0.82)
        if bar % 4 == 0:
            add(track, pluck(midi(theme.root - 5), beat * 4.8, theme.seed * 170 + bar, dark=True), start + beat * 0.22, 0.22, 0.54)

    # Each four-bar phrase has a long xiao statement, a pause and an erhu answer.
    for phrase, bar in enumerate(range(1, theme.bars - 3, 4)):
        motif = theme.motif_a if phrase % 2 == 0 else theme.motif_b
        phrase_start = bar * 4.0 * beat
        cursor = phrase_start
        for index, degree in enumerate(motif[:5]):
            note_duration = beat * (1.75 if dark else 1.35)
            register = -12 if theme.mood == "cave" else 0
            lead = wind(
                midi(theme.root + 12 + register + degree),
                note_duration,
                theme.seed * 1000 + phrase * 20 + index,
                xiao=theme.mood != "city",
                suona=theme.mood == "city" and index in {0, 4},
            )
            add(track, lead, cursor, 0.24, 0.76 if not dark else 0.58)
            cursor += beat * (1.25 if index in {0, 3} else 0.92)

        answer_start = phrase_start + 8.5 * beat
        answer = tuple(reversed(motif[1:5]))
        for index, degree in enumerate(answer):
            bowed = erhu(midi(theme.root + 12 + degree), beat * 1.55, theme.seed * 2000 + phrase * 20 + index)
            add(track, bowed, answer_start + index * beat * 1.10, -0.16, 0.58 if theme.mood != "cave" else 0.42)

    # Mood accents are deliberately sparse and structurally distinct.
    for bar in range(theme.bars):
        start = bar * 4.0 * beat
        if theme.mood == "market" and bar % 2 == 0:
            add(track, woodblock(0.42), start, 0.34)
            add(track, pluck(midi(theme.root + 19), beat * 1.3, theme.seed * 3000 + bar, pipa=True), start + beat * 2.5, -0.28, 0.44)
        elif theme.mood == "village" and bar % 4 == 2:
            add(track, pluck(midi(theme.root + 16), beat * 1.8, theme.seed * 3100 + bar), start + beat, 0.18, 0.38)
        elif theme.mood == "journey" and bar % 4 == 0:
            add(track, tanggu(0.18, theme.seed + bar), start, -0.30)
        elif theme.mood == "city" and bar % 4 == 0:
            add(track, tanggu(0.42, theme.seed + bar), start, -0.20)
            add(track, gong(0.30), start, 0.24)
        elif theme.mood == "sect" and bar % 6 == 0:
            add(track, gong(0.34), start, 0.28)
        elif theme.mood == "cave" and bar % 8 == 0:
            add(track, gong(0.30, low=True), start, 0.06)

    track = room(track, 1.00 if theme.mood in {"cave", "sect"} else 0.62)
    return master(track, loop_fade=3.5)


def compose_battle(theme: BattleTheme) -> np.ndarray:
    beat = 60.0 / theme.bpm
    duration = theme.bars * 4.0 * beat
    track = np.zeros((round(duration * SR), 2), dtype=np.float64)
    boss = theme.mood == "boss"
    spar = theme.mood == "spar"

    # First beat starts immediately. Drum grammar differs per theme.
    for bar in range(theme.bars):
        start = bar * 4.0 * beat
        for index, pulse in enumerate(theme.rhythm):
            strength = 0.86 if pulse in {0.0, 2.0} else (0.58 if not spar else 0.36)
            add(track, tanggu(strength, theme.seed * 100 + bar * 10 + index), start + pulse * beat, -0.12 if index % 2 == 0 else 0.18)
        if not spar:
            for pulse in (1.0, 3.0):
                add(track, woodblock(0.42 if not boss else 0.58), start + pulse * beat, 0.38)
        if bar % (3 if boss else 6) == 0:
            add(track, gong(0.52 if boss else 0.25, low=boss), start, 0.16)
        if boss and bar % 3 == 2:
            add(track, cymbal(theme.seed + bar, 0.42), start + 3.5 * beat, 0.30)

        # Low guqin pulse supplies weight without a modern bass line.
        add(track, pluck(midi(theme.root - 12), beat * 2.8, theme.seed * 400 + bar, dark=True), start, -0.18, 0.68)
        if bar % 2 == 1:
            add(track, pluck(midi(theme.root - 5), beat * 2.2, theme.seed * 500 + bar, dark=True), start + 2.0 * beat, 0.12, 0.48)

    # Erhu/suona phrases answer every four bars; each BGM has a unique motif.
    for phrase, bar in enumerate(range(0, theme.bars - 3, 4)):
        start = bar * 4.0 * beat + beat * 0.45
        motif = theme.motif if phrase % 2 == 0 else tuple(reversed(theme.motif))
        for index, degree in enumerate(motif):
            duration_note = beat * (1.05 if boss else 1.30)
            if boss and index in {0, len(motif) - 1}:
                voice = wind(midi(theme.root + 12 + degree), duration_note, theme.seed * 1000 + phrase * 20 + index, suona=True)
                gain = 0.72
            else:
                voice = erhu(midi(theme.root + 12 + degree), duration_note, theme.seed * 1000 + phrase * 20 + index)
                gain = 0.58 if not spar else 0.44
            add(track, voice, start + index * beat * 0.86, 0.24, gain)

    track = room(track, 0.44 if spar else 0.58)
    return master(track, loop_fade=2.0)


def main() -> None:
    OUT.mkdir(parents=True, exist_ok=True)
    fields = [
        FieldTheme("bgm_jianghu_journey_v5.wav", 72, 43, 30, (0,4,7,9,7), (4,7,11,9,4), "journey", 5101),
        FieldTheme("bgm_village_day_v5.wav", 76, 48, 28, (0,4,7,4,2), (4,9,7,4,0), "village", 5102),
        FieldTheme("bgm_mountain_path_v5.wav", 62, 41, 26, (0,7,9,7,4), (-3,0,4,7,2), "mountain", 5103),
        FieldTheme("bgm_forest_mystery_v5.wav", 56, 38, 24, (0,2,7,4,-3), (4,2,0,-5,-3), "forest", 5104),
        FieldTheme("bgm_cave_ominous_v5.wav", 50, 36, 22, (0,-3,2,-5,-3), (-5,0,2,-3,-7), "cave", 5105),
        FieldTheme("bgm_market_lively_v5.wav", 86, 50, 30, (0,4,7,9,12), (7,9,4,2,4), "market", 5106),
        FieldTheme("bgm_city_ceremony_v5.wav", 68, 43, 28, (0,7,12,9,7), (5,9,7,4,0), "city", 5107),
        FieldTheme("bgm_sect_clouds_v5.wav", 58, 45, 24, (0,5,9,7,4), (9,12,7,5,0), "sect", 5108),
    ]
    battles = [
        BattleTheme("bgm_battle_village_v5.wav", 124, 48, 30, (0.0,1.5,2.0,3.25), (0,4,7,9,4), "standard", 6101),
        BattleTheme("bgm_battle_mountain_v5.wav", 130, 41, 32, (0.0,1.0,2.0,2.75,3.5), (0,5,9,7,2), "standard", 6102),
        BattleTheme("bgm_battle_river_v5.wav", 126, 43, 30, (0.0,1.25,2.0,3.0), (0,4,11,9,7), "standard", 6103),
        BattleTheme("bgm_battle_spar_v5.wav", 116, 50, 26, (0.0,2.0), (0,4,7,9,7), "spar", 6104),
        BattleTheme("bgm_battle_boss_v5.wav", 140, 36, 36, (0.0,0.75,1.5,2.0,2.75,3.5), (0,3,7,10,5), "boss", 6105),
    ]
    for theme in fields:
        write_wav(OUT / theme.name, compose_field(theme))
    for theme in battles:
        write_wav(OUT / theme.name, compose_battle(theme))


if __name__ == "__main__":
    main()
