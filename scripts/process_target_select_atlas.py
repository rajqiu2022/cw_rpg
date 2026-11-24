#!/usr/bin/env python3
"""Split a three-state chroma-key target-button atlas into equal runtime assets."""

from __future__ import annotations

import argparse
from pathlib import Path

from PIL import Image


STATE_NAMES = ("normal", "hover", "pressed")


def alpha_bbox(image: Image.Image) -> tuple[int, int, int, int]:
    bbox = image.getchannel("A").getbbox()
    if bbox is None:
        raise ValueError("state contains no visible pixels")
    return bbox


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("source", type=Path)
    parser.add_argument("output_dir", type=Path)
    parser.add_argument("--width", type=int, default=320)
    parser.add_argument("--height", type=int, default=96)
    args = parser.parse_args()

    source = Image.open(args.source).convert("RGBA")
    args.output_dir.mkdir(parents=True, exist_ok=True)
    cell_width = source.width // 3
    crops: list[Image.Image] = []
    for index in range(3):
        left = index * cell_width
        right = source.width if index == 2 else (index + 1) * cell_width
        cell = source.crop((left, 0, right, source.height))
        crops.append(cell.crop(alpha_bbox(cell)))

    common_width = max(crop.width for crop in crops)
    common_height = max(crop.height for crop in crops)
    for state, crop in zip(STATE_NAMES, crops, strict=True):
        common = Image.new("RGBA", (common_width, common_height), (0, 0, 0, 0))
        common.alpha_composite(
            crop,
            ((common_width - crop.width) // 2, (common_height - crop.height) // 2),
        )
        common.thumbnail((args.width - 8, args.height - 8), Image.Resampling.LANCZOS)
        canvas = Image.new("RGBA", (args.width, args.height), (0, 0, 0, 0))
        canvas.alpha_composite(
            common,
            ((args.width - common.width) // 2, (args.height - common.height) // 2),
        )
        canvas.save(args.output_dir / f"target_select_{state}_v1.png")


if __name__ == "__main__":
    main()
