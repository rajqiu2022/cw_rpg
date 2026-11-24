"""Fail-closed uniform resize + transparent padding for approved static soldier sources.

This never repairs alpha, paints pixels, distorts proportions, or modifies the raw input.
It refuses output if all original A>0 pixels cannot fit after body-height normalization.
"""
import argparse
import hashlib
import json
from pathlib import Path

from PIL import Image


def parse_bbox(value: str) -> tuple[int, int, int, int]:
    parts = [int(item) for item in value.split(",")]
    if len(parts) != 4:
        raise argparse.ArgumentTypeError("bbox must be x0,y0,x1,y1 with PIL-exclusive x1/y1")
    x0, y0, x1, y1 = parts
    if x1 <= x0 or y1 <= y0:
        raise argparse.ArgumentTypeError("bbox must have positive width and height")
    return x0, y0, x1, y1


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--source", required=True, type=Path)
    parser.add_argument("--body-bbox", required=True, type=parse_bbox, help="approved body-only PIL-exclusive bbox")
    parser.add_argument("--target-size", type=int, default=160)
    parser.add_argument("--target-body-height", type=int, default=140)
    parser.add_argument("--target-foot-end-y", type=int, default=152, help="PIL-exclusive alpha foot end")
    parser.add_argument("--output", type=Path)
    parser.add_argument("--write", action="store_true", help="write only after every fit check passes")
    args = parser.parse_args()

    raw = args.source.read_bytes()
    source = Image.open(args.source).convert("RGBA")
    alpha = source.getchannel("A")
    full_bbox = alpha.getbbox()
    if full_bbox is None:
        raise SystemExit("source has no A>0 pixels")
    bx0, by0, bx1, by1 = args.body_bbox
    if not (0 <= bx0 < bx1 <= source.width and 0 <= by0 < by1 <= source.height):
        raise SystemExit("body bbox is outside source")

    body_height = by1 - by0
    scale = args.target_body_height / body_height
    fx0, fy0, fx1, fy1 = full_bbox
    crop = source.crop(full_bbox)
    resized_size = (max(1, round(crop.width * scale)), max(1, round(crop.height * scale)))
    body_left = round((bx0 - fx0) * scale)
    body_right = round((bx1 - fx0) * scale)
    body_bottom = round((by1 - fy0) * scale)
    body_center = (body_left + body_right) / 2.0
    paste_x = round(args.target_size / 2.0 - body_center)
    paste_y = args.target_foot_end_y - body_bottom
    transformed_full_bbox = [paste_x, paste_y, paste_x + resized_size[0], paste_y + resized_size[1]]
    fits = transformed_full_bbox[0] >= 0 and transformed_full_bbox[1] >= 0 and transformed_full_bbox[2] <= args.target_size and transformed_full_bbox[3] <= args.target_size

    report = {
        "kind": "STATIC_FULLBODY_UNIFORM_NORMALIZATION_CHECK",
        "source": str(args.source).replace("\\", "/"),
        "source_sha256": hashlib.sha256(raw).hexdigest(),
        "source_size": list(source.size),
        "source_a_gt_0_bbox_pil_exclusive": list(full_bbox),
        "approved_body_bbox_pil_exclusive": list(args.body_bbox),
        "target_size": [args.target_size, args.target_size],
        "target_body_height": args.target_body_height,
        "target_foot_end_y": args.target_foot_end_y,
        "uniform_scale": scale,
        "resized_full_alpha_crop_size": list(resized_size),
        "transformed_full_alpha_bbox": transformed_full_bbox,
        "all_a_gt_0_pixels_fit": fits,
        "alpha_repair": False,
        "nonuniform_scaling": False,
        "raw_modified": False,
        "wrote_output": False,
    }
    if args.write:
        if args.output is None:
            raise SystemExit("--write requires --output")
        if not fits:
            print(json.dumps(report, indent=2))
            raise SystemExit("refusing output: full A>0 subject does not fit without clipping")
        resized = crop.resize(resized_size, Image.Resampling.LANCZOS)
        canvas = Image.new("RGBA", (args.target_size, args.target_size), (0, 0, 0, 0))
        canvas.alpha_composite(resized, (paste_x, paste_y))
        args.output.parent.mkdir(parents=True, exist_ok=True)
        canvas.save(args.output, format="PNG")
        report["wrote_output"] = True
        report["output"] = str(args.output).replace("\\", "/")
        report["output_sha256"] = hashlib.sha256(args.output.read_bytes()).hexdigest()
    print(json.dumps(report, indent=2))
    return 0 if fits else 2


if __name__ == "__main__":
    raise SystemExit(main())
