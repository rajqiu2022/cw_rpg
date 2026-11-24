from __future__ import annotations

import argparse
import hashlib
import json
import math
from pathlib import Path

import numpy as np
from PIL import Image, ImageDraw, ImageFilter


def sha256_bytes(data: bytes) -> str:
    return hashlib.sha256(data).hexdigest().upper()


def sha256_file(path: Path) -> str:
    return sha256_bytes(path.read_bytes())


def rgba_hash(array: np.ndarray) -> str:
    return sha256_bytes(array.tobytes(order="C"))


def bbox_exclusive(mask: np.ndarray) -> list[int]:
    ys, xs = np.where(mask)
    if len(xs) == 0:
        raise RuntimeError("empty A1 subject after cleanup")
    return [int(xs.min()), int(ys.min()), int(xs.max()) + 1, int(ys.max()) + 1]


def polygon_inside(size: tuple[int, int], points: list[list[int]]) -> np.ndarray:
    mask = Image.new("L", size, 0)
    ImageDraw.Draw(mask).polygon([tuple(p) for p in points], fill=255)
    return np.asarray(mask) > 0


def build_editable_mask(src: np.ndarray, policy: dict) -> np.ndarray:
    alpha = src[:, :, 3]
    hidden_rgb = (alpha == 0) & np.any(src[:, :, :3] != 0, axis=2)
    kind = policy["kind"]
    if kind == "manual_outer_polygon":
        inside = polygon_inside((src.shape[1], src.shape[0]), policy["keep_polygon_px"])
        return (~inside) | hidden_rgb
    if kind == "weak_alpha_far_from_strong_subject":
        threshold = int(policy["strong_alpha_min"])
        radius = int(policy["preserve_weak_edge_radius_px"])
        core = Image.fromarray(np.where(alpha >= threshold, 255, 0).astype(np.uint8), "L")
        near_core = np.asarray(core.filter(ImageFilter.MaxFilter(radius * 2 + 1))) > 0
        weak_outlier = (alpha > 0) & (alpha < threshold) & (~near_core)
        return weak_outlier | hidden_rgb
    raise RuntimeError(f"unknown cleanup policy: {kind}")


def translate_point(point: list[int], dx: int, dy: int) -> list[int]:
    return [int(point[0] + dx), int(point[1] + dy)]


def translate_rect(rect: list[int], dx: int, dy: int) -> list[int]:
    return [int(rect[0] + dx), int(rect[1] + dy), int(rect[2]), int(rect[3])]


