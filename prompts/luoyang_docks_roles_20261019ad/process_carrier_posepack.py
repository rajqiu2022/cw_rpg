"""Mechanical carrier pose-pack processor.

This script never calls an engine, SDK, network or generator. It accepts one
untouched RGBA source plus manually reviewed rectangles, then performs only:

* lossless source cropping that contains every source A>0 pixel exactly once;
* one shared uniform RGBA resize for all five full-body poses;
* transparent placement into one 160x160 idle cell and four 160x160 walk cells;
* one explicitly measured square head-and-shoulders crop from the same raw.

It does not threshold, erase, repaint, mirror, synthesize or per-pose fit art.
Requested prompt layout is not evidence: actual rectangles and source SHA are
mandatory inputs after human inspection.
"""

from __future__ import annotations

import argparse
import hashlib
import json
import math
from pathlib import Path
from typing import Any

from PIL import Image, ImageChops, ImageDraw


POSE_NAMES = [
    "idle_down_front",
    "walk_right_left_contact",
    "walk_right_right_passing",
    "walk_right_right_contact",
    "walk_right_left_passing",
]
CELL_SIZE = (160, 160)
WALK_SIZE = (640, 160)
PORTRAIT_SIZE = (512, 512)
TARGET_ALPHA_HEIGHT = 140
TARGET_SOLE_Y = 152
MAX_ALPHA_WIDTH = 144


def file_sha256(path: Path) -> str:
    return hashlib.sha256(path.read_bytes()).hexdigest().upper()


def alpha_bbox(image: Image.Image) -> tuple[int, int, int, int] | None:
    return image.getchannel("A").getbbox()


def rect_xyxy(rect: list[int]) -> tuple[int, int, int, int]:
    if len(rect) != 4 or not all(isinstance(value, int) for value in rect):
        raise ValueError(f"rect must be four integers [x,y,w,h], got {rect!r}")
    x, y, width, height = rect
    if width <= 0 or height <= 0:
        raise ValueError(f"rect width/height must be positive: {rect!r}")
    return x, y, x + width, y + height


def overlaps(a: tuple[int, int, int, int], b: tuple[int, int, int, int]) -> bool:
    return max(a[0], b[0]) < min(a[2], b[2]) and max(a[1], b[1]) < min(a[3], b[3])


def count_nonzero_alpha(image: Image.Image) -> int:
    histogram = image.getchannel("A").histogram()
    return sum(histogram[1:])


def alpha_sum(image: Image.Image) -> int:
    histogram = image.getchannel("A").histogram()
    return sum(value * count for value, count in enumerate(histogram))


