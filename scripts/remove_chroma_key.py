"""Remove the project's flat magenta asset background and write RGBA PNG.

The image prompts reserve #FF00FF exclusively for the background, so this
processor can also decontaminate anti-aliased magenta edge pixels without
removing legitimate artwork colours.
"""

from __future__ import annotations

import argparse
from pathlib import Path
from statistics import median

from PIL import Image, ImageFilter


KEY = (255, 0, 255)


def _sample_border_key(image: Image.Image) -> tuple[int, int, int]:
    pixels = image.convert("RGB").load()
    width, height = image.size
    samples: list[tuple[int, int, int]] = []
    band = max(1, min(width, height, 6))
    step = max(1, min(width, height) // 256)
    for x in range(0, width, step):
        for offset in range(band):
            samples.extend((pixels[x, offset], pixels[x, height - 1 - offset]))
    for y in range(0, height, step):
        for offset in range(band):
            samples.extend((pixels[offset, y], pixels[width - 1 - offset, y]))
    return tuple(round(median(pixel[channel] for pixel in samples)) for channel in range(3))


def _parse_hex_color(value: str) -> tuple[int, int, int]:
    text = value.strip().lstrip("#")
    if len(text) != 6:
        raise ValueError("key colour must be a six-digit RGB hex value")
    return tuple(int(text[index:index + 2], 16) for index in (0, 2, 4))


def remove_magenta(
    image: Image.Image,
    tolerance: int = 52,
    key: tuple[int, int, int] = KEY,
) -> Image.Image:
    rgba = image.convert("RGBA")
    pixels = rgba.load()
    for y in range(rgba.height):
        for x in range(rgba.width):
            red, green, blue, source_alpha = pixels[x, y]
            distance = max(abs(red - key[0]), abs(green - key[1]), abs(blue - key[2]))
            magenta_dominance = min(red, blue) - green
            if distance <= tolerance:
                pixels[x, y] = (0, 0, 0, 0)
                continue
            if magenta_dominance > 24 and red > 72 and blue > 72:
                # Convert chroma dominance into a soft edge alpha, then cap
                # red/blue so transparent fringes do not retain a pink halo.
                alpha = max(0, min(source_alpha, round(255 - magenta_dominance * 1.7)))
                neutral_cap = max(green, 24)
                pixels[x, y] = (
                    min(red, neutral_cap),
                    green,
                    min(blue, neutral_cap),
                    alpha,
                )
    return rgba


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("source", type=Path, nargs="?")
    parser.add_argument("output", type=Path, nargs="?")
    parser.add_argument("--input", dest="input_path", type=Path)
    parser.add_argument("--out", dest="output_path", type=Path)
    parser.add_argument("--key-color", default="#FF00FF")
    parser.add_argument("--auto-key", choices=("none", "border"), default="none")
    parser.add_argument("--tolerance", type=int, default=52)
    parser.add_argument("--soft-matte", action="store_true")
    parser.add_argument("--spill-cleanup", "--despill", action="store_true")
    parser.add_argument("--edge-contract", type=int, default=0)
    parser.add_argument("--edge-feather", type=float, default=0.0)
    parser.add_argument("--force", action="store_true")
    args = parser.parse_args()
    if not 0 <= args.tolerance <= 255:
        parser.error("--tolerance must be between 0 and 255")
    source = args.input_path or args.source
    output_path = args.output_path or args.output
    if source is None or output_path is None:
        parser.error("provide source/output positionally or with --input/--out")
    if output_path.exists() and not args.force:
        parser.error(f"output already exists: {output_path} (use --force to overwrite)")
    source_image = Image.open(source)
    key = _sample_border_key(source_image) if args.auto_key == "border" else _parse_hex_color(args.key_color)
    output = remove_magenta(source_image, args.tolerance, key)
    if args.edge_contract:
        alpha = output.getchannel("A")
        for _ in range(args.edge_contract):
            alpha = alpha.filter(ImageFilter.MinFilter(3))
        output.putalpha(alpha)
    if args.edge_feather:
        output.putalpha(output.getchannel("A").filter(ImageFilter.GaussianBlur(args.edge_feather)))
    output_path.parent.mkdir(parents=True, exist_ok=True)
    output.save(output_path)
    alpha = output.getchannel("A")
    transparent = alpha.histogram()[0]
    print(
        f"Wrote {output_path} using key #{key[0]:02X}{key[1]:02X}{key[2]:02X} "
        f"({transparent}/{output.width * output.height} transparent pixels)"
    )
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
