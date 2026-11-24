"""Slice a fixed-grid image atlas into consistently anchored runtime assets."""

from __future__ import annotations

import argparse
from pathlib import Path

from PIL import Image


def _parse_size(value: str) -> tuple[int, int]:
    width, height = value.lower().split("x", 1)
    return int(width), int(height)


def _keep_largest_component(image: Image.Image) -> Image.Image:
    """Remove disconnected neighboring-cell leaks from character atlas cells."""
    rgba = image.convert("RGBA")
    alpha = rgba.getchannel("A")
    width, height = rgba.size
    visible = alpha.load()
    visited = bytearray(width * height)
    components: list[list[tuple[int, int]]] = []
    for y in range(height):
        for x in range(width):
            index = y * width + x
            if visited[index] or visible[x, y] <= 20:
                continue
            stack = [(x, y)]
            visited[index] = 1
            component: list[tuple[int, int]] = []
            while stack:
                px, py = stack.pop()
                component.append((px, py))
                for nx, ny in ((px - 1, py), (px + 1, py), (px, py - 1), (px, py + 1)):
                    if nx < 0 or ny < 0 or nx >= width or ny >= height:
                        continue
                    neighbor = ny * width + nx
                    if not visited[neighbor] and visible[nx, ny] > 20:
                        visited[neighbor] = 1
                        stack.append((nx, ny))
            components.append(component)
    if not components:
        return rgba
    keep = set(max(components, key=len))
    pixels = rgba.load()
    for y in range(height):
        for x in range(width):
            if visible[x, y] > 0 and (x, y) not in keep:
                r, g, b, _a = pixels[x, y]
                pixels[x, y] = (r, g, b, 0)
    return rgba


def _fit_to_canvas(
    image: Image.Image,
    canvas_size: tuple[int, int],
    padding: int,
    bottom: int,
    allow_upscale: bool,
    largest_component: bool,
) -> Image.Image:
    rgba = image.convert("RGBA")
    if largest_component:
        rgba = _keep_largest_component(rgba)
    bbox = rgba.getchannel("A").getbbox()
    if bbox is None:
        raise ValueError("atlas cell has no visible pixels")
    sprite = rgba.crop(bbox)
    canvas_width, canvas_height = canvas_size
    max_width = canvas_width - padding * 2
    max_height = canvas_height - padding - bottom
    scale = min(max_width / sprite.width, max_height / sprite.height)
    if not allow_upscale:
        scale = min(scale, 1.0)
    sprite = sprite.resize(
        (max(1, round(sprite.width * scale)), max(1, round(sprite.height * scale))),
        Image.Resampling.LANCZOS,
    )
    frame = Image.new("RGBA", canvas_size, (0, 0, 0, 0))
    x = (canvas_width - sprite.width) // 2
    y = canvas_height - bottom - sprite.height
    frame.alpha_composite(sprite, (x, y))
    return frame


def slice_atlas(
    source: Path,
    output_dir: Path,
    columns: int,
    rows: int,
    names: list[str],
    canvas_size: tuple[int, int],
    padding: int,
    bottom: int,
    allow_upscale: bool,
    largest_component: bool,
    overlap: int,
) -> list[Path]:
    atlas = Image.open(source).convert("RGBA")
    expected = columns * rows
    if len(names) != expected:
        raise ValueError(f"expected {expected} names, got {len(names)}")
    output_dir.mkdir(parents=True, exist_ok=True)
    outputs: list[Path] = []
    for row in range(rows):
        top = round(row * atlas.height / rows)
        lower = round((row + 1) * atlas.height / rows)
        for column in range(columns):
            left = round(column * atlas.width / columns)
            right = round((column + 1) * atlas.width / columns)
            index = row * columns + column
            expanded_left = max(0, left - overlap)
            expanded_top = max(0, top - overlap)
            expanded_right = min(atlas.width, right + overlap)
            expanded_lower = min(atlas.height, lower + overlap)
            frame = _fit_to_canvas(
                atlas.crop((expanded_left, expanded_top, expanded_right, expanded_lower)),
                canvas_size,
                padding,
                bottom,
                allow_upscale,
                largest_component,
            )
            output = output_dir / f"{names[index]}.png"
            frame.save(output)
            outputs.append(output)
    return outputs


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("source", type=Path)
    parser.add_argument("output_dir", type=Path)
    parser.add_argument("--columns", type=int, required=True)
    parser.add_argument("--rows", type=int, required=True)
    parser.add_argument("--names", required=True, help="Comma-separated row-major output names")
    parser.add_argument("--canvas", type=_parse_size, default=(512, 512))
    parser.add_argument("--padding", type=int, default=24)
    parser.add_argument("--bottom", type=int, default=24)
    parser.add_argument("--no-upscale", action="store_true")
    parser.add_argument("--largest-component", action="store_true")
    parser.add_argument("--overlap", type=int, default=0, help="Extra source pixels around each cell")
    args = parser.parse_args()
    outputs = slice_atlas(
        args.source,
        args.output_dir,
        args.columns,
        args.rows,
        [name.strip() for name in args.names.split(",") if name.strip()],
        args.canvas,
        args.padding,
        args.bottom,
        not args.no_upscale,
        args.largest_component,
        args.overlap,
    )
    print("\n".join(str(path) for path in outputs))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
