"""Build fixed-size transparent 4-frame strips from a keyed 4-frame source."""

from __future__ import annotations

import argparse
from pathlib import Path

from PIL import Image, ImageChops, ImageOps


def bbox(frame: Image.Image) -> tuple[int, int, int, int] | None:
    alpha = frame.getchannel("A")
    return alpha.getbbox()


def build(source: Path, output: Path, mirror: bool = False) -> None:
    sheet = Image.open(source).convert("RGBA")
    frame_width = sheet.width // 4
    frames: list[Image.Image] = []
    for index in range(4):
        frame = sheet.crop((index * frame_width, 0, (index + 1) * frame_width, sheet.height))
        if mirror:
            frame = ImageOps.mirror(frame)
        box = bbox(frame)
        if box is None:
            continue
        frame = frame.crop(box)
        scale = 120.0 / max(1, frame.height)
        frame = frame.resize((max(1, round(frame.width * scale)), 120), Image.Resampling.LANCZOS)
        canvas = Image.new("RGBA", (160, 160), (0, 0, 0, 0))
        x = (160 - frame.width) // 2
        canvas.alpha_composite(frame, (x, 32))
        frames.append(canvas)
    if len(frames) != 4:
        raise RuntimeError(f"expected 4 non-empty frames, got {len(frames)}")
    result = Image.new("RGBA", (640, 160), (0, 0, 0, 0))
    for index, frame in enumerate(frames):
        result.alpha_composite(frame, (index * 160, 0))
    output.parent.mkdir(parents=True, exist_ok=True)
    result.save(output)
    print(output)


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("source", type=Path)
    parser.add_argument("output", type=Path)
    parser.add_argument("--mirror", action="store_true")
    args = parser.parse_args()
    build(args.source, args.output, args.mirror)
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
