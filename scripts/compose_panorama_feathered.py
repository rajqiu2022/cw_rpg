"""Compose native-height panorama panels with an overlap-only feather blend."""

from __future__ import annotations

import argparse
from pathlib import Path

from PIL import Image


def blend_pair(left: Image.Image, right: Image.Image, overlap: int) -> Image.Image:
    if left.height != right.height:
        raise ValueError("panel heights must match")
    if overlap <= 0 or overlap >= min(left.width, right.width):
        raise ValueError("overlap must be smaller than both panel widths")
    result = Image.new("RGBA", (left.width + right.width - overlap, left.height))
    result.alpha_composite(left.crop((0, 0, left.width - overlap, left.height)), (0, 0))
    left_tail = left.crop((left.width - overlap, 0, left.width, left.height))
    right_head = right.crop((0, 0, overlap, right.height))
    blend = Image.new("RGBA", (overlap, left.height))
    for x in range(overlap):
        alpha = round(255 * x / max(1, overlap - 1))
        mask = Image.new("L", (1, left.height), alpha)
        blend.alpha_composite(left_tail.crop((x, 0, x + 1, left.height)), (x, 0))
        blended_column = Image.composite(right_head.crop((x, 0, x + 1, right.height)), blend.crop((x, 0, x + 1, left.height)), mask)
        blend.paste(blended_column, (x, 0))
    result.alpha_composite(blend, (left.width - overlap, 0))
    result.alpha_composite(right.crop((overlap, 0, right.width, right.height)), (left.width, 0))
    return result


def blend_vertical(top: Image.Image, bottom: Image.Image, overlap: int) -> Image.Image:
    if top.width != bottom.width:
        raise ValueError("panel widths must match")
    if overlap <= 0 or overlap >= min(top.height, bottom.height):
        raise ValueError("overlap must be smaller than both panel heights")
    result = Image.new("RGBA", (top.width, top.height + bottom.height - overlap))
    result.alpha_composite(top.crop((0, 0, top.width, top.height - overlap)), (0, 0))
    top_tail = top.crop((0, top.height - overlap, top.width, top.height))
    bottom_head = bottom.crop((0, 0, bottom.width, overlap))
    mask = Image.new("L", (top.width, overlap))
    for y in range(overlap):
        alpha = round(255 * y / max(1, overlap - 1))
        mask.paste(alpha, (0, y, top.width, y + 1))
    blend = Image.composite(bottom_head, top_tail, mask)
    result.alpha_composite(blend, (0, top.height - overlap))
    result.alpha_composite(bottom.crop((0, overlap, bottom.width, bottom.height)), (0, top.height))
    return result


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--panels", nargs="+", required=True, type=Path)
    parser.add_argument("--overlap", required=True, type=int)
    parser.add_argument("--axis", choices=("horizontal", "vertical"), default="horizontal")
    parser.add_argument("--out", required=True, type=Path)
    args = parser.parse_args()
    images = [Image.open(path).convert("RGBA") for path in args.panels]
    panorama = images[0]
    for image in images[1:]:
        if args.axis == "vertical":
            panorama = blend_vertical(panorama, image, args.overlap)
        else:
            panorama = blend_pair(panorama, image, args.overlap)
    args.out.parent.mkdir(parents=True, exist_ok=True)
    panorama.save(args.out)
    print(f"Composed {args.out}: {panorama.width}x{panorama.height}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
