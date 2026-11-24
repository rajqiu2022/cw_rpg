#!/usr/bin/env python3
"""Create the one authorized AH transparent-padding derivative.

This tool is deliberately narrow: it verifies the frozen AG input, copies the
entire decoded RGBA image onto a larger transparent canvas with Image.paste
and no mask, verifies the saved readback, and writes provenance metadata.  It
never crops, resizes, thresholds, composites, or edits source pixels.
"""

from __future__ import annotations

import argparse
import hashlib
import json
import os
from pathlib import Path
from typing import Any

from PIL import Image


def sha256_bytes(data: bytes) -> str:
    return hashlib.sha256(data).hexdigest().upper()


def sha256_file(path: Path) -> str:
    return sha256_bytes(path.read_bytes())


def require(condition: bool, message: str) -> None:
    if not condition:
        raise RuntimeError(message)


def alpha_bbox(alpha: Image.Image, threshold: int) -> list[int]:
    if threshold == 1:
        bbox = alpha.getbbox()
    else:
        bbox = alpha.point(lambda value: 255 if value >= threshold else 0).getbbox()
    require(bbox is not None, f"empty alpha at threshold {threshold}")
    return list(bbox)


def alpha_count(alpha: Image.Image, threshold: int) -> int:
    return sum(1 for value in alpha.getdata() if value >= threshold)


