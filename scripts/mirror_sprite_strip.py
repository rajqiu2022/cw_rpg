"""Mirror a horizontal sprite strip per cell.

Takes a right-facing walk strip, detects each sprite column via white gaps,
flips every cell horizontally, and writes a new strip preserving frame order.
This lets us derive a left-facing walk asset from a right-facing PASS baseline
without spending API quota and without breaking anchor/loop assumptions.
"""

from __future__ import annotations

import argparse
from pathlib import Path

from PIL import Image, ImageChops, ImageOps


WHITE = (255, 255, 255, 255)


def _segment_cells_by_columns(sheet: Image.Image, expected: int) -> list[tuple[int, int]]:
    bg = Image.new("RGBA", sheet.size, WHITE)
    diff = ImageChops.difference(sheet, bg).convert("L")
    mask = diff.point(lambda p: 255 if p > 12 else 0)
    pixels = mask.load()

    column_counts: list[int] = []
    for x in range(mask.width):
        count = 0
        for y in range(mask.height):
            if pixels[x, y]:
                count += 1
        column_counts.append(count)

    groups: list[tuple[int, int]] = []
    in_group = False
    start = 0
    min_count = 4
    for x, count in enumerate(column_counts):
        if count >= min_count and not in_group:
            start = x
            in_group = True
        elif count < min_count and in_group:
            groups.append((start, x))
            in_group = False
    if in_group:
        groups.append((start, len(column_counts)))

    merged: list[tuple[int, int]] = []
    max_inner_gap = 8
    for group in groups:
        if not merged or group[0] - merged[-1][1] > max_inner_gap:
            merged.append(group)
        else:
            merged[-1] = (merged[-1][0], group[1])

    merged = [g for g in merged if g[1] - g[0] > 24]
    if len(merged) != expected:
        merged = sorted(merged, key=lambda g: g[1] - g[0], reverse=True)[:expected]
        merged.sort(key=lambda g: g[0])
    return merged


def mirror_strip(source: Path, output: Path, expected: int) -> None:
    sheet = Image.open(source).convert("RGBA")
    groups = _segment_cells_by_columns(sheet, expected)

    out = Image.new("RGBA", sheet.size, WHITE)
    for left, right in groups:
        cell = sheet.crop((left, 0, right, sheet.height))
        flipped = ImageOps.mirror(cell)
        out.alpha_composite(flipped, (left, 0))

    output.parent.mkdir(parents=True, exist_ok=True)
    out.save(output)


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(description="Mirror sprite strip per cell")
    parser.add_argument("--source", type=Path, required=True)
    parser.add_argument("--output", type=Path, required=True)
    parser.add_argument("--expected", type=int, default=9)
    return parser.parse_args()


def main() -> int:
    args = parse_args()
    mirror_strip(args.source, args.output, args.expected)
    print(args.output)
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
