from __future__ import annotations

import argparse
import hashlib
import json
import math
from pathlib import Path

import numpy as np
from PIL import Image, ImageFilter


def sha256_bytes(data: bytes) -> str:
    return hashlib.sha256(data).hexdigest().upper()


def sha256_file(path: Path) -> str:
    return sha256_bytes(path.read_bytes())


def rgba_sha256(array: np.ndarray) -> str:
    return sha256_bytes(array.tobytes(order="C"))


def a1_bbox_exclusive(alpha: np.ndarray) -> list[int]:
    ys, xs = np.where(alpha > 0)
    if len(xs) == 0:
        raise RuntimeError("empty A1 subject")
    return [int(xs.min()), int(ys.min()), int(xs.max()) + 1, int(ys.max()) + 1]


def process_one(root: Path, row: dict) -> dict:
    source = root / row["source_path"]
    output = root / row["output_path"]
    mask_output = root / row["protection_mask_path"]
    metadata_output = root / row["metadata_path"]
    for target in (output, mask_output, metadata_output):
        if target.exists():
            raise RuntimeError(f"refuse overwrite: {target}")

    source_bytes = source.read_bytes()
    if sha256_bytes(source_bytes) != row["source_png_sha256"]:
        raise RuntimeError(f"source PNG SHA mismatch: {source}")
    image = Image.open(source).convert("RGBA")
    source_rgba = np.asarray(image).copy()
    if [image.width, image.height] != row["source_size_px"]:
        raise RuntimeError(f"source size mismatch: {source}")
    if rgba_sha256(source_rgba) != row["source_rgba8_sha256"]:
        raise RuntimeError(f"source RGBA SHA mismatch: {source}")

    alpha = source_rgba[:, :, 3]
    strong_min = int(row["cleanup_policy"]["strong_alpha_min"])
    radius = int(row["cleanup_policy"]["protection_chebyshev_radius_px"])
    strong_image = Image.fromarray(
        np.where(alpha >= strong_min, 255, 0).astype(np.uint8), "L"
    )
    protected = np.asarray(
        strong_image.filter(ImageFilter.MaxFilter(radius * 2 + 1))
    ) > 0
    editable = (alpha > 0) & (alpha < strong_min) & (~protected)

    if int(protected.sum()) != int(row["expected_protected_pixel_count"]):
        raise RuntimeError("protected-pixel count differs from frozen preflight")
    if int(editable.sum()) != int(row["expected_zeroed_weak_pixel_count"]):
        raise RuntimeError("editable weak-pixel count differs from frozen preflight")

    cleaned = source_rgba.copy()
    cleaned[editable] = np.array([0, 0, 0, 0], dtype=np.uint8)
    changed = np.any(cleaned != source_rgba, axis=2)
    if not np.array_equal(changed, editable):
        raise RuntimeError("changed-pixel set is not exactly the frozen editable set")
    if not np.array_equal(cleaned[protected], source_rgba[protected]):
        raise RuntimeError("protected subject RGBA changed")

    cleaned_box = a1_bbox_exclusive(cleaned[:, :, 3])
    if cleaned_box != row["expected_cleaned_A1_bbox_exclusive_source_px"]:
        raise RuntimeError("cleaned A1 bbox differs from frozen preflight")
    x0, y0, x1, y1 = cleaned_box
    subject_w, subject_h = x1 - x0, y1 - y0
    pad_fraction = float(row["padding_each_side_as_fraction_of_subject_extent"])
    pad_x = int(math.ceil(subject_w * pad_fraction))
    pad_y = int(math.ceil(subject_h * pad_fraction))
    if [pad_x, pad_y] != row["expected_padding_left_top_px"]:
        raise RuntimeError("padding differs from frozen preflight")
    out_w, out_h = subject_w + pad_x * 2, subject_h + pad_y * 2
    if [out_w, out_h] != row["expected_output_size_px"]:
        raise RuntimeError("output size differs from frozen preflight")

    source_crop = cleaned[y0:y1, x0:x1]
    output_rgba = np.zeros((out_h, out_w, 4), dtype=np.uint8)
    output_rgba[pad_y:pad_y + subject_h, pad_x:pad_x + subject_w] = source_crop
    source_to_output = [pad_x - x0, pad_y - y0]
    if source_to_output != row["expected_source_to_output_translation_px"]:
        raise RuntimeError("source-to-output translation differs from frozen preflight")

    # The exact crop copy preserves every alpha-zero opening and its hidden RGB.
    # This is important for the bridge arch/deck gaps and pavilion column bays.
    mapped_source_crop = output_rgba[pad_y:pad_y + subject_h, pad_x:pad_x + subject_w]
    if not np.array_equal(mapped_source_crop, source_crop):
        raise RuntimeError("mapped source crop changed")

    output.parent.mkdir(parents=True, exist_ok=True)
    mask_output.parent.mkdir(parents=True, exist_ok=True)
    metadata_output.parent.mkdir(parents=True, exist_ok=True)
    Image.fromarray(np.where(protected, 255, 0).astype(np.uint8), "L").save(mask_output)
    Image.fromarray(output_rgba, "RGBA").save(output)

    saved = np.asarray(Image.open(output).convert("RGBA"))
    if not np.array_equal(saved, output_rgba):
        raise RuntimeError("saved PNG RGBA readback mismatch")
    saved_box = a1_bbox_exclusive(saved[:, :, 3])
    expected_saved_box = [pad_x, pad_y, pad_x + subject_w, pad_y + subject_h]
    if saved_box != expected_saved_box:
        raise RuntimeError("saved A1 bbox mismatch")
    margins = [saved_box[0], saved_box[1], out_w - saved_box[2], out_h - saved_box[3]]
    margin_fractions = [
        margins[0] / out_w,
        margins[1] / out_h,
        margins[2] / out_w,
        margins[3] / out_h,
    ]
    if min(margin_fractions) < float(row["minimum_final_canvas_margin_fraction"]):
        raise RuntimeError("final transparent margin below contract")
    if sha256_file(source) != row["source_png_sha256"]:
        raise RuntimeError("source bytes changed during processing")

    metadata = {
        "id": row["id"],
        "status": "MECHANICAL_CANDIDATE_WRITTEN_ART_AND_RUNTIME_ADMISSION_PENDING",
        "authorization_scope": "EXPLICIT_ALLOW_FLAG_FOR_THIS_ONE_RUN_ONLY",
        "source": {
            "path": row["source_path"],
            "png_sha256_before_and_after": row["source_png_sha256"],
            "rgba8_sha256": row["source_rgba8_sha256"],
            "size_px": row["source_size_px"],
            "unchanged": True,
        },
        "cleanup": {
            "strong_alpha_min": strong_min,
            "protection_chebyshev_radius_px": radius,
            "protected_pixel_count": int(protected.sum()),
            "zeroed_weak_alpha_1_to15_pixel_count": int(editable.sum()),
            "protected_RGBA_byte_exact": True,
            "alpha_zero_openings_and_hidden_RGB_inside_subject_crop_preserved": True,
            "subject_resize_rotate_recolor_repaint": False,
            "transparent_canvas_reframed": True,
        },
        "protection_mask": {
            "path": row["protection_mask_path"],
            "png_sha256": sha256_file(mask_output),
            "white_means_protected_RGBA_byte_exact": True,
        },
        "output": {
            "path": row["output_path"],
            "png_sha256": sha256_file(output),
            "rgba8_sha256": rgba_sha256(saved),
            "size_px": [out_w, out_h],
            "complete_A1_bbox_exclusive": saved_box,
            "true_transparent_margins_left_top_right_bottom_px": margins,
            "margin_fractions_left_top_right_bottom": margin_fractions,
            "source_to_output_translation_px": source_to_output,
        },
        "mapping_only_not_physics": row["mapping_only_not_physics"],
        "not_authorized": [
            "runtime_or_formal_binding",
            "engine_or_import",
            "source_overwrite",
            "additional_generation_or_local_retouch",
        ],
    }
    metadata_output.write_text(
        json.dumps(metadata, ensure_ascii=False, indent=2) + "\n", encoding="utf-8"
    )
    return metadata


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--spec", required=True)
    parser.add_argument("--expected-spec-sha256", required=True)
    parser.add_argument("--asset", required=True, choices=("sign", "bridge", "pavilion"))
    parser.add_argument("--allow-local-cleanup", action="store_true")
    args = parser.parse_args()
    if not args.allow_local_cleanup:
        raise RuntimeError("local cleanup is not authorized; explicit allow flag is required")

    spec_path = Path(args.spec).resolve()
    if sha256_file(spec_path) != args.expected_spec_sha256.upper():
        raise RuntimeError("spec SHA mismatch")
    spec = json.loads(spec_path.read_text(encoding="utf-8"))
    if spec["authorization_state"] != "PENDING_EXPLICIT_USER_PERMISSION_DO_NOT_EXECUTE_YET":
        raise RuntimeError("prepared spec must retain the pending-authorization provenance state")
    root = Path(spec["workspace_root"]).resolve()
    rows = {row["id"]: row for row in spec["assets"]}
    result = process_one(root, rows[args.asset])
    print(json.dumps({"passed": True, "id": args.asset, "output": result["output"]["path"]}))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