def load_json(path: Path) -> dict[str, Any]:
    value = json.loads(path.read_text(encoding="utf-8"))
    require(isinstance(value, dict), f"expected JSON object: {path}")
    return value


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument(
        "--spec",
        type=Path,
        default=Path(__file__).with_suffix(".spec.json"),
        help="AH source-binding spec",
    )
    parser.add_argument(
        "--repo-root",
        type=Path,
        default=Path(__file__).resolve().parents[3],
        help="repository root; defaults to the script's repository",
    )
    args = parser.parse_args()

    repo_root = args.repo_root.resolve()
    spec_path = args.spec.resolve()
    spec = load_json(spec_path)
    source_cfg = spec["source"]
    output_cfg = spec["output"]
    expected = spec["expected"]

    source_path = repo_root / source_cfg["path"]
    source_meta_path = repo_root / source_cfg["metadata_path"]
    output_path = repo_root / output_cfg["path"]
    output_meta_path = repo_root / output_cfg["metadata_path"]
    tmp_output_path = output_path.with_name(output_path.name + ".tmp")
    tmp_meta_path = output_meta_path.with_name(output_meta_path.name + ".tmp")

    for path in (output_path, output_meta_path, tmp_output_path, tmp_meta_path):
        require(not path.exists(), f"refuse overwrite or stale temporary file: {path}")

    source_png_before = source_path.read_bytes()
    source_stat_before = source_path.stat()
    require(sha256_bytes(source_png_before) == source_cfg["png_sha256"], "source PNG SHA mismatch")
    require(len(source_png_before) == source_cfg["png_bytes"], "source PNG byte count mismatch")
    require(sha256_file(source_meta_path) == source_cfg["metadata_sha256"], "source metadata SHA mismatch")

    with Image.open(source_path) as opened:
        require(opened.mode == source_cfg["mode"], f"source mode mismatch: {opened.mode}")
        require(list(opened.size) == source_cfg["canvas_px"], f"source size mismatch: {opened.size}")
        source_rgba = opened.copy()

    source_rgba_bytes = source_rgba.tobytes()
    require(sha256_bytes(source_rgba_bytes) == source_cfg["rgba8_sha256"], "source RGBA SHA mismatch")
    require(alpha_bbox(source_rgba.getchannel("A"), 1) == source_cfg["a1_bbox_exclusive"], "source A1 bbox mismatch")
    require(alpha_bbox(source_rgba.getchannel("A"), 16) == source_cfg["a16_bbox_exclusive"], "source A16 bbox mismatch")

    output_size = tuple(output_cfg["canvas_px"])
    offset = tuple(output_cfg["paste_offset_px"])
    require(output_size == (1907, 1567), "this tool is authorized only for the frozen 1907x1567 canvas")
    require(offset == (382, 148), "this tool is authorized only for the frozen 382,148 offset")

    padded = Image.new("RGBA", output_size, (0, 0, 0, 0))
    # No mask is intentional: this copies every RGBA byte, including RGB under A=0.
    padded.paste(source_rgba, offset)
    expected_rgba_bytes = padded.tobytes()

    output_path.parent.mkdir(parents=True, exist_ok=True)
    padded.save(tmp_output_path, format="PNG", optimize=False, compress_level=9)

    with Image.open(tmp_output_path) as opened_output:
        require(opened_output.mode == "RGBA", f"output mode mismatch: {opened_output.mode}")
        require(opened_output.size == output_size, f"output size mismatch: {opened_output.size}")
        readback = opened_output.copy()

    require(readback.tobytes() == expected_rgba_bytes, "saved PNG full RGBA readback differs from expected canvas")
    crop_box = tuple(output_cfg["source_crop_exclusive"])
    require(readback.crop(crop_box).tobytes() == source_rgba_bytes, "embedded source crop is not full RGBA byte-exact")

    outside = readback.copy()
    outside.paste((0, 0, 0, 0), crop_box)
    require(not any(outside.tobytes()), "pixels outside source crop are not all RGBA zero")

    output_alpha = readback.getchannel("A")
    actual_a1 = alpha_bbox(output_alpha, 1)
    actual_a16 = alpha_bbox(output_alpha, 16)
    require(actual_a1 == expected["a1_bbox_exclusive"], f"output A1 bbox mismatch: {actual_a1}")
    require(actual_a16 == expected["a16_bbox_exclusive"], f"output A16 bbox mismatch: {actual_a16}")
    require(alpha_count(output_alpha, 1) == source_cfg["a1_pixel_count"], "A1 pixel count changed")
    require(alpha_count(output_alpha, 16) == source_cfg["a16_pixel_count"], "A16 pixel count changed")

    left, top, right, bottom = actual_a1
    width, height = output_size
    margins_px = [left, top, width - right, height - bottom]
    margins_fraction = [left / width, top / height, (width - right) / width, (height - bottom) / height]
    occupancy_width = (right - left) / width
    require(margins_px == expected["a1_margin_px_left_top_right_bottom"], "A1 margin pixel values changed")
    require(all(value >= 0.10 for value in margins_fraction), "A1 true-transparent margin below 10 percent")
    require(0.50 <= occupancy_width <= 0.60, "A1 width occupancy outside 50-60 percent")

    source_png_after = source_path.read_bytes()
    source_stat_after = source_path.stat()
    require(source_png_after == source_png_before, "source PNG bytes changed during processing")
    require(source_stat_after.st_size == source_stat_before.st_size, "source PNG size changed during processing")
    require(source_stat_after.st_mtime_ns == source_stat_before.st_mtime_ns, "source PNG mtime changed during processing")

    output_png_bytes = tmp_output_path.read_bytes()
    report = {
        "change_id": spec["change_id"],
        "operation": "transparent_canvas_padding_only",
        "image_generation_calls": 0,
        "source": {
            "path": source_cfg["path"],
            "png_sha256_before": source_cfg["png_sha256"],
            "png_sha256_after": sha256_bytes(source_png_after),
            "png_bytes_before_after": [len(source_png_before), len(source_png_after)],
            "mtime_ns_before_after": [source_stat_before.st_mtime_ns, source_stat_after.st_mtime_ns],
            "canvas_px": source_cfg["canvas_px"],
            "mode": source_cfg["mode"],
            "rgba8_sha256": source_cfg["rgba8_sha256"],
            "a1_connected_component_count_preserved_by_exact_crop": source_cfg["a1_connected_component_count"],
            "a1_other_component_pixel_count_preserved_by_exact_crop": source_cfg["a1_other_component_pixel_count"],
        },
        "mechanical_transform": {
            "canvas_px": list(output_size),
            "paste_offset_px": list(offset),
            "paste_used_mask": False,
            "resize": False,
            "crop": False,
            "alpha_threshold_or_erase": False,
            "redraw": False,
            "rotation": False,
            "source_crop_exclusive": list(crop_box),
            "source_crop_full_rgba_byte_exact": True,
            "outside_source_crop_all_rgba_zero": True,
        },
        "output": {
            "path": output_cfg["path"],
            "png_sha256": sha256_bytes(output_png_bytes),
            "png_bytes": len(output_png_bytes),
            "canvas_px": list(output_size),
            "mode": "RGBA",
            "rgba8_sha256": sha256_bytes(readback.tobytes()),
            "a1_bbox_exclusive": actual_a1,
            "a16_bbox_exclusive": actual_a16,
            "a1_margin_px_left_top_right_bottom": margins_px,
            "a1_margin_fraction_left_top_right_bottom": margins_fraction,
            "a1_canvas_width_fraction": occupancy_width,
            "a1_pixel_count": alpha_count(output_alpha, 1),
            "a16_pixel_count": alpha_count(output_alpha, 16),
        },
        "status": "OFFLINE_PADDING_RGBA_EXACT_MARGIN_AND_BODY_PROPORTION_PASS_NO_IMPORT_LAYOUT_RUNTIME",
        "credit_boundary": spec["credit_boundary"],
    }

    tmp_meta_path.parent.mkdir(parents=True, exist_ok=True)
    tmp_meta_path.write_text(json.dumps(report, ensure_ascii=False, indent=2, sort_keys=True) + "\n", encoding="utf-8", newline="\n")
    require(not output_path.exists() and not output_meta_path.exists(), "target appeared during verification; refuse overwrite")
    os.replace(tmp_output_path, output_path)
    os.replace(tmp_meta_path, output_meta_path)
    print(json.dumps({"status": report["status"], "output": report["output"]}, ensure_ascii=False, sort_keys=True))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
