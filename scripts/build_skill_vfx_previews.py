#!/usr/bin/env python3
"""Render the runtime 2x2 battle VFX sheets as animated catalogue previews."""

from __future__ import annotations

import re
from pathlib import Path

from PIL import Image


ROOT = Path(__file__).resolve().parents[1]
GAME = ROOT / "game"
VFX_SCRIPT = GAME / "scripts" / "battle" / "battle_vfx_player.gd"
OUTPUT_DIR = ROOT / "docs" / "assets" / "skill-vfx"


def collect_effects() -> dict[str, tuple[Path, float]]:
    source = VFX_SCRIPT.read_text(encoding="utf-8")
    effects: dict[str, tuple[Path, float]] = {}
    for match in re.finditer(r'&"([^"]+)"\s*:\s*\{(.*?)\}', source, re.DOTALL):
        animation_id, config = match.groups()
        sheet_match = re.search(r'"sheet"\s*:\s*"res://([^"]+)"', config)
        if not sheet_match:
            continue
        seconds_match = re.search(r'"frame_seconds"\s*:\s*([0-9.]+)', config)
        frame_seconds = float(seconds_match.group(1)) if seconds_match else 0.10
        effects[animation_id] = (GAME / sheet_match.group(1), frame_seconds)
    unique_dir = GAME / "art" / "battle_vfx" / "skill_unique_v1"
    for sheet_path in unique_dir.glob("vfx_*_4frame_v1.png"):
        animation_id = sheet_path.name.removeprefix("vfx_").removesuffix("_4frame_v1.png")
        if animation_id not in effects:
            effects[animation_id] = (sheet_path, 0.10)
    return effects


def render_preview(sheet_path: Path, output_path: Path, frame_seconds: float) -> None:
    with Image.open(sheet_path) as sheet:
        rgba = sheet.convert("RGBA")
    frame_width = rgba.width // 2
    frame_height = rgba.height // 2
    if frame_width <= 0 or frame_height <= 0:
        raise ValueError(f"invalid VFX sheet dimensions: {sheet_path}")
    frames = [
        rgba.crop((column * frame_width, row * frame_height, (column + 1) * frame_width, (row + 1) * frame_height))
        for row in range(2)
        for column in range(2)
    ]
    maximum = 360
    scale = min(maximum / frame_width, maximum / frame_height, 1.0)
    if scale < 1.0:
        size = (max(1, round(frame_width * scale)), max(1, round(frame_height * scale)))
        frames = [frame.resize(size, Image.Resampling.LANCZOS) for frame in frames]
    duration = max(65, round(frame_seconds * 1000))
    output_path.parent.mkdir(parents=True, exist_ok=True)
    frames[0].save(
        output_path,
        format="WEBP",
        save_all=True,
        append_images=frames[1:],
        duration=[duration, duration, duration, duration * 2],
        loop=0,
        lossless=True,
        method=6,
    )


def build() -> dict[str, Path]:
    previews: dict[str, Path] = {}
    for animation_id, (sheet_path, frame_seconds) in collect_effects().items():
        if not sheet_path.is_file():
            raise FileNotFoundError(f"missing VFX sheet for {animation_id}: {sheet_path}")
        output_path = OUTPUT_DIR / f"{animation_id}.webp"
        render_preview(sheet_path, output_path, frame_seconds)
        previews[animation_id] = output_path
    return previews


if __name__ == "__main__":
    generated = build()
    print(f"Wrote {len(generated)} animated VFX previews to {OUTPUT_DIR.relative_to(ROOT)}")
