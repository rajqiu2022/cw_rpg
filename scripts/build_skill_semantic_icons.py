#!/usr/bin/env python3
"""Slice the approved 4x4 semantic martial-art icon atlas into runtime icons."""

from __future__ import annotations

from pathlib import Path

from PIL import Image


ROOT = Path(__file__).resolve().parents[1]
SOURCE = ROOT / "assets" / "raw" / "ui_icon" / "skill_semantic_v1" / "atlas_skill_semantic_4x4_v1.png"
BASIC_SOURCE = ROOT / "assets" / "raw" / "ui_icon" / "skill_semantic_v1" / "atlas_basic_attack_2x2_v1.png"
OUTPUT = ROOT / "game" / "art" / "ui" / "skill" / "icons_semantic_v1"

ICON_NAMES = [
    "sword_slash", "sword_cross", "sword_star", "sword_yinyang",
    "blade_heavy", "blade_crescent", "staff_sweep", "palm_wave",
    "frost_needles", "poison_needles", "shadow_dagger", "footwork",
    "inner_breath", "guard", "healing", "redirect",
]
BASIC_ICON_NAMES = ["basic_sword", "basic_blade", "basic_staff", "basic_unarmed"]


def build() -> list[Path]:
    if not SOURCE.is_file():
        raise FileNotFoundError(SOURCE)
    OUTPUT.mkdir(parents=True, exist_ok=True)
    with Image.open(SOURCE) as opened:
        atlas = opened.convert("RGBA")
    written: list[Path] = []
    for index, name in enumerate(ICON_NAMES):
        column = index % 4
        row = index // 4
        left = round(column * atlas.width / 4)
        top = round(row * atlas.height / 4)
        right = round((column + 1) * atlas.width / 4)
        bottom = round((row + 1) * atlas.height / 4)
        icon = atlas.crop((left, top, right, bottom)).resize((256, 256), Image.Resampling.LANCZOS)
        output = OUTPUT / f"icon_skill_{name}_v1.png"
        icon.save(output, optimize=True)
        written.append(output)
    if not BASIC_SOURCE.is_file():
        raise FileNotFoundError(BASIC_SOURCE)
    with Image.open(BASIC_SOURCE) as opened:
        basic_atlas = opened.convert("RGBA")
    for index, name in enumerate(BASIC_ICON_NAMES):
        column = index % 2
        row = index // 2
        left = round(column * basic_atlas.width / 2)
        top = round(row * basic_atlas.height / 2)
        right = round((column + 1) * basic_atlas.width / 2)
        bottom = round((row + 1) * basic_atlas.height / 2)
        icon = basic_atlas.crop((left, top, right, bottom)).resize((256, 256), Image.Resampling.LANCZOS)
        output = OUTPUT / f"icon_skill_{name}_v1.png"
        icon.save(output, optimize=True)
        written.append(output)
    return written


if __name__ == "__main__":
    files = build()
    print(f"Wrote {len(files)} semantic skill icons to {OUTPUT.relative_to(ROOT)}")
