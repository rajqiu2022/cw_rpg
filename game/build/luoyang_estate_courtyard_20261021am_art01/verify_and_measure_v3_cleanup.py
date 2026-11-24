from __future__ import annotations

import argparse
import hashlib
import json
import math
from pathlib import Path

import numpy as np
from PIL import Image


def sha256_bytes(data: bytes) -> str:
    return hashlib.sha256(data).hexdigest().upper()


def sha256_file(path: Path) -> str:
    return sha256_bytes(path.read_bytes())


def rgba_sha(array: np.ndarray) -> str:
    return sha256_bytes(array.tobytes(order="C"))


def bbox_exclusive(mask: np.ndarray) -> list[int]:
    ys, xs = np.where(mask)
    if len(xs) == 0:
        raise RuntimeError("empty subject")
    return [int(xs.min()), int(ys.min()), int(xs.max()) + 1, int(ys.max()) + 1]


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--spec", required=True)
    parser.add_argument("--expected-spec-sha256", required=True)
    args = parser.parse_args()
    spec_path = Path(args.spec).resolve()
    if sha256_file(spec_path) != args.expected_spec_sha256.upper():
        raise RuntimeError("spec SHA mismatch")
    spec = json.loads(spec_path.read_text(encoding="utf-8"))
    root = Path(spec["workspace_root"]).resolve()
    source_path = root / spec["source"]["path"]
    output_path = root / spec["outputs"]["processed_png"]
    mask_path = root / spec["outputs"]["editable_mask_png"]
    process_report_path = root / spec["outputs"]["processing_report_json"]
    verify_path = root / spec["outputs"]["verification_and_measurement_json"]
    if verify_path.exists():
        raise RuntimeError(f"refuse overwrite: {verify_path}")
    for path in (source_path, output_path, mask_path, process_report_path):
        if not path.is_file():
            raise RuntimeError(f"missing required input: {path}")

    if sha256_file(source_path) != spec["source"]["png_sha256"]:
        raise RuntimeError("source PNG SHA mismatch")
    source = np.asarray(Image.open(source_path).convert("RGBA"))
    if list(source.shape[1::-1]) != spec["source"]["size_px"]:
        raise RuntimeError("source dimensions mismatch")
    if rgba_sha(source) != spec["source"]["rgba8_sha256"]:
        raise RuntimeError("source RGBA mismatch")

    h, w = source.shape[:2]
    x0, y0, x1, y1 = spec["cleanup_contract"]["protected_source_rect_xyxy"]
    inside = np.zeros((h, w), dtype=bool)
    inside[y0:y1, x0:x1] = True
    alpha = source[:, :, 3]
    low, high = [int(v) for v in spec["cleanup_contract"]["editable_source_alpha_inclusive"]]
    strong_min = int(spec["cleanup_contract"]["strong_alpha_min"])
    if np.any((alpha >= strong_min) & (~inside)):
        raise RuntimeError("strong source alpha outside protected rect")
    expected_editable = (~inside) & (alpha >= low) & (alpha <= high)
    actual_mask = np.asarray(Image.open(mask_path).convert("L")) > 0
    if not np.array_equal(actual_mask, expected_editable):
        raise RuntimeError("editable mask differs from independently recomputed contract")

    cleaned = source.copy()
    cleaned[expected_editable] = np.array([0, 0, 0, 0], dtype=np.uint8)
    box = bbox_exclusive(cleaned[:, :, 3] > 0)
    bx0, by0, bx1, by1 = box
    subject_w, subject_h = bx1 - bx0, by1 - by0
    ratio = subject_w / subject_h
    rmin, rmax = spec["cleanup_contract"]["required_cleaned_A1_width_to_height_range"]
    if not (float(rmin) <= ratio <= float(rmax)):
        raise RuntimeError("independent cleaned ratio rejected")
    margin_fraction = float(spec["cleanup_contract"]["minimum_final_canvas_margin_fraction_each_side"])
    pad_x = int(math.ceil(subject_w * margin_fraction / (1.0 - 2.0 * margin_fraction)))
    pad_y = int(math.ceil(subject_h * margin_fraction / (1.0 - 2.0 * margin_fraction)))
    expected = np.zeros((subject_h + 2 * pad_y, subject_w + 2 * pad_x, 4), dtype=np.uint8)
    expected[pad_y:pad_y + subject_h, pad_x:pad_x + subject_w] = cleaned[by0:by1, bx0:bx1]
    output = np.asarray(Image.open(output_path).convert("RGBA"))
    if not np.array_equal(output, expected):
        raise RuntimeError("processed output is not the independently reconstructed exact result")
    if not np.array_equal(cleaned[inside], source[inside]):
        raise RuntimeError("protected source bytes changed")

    out_box = bbox_exclusive(output[:, :, 3] > 0)
    margins = [out_box[0], out_box[1], output.shape[1] - out_box[2], output.shape[0] - out_box[3]]
    fractions = [margins[0] / output.shape[1], margins[1] / output.shape[0], margins[2] / output.shape[1], margins[3] / output.shape[0]]
    if min(fractions) < margin_fraction:
        raise RuntimeError("independent output margin rejected")

    dx, dy = pad_x - bx0, pad_y - by0
    annotation = spec["source_annotations"]
    anchor_source = annotation["ground_anchor_px"]
    anchor_output = [int(anchor_source[0] + dx), int(anchor_source[1] + dy)]
    sx, sy, sw, sh = annotation["stone_foot_solid_rect_xywh"]
    solid_output = [int(sx + dx), int(sy + dy), int(sw), int(sh)]
    world_width = float(annotation["target_world_complete_A1_width_px"])
    scale = world_width / subject_w
    world_height = subject_h * scale
    if not (120.0 <= world_height <= 140.0):
        raise RuntimeError(f"world A1 height rejected: {world_height}")
    solid_relative = [
        (sx - anchor_source[0]) * scale,
        (sy - anchor_source[1]) * scale,
        sw * scale,
        sh * scale,
    ]
    instances = []
    axis_x0, axis_x1 = annotation["protected_central_axis_x_px"]
    for index, foot in enumerate(annotation["planned_instance_ground_feet_px"]):
        world_a1 = [foot[0] - world_width * 0.5, foot[1] - world_height, world_width, world_height]
        world_solid = [foot[0] + solid_relative[0], foot[1] + solid_relative[1], solid_relative[2], solid_relative[3]]
        if world_a1[0] < axis_x1 and world_a1[0] + world_a1[2] > axis_x0:
            raise RuntimeError(f"instance {index} enters protected central axis")
        instances.append({
            "index": index,
            "ground_foot_px": foot,
            "world_complete_A1_bbox_xywh": world_a1,
            "world_stone_foot_solid_rect_xywh": world_solid,
        })

    process_report = json.loads(process_report_path.read_text(encoding="utf-8"))
    if process_report["source"]["png_sha256_before_and_after"] != spec["source"]["png_sha256"]:
        raise RuntimeError("processing report source SHA mismatch")
    if process_report["output"]["png_sha256"] != sha256_file(output_path):
        raise RuntimeError("processing report output SHA mismatch")
    result = {
        "schema_version": 1,
        "change_id": spec["change_id"],
        "passed": True,
        "source_png_sha256": sha256_file(source_path),
        "processed_png": {
            "path": spec["outputs"]["processed_png"],
            "png_sha256": sha256_file(output_path),
            "rgba8_sha256": rgba_sha(output),
            "size_px": [int(output.shape[1]), int(output.shape[0])],
            "complete_A1_bbox_xyxy": out_box,
            "complete_A1_size_px": [subject_w, subject_h],
            "complete_A1_width_to_height": ratio,
            "margin_fractions_ltrb": fractions,
        },
        "independent_pixel_proof": {
            "editable_mask_exact": True,
            "all_alpha_at_least_8_inside_protected_rect": True,
            "protected_rect_rgba_byte_exact": True,
            "changed_source_pixels_exactly_outside_rect_alpha_1_to_7": True,
            "processed_output_exact_independent_reconstruction": True,
            "source_unchanged": True,
            "source_to_output_translation_px": [dx, dy],
        },
        "measured_binding": {
            "ground_anchor_source_px": anchor_source,
            "ground_anchor_output_px": anchor_output,
            "stone_foot_solid_source_rect_xywh": annotation["stone_foot_solid_rect_xywh"],
            "stone_foot_solid_output_rect_xywh": solid_output,
            "uniform_scale_for_world_A1_width_310": scale,
            "world_complete_A1_size_px": [world_width, world_height],
            "render_canvas_size_px": [output.shape[1] * scale, output.shape[0] * scale],
            "instances": instances,
        },
        "art_review_pending": True,
        "runtime_import_engine_formal_credit": False,
    }
    verify_path.parent.mkdir(parents=True, exist_ok=True)
    verify_path.write_text(json.dumps(result, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")
    print(json.dumps({"passed": True, "report": str(verify_path), "instances": len(instances)}))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
