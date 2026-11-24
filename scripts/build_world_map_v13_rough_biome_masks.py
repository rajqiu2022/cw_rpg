"""Create reproducible rough biome masks for the center/east v13 art sample.

These are colour-guided review masks, not authored navigation or approved
shorelines. The output is intentionally limited to reference pixels x512:1536,
y341:683; the other seven regions remain unpainted PLACEHOLDER terrain.
"""

from __future__ import annotations

import argparse
from pathlib import Path

import numpy as np
from PIL import Image, ImageFilter


ROOT = Path(__file__).resolve().parents[1]
REFERENCE = ROOT / "game/art/backgrounds/world_map_v13_tiles/world_map_v13_unified_topology_master_v1_candidate.png"
DEFAULT_OUT = ROOT / "game/build/world_map_v13_native_candidate/masks"
SIZE = (4608, 3072)


def build(out_dir: Path) -> None:
    out_dir = out_dir.resolve()
    if not out_dir.is_relative_to(ROOT / "game/build"):
        raise ValueError("Rough masks may only be written under game/build")
    out_dir.mkdir(parents=True, exist_ok=True)
    with Image.open(REFERENCE) as source:
        if source.size != (1536, 1024):
            raise ValueError(f"Unexpected topology reference size: {source.size}")
        rgb = np.asarray(source.convert("RGB"), dtype=np.float32)
    red, green, blue = rgb[:, :, 0], rgb[:, :, 1], rgb[:, :, 2]
    yy, xx = np.indices((1024, 1536))
    sample = (xx >= 512) & (yy >= 341) & (yy < 683)
    water = sample & (blue > red * 1.12) & (green > red * 1.07) & (blue > 72) & (green > 67)
    near_water = np.asarray(
        Image.fromarray(np.uint8(water) * 255).filter(ImageFilter.MaxFilter(43))
    ) > 0
    deep = water & (xx > 1200) & (blue > green * 1.06)
    shallow = water & ~deep
    sand = sample & ~water & near_water & (xx > 1120) & (red > 125) & (green > 105) & (red > blue * 1.10)
    wetland = sample & ~water & ~sand & near_water & (yy > 490) & (red < 170)
    rock = sample & ~water & ~sand & ~wetland & (
        ((yy < 410) & (xx > 920) & (red < 175))
        | ((xx > 1120) & (yy > 600) & (red < 140))
    )
    grass = sample & ~water & ~sand & ~wetland & ~rock
    categories = {
        "dry_grass": grass,
        "rock": rock,
        "wetland_bank": wetland,
        "beach_sand": sand,
        "shallow_water": shallow,
        "deep_water": deep,
    }
    for name, condition in categories.items():
        small = Image.fromarray(np.uint8(condition) * 255, "L")
        # Soft edges follow the shared topology rather than a per-tile seam.
        native = small.filter(ImageFilter.GaussianBlur(1.5)).resize(SIZE, Image.Resampling.BILINEAR)
        native.save(out_dir / f"rough_{name}.png")
        print(f"{name}: {int(condition.sum())} reference pixels")


if __name__ == "__main__":
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--out-dir", type=Path, default=DEFAULT_OUT)
    build(parser.parse_args().out_dir)
