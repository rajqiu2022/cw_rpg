"""Create a stable four-frame idle strip from frame one of an anchored walk strip."""

from __future__ import annotations

import argparse
from pathlib import Path

from PIL import Image


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--source", type=Path, required=True)
    parser.add_argument("--output", type=Path, required=True)
    parser.add_argument("--frame-width", type=int, default=160)
    args = parser.parse_args()

    source = Image.open(args.source).convert("RGBA")
    frame = source.crop((0, 0, args.frame_width, source.height))
    output = Image.new("RGBA", (args.frame_width * 4, source.height))
    for index in range(4):
        output.alpha_composite(frame, (index * args.frame_width, 0))
    args.output.parent.mkdir(parents=True, exist_ok=True)
    output.save(args.output)
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
