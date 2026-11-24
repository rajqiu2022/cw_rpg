"""Remove disconnected alpha specks while preserving the main RGBA subject."""

from __future__ import annotations

import argparse
from collections import deque
from pathlib import Path

from PIL import Image


def clean(source: Path, output: Path, alpha_threshold: int = 8) -> None:
    image = Image.open(source).convert("RGBA")
    pixels = image.load()
    width, height = image.size
    seen: set[tuple[int, int]] = set()
    components: list[list[tuple[int, int]]] = []

    for y in range(height):
        for x in range(width):
            if (x, y) in seen or pixels[x, y][3] <= alpha_threshold:
                continue
            queue = deque([(x, y)])
            seen.add((x, y))
            component: list[tuple[int, int]] = []
            while queue:
                cx, cy = queue.popleft()
                component.append((cx, cy))
                for nx, ny in ((cx - 1, cy), (cx + 1, cy), (cx, cy - 1), (cx, cy + 1)):
                    if not (0 <= nx < width and 0 <= ny < height):
                        continue
                    if (nx, ny) in seen or pixels[nx, ny][3] <= alpha_threshold:
                        continue
                    seen.add((nx, ny))
                    queue.append((nx, ny))
            components.append(component)

    if not components:
        raise RuntimeError(f"no visible alpha component found in {source}")
    keep = set(max(components, key=len))
    for y in range(height):
        for x in range(width):
            if pixels[x, y][3] > 0 and (x, y) not in keep:
                pixels[x, y] = (0, 0, 0, 0)
    output.parent.mkdir(parents=True, exist_ok=True)
    image.save(output)


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("source", type=Path)
    parser.add_argument("output", type=Path)
    args = parser.parse_args()
    clean(args.source, args.output)


if __name__ == "__main__":
    main()
