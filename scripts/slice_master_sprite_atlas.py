"""Slice a fixed 4x8 generated walk atlas into transparent, anchored strips."""

from __future__ import annotations

import argparse
from collections import deque
from pathlib import Path

from PIL import Image



ROWS = ("down", "up", "right", "left")


def _split_by_local_valleys(row: Image.Image, expected: int = 8) -> list[Image.Image]:
    """Find the quietest cut near each nominal 128px cell boundary."""
    row = row.convert("RGBA")
    pixels = row.load()
    counts = [sum(1 for y in range(row.height) if min(pixels[x, y][:3]) < 240) for x in range(row.width)]
    boundaries = [0]
    nominal = row.width // expected
    for index in range(1, expected):
        center = index * nominal
        left, right = max(boundaries[-1] + 40, center - 28), min(row.width - 40, center + 28)
        boundary = min(range(left, right + 1), key=lambda x: counts[x])
        boundaries.append(boundary)
    boundaries.append(row.width)
    return [row.crop((boundaries[i], 0, boundaries[i + 1], row.height)) for i in range(expected)]


def _remove_edge_white(image: Image.Image, threshold: int = 245) -> Image.Image:
    image = image.convert("RGBA")
    pixels = image.load()
    width, height = image.size
    queue: deque[tuple[int, int]] = deque()
    seen: set[tuple[int, int]] = set()

    def enqueue(x: int, y: int) -> None:
        if (x, y) not in seen and all(channel >= threshold for channel in pixels[x, y][:3]):
            seen.add((x, y))
            queue.append((x, y))

    for x in range(width):
        enqueue(x, 0)
        enqueue(x, height - 1)
    for y in range(height):
        enqueue(0, y)
        enqueue(width - 1, y)

    while queue:
        x, y = queue.popleft()
        for nx, ny in ((x - 1, y), (x + 1, y), (x, y - 1), (x, y + 1)):
            if 0 <= nx < width and 0 <= ny < height:
                enqueue(nx, ny)

    for x, y in seen:
        r, g, b, _a = pixels[x, y]
        pixels[x, y] = (r, g, b, 0)
    return image


def _anchored_frame(cell: Image.Image, canvas_size: int, sprite_height: int, bottom_margin: int) -> Image.Image:
    cell = _remove_edge_white(cell)
    # Generated atlases occasionally leave tiny ink flecks in otherwise empty cells.
    # Remove disconnected foreground components smaller than a visible sprite detail.
    pixels = cell.load()
    width, height = cell.size
    visited: set[tuple[int, int]] = set()
    components: list[list[tuple[int, int]]] = []
    for start_y in range(height):
        for start_x in range(width):
            if (start_x, start_y) in visited or pixels[start_x, start_y][3] == 0:
                continue
            component: list[tuple[int, int]] = []
            queue: deque[tuple[int, int]] = deque([(start_x, start_y)])
            visited.add((start_x, start_y))
            while queue:
                x, y = queue.popleft()
                component.append((x, y))
                for nx, ny in ((x - 1, y), (x + 1, y), (x, y - 1), (x, y + 1)):
                    if 0 <= nx < width and 0 <= ny < height and (nx, ny) not in visited and pixels[nx, ny][3] > 0:
                        visited.add((nx, ny))
                        queue.append((nx, ny))
            components.append(component)
    if components:
        main_component = max(components, key=len)
        keep = set(main_component)
        for component in components:
            if component is main_component:
                continue
            for x, y in component:
                r, g, b, _a = pixels[x, y]
                pixels[x, y] = (r, g, b, 0)
    # The source contract reserves the bottom 16 px of every cell as whitespace.
    for y in range(height - 16, height):
        for x in range(width):
            r, g, b, _a = pixels[x, y]
            pixels[x, y] = (r, g, b, 0)
    bbox = cell.getbbox()
    if bbox is None:
        return Image.new("RGBA", (canvas_size, canvas_size))
    sprite = cell.crop(bbox)
    scale = sprite_height / sprite.height
    sprite = sprite.resize((round(sprite.width * scale), sprite_height), Image.Resampling.LANCZOS)
    frame = Image.new("RGBA", (canvas_size, canvas_size))
    frame.alpha_composite(sprite, ((canvas_size - sprite.width) // 2, canvas_size - bottom_margin - sprite.height))
    return frame


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--source", type=Path, required=True)
    parser.add_argument("--output-dir", type=Path, required=True)
    parser.add_argument("--canvas", type=int, default=160)
    parser.add_argument("--sprite-height", type=int, default=112)
    parser.add_argument("--bottom-margin", type=int, default=10)
    parser.add_argument("--duration-ms", type=int, default=120)
    args = parser.parse_args()

    atlas = Image.open(args.source).convert("RGBA")
    if atlas.size != (1024, 1024):
        raise ValueError(f"Expected 1024x1024 atlas, got {atlas.size}")
    args.output_dir.mkdir(parents=True, exist_ok=True)
    cell_height = 256

    for row_index, direction in enumerate(ROWS):
        frames = []
        # AI output keeps the row order but slightly shifts individual sprite
        # centers. Detect the real white gaps instead of forcing 128px cells.
        row_image = atlas.crop((0, row_index * cell_height, atlas.width, (row_index + 1) * cell_height))
        cells = _split_by_local_valleys(row_image)
        for cell in cells:
            frames.append(_anchored_frame(cell, args.canvas, args.sprite_height, args.bottom_margin))

        strip = Image.new("RGBA", (args.canvas * 8, args.canvas))
        for index, frame in enumerate(frames):
            strip.alpha_composite(frame, (index * args.canvas, 0))
        strip.save(args.output_dir / f"lengguyun_walk_{direction}_8f.png")

        preview = Image.new("RGBA", (args.canvas * 8, args.canvas), "white")
        for index, frame in enumerate(frames):
            preview.alpha_composite(frame, (index * args.canvas, 0))
        preview.save(args.output_dir / f"lengguyun_walk_{direction}_8f_preview.png")
        palette_frames = [frame.convert("P", palette=Image.Palette.ADAPTIVE) for frame in frames]
        palette_frames[0].save(args.output_dir / f"lengguyun_walk_{direction}_8f.gif", save_all=True, append_images=palette_frames[1:], duration=args.duration_ms, loop=0, disposal=2)

    return 0


if __name__ == "__main__":
    raise SystemExit(main())
