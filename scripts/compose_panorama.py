"""Compose adjacent PNG panels without scaling or blending either source."""

from __future__ import annotations

import argparse
from pathlib import Path

from PIL import Image


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--left", type=Path, required=True)
    parser.add_argument("--right", type=Path, required=True)
    parser.add_argument("--out", type=Path, required=True)
    return parser.parse_args()


def main() -> None:
    args = parse_args()
    with Image.open(args.left) as left_source, Image.open(args.right) as right_source:
        left = left_source.convert("RGBA")
        right = right_source.convert("RGBA")
        if left.height != right.height:
            raise ValueError(
                "Panels must have the same native height: "
                f"left={left.size}, right={right.size}"
            )

        panorama = Image.new("RGBA", (left.width + right.width, left.height))
        panorama.alpha_composite(left, (0, 0))
        panorama.alpha_composite(right, (left.width, 0))

    args.out.parent.mkdir(parents=True, exist_ok=True)
    panorama.save(args.out)
    print(f"Composed {args.out}: {panorama.width}x{panorama.height}")


if __name__ == "__main__":
    main()
