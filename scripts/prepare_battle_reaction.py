"""Convert chroma-key battle reaction art into fixed-anchor transparent frames."""

from __future__ import annotations

import argparse
from pathlib import Path

from PIL import Image


def _remove_green_key(image: Image.Image) -> Image.Image:
    result = image.convert("RGBA")
    pixels = result.load()
    for y in range(result.height):
        for x in range(result.width):
            r, g, b, _a = pixels[x, y]
            if g >= 175 and r <= 115 and b <= 115 and g - max(r, b) >= 80:
                pixels[x, y] = (r, g, b, 0)
    return result


def _validate_safe_bbox(image: Image.Image, padding: int, bottom_inset: int, source: Path) -> None:
    bbox = image.getchannel("A").getbbox()
    if bbox is None:
        raise ValueError(f"no visible pixels after preparing: {source}")
    left, top, right, bottom = bbox
    if left < padding or top < padding or right > image.width - padding or bottom > image.height - bottom_inset:
        raise ValueError(
            f"prepared frame touches safety inset ({bbox}) for {source}; refusing cropped output"
        )


def prepare(
    source: Path,
    output: Path,
    canvas_width: int,
    canvas_height: int,
    padding: int,
    bottom: int,
) -> None:
    image = _remove_green_key(Image.open(source))
    bbox = image.getchannel("A").getbbox()
    if bbox is None:
        raise ValueError(f"no visible pixels after chroma key: {source}")
    cropped = image.crop(bbox)
    max_width = max(1, canvas_width - padding * 2)
    max_height = max(1, canvas_height - padding - bottom)
    # Fallen fighters are normally width-limited. Both limits preserve the
    # complete alpha silhouette rather than cropping head, feet, or weapon.
    scale = min(max_width / cropped.width, max_height / cropped.height)
    resized_width = max(1, round(cropped.width * scale))
    resized_height = max(1, round(cropped.height * scale))
    resized = cropped.resize(
        (resized_width, resized_height), Image.Resampling.LANCZOS
    )
    frame = Image.new("RGBA", (canvas_width, canvas_height), (0, 0, 0, 0))
    x = (canvas_width - resized.width) // 2
    y = canvas_height - bottom - resized.height
    frame.alpha_composite(resized, (x, y))
    _validate_safe_bbox(frame, padding, bottom, source)
    output.parent.mkdir(parents=True, exist_ok=True)
    frame.save(output)


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("source", type=Path)
    parser.add_argument("output", type=Path)
    parser.add_argument("--canvas-width", type=int, default=512)
    parser.add_argument("--canvas-height", type=int, default=384)
    parser.add_argument("--padding", type=int, default=20)
    parser.add_argument("--bottom", type=int, default=12)
    args = parser.parse_args()
    prepare(
        args.source,
        args.output,
        args.canvas_width,
        args.canvas_height,
        args.padding,
        args.bottom,
    )
    print(args.output)
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