def process_one(root: Path, row: dict) -> dict:
    source = root / row["source_path"]
    output = root / row["output_path"]
    mask_output = root / row["editable_mask_path"]
    meta_output = root / row["metadata_path"]
    for path in (output, mask_output, meta_output):
        if path.exists():
            raise RuntimeError(f"refuse overwrite: {path}")

    source_before = source.read_bytes()
    if sha256_bytes(source_before) != row["source_png_sha256"]:
        raise RuntimeError(f"source PNG SHA mismatch: {source}")
    image = Image.open(source).convert("RGBA")
    src = np.asarray(image).copy()
    if [image.width, image.height] != row["source_size_px"]:
        raise RuntimeError(f"source size mismatch: {source}")
    if rgba_hash(src) != row["source_rgba8_sha256"]:
        raise RuntimeError(f"source RGBA SHA mismatch: {source}")

    editable = build_editable_mask(src, row["cleanup_policy"])
    cleaned = src.copy()
    cleaned[editable] = np.array([0, 0, 0, 0], dtype=np.uint8)
    changed = np.any(cleaned != src, axis=2)
    if np.any(changed & (~editable)):
        raise RuntimeError("changed pixel outside frozen editable mask")
    if not np.array_equal(cleaned[~editable], src[~editable]):
        raise RuntimeError("protected source RGBA changed")

    a1 = cleaned[:, :, 3] > 0
    box = bbox_exclusive(a1)
    x0, y0, x1, y1 = box
    subject_w, subject_h = x1 - x0, y1 - y0
    pad_ratio = float(row["padding_margin_as_fraction_of_subject_extent"])
    pad_x = int(math.ceil(subject_w * pad_ratio))
    pad_y = int(math.ceil(subject_h * pad_ratio))
    out_w, out_h = subject_w + 2 * pad_x, subject_h + 2 * pad_y
    out = np.zeros((out_h, out_w, 4), dtype=np.uint8)
    source_crop = cleaned[y0:y1, x0:x1]
    out[pad_y:pad_y + subject_h, pad_x:pad_x + subject_w] = source_crop
    dx, dy = pad_x - x0, pad_y - y0

    output.parent.mkdir(parents=True, exist_ok=True)
    mask_output.parent.mkdir(parents=True, exist_ok=True)
    meta_output.parent.mkdir(parents=True, exist_ok=True)
    Image.fromarray(np.where(editable, 255, 0).astype(np.uint8), "L").save(mask_output)
    Image.fromarray(out, "RGBA").save(output)

    saved = np.asarray(Image.open(output).convert("RGBA"))
    if not np.array_equal(saved, out):
        raise RuntimeError("saved PNG RGBA readback mismatch")
    if not np.array_equal(saved[pad_y:pad_y + subject_h, pad_x:pad_x + subject_w], source_crop):
        raise RuntimeError("saved subject crop is not exact cleaned RGBA")
    out_box = bbox_exclusive(saved[:, :, 3] > 0)
    margins = [out_box[0], out_box[1], out_w - out_box[2], out_h - out_box[3]]
    fractions = [margins[0] / out_w, margins[1] / out_h, margins[2] / out_w, margins[3] / out_h]
    if min(fractions) < float(row["minimum_final_canvas_margin_fraction"]):
        raise RuntimeError(f"final transparent margin below contract: {fractions}")

    source_after_sha = sha256_file(source)
    if source_after_sha != row["source_png_sha256"]:
        raise RuntimeError("source bytes changed during processing")

    annotations = row["source_annotations"]
    transformed = {
        "ground_anchor_px": translate_point(annotations["ground_anchor_px"], dx, dy),
        "door_clear_rect_px": translate_rect(annotations["door_clear_rect_px"], dx, dy)
        if annotations.get("door_clear_rect_px") else None,
        "solid_source_rects_px": [translate_rect(r, dx, dy) for r in annotations["solid_source_rects_px"]],
        "column_foot_centers_px": [translate_point(p, dx, dy) for p in annotations.get("column_foot_centers_px", [])],
    }
    if annotations.get("open_gap_clear_vertical_landmarks_y_px"):
        transformed["open_gap_clear_vertical_landmarks_y_px"] = [
            int(y + dy) for y in annotations["open_gap_clear_vertical_landmarks_y_px"]
        ]
        transformed["open_gap_clear_height_px_conservative"] = int(
            annotations["open_gap_clear_height_px_conservative"]
        )
    for key in (
        "door_clear_height_px_approx",
        "door_clear_height_uncertainty_px",
        "door_clear_height_px_conservative_lower",
        "door_world_height_at_target_width_px_conservative_lower",
    ):
        if key in annotations:
            transformed[key] = annotations[key]
    result = {
        "id": row["id"],
        "status": "MECHANICAL_BACKGROUND_CLEAN_AND_PADDING_COMPLETE_NOT_ART_OR_RUNTIME_ADMISSION",
        "source": {
            "path": row["source_path"],
            "png_sha256_before_and_after": source_after_sha,
            "rgba8_sha256": row["source_rgba8_sha256"],
            "size_px": row["source_size_px"],
            "unchanged": True,
        },
        "editable_mask": {
            "path": row["editable_mask_path"],
            "png_sha256": sha256_file(mask_output),
            "size_px": row["source_size_px"],
            "white_means_RGBA_may_be_zeroed_only": True,
            "protected_mask_zero_pixels_remain_source_RGBA_byte_exact": True,
            "editable_pixels": int(editable.sum()),
            "actually_changed_pixels": int(changed.sum()),
        },
        "cleanup_policy": row["cleanup_policy"],
        "output": {
            "path": row["output_path"],
            "png_sha256": sha256_file(output),
            "png_bytes": output.stat().st_size,
            "rgba8_sha256": rgba_hash(saved),
            "size_px": [out_w, out_h],
            "complete_A1_bbox_exclusive": out_box,
            "true_transparent_margins_left_top_right_bottom_px": margins,
            "margin_fractions_left_top_right_bottom": fractions,
            "source_to_output_translation_px": [dx, dy],
            "subject_resize_crop_rotate_recolor": False,
            "transparent_canvas_reframed": True,
        },
        "source_annotations": annotations,
        "output_annotations": transformed,
        "admission": {
            "background_cleanup_authorized_by_user": True,
            "pixels_inside_protected_region_preserved": True,
            "art_review_pending": True,
            "runtime_import_or_formal_layout_authorized": False,
        },
    }
    meta_output.write_text(json.dumps(result, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")
    result["metadata"] = {
        "path": row["metadata_path"],
        "sha256": sha256_file(meta_output),
    }
    return result


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--spec", required=True)
    parser.add_argument("--expected-spec-sha256", required=True)
    args = parser.parse_args()
    spec_path = Path(args.spec).resolve()
    control = json.loads(spec_path.read_text(encoding="utf-8"))
    root = Path(control["workspace_root"]).resolve()
    if sha256_file(spec_path) != args.expected_spec_sha256.upper():
        raise RuntimeError("spec SHA mismatch")
    if control.get("base_spec_path"):
        base_path = root / control["base_spec_path"]
        if sha256_file(base_path) != control["base_spec_sha256"]:
            raise RuntimeError("base spec SHA mismatch")
        spec = json.loads(base_path.read_text(encoding="utf-8"))
        by_id = {row["id"]: row for row in spec["assets"]}
        for asset_id, overrides in control["asset_source_annotation_overrides"].items():
            if asset_id not in by_id:
                raise RuntimeError(f"unknown override asset id: {asset_id}")
            by_id[asset_id]["source_annotations"].update(overrides)
        spec["combined_report_path"] = control["combined_report_path"]
        spec["change_id"] = control["change_id"]
    else:
        spec = control
    rows = [process_one(root, row) for row in spec["assets"]]
    report_path = root / spec["combined_report_path"]
    if report_path.exists():
        raise RuntimeError(f"refuse overwrite: {report_path}")
    report_path.parent.mkdir(parents=True, exist_ok=True)
    report = {
        "change_id": spec["change_id"],
        "status": "THREE_MECHANICAL_DERIVATIVES_WRITTEN_ART_AND_RUNTIME_ADMISSION_PENDING",
        "rows": rows,
        "no_generation_engine_network_or_source_overwrite": True,
    }
    report_path.write_text(json.dumps(report, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")
    print(json.dumps({"passed": True, "report": str(report_path), "rows": len(rows)}))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
