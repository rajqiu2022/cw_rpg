"""Turn a four/eight-cell chroma-key NPC strip into a 160px Godot strip."""

from __future__ import annotations

import argparse
import math
from pathlib import Path

from PIL import Image


CANVAS = 160
BODY_HEIGHT = 140
BOTTOM_MARGIN = 8
MIN_SOURCE_BOTTOM_RATIO = 0.02


def _remove_green(image: Image.Image) -> Image.Image:
	image = image.convert("RGBA")
	pixels = image.load()
	for y in range(image.height):
		for x in range(image.width):
			r, g, b, _alpha = pixels[x, y]
			if g > 110 and g > r * 1.18 and g > b * 1.18:
				pixels[x, y] = (r, g, b, 0)
			elif g > max(r, b) + 12:
				# Neutralize the green fringe left by anti-aliased chroma edges.
				pixels[x, y] = (r, max(r, b), b, _alpha)
	return image


def _frame(
	cell: Image.Image,
	bottom_margin: int = BOTTOM_MARGIN,
	min_source_bottom_ratio: float = MIN_SOURCE_BOTTOM_RATIO,
) -> Image.Image:
	if bottom_margin < 0 or BODY_HEIGHT + bottom_margin > CANVAS:
		raise ValueError(
			f"bottom margin must be between 0 and {CANVAS - BODY_HEIGHT}, got {bottom_margin}"
		)
	cell = _remove_green(cell)
	bbox = cell.getbbox()
	if bbox is None:
		raise ValueError("empty NPC cell after chroma removal")
	min_source_bottom = max(4, math.ceil(cell.height * min_source_bottom_ratio))
	source_bottom_margin = cell.height - bbox[3]
	if source_bottom_margin < min_source_bottom:
		raise ValueError(
			"source NPC touches the cell bottom; refusing to hide a cropped source "
			f"with runtime padding (margin={source_bottom_margin}, required={min_source_bottom})"
		)
	sprite = cell.crop(bbox)
	scale = BODY_HEIGHT / sprite.height
	sprite = sprite.resize((max(1, round(sprite.width * scale)), BODY_HEIGHT), Image.Resampling.LANCZOS)
	frame = Image.new("RGBA", (CANVAS, CANVAS), (0, 0, 0, 0))
	frame.alpha_composite(
		sprite,
		((CANVAS - sprite.width) // 2, CANVAS - BODY_HEIGHT - bottom_margin),
	)
	return frame


def main() -> int:
	parser = argparse.ArgumentParser()
	parser.add_argument("--source", type=Path, required=True)
	parser.add_argument("--output", type=Path, required=True)
	parser.add_argument("--bottom-margin", type=int, default=BOTTOM_MARGIN)
	parser.add_argument("--columns", type=int, choices=(4, 8), default=4)
	parser.add_argument(
		"--min-source-bottom-ratio",
		type=float,
		default=MIN_SOURCE_BOTTOM_RATIO,
		help="Reject a source whose visible pixels are too close to the cell bottom.",
	)
	args = parser.parse_args()

	image = Image.open(args.source).convert("RGBA")
	frames: list[Image.Image] = []
	for index in range(args.columns):
		left = round(index * image.width / args.columns)
		right = round((index + 1) * image.width / args.columns)
		frames.append(
			_frame(
				image.crop((left, 0, right, image.height)),
				args.bottom_margin,
				args.min_source_bottom_ratio,
			)
		)
	strip = Image.new("RGBA", (CANVAS * args.columns, CANVAS), (0, 0, 0, 0))
	for index, frame in enumerate(frames):
		strip.alpha_composite(frame, (index * CANVAS, 0))
	args.output.parent.mkdir(parents=True, exist_ok=True)
	strip.save(args.output)
	return 0


if __name__ == "__main__":
	raise SystemExit(main())
