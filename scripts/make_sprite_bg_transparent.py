from __future__ import annotations

import argparse
from collections import deque
from pathlib import Path

from PIL import Image


def is_bg(pixel: tuple[int, int, int, int], threshold: int) -> bool:
    r, g, b, a = pixel
    return a > 0 and r >= threshold and g >= threshold and b >= threshold


def connected_edge_mask(img: Image.Image, threshold: int) -> set[tuple[int, int]]:
    rgba = img.convert("RGBA")
    w, h = rgba.size
    pix = rgba.load()
    q: deque[tuple[int, int]] = deque()
    seen: set[tuple[int, int]] = set()

    for x in range(w):
        for y in (0, h - 1):
            if (x, y) not in seen and is_bg(pix[x, y], threshold):
                seen.add((x, y))
                q.append((x, y))
    for y in range(h):
        for x in (0, w - 1):
            if (x, y) not in seen and is_bg(pix[x, y], threshold):
                seen.add((x, y))
                q.append((x, y))

    while q:
        x, y = q.popleft()
        for nx, ny in ((x - 1, y), (x + 1, y), (x, y - 1), (x, y + 1)):
            if nx < 0 or ny < 0 or nx >= w or ny >= h or (nx, ny) in seen:
                continue
            if is_bg(pix[nx, ny], threshold):
                seen.add((nx, ny))
                q.append((nx, ny))
    return seen


def process(path: Path, threshold: int, soften: int, dry_run: bool) -> tuple[int, int]:
    img = Image.open(path).convert("RGBA")
    pix = img.load()
    mask = connected_edge_mask(img, threshold)
    w, h = img.size

    alpha_zero = set(mask)
    if soften > 0:
        for x, y in list(mask):
            for dx in range(-soften, soften + 1):
                for dy in range(-soften, soften + 1):
                    nx, ny = x + dx, y + dy
                    if nx < 0 or ny < 0 or nx >= w or ny >= h or (nx, ny) in alpha_zero:
                        continue
                    r, g, b, a = pix[nx, ny]
                    if r >= threshold - 12 and g >= threshold - 12 and b >= threshold - 12:
                        alpha_zero.add((nx, ny))

    if not dry_run:
        for x, y in alpha_zero:
            r, g, b, _a = pix[x, y]
            pix[x, y] = (r, g, b, 0)
        img.save(path)
    return len(mask), len(alpha_zero)


def main() -> int:
    parser = argparse.ArgumentParser(description="Remove edge-connected white background from sprite strips.")
    parser.add_argument("files", nargs="+", type=Path)
    parser.add_argument("--threshold", type=int, default=245)
    parser.add_argument("--soften", type=int, default=1)
    parser.add_argument("--dry-run", action="store_true")
    args = parser.parse_args()

    for file_path in args.files:
        mask_count, write_count = process(file_path, args.threshold, args.soften, args.dry_run)
        mode = "DRY" if args.dry_run else "WRITE"
        print(f"[{mode}] {file_path}: edge={mask_count} alpha={write_count}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
