#!/usr/bin/env python3
"""Split a 2x2 NPC conversation atlas into normalized 160px RGBA directions."""

from __future__ import annotations

import argparse
from pathlib import Path

from PIL import Image


DIRECTIONS = ("down", "up", "left", "right")
CANVAS = 160
BODY_HEIGHT = 140
BOTTOM_MARGIN = 8


def _alpha_bbox(image: Image.Image) -> tuple[int, int, int, int]:
    alpha = image.getchannel("A")
    bbox = alpha.getbbox()
    if bbox is None:
        raise ValueError("direction cell has no visible pixels")
    return bbox


def _normalize(cell: Image.Image) -> Image.Image:
    bbox = _alpha_bbox(cell)
    subject = cell.crop(bbox)
    scale = min(BODY_HEIGHT / subject.height, (CANVAS - 12) / subject.width)
    size = (max(1, round(subject.width * scale)), max(1, round(subject.height * scale)))
    subject = subject.resize(size, Image.Resampling.LANCZOS)
    canvas = Image.new("RGBA", (CANVAS, CANVAS), (0, 0, 0, 0))
    x = (CANVAS - subject.width) // 2
    y = CANVAS - BOTTOM_MARGIN - subject.height
    canvas.alpha_composite(subject, (x, y))
    return canvas


def process(source: Path, output_dir: Path, prefix: str) -> None:
    atlas = Image.open(source).convert("RGBA")
    if atlas.width % 2 or atlas.height % 2:
        raise ValueError(f"atlas must divide evenly into 2x2 cells: {atlas.size}")
    cell_w, cell_h = atlas.width // 2, atlas.height // 2
    output_dir.mkdir(parents=True, exist_ok=True)
    for index, direction in enumerate(DIRECTIONS):
        column, row = index % 2, index // 2
        cell = atlas.crop((column * cell_w, row * cell_h, (column + 1) * cell_w, (row + 1) * cell_h))
        runtime = _normalize(cell)
        output = output_dir / f"{prefix}_{direction}_conversation_1f.png"
        runtime.save(output, optimize=True)
        print(f"Wrote {output}")


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("source", type=Path)
    parser.add_argument("output_dir", type=Path)
    parser.add_argument("prefix")
    args = parser.parse_args()
    process(args.source, args.output_dir, args.prefix)


if __name__ == "__main__":
    main()
