from __future__ import annotations

import argparse
import hashlib
import json
from pathlib import Path

from PIL import Image


EXPECTED_SOURCE_SHA256 = "5BAD0580CDDD4D8E9FFA1AE4364F086775BFC8EBE6488AE794E5495078A967D3"
EXPECTED_SOURCE_SIZE = (1254, 1254)
RESIZED_WHOLE_CANVAS = (148, 148)
OUTPUT_SIZE = (160, 160)
PASTE_OFFSET = (6, 8)
EXPECTED_A8_BBOX = (52, 12, 108, 152)


def sha256_file(path: Path) -> str:
    return hashlib.sha256(path.read_bytes()).hexdigest().upper()


def rgba_sha256(image: Image.Image) -> str:
    return hashlib.sha256(image.convert("RGBA").tobytes()).hexdigest().upper()


def alpha_bbox(alpha: Image.Image, minimum: int) -> tuple[int, int, int, int] | None:
    mask = alpha.point(lambda value: 255 if value >= minimum else 0)
    return mask.getbbox()


def edge_nonzero_count(alpha: Image.Image) -> int:
    width, height = alpha.size
    count = sum(1 for x in range(width) if alpha.getpixel((x, 0)) or alpha.getpixel((x, height - 1)))
    count += sum(1 for y in range(1, height - 1) if alpha.getpixel((0, y)) or alpha.getpixel((width - 1, y)))
    return count


def main() -> int:
    parser = argparse.ArgumentParser(description="Uniformly normalize the approved AP patrol idle raw without background cleanup.")
    parser.add_argument("--source", required=True, type=Path)
    parser.add_argument("--output", required=True, type=Path)
    parser.add_argument("--report", required=True, type=Path)
    args = parser.parse_args()

    if args.output.exists() or args.report.exists():
        raise FileExistsError("Refusing to overwrite an existing output or report")

    source_sha_before = sha256_file(args.source)
    if source_sha_before != EXPECTED_SOURCE_SHA256:
        raise ValueError(f"Unexpected source SHA256: {source_sha_before}")

    source = Image.open(args.source)
    if source.mode != "RGBA" or source.size != EXPECTED_SOURCE_SIZE:
        raise ValueError(f"Expected RGBA {EXPECTED_SOURCE_SIZE}, got {source.mode} {source.size}")

    source_rgba_sha = rgba_sha256(source)
    resized = source.resize(RESIZED_WHOLE_CANVAS, Image.Resampling.LANCZOS)
    output = Image.new("RGBA", OUTPUT_SIZE, (0, 0, 0, 0))
    output.paste(resized, PASTE_OFFSET)

    alpha = output.getchannel("A")
    a1_bbox = alpha_bbox(alpha, 1)
    a8_bbox = alpha_bbox(alpha, 8)
    a16_bbox = alpha_bbox(alpha, 16)
    if a8_bbox != EXPECTED_A8_BBOX:
        raise ValueError(f"Unexpected A>=8 bbox: {a8_bbox}, expected {EXPECTED_A8_BBOX}")
    if edge_nonzero_count(alpha) != 0:
        raise ValueError("Nonzero alpha touches the output edge")

    source_sha_after_processing = sha256_file(args.source)
    if source_sha_after_processing != source_sha_before:
        raise RuntimeError("Source bytes changed during processing")

    args.output.parent.mkdir(parents=True, exist_ok=True)
    output.save(args.output, format="PNG")
    reloaded = Image.open(args.output).convert("RGBA")
    if reloaded.size != OUTPUT_SIZE or reloaded.tobytes() != output.tobytes():
        raise RuntimeError("Saved PNG RGBA readback differs from the in-memory output")

    alpha_histogram = alpha.histogram()
    report = {
        "schema_version": 1,
        "change_id": "luoyang-city-full-rollout-20261022ap",
        "status": "MECHANICAL_NORMALIZE_COMPLETE_NOT_RUNTIME_ADMISSION",
        "source": {
            "path": str(args.source),
            "sha256_before": source_sha_before,
            "sha256_after": sha256_file(args.source),
            "rgba_sha256": source_rgba_sha,
            "size_px": list(source.size),
            "mode": source.mode,
        },
        "mechanical_transform": {
            "whole_rgba_resampled": True,
            "resample_filter": "Pillow Image.Resampling.LANCZOS",
            "resized_whole_canvas_px": list(RESIZED_WHOLE_CANVAS),
            "output_canvas_px": list(OUTPUT_SIZE),
            "paste_offset_px": list(PASTE_OFFSET),
            "paste_used_mask": False,
            "alpha_threshold_or_erasure": False,
            "crop": False,
            "rotate": False,
            "recolor": False,
        },
        "output": {
            "path": str(args.output),
            "png_sha256": sha256_file(args.output),
            "png_bytes": args.output.stat().st_size,
            "rgba_sha256": rgba_sha256(reloaded),
            "size_px": list(reloaded.size),
            "mode": reloaded.mode,
            "a1_xyxy": list(a1_bbox) if a1_bbox else None,
            "a8_xyxy": list(a8_bbox) if a8_bbox else None,
            "a16_xyxy": list(a16_bbox) if a16_bbox else None,
            "alpha_1_through_7_pixels": sum(alpha_histogram[1:8]),
            "edge_nonzero_count": edge_nonzero_count(alpha),
        },
        "scope_limits": {
            "background_cleanup_performed": False,
            "animation_or_portrait_created": False,
            "runtime_field_or_import_verified": False,
        },
    }
    args.report.parent.mkdir(parents=True, exist_ok=True)
    args.report.write_text(json.dumps(report, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
