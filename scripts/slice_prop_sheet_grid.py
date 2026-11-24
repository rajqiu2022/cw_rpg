"""Slice a chroma-keyed prop review sheet into trimmed transparent PNGs."""

from __future__ import annotations

import argparse
from pathlib import Path

from PIL import Image


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--input", type=Path, required=True)
    parser.add_argument("--out-dir", type=Path, required=True)
    parser.add_argument("--ids", required=True, help="Comma-separated IDs in row-major order.")
    parser.add_argument("--cols", type=int, default=3)
    parser.add_argument("--rows", type=int, default=2)
    parser.add_argument("--padding", type=int, default=12)
    parser.add_argument(
        "--alpha-threshold",
        type=int,
        default=0,
        help="Treat alpha values at or below this value as transparent when trimming.",
    )
    return parser.parse_args()


def main() -> None:
    args = parse_args()
    ids = [item.strip() for item in args.ids.split(",") if item.strip()]
    expected = args.cols * args.rows
    if len(ids) != expected:
        raise ValueError(f"Expected {expected} IDs for a {args.cols}x{args.rows} sheet, got {len(ids)}")

    source = Image.open(args.input).convert("RGBA")
    cell_width = source.width // args.cols
    cell_height = source.height // args.rows
    args.out_dir.mkdir(parents=True, exist_ok=True)

    for index, asset_id in enumerate(ids):
        column = index % args.cols
        row = index // args.cols
        x0 = column * cell_width
        y0 = row * cell_height
        x1 = source.width if column == args.cols - 1 else x0 + cell_width
        y1 = source.height if row == args.rows - 1 else y0 + cell_height
        cell = source.crop((x0, y0, x1, y1))
        alpha = cell.getchannel("A")
        if args.alpha_threshold > 0:
            alpha = alpha.point(lambda value: 255 if value > args.alpha_threshold else 0)
        alpha_bounds = alpha.getbbox()
        if alpha_bounds is None:
            raise ValueError(f"Cell {asset_id} has no visible pixels")

        left = max(0, alpha_bounds[0] - args.padding)
        top = max(0, alpha_bounds[1] - args.padding)
        right = min(cell.width, alpha_bounds[2] + args.padding)
        bottom = min(cell.height, alpha_bounds[3] + args.padding)
        output = cell.crop((left, top, right, bottom))
        output_path = args.out_dir / f"{asset_id}.png"
        output.save(output_path)
        print(f"{asset_id}: {output.size[0]}x{output.size[1]} -> {output_path}")


if __name__ == "__main__":
    main()
