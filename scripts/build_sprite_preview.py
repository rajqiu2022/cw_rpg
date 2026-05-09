"""
Build fixed-canvas sprite previews from generated sprite strips/sheets.

The image model often places each sprite slightly differently inside its cell.
For animation review and in-game use, every frame must share the same canvas
size and anchor. This script trims white space per cell, normalizes sprite
height, and places each frame on a fixed canvas using a bottom-center anchor.
"""

from __future__ import annotations

import argparse
from pathlib import Path

from PIL import Image, ImageChops


WHITE = (255, 255, 255, 255)


def _non_white_bbox(img: Image.Image, threshold: int = 12) -> tuple[int, int, int, int] | None:
    bg = Image.new("RGBA", img.size, WHITE)
    diff = ImageChops.difference(img, bg).convert("L")
    mask = diff.point(lambda p: 255 if p > threshold else 0)
    return mask.getbbox()


def _trim(img: Image.Image, pad: int) -> Image.Image:
    bbox = _non_white_bbox(img)
    if bbox is None:
        return img
    left, top, right, bottom = bbox
    left = max(0, left - pad)
    top = max(0, top - pad)
    right = min(img.width, right + pad)
    bottom = min(img.height, bottom + pad)
    return img.crop((left, top, right, bottom))


def _normalize_frame(
    cell: Image.Image,
    *,
    sprite_height: int,
    canvas_width: int,
    canvas_height: int,
    pad: int,
    bottom_margin: int,
    preserve_scale: bool,
) -> Image.Image:
    trimmed = _trim(cell, pad)
    if preserve_scale:
        resized = trimmed
    else:
        scale = sprite_height / max(1, trimmed.height)
        target_width = max(1, round(trimmed.width * scale))
        resized = trimmed.resize((target_width, sprite_height), Image.Resampling.LANCZOS)

    frame = Image.new("RGBA", (canvas_width, canvas_height), WHITE)
    x = (canvas_width - resized.width) // 2
    y = canvas_height - bottom_margin - resized.height
    frame.alpha_composite(resized, (x, y))
    return frame


def build_strip_preview(
    source: Path,
    output_gif: Path,
    output_sheet: Path,
    *,
    cols: int,
    row: int,
    rows: int,
    sprite_height: int,
    canvas_width: int,
    canvas_height: int,
    duration_ms: int,
    segment_columns: bool,
    preserve_scale: bool,
    frame_count: int | None,
    cell_top_inset: int,
    cell_bottom_inset: int,
) -> None:
    sheet = Image.open(source).convert("RGBA")
    cells: list[Image.Image] = []
    if segment_columns:
        cells = _segment_cells_by_columns(sheet, expected=cols)
    else:
        cell_width = sheet.width // cols
        cell_height = sheet.height // rows
        for col in range(cols):
            top = row * cell_height + cell_top_inset
            bottom = (row + 1) * cell_height - cell_bottom_inset
            cells.append(
                sheet.crop(
                    (
                        col * cell_width,
                        top,
                        (col + 1) * cell_width,
                        bottom,
                    )
                )
            )

    if frame_count is not None:
        cells = cells[:frame_count]

    frames: list[Image.Image] = []
    for cell in cells:
        frames.append(
            _normalize_frame(
                cell,
                sprite_height=sprite_height,
                canvas_width=canvas_width,
                canvas_height=canvas_height,
                pad=8,
                bottom_margin=8,
                preserve_scale=preserve_scale,
            )
        )

    output_gif.parent.mkdir(parents=True, exist_ok=True)
    gif_frames = [frame.convert("P", palette=Image.Palette.ADAPTIVE) for frame in frames]
    gif_frames[0].save(
        output_gif,
        save_all=True,
        append_images=gif_frames[1:],
        duration=duration_ms,
        loop=0,
        disposal=2,
    )

    output_sheet.parent.mkdir(parents=True, exist_ok=True)
    fixed_sheet = Image.new("RGBA", (canvas_width * len(frames), canvas_height), WHITE)
    for index, frame in enumerate(frames):
        fixed_sheet.alpha_composite(frame, (index * canvas_width, 0))
    fixed_sheet.save(output_sheet)


