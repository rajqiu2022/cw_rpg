"""Normalize generated attack frames into a transparent fixed-anchor strip."""

from __future__ import annotations

import argparse
from pathlib import Path

from PIL import Image, ImageOps


def build(frames: list[Path], output_sheet: Path, output_gif: Path, *, canvas: int, height: int, bottom: int, duration: int, mirror: bool, output_frames: Path | None) -> None:
    normalized: list[Image.Image] = []
    for source in frames:
        image = Image.open(source).convert("RGBA")
        if mirror:
            image = ImageOps.mirror(image)
        alpha = image.getchannel("A")
        bbox = alpha.getbbox()
        if bbox is None:
            raise ValueError(f"empty alpha: {source}")
        cropped = image.crop(bbox)
        scale = height / cropped.height
        resized = cropped.resize((max(1, round(cropped.width * scale)), height), Image.Resampling.LANCZOS)
        frame = Image.new("RGBA", (canvas, canvas), (0, 0, 0, 0))
        x = (canvas - resized.width) // 2
        y = canvas - bottom - resized.height
        frame.alpha_composite(resized, (x, y))
        normalized.append(frame)

    output_sheet.parent.mkdir(parents=True, exist_ok=True)
    sheet = Image.new("RGBA", (canvas * len(normalized), canvas), (0, 0, 0, 0))
    for index, frame in enumerate(normalized):
        sheet.alpha_composite(frame, (index * canvas, 0))
    sheet.save(output_sheet)

    if output_frames is not None:
        output_frames.mkdir(parents=True, exist_ok=True)
        for index, frame in enumerate(normalized, start=1):
            frame.save(output_frames / f"frame_{index:02d}.png")

    output_gif.parent.mkdir(parents=True, exist_ok=True)
    gif_frames = [frame.convert("P", palette=Image.Palette.ADAPTIVE, colors=255) for frame in normalized]
    gif_frames[0].save(output_gif, save_all=True, append_images=gif_frames[1:], duration=duration, loop=0, disposal=2, transparency=0)


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("frames", nargs=3, type=Path)
    parser.add_argument("--output-sheet", required=True, type=Path)
    parser.add_argument("--output-gif", required=True, type=Path)
    parser.add_argument("--canvas", type=int, default=256)
    parser.add_argument("--height", type=int, default=196)
    parser.add_argument("--bottom", type=int, default=12)
    parser.add_argument("--duration", type=int, default=150)
    parser.add_argument("--mirror", action="store_true")
    parser.add_argument("--output-frames", type=Path, default=None)
    args = parser.parse_args()
    build(args.frames, args.output_sheet, args.output_gif, canvas=args.canvas, height=args.height, bottom=args.bottom, duration=args.duration, mirror=args.mirror, output_frames=args.output_frames)
    print(args.output_sheet)
    print(args.output_gif)
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
