"""Build normalized 160px field sprite strips from a transparent grid atlas."""

from __future__ import annotations

import argparse
from pathlib import Path

from PIL import Image

from slice_fixed_grid_atlas import _keep_largest_component


CANVAS = 160
BODY_HEIGHT = 140
BOTTOM_MARGIN = 8


def _frame(cell: Image.Image) -> Image.Image:
    rgba = _keep_largest_component(cell.convert("RGBA"))
    bbox = rgba.getchannel("A").getbbox()
    if bbox is None:
        raise ValueError("field sprite cell has no visible pixels")
    sprite = rgba.crop(bbox)
    max_width = CANVAS - 12
    scale = min(max_width / sprite.width, BODY_HEIGHT / sprite.height)
    sprite = sprite.resize(
        (max(1, round(sprite.width * scale)), max(1, round(sprite.height * scale))),
        Image.Resampling.LANCZOS,
    )
    frame = Image.new("RGBA", (CANVAS, CANVAS), (0, 0, 0, 0))
    frame.alpha_composite(
        sprite,
        ((CANVAS - sprite.width) // 2, CANVAS - BOTTOM_MARGIN - sprite.height),
    )
    return frame


def build(
    source: Path,
    output_dir: Path,
    columns: int,
    rows: int,
    row_names: list[str],
    suffix: str,
) -> list[Path]:
    if len(row_names) != rows:
        raise ValueError(f"expected {rows} row names, got {len(row_names)}")
    atlas = Image.open(source).convert("RGBA")
    output_dir.mkdir(parents=True, exist_ok=True)
    outputs: list[Path] = []
    for row in range(rows):
        strip = Image.new("RGBA", (CANVAS * columns, CANVAS), (0, 0, 0, 0))
        top = round(row * atlas.height / rows)
        bottom = round((row + 1) * atlas.height / rows)
        for column in range(columns):
            left = round(column * atlas.width / columns)
            right = round((column + 1) * atlas.width / columns)
            strip.alpha_composite(_frame(atlas.crop((left, top, right, bottom))), (column * CANVAS, 0))
        output = output_dir / f"{row_names[row]}_{suffix}.png"
        strip.save(output)
        outputs.append(output)
    return outputs


def build_idle_strip(
    source: Path,
    output: Path,
    columns: int,
    rows: int,
    row: int,
    frame_indices: list[int],
) -> Path:
    """Build a stable idle strip directly from approved full-body source cells."""
    atlas = Image.open(source).convert("RGBA")
    if row < 0 or row >= rows:
        raise ValueError(f"idle row {row} outside 0..{rows - 1}")
    if not frame_indices:
        raise ValueError("idle frame indices cannot be empty")
    strip = Image.new("RGBA", (CANVAS * len(frame_indices), CANVAS), (0, 0, 0, 0))
    top = round(row * atlas.height / rows)
    bottom = round((row + 1) * atlas.height / rows)
    for output_index, source_column in enumerate(frame_indices):
        if source_column < 0 or source_column >= columns:
            raise ValueError(f"idle frame column {source_column} outside 0..{columns - 1}")
        left = round(source_column * atlas.width / columns)
        right = round((source_column + 1) * atlas.width / columns)
        strip.alpha_composite(_frame(atlas.crop((left, top, right, bottom))), (output_index * CANVAS, 0))
    output.parent.mkdir(parents=True, exist_ok=True)
    strip.save(output)
    return output


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("source", type=Path)
    parser.add_argument("output_dir", type=Path)
    parser.add_argument("--columns", type=int, required=True)
    parser.add_argument("--rows", type=int, required=True)
    parser.add_argument("--row-names", required=True)
    parser.add_argument("--suffix", required=True)
    parser.add_argument("--idle-output", type=Path)
    parser.add_argument("--idle-row", type=int, default=0)
    parser.add_argument(
        "--idle-frame-indices",
        default="0,2,4,6",
        help="Comma-separated source columns used for the optional idle strip.",
    )
    args = parser.parse_args()
    outputs = build(
        args.source,
        args.output_dir,
        args.columns,
        args.rows,
        [name.strip() for name in args.row_names.split(",") if name.strip()],
        args.suffix,
    )
    if args.idle_output is not None:
        outputs.append(build_idle_strip(
            args.source,
            args.idle_output,
            args.columns,
            args.rows,
            args.idle_row,
            [int(value.strip()) for value in args.idle_frame_indices.split(",") if value.strip()],
        ))
    print("\n".join(str(path) for path in outputs))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