def fit_pose_without_content_change(crop: Image.Image, scale: float) -> tuple[Image.Image, dict[str, Any]]:
    source_bbox = alpha_bbox(crop)
    if source_bbox is None:
        raise ValueError("pose crop contains no A>0 pixel")
    content = crop.crop(source_bbox)
    target_width = max(1, round(content.width * scale))
    target_height = max(1, round(content.height * scale))
    resized = content.resize((target_width, target_height), Image.Resampling.LANCZOS)
    resized_bbox = alpha_bbox(resized)
    if resized_bbox is None:
        raise ValueError("resized pose lost all alpha")
    actual_width = resized_bbox[2] - resized_bbox[0]
    actual_height = resized_bbox[3] - resized_bbox[1]
    if actual_width > MAX_ALPHA_WIDTH:
        raise ValueError(f"scaled alpha width {actual_width}px exceeds {MAX_ALPHA_WIDTH}px")
    if actual_height > TARGET_ALPHA_HEIGHT + 1:
        raise ValueError(f"scaled alpha height {actual_height}px exceeds bounded 141px raster allowance")

    canvas = Image.new("RGBA", CELL_SIZE, (0, 0, 0, 0))
    centre_x = (resized_bbox[0] + resized_bbox[2] - 1) / 2.0
    target_x = round(CELL_SIZE[0] / 2.0 - centre_x)
    target_y = (TARGET_SOLE_Y + 1) - resized_bbox[3]
    if target_x < 0 or target_y < 0 or target_x + resized.width > CELL_SIZE[0] or target_y + resized.height > CELL_SIZE[1]:
        raise ValueError(
            f"pose cannot be transparently placed in 160x160: offset={(target_x, target_y)} size={resized.size}"
        )
    canvas.alpha_composite(resized, (target_x, target_y))
    final_bbox = alpha_bbox(canvas)
    if final_bbox is None or final_bbox[3] - 1 != TARGET_SOLE_Y:
        raise ValueError(f"actual sole row is not {TARGET_SOLE_Y}: bbox={final_bbox}")
    return canvas, {
        "source_alpha_bbox_in_pose_rect_xyxy_exclusive": list(source_bbox),
        "source_alpha_pixels": count_nonzero_alpha(crop),
        "source_alpha_sum": alpha_sum(crop),
        "content_size_px": [content.width, content.height],
        "shared_scale": scale,
        "resized_canvas_px": [resized.width, resized.height],
        "placement_xy_px": [target_x, target_y],
        "output_alpha_bbox_xyxy_exclusive": list(final_bbox),
        "output_alpha_pixels": count_nonzero_alpha(canvas),
        "output_alpha_sum": alpha_sum(canvas),
        "alpha_processing": "full RGBA Lanczos; no alpha threshold, erasure or repaint",
    }


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--input", type=Path, required=True)
    parser.add_argument("--layout", type=Path, required=True)
    parser.add_argument("--output-dir", type=Path, required=True)
    args = parser.parse_args()

    source = args.input.resolve()
    layout_path = args.layout.resolve()
    output_dir = args.output_dir.resolve()
    if not source.is_file() or not layout_path.is_file():
        raise FileNotFoundError("input raw and reviewed layout JSON must both exist")
    layout = json.loads(layout_path.read_text(encoding="utf-8"))
    actual_sha = file_sha256(source)
    if layout.get("input_sha256", "").upper() != actual_sha:
        raise ValueError(f"input SHA mismatch: actual {actual_sha}")

    raw = Image.open(source)
    raw.load()
    if raw.mode != "RGBA":
        raise ValueError(f"source must already be RGBA, got {raw.mode}")
    pose_rows = layout.get("pose_rects")
    if not isinstance(pose_rows, list) or [row.get("name") for row in pose_rows] != POSE_NAMES:
        raise ValueError(f"pose_rects names/order must be exactly {POSE_NAMES}")
    pose_rects = [rect_xyxy(row.get("rect_px")) for row in pose_rows]
    for index, rect in enumerate(pose_rects):
        if rect[0] < 0 or rect[1] < 0 or rect[2] > raw.width or rect[3] > raw.height:
            raise ValueError(f"pose rect {index} is outside raw canvas: {rect}")
        for other in range(index):
            if overlaps(rect, pose_rects[other]):
                raise ValueError(f"pose rects overlap: {other} and {index}")

    alpha_binary = raw.getchannel("A").point(lambda value: 255 if value > 0 else 0)
    coverage = Image.new("L", raw.size, 0)
    draw = ImageDraw.Draw(coverage)
    for left, top, right, bottom in pose_rects:
        draw.rectangle((left, top, right - 1, bottom - 1), fill=255)
    outside = ImageChops.subtract(alpha_binary, coverage)
    if outside.getbbox() is not None:
        raise ValueError(f"reviewed pose rects do not contain every source A>0 pixel: outside={outside.getbbox()}")

    crops: list[Image.Image] = []
    source_measurements: list[dict[str, Any]] = []
    max_height = 0
    max_width = 0
    for name, rect in zip(POSE_NAMES, pose_rects):
        crop = raw.crop(rect)
        bbox = alpha_bbox(crop)
        if bbox is None:
            raise ValueError(f"{name} contains no alpha")
        if bbox[0] <= 0 or bbox[1] <= 0 or bbox[2] >= crop.width or bbox[3] >= crop.height:
            raise ValueError(f"{name} lacks a measured transparent margin inside its reviewed rect: bbox={bbox} rect_size={crop.size}")
        width = bbox[2] - bbox[0]
        height = bbox[3] - bbox[1]
        max_width = max(max_width, width)
        max_height = max(max_height, height)
        crops.append(crop)
        source_measurements.append({
            "name": name,
            "rect_xyxy_exclusive": list(rect),
            "rect_size_px": [crop.width, crop.height],
            "alpha_bbox_xyxy_exclusive": list(bbox),
            "alpha_pixels": count_nonzero_alpha(crop),
            "alpha_sum": alpha_sum(crop),
        })

    shared_scale = TARGET_ALPHA_HEIGHT / max_height
    if math.ceil(max_width * shared_scale) > MAX_ALPHA_WIDTH:
        raise ValueError(
            f"one shared 140px-height scale would exceed the {MAX_ALPHA_WIDTH}px width envelope; "
            "do not silently shrink or fit poses independently"
        )
    normalized: list[Image.Image] = []
    normalized_measurements: list[dict[str, Any]] = []
    for crop in crops:
        cell, measurement = fit_pose_without_content_change(crop, shared_scale)
        normalized.append(cell)
        normalized_measurements.append(measurement)

    idle = normalized[0]
    walk = Image.new("RGBA", WALK_SIZE, (0, 0, 0, 0))
    for index, frame in enumerate(normalized[1:]):
        walk.alpha_composite(frame, (index * CELL_SIZE[0], 0))

    portrait_rect = rect_xyxy(layout.get("portrait_rect_px"))
    idle_rect = pose_rects[0]
    if not (portrait_rect[0] >= idle_rect[0] and portrait_rect[1] >= idle_rect[1] and portrait_rect[2] <= idle_rect[2] and portrait_rect[3] <= idle_rect[3]):
        raise ValueError("portrait rect must be wholly inside the reviewed idle pose rect")
    if portrait_rect[2] - portrait_rect[0] != portrait_rect[3] - portrait_rect[1]:
        raise ValueError("portrait rect must be square to prevent aspect-ratio distortion")
    portrait_source = raw.crop(portrait_rect)
    if alpha_bbox(portrait_source) is None:
        raise ValueError("portrait crop contains no alpha")
    portrait = portrait_source.resize(PORTRAIT_SIZE, Image.Resampling.LANCZOS)

    outputs = {
        "idle": output_dir / "npc_docks_strong_carrier_idle_down_1f_v1_runtime.png",
        "walk": output_dir / "npc_docks_strong_carrier_walk_right_4f_v1_runtime.png",
        "portrait": output_dir / "portrait_docks_strong_carrier_v1.png",
        "report": output_dir / "mechanical_derivative_report.json",
    }
    if any(path.exists() for path in outputs.values()):
        raise FileExistsError("refusing to overwrite an existing derivative or report")
    output_dir.mkdir(parents=True, exist_ok=True)
    idle.save(outputs["idle"], format="PNG", optimize=False)
    walk.save(outputs["walk"], format="PNG", optimize=False)
    portrait.save(outputs["portrait"], format="PNG", optimize=False)

    result = {
        "schema": "luoyang_docks_carrier_mechanical_derivative_v1",
        "passed": True,
        "source": {
            "path": source.as_posix(),
            "sha256": actual_sha,
            "bytes": source.stat().st_size,
            "mode": raw.mode,
            "size_px": [raw.width, raw.height],
            "alpha_bbox_xyxy_exclusive": list(alpha_bbox(raw) or []),
            "alpha_pixels": count_nonzero_alpha(raw),
            "alpha_sum": alpha_sum(raw),
            "unchanged": True,
        },
        "layout": {
            "path": layout_path.as_posix(),
            "sha256": file_sha256(layout_path),
            "pose_alpha_union_covers_all_source_alpha": outside.getbbox() is None,
            "pose_rects_pairwise_nonoverlap": True,
            "portrait_rect_xyxy_exclusive": list(portrait_rect),
        },
        "shared_scale": shared_scale,
        "target": {
            "cell_px": list(CELL_SIZE),
            "walk_px": list(WALK_SIZE),
            "portrait_px": list(PORTRAIT_SIZE),
            "maximum_alpha_height_px": TARGET_ALPHA_HEIGHT,
            "sole_row_y_px": TARGET_SOLE_Y,
            "maximum_alpha_width_px": MAX_ALPHA_WIDTH,
        },
        "source_poses": source_measurements,
        "normalized_poses": [
            {"name": name, **measurement}
            for name, measurement in zip(POSE_NAMES, normalized_measurements)
        ],
        "outputs": [
            {
                "kind": kind,
                "path": path.as_posix(),
                "sha256": file_sha256(path),
                "bytes": path.stat().st_size,
                "size_px": list(Image.open(path).size),
            }
            for kind, path in outputs.items()
            if kind != "report"
        ],
        "processing": "crop measured rectangles; one shared RGBA Lanczos scale; transparent placement; no alpha threshold, erase, repaint, mirror, inpaint or per-pose fit",
        "credit_boundary": "Mechanical structure only. Same-person identity, four real gait phases, portrait likeness, import, runtime and Field admission remain manual/QA gates.",
    }
    outputs["report"].write_text(json.dumps(result, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")
    print(json.dumps(result, ensure_ascii=False, indent=2))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
