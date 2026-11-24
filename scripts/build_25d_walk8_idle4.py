"""Build the locked 160px canvas / 140px body-height 2.5D preview set."""

from __future__ import annotations

import argparse
from pathlib import Path

from PIL import Image, ImageOps


CANVAS_SIZE = 160
CHARACTER_HEIGHT = 140
SOURCE_FRAMES = 4
WALK_FRAMES = 8
IDLE_FRAMES = 4


def prepare_frame(frame: Image.Image) -> Image.Image:
    alpha = frame.getchannel("A")
    box = alpha.getbbox()
    if box is None:
        raise RuntimeError("empty sprite frame")
    frame = frame.crop(box)
    scale = CHARACTER_HEIGHT / max(1, frame.height)
    frame = frame.resize(
        (max(1, round(frame.width * scale)), CHARACTER_HEIGHT),
        Image.Resampling.LANCZOS,
    )
    canvas = Image.new("RGBA", (CANVAS_SIZE, CANVAS_SIZE), (0, 0, 0, 0))
    canvas.alpha_composite(frame, ((CANVAS_SIZE - frame.width) // 2, CANVAS_SIZE - CHARACTER_HEIGHT))
    return canvas


def build(source: Path, walk_output: Path, idle_output: Path, mirror: bool) -> None:
    sheet = Image.open(source).convert("RGBA")
    frame_width = sheet.width // SOURCE_FRAMES
    source_frames = []
    for index in range(SOURCE_FRAMES):
        frame = sheet.crop((index * frame_width, 0, (index + 1) * frame_width, sheet.height))
        if mirror:
            frame = ImageOps.mirror(frame)
        source_frames.append(prepare_frame(frame))

    # Keep each generated pose opaque and stable. Cross-fading two full-body
    # poses creates a ghosted foot and robe edge, which is worse than a short
    # held contact pose in a pixel-style RPG loop.
    walk = []
    for index, frame in enumerate(source_frames):
        walk.extend((frame, frame.copy()))

    # A walk frame must never leak into idle. Frame 1 is the locked neutral
    # pose for this preview set and is repeated to preserve the 4-frame contract.
    idle = [source_frames[0]] * IDLE_FRAMES

    for output, frames in ((walk_output, walk), (idle_output, idle)):
        strip = Image.new("RGBA", (CANVAS_SIZE * len(frames), CANVAS_SIZE), (0, 0, 0, 0))
        for index, frame in enumerate(frames):
            strip.alpha_composite(frame, (index * CANVAS_SIZE, 0))
        output.parent.mkdir(parents=True, exist_ok=True)
        strip.save(output)
        print(output)


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("source", type=Path)
    parser.add_argument("walk_output", type=Path)
    parser.add_argument("idle_output", type=Path)
    parser.add_argument("--mirror", action="store_true")
    args = parser.parse_args()
    build(args.source, args.walk_output, args.idle_output, args.mirror)
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
