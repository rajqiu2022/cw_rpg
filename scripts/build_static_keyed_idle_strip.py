"""Build a stable 160px four-frame idle strip from one keyed full-body master."""

from __future__ import annotations

import argparse
from pathlib import Path

from PIL import Image


def remove_key(image: Image.Image) -> Image.Image:
    result = image.convert("RGBA")
    pixels = result.load()
    for y in range(result.height):
        for x in range(result.width):
            r, g, b, _a = pixels[x, y]
            if r > 150 and b > 120 and g < 100:
                pixels[x, y] = (r, g, b, 0)
    return result


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("source", type=Path)
    parser.add_argument("output", type=Path)
    args = parser.parse_args()

    source = remove_key(Image.open(args.source))
    bbox = source.getbbox()
    if bbox is None:
        raise RuntimeError("key removal left no visible character")
    body = source.crop(bbox)
    body = body.resize((round(body.width * 140 / body.height), 140), Image.Resampling.LANCZOS)
    strip = Image.new("RGBA", (640, 160), (0, 0, 0, 0))
    for index in range(4):
        # A tiny horizontal robe sway keeps the idle alive without a footstep.
        x = index * 160 + (160 - body.width) // 2 + (1 if index == 2 else 0)
        strip.alpha_composite(body, (x, 20))
    args.output.parent.mkdir(parents=True, exist_ok=True)
    strip.save(args.output)
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
