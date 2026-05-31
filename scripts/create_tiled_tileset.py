"""Create a Tiled image collection tileset from module PNG files.

The output is a .tsx file that Tiled can add as an external tileset. Each PNG
becomes one tile with useful custom properties (`id`, `category`, `z_index`).

Usage:
    python scripts/create_tiled_tileset.py --out maps/tiled/tilesets/scene_elements.tsx
    python scripts/create_tiled_tileset.py game/art/modules/ground game/art/modules/prop --out maps/tiled/tilesets/linxi_props.tsx
"""

from __future__ import annotations

import argparse
import os
import struct
import xml.etree.ElementTree as ET
from pathlib import Path
from typing import Iterable

PROJECT_ROOT = Path(__file__).resolve().parent.parent
DEFAULT_ROOTS = [
    PROJECT_ROOT / "game" / "art" / "modules" / "ground",
    PROJECT_ROOT / "game" / "art" / "modules" / "building",
    PROJECT_ROOT / "game" / "art" / "modules" / "veg",
    PROJECT_ROOT / "game" / "art" / "modules" / "prop",
]

CATEGORY_Z = {
    "ground": 0,
    "building": 10,
    "prop": 12,
    "veg": 18,
    "foreground": 30,
}


def _png_size(path: Path) -> tuple[int, int]:
    with path.open("rb") as f:
        header = f.read(24)
    if len(header) < 24 or header[:8] != b"\x89PNG\r\n\x1a\n" or header[12:16] != b"IHDR":
        raise ValueError(f"Not a PNG file: {path}")
    width, height = struct.unpack(">II", header[16:24])
    return int(width), int(height)


def _iter_pngs(roots: Iterable[Path], pattern: str) -> list[Path]:
    files: list[Path] = []
    for root in roots:
        if root.is_file() and root.suffix.lower() == ".png":
            files.append(root)
        elif root.exists():
            files.extend(root.rglob(pattern))
    return sorted({p.resolve() for p in files}, key=lambda p: p.as_posix().lower())


def _category_for(path: Path) -> str:
    parts = [p.lower() for p in path.parts]
    for name in ("ground", "building", "veg", "prop", "foreground"):
        if name in parts:
            return name
    stem = path.stem.lower()
    if stem.startswith("road_"):
        return "ground"
    if stem.startswith("build_"):
        return "building"
    if stem.startswith("veg_"):
        return "veg"
    if stem.startswith("prop_"):
        return "prop"
    return "prop"


def _relative_source(image_path: Path, tileset_path: Path) -> str:
    return image_path.resolve().relative_to(tileset_path.resolve().parent).as_posix()


def _safe_relative_source(image_path: Path, tileset_path: Path) -> str:
    try:
        return os.path.relpath(image_path.resolve(), tileset_path.resolve().parent).replace("\\", "/")
    except ValueError:
        return image_path.resolve().as_posix()


def create_tileset(roots: list[Path], out_path: Path, name: str, pattern: str) -> int:
    images = _iter_pngs(roots, pattern)
    if not images:
        roots_text = ", ".join(str(p) for p in roots)
        raise SystemExit(f"No PNG files found under: {roots_text}")

    sizes = {path: _png_size(path) for path in images}
    max_w = max(w for w, _h in sizes.values())
    max_h = max(h for _w, h in sizes.values())

    tileset = ET.Element(
        "tileset",
        {
            "version": "1.10",
            "tiledversion": "1.11.0",
            "name": name,
            "tilewidth": str(max_w),
            "tileheight": str(max_h),
            "tilecount": str(len(images)),
            "columns": "0",
        },
    )
    ET.SubElement(tileset, "grid", {"orientation": "orthogonal", "width": "1", "height": "1"})

    for tile_id, image_path in enumerate(images):
        width, height = sizes[image_path]
        category = _category_for(image_path)
        tile = ET.SubElement(tileset, "tile", {"id": str(tile_id)})
        props = ET.SubElement(tile, "properties")
        ET.SubElement(props, "property", {"name": "id", "type": "string", "value": image_path.stem})
        ET.SubElement(props, "property", {"name": "category", "type": "string", "value": category})
        ET.SubElement(props, "property", {"name": "z_index", "type": "int", "value": str(CATEGORY_Z.get(category, 12))})
        ET.SubElement(
            tile,
            "image",
            {
                "width": str(width),
                "height": str(height),
                "source": _safe_relative_source(image_path, out_path),
            },
        )

    ET.indent(tileset, space="  ")
    out_path.parent.mkdir(parents=True, exist_ok=True)
    ET.ElementTree(tileset).write(out_path, encoding="UTF-8", xml_declaration=True)
    return len(images)


def main() -> None:
    parser = argparse.ArgumentParser(description="Create a Tiled image collection .tsx from PNG modules")
    parser.add_argument("roots", nargs="*", type=Path, help="PNG files or folders to include; defaults to game/art/modules/*")
    parser.add_argument("--out", type=Path, default=PROJECT_ROOT / "maps" / "tiled" / "tilesets" / "scene_elements.tsx")
    parser.add_argument("--name", default="scene_elements")
    parser.add_argument("--glob", default="*.png", help="PNG filename glob used under directory roots")
    args = parser.parse_args()

    roots = [p if p.is_absolute() else PROJECT_ROOT / p for p in args.roots] if args.roots else DEFAULT_ROOTS
    out_path = args.out if args.out.is_absolute() else PROJECT_ROOT / args.out
    count = create_tileset(roots, out_path, args.name, args.glob)
    print(f"[tiled] wrote {out_path} ({count} tiles)")


if __name__ == "__main__":
    main()