def _segment_cells_by_columns(sheet: Image.Image, expected: int) -> list[Image.Image]:
    """Split a horizontal strip by detecting white gaps between sprites.

    GPT image output often ignores exact cell boundaries. This finds the actual
    eight character blobs, preserving swords/hair that spill beyond the nominal
    grid columns.
    """
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

    # Merge tiny gaps caused by hair/sword separation inside one sprite.
    merged: list[tuple[int, int]] = []
    max_inner_gap = 8
    for group in groups:
        if not merged or group[0] - merged[-1][1] > max_inner_gap:
            merged.append(group)
        else:
            merged[-1] = (merged[-1][0], group[1])

    # Drop dust/noise and keep the expected left-to-right sprite groups.
    merged = [group for group in merged if group[1] - group[0] > 24]
    if len(merged) != expected:
        # Fallback: keep the widest expected groups in left-to-right order.
        merged = sorted(merged, key=lambda g: g[1] - g[0], reverse=True)[:expected]
        merged.sort(key=lambda g: g[0])

    cells: list[Image.Image] = []
    pad_x = 12
    pad_y = 16
    for left, right in merged:
        left = max(0, left - pad_x)
        right = min(sheet.width, right + pad_x)
        slice_img = sheet.crop((left, 0, right, sheet.height))
        bbox = _non_white_bbox(slice_img)
        if bbox is None:
            cells.append(slice_img)
            continue
        l, t, r, b = bbox
        t = max(0, t - pad_y)
        b = min(slice_img.height, b + pad_y)
        cells.append(slice_img.crop((0, t, slice_img.width, b)))

    return cells


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(description="Build fixed-anchor sprite preview GIFs")
    parser.add_argument("--source", type=Path, required=True)
    parser.add_argument("--output-gif", type=Path, required=True)
    parser.add_argument("--output-sheet", type=Path, required=True)
    parser.add_argument("--cols", type=int, default=8)
    parser.add_argument("--rows", type=int, default=1)
    parser.add_argument("--row", type=int, default=0)
    parser.add_argument("--sprite-height", type=int, default=112)
    parser.add_argument("--canvas-width", type=int, default=160)
    parser.add_argument("--canvas-height", type=int, default=160)
    parser.add_argument("--duration-ms", type=int, default=90)
    parser.add_argument(
        "--segment-columns",
        action="store_true",
        help="Detect sprite columns from white gaps instead of equal grid slicing",
    )
    parser.add_argument(
        "--preserve-scale",
        action="store_true",
        help="Do not resize individual frames; only anchor them on a fixed canvas",
    )
    parser.add_argument(
        "--frame-count",
        type=int,
        default=None,
        help="Only use the first N detected/sliced frames (for 9-grid loop-check sources, use 8 for playable previews)",
    )
    parser.add_argument(
        "--cell-top-inset",
        type=int,
        default=0,
        help="Crop this many pixels from the top of each equal-grid cell before trimming",
    )
    parser.add_argument(
        "--cell-bottom-inset",
        type=int,
        default=0,
        help="Crop this many pixels from the bottom of each equal-grid cell before trimming",
    )
    return parser.parse_args()


def main() -> int:
    args = parse_args()
    build_strip_preview(
        args.source,
        args.output_gif,
        args.output_sheet,
        cols=args.cols,
        rows=args.rows,
        row=args.row,
        sprite_height=args.sprite_height,
        canvas_width=args.canvas_width,
        canvas_height=args.canvas_height,
        duration_ms=args.duration_ms,
        segment_columns=args.segment_columns,
        preserve_scale=args.preserve_scale,
        frame_count=args.frame_count,
        cell_top_inset=args.cell_top_inset,
        cell_bottom_inset=args.cell_bottom_inset,
    )
    print(args.output_gif)
    print(args.output_sheet)
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
