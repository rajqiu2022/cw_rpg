"""Build three Godot 2x2 animation sheets from a 4-column x 3-tier VFX atlas."""

from __future__ import annotations

import argparse
from pathlib import Path

from PIL import Image


CELL_SIZE = 512
PADDING = 22


def _fit(cell: Image.Image) -> Image.Image:
    bbox = cell.getchannel("A").getbbox()
    if bbox is None:
        raise ValueError("VFX cell is empty after background removal")
    effect = cell.crop(bbox)
    available = CELL_SIZE - PADDING * 2
    scale = min(available / effect.width, available / effect.height)
    effect = effect.resize(
        (max(1, round(effect.width * scale)), max(1, round(effect.height * scale))),
        Image.Resampling.LANCZOS,
    )
    frame = Image.new("RGBA", (CELL_SIZE, CELL_SIZE), (0, 0, 0, 0))
    frame.alpha_composite(
        effect,
        ((CELL_SIZE - effect.width) // 2, (CELL_SIZE - effect.height) // 2),
    )
    return frame


def build(source: Path, output_dir: Path, prefix: str) -> list[Path]:
    atlas = Image.open(source).convert("RGBA")
    output_dir.mkdir(parents=True, exist_ok=True)
    outputs: list[Path] = []
    for tier in range(3):
        sheet = Image.new("RGBA", (CELL_SIZE * 2, CELL_SIZE * 2), (0, 0, 0, 0))
        top = round(tier * atlas.height / 3)
        bottom = round((tier + 1) * atlas.height / 3)
        for frame_index in range(4):
            left = round(frame_index * atlas.width / 4)
            right = round((frame_index + 1) * atlas.width / 4)
            frame = _fit(atlas.crop((left, top, right, bottom)))
            sheet.alpha_composite(
                frame,
                ((frame_index % 2) * CELL_SIZE, (frame_index // 2) * CELL_SIZE),
            )
        output = output_dir / f"{prefix}_tier{tier + 1}_4frame_v1.png"
        sheet.save(output)
        outputs.append(output)
    return outputs


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("source", type=Path)
    parser.add_argument("output_dir", type=Path)
    parser.add_argument("--prefix", required=True)
    args = parser.parse_args()
    print("\n".join(str(path) for path in build(args.source, args.output_dir, args.prefix)))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
