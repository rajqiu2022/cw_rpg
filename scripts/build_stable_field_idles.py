"""Build a field-variant root whose idle strips keep both feet planted.

Existing v6 idle strips were sampled from walk cycles. This tool selects one
reviewed planted pose per direction and repeats it across the four-frame idle
strip while preserving the authored eight-frame walk strips unchanged.
"""

from __future__ import annotations

import argparse
import shutil
from pathlib import Path

from PIL import Image


STYLES = ("sword", "dao", "staff", "palm", "hidden")
DIRECTIONS = ("down", "up", "left", "right")
PLANTED_FRAME = {"down": 0, "up": 0, "left": 2, "right": 2}
CELL = 160


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--source-root", type=Path, required=True)
    parser.add_argument("--output-root", type=Path, required=True)
    args = parser.parse_args()

    if args.output_root.exists():
        parser.error(f"output already exists: {args.output_root}")

    for style in STYLES:
        output_dir = args.output_root / style
        output_dir.mkdir(parents=True, exist_ok=True)
        for direction in DIRECTIONS:
            walk_name = f"lengguyun_{style}_walk_{direction}_25d_8f.png"
            shutil.copy2(args.source_root / style / walk_name, output_dir / walk_name)

            idle_name = f"lengguyun_{style}_idle_{direction}_25d_4f.png"
            source = Image.open(args.source_root / style / idle_name).convert("RGBA")
            index = PLANTED_FRAME[direction]
            planted = source.crop((index * CELL, 0, (index + 1) * CELL, CELL))
            strip = Image.new("RGBA", (CELL * 4, CELL), (0, 0, 0, 0))
            for frame_index in range(4):
                strip.alpha_composite(planted, (frame_index * CELL, 0))
            strip.save(output_dir / idle_name)
    print(args.output_root)
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
