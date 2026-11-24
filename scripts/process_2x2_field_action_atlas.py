"""Convert a transparent 2x2 action atlas into a stable four-frame field strip."""

from __future__ import annotations

import argparse
from pathlib import Path

from PIL import Image


def _cell(sheet: Image.Image, index: int) -> Image.Image:
    column = index % 2
    row = index // 2
    left = round(column * sheet.width / 2)
    top = round(row * sheet.height / 2)
    right = round((column + 1) * sheet.width / 2)
    bottom = round((row + 1) * sheet.height / 2)
    return sheet.crop((left, top, right, bottom))


def build(source: Path, output: Path, preview: Path | None, canvas: int, padding: int) -> None:
    sheet = Image.open(source).convert("RGBA")
    frames = [_cell(sheet, index) for index in range(4)]
    bounds = [frame.getchannel("A").getbbox() for frame in frames]
    if any(bound is None for bound in bounds):
        raise ValueError("all four atlas cells must contain visible pixels")

    # Use one shared crop and scale for all frames. Per-frame fitting makes the
    # actor and training dummy visibly jump even when the source atlas is sound.
    left = min(bound[0] for bound in bounds if bound is not None)
    top = min(bound[1] for bound in bounds if bound is not None)
    right = max(bound[2] for bound in bounds if bound is not None)
    bottom = max(bound[3] for bound in bounds if bound is not None)
    left = max(0, left - padding)
    top = max(0, top - padding)
    right = min(frames[0].width, right + padding)
    bottom = min(frames[0].height, bottom + padding)
    crop_width = right - left
    crop_height = bottom - top
    target_extent = canvas - padding * 2
    scale = min(target_extent / crop_width, target_extent / crop_height)
    target_size = (max(1, round(crop_width * scale)), max(1, round(crop_height * scale)))

    runtime_frames: list[Image.Image] = []
    for frame in frames:
        cropped = frame.crop((left, top, right, bottom))
        resized = cropped.resize(target_size, Image.Resampling.LANCZOS)
        runtime = Image.new("RGBA", (canvas, canvas), (0, 0, 0, 0))
        x = (canvas - resized.width) // 2
        y = canvas - padding - resized.height
        runtime.alpha_composite(resized, (x, y))
        runtime_frames.append(runtime)

    strip = Image.new("RGBA", (canvas * 4, canvas), (0, 0, 0, 0))
    for index, frame in enumerate(runtime_frames):
        strip.alpha_composite(frame, (index * canvas, 0))
    output.parent.mkdir(parents=True, exist_ok=True)
    strip.save(output)

    if preview is not None:
        preview.parent.mkdir(parents=True, exist_ok=True)
        gif_frames: list[Image.Image] = []
        for frame in runtime_frames:
            checker = Image.new("RGBA", frame.size, (46, 52, 55, 255))
            checker.alpha_composite(frame)
            gif_frames.append(checker.convert("P", palette=Image.Palette.ADAPTIVE))
        gif_frames[0].save(
            preview,
            save_all=True,
            append_images=gif_frames[1:],
            duration=220,
            loop=0,
            disposal=2,
        )

    print(f"runtime={output} size={strip.width}x{strip.height}")
    if preview is not None:
        print(f"preview={preview}")


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("source", type=Path)
    parser.add_argument("output", type=Path)
    parser.add_argument("--preview", type=Path)
    parser.add_argument("--canvas", type=int, default=256)
    parser.add_argument("--padding", type=int, default=8)
    args = parser.parse_args()
    build(args.source, args.output, args.preview, args.canvas, args.padding)
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
