"""Remove an edge-connected neon-green chroma background from a sprite strip."""

from __future__ import annotations

import argparse
from collections import deque
from pathlib import Path

from PIL import Image


def is_green(pixel: tuple[int, int, int, int], tolerance: int) -> bool:
    r, g, b, a = pixel
    return a > 0 and g > 150 and g > r * 1.35 and g > b * 1.35 and g - max(r, b) >= tolerance


def remove_background(path: Path, tolerance: int) -> None:
    image = Image.open(path).convert("RGBA")
    pixels = image.load()
    width, height = image.size
    queue: deque[tuple[int, int]] = deque()
    seen: set[tuple[int, int]] = set()

    for x in range(width):
        for y in (0, height - 1):
            if is_green(pixels[x, y], tolerance):
                seen.add((x, y))
                queue.append((x, y))
    for y in range(height):
        for x in (0, width - 1):
            if is_green(pixels[x, y], tolerance) and (x, y) not in seen:
                seen.add((x, y))
                queue.append((x, y))

    while queue:
        x, y = queue.popleft()
        for nx, ny in ((x - 1, y), (x + 1, y), (x, y - 1), (x, y + 1)):
            if nx < 0 or ny < 0 or nx >= width or ny >= height or (nx, ny) in seen:
                continue
            if is_green(pixels[nx, ny], tolerance):
                seen.add((nx, ny))
                queue.append((nx, ny))

    for x, y in seen:
        r, g, b, _ = pixels[x, y]
        pixels[x, y] = (r, g, b, 0)
    path.parent.mkdir(parents=True, exist_ok=True)
    image.save(path)


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("files", nargs="+", type=Path)
    parser.add_argument("--tolerance", type=int, default=28)
    args = parser.parse_args()
    for path in args.files:
        remove_background(path, args.tolerance)
        print(path)
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
