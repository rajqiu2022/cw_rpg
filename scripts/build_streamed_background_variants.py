"""Build overlap-safe runtime chunks for one logical painted map.

The PC source may be a 2x AI-upscaled image while the mobile source stays at
logical resolution. Both variants therefore share gameplay coordinates and
navigation data; only draw_scale changes.
"""

from __future__ import annotations

import argparse
import json
from pathlib import Path

from PIL import Image


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser()
    parser.add_argument("--mobile", type=Path, required=True)
    parser.add_argument("--desktop", type=Path, required=True)
    parser.add_argument("--output", type=Path, required=True)
    parser.add_argument("--logical-width", type=int, required=True)
    parser.add_argument("--logical-height", type=int, required=True)
    parser.add_argument("--chunk-size", type=int, default=512)
    parser.add_argument("--overlap", type=int, default=12)
    return parser.parse_args()


def build_variant(
    source_path: Path,
    output_dir: Path,
    logical_size: tuple[int, int],
    chunk_size: int,
    overlap: int,
) -> list[dict[str, object]]:
    image = Image.open(source_path).convert("RGB")
    logical_w, logical_h = logical_size
    scale_x = image.width / logical_w
    scale_y = image.height / logical_h
    if abs(scale_x - scale_y) > 0.0001:
        raise ValueError(f"Non-uniform source scale: {source_path} {scale_x}x{scale_y}")
    scale = scale_x
    output_dir.mkdir(parents=True, exist_ok=True)
    entries: list[dict[str, object]] = []
    for y in range(0, logical_h, chunk_size):
        for x in range(0, logical_w, chunk_size):
            core_w = min(chunk_size, logical_w - x)
            core_h = min(chunk_size, logical_h - y)
            left = max(0, x - overlap)
            top = max(0, y - overlap)
            right = min(logical_w, x + core_w + overlap)
            bottom = min(logical_h, y + core_h + overlap)
            source_box = tuple(round(value * scale) for value in (left, top, right, bottom))
            tile = image.crop(source_box)
            filename = f"tile_{x // chunk_size:02d}_{y // chunk_size:02d}.png"
            tile.save(output_dir / filename, optimize=True, compress_level=6)
            entries.append(
                {
                    "file": filename,
                    "logical_rect": [x, y, core_w, core_h],
                    "draw_position": [left, top],
                    "draw_scale": 1.0 / scale,
                    "source_size": list(tile.size),
                }
            )
    return entries


def main() -> None:
    args = parse_args()
    logical_size = (args.logical_width, args.logical_height)
    manifest = {
        "schema_version": 1,
        "logical_size": list(logical_size),
        "chunk_size": args.chunk_size,
        "overlap": args.overlap,
        "mobile": build_variant(args.mobile, args.output / "mobile", logical_size, args.chunk_size, args.overlap),
        "desktop": build_variant(args.desktop, args.output / "desktop", logical_size, args.chunk_size, args.overlap),
    }
    (args.output / "manifest.json").write_text(json.dumps(manifest, ensure_ascii=False, indent=2), encoding="utf-8")
    print(json.dumps({key: len(manifest[key]) for key in ("mobile", "desktop")}))


if __name__ == "__main__":
    main()
