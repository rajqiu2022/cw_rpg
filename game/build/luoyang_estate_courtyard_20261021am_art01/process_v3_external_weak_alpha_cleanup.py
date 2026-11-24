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
        raise RuntimeError("empty A1 subject")
    return [int(xs.min()), int(ys.min()), int(xs.max()) + 1, int(ys.max()) + 1]


def alpha_histogram(alpha: np.ndarray) -> list[int]:
    return [int(value) for value in np.bincount(alpha.reshape(-1), minlength=256)]


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--spec", required=True)
    parser.add_argument("--expected-spec-sha256", required=True)
    parser.add_argument("--authorization-token", required=True)
    args = parser.parse_args()

    spec_path = Path(args.spec).resolve()
    if sha256_file(spec_path) != args.expected_spec_sha256.upper():
        raise RuntimeError("spec SHA mismatch")
    spec = json.loads(spec_path.read_text(encoding="utf-8"))
    if args.authorization_token != spec["required_authorization_token"]:
        raise RuntimeError("explicit user authorization token missing or incorrect")

    root = Path(spec["workspace_root"]).resolve()
    source = root / spec["source"]["path"]
    output = root / spec["outputs"]["processed_png"]
    mask_output = root / spec["outputs"]["editable_mask_png"]
    report_output = root / spec["outputs"]["processing_report_json"]
    for path in (output, mask_output, report_output):
        if path.exists():
            raise RuntimeError(f"refuse overwrite: {path}")

    source_before = source.read_bytes()
    if sha256_bytes(source_before) != spec["source"]["png_sha256"]:
        raise RuntimeError("source PNG SHA mismatch")
    opened = Image.open(source)
    if opened.mode != spec["source"]["mode"]:
        raise RuntimeError("source mode mismatch")
    src = np.asarray(opened.convert("RGBA")).copy()
    if [opened.width, opened.height] != spec["source"]["size_px"]:
        raise RuntimeError("source size mismatch")
    if rgba_sha(src) != spec["source"]["rgba8_sha256"]:
        raise RuntimeError("source RGBA SHA mismatch")

    h, w = src.shape[:2]
    x0, y0, x1, y1 = spec["cleanup_contract"]["protected_source_rect_xyxy"]
    if not (0 <= x0 < x1 <= w and 0 <= y0 < y1 <= h):
        raise RuntimeError("protected rect outside source")
    inside = np.zeros((h, w), dtype=bool)
    inside[y0:y1, x0:x1] = True
    alpha = src[:, :, 3]
    strong_min = int(spec["cleanup_contract"]["strong_alpha_min"])
    if np.any((alpha >= strong_min) & (~inside)):
        raise RuntimeError("strong subject alpha exists outside protected rect")
    low, high = [int(v) for v in spec["cleanup_contract"]["editable_source_alpha_inclusive"]]
    editable = (~inside) & (alpha >= low) & (alpha <= high)

    cleaned = src.copy()
    cleaned[editable] = np.array([0, 0, 0, 0], dtype=np.uint8)
    changed = np.any(cleaned != src, axis=2)
    if not np.array_equal(changed, editable):
        raise RuntimeError("changed-pixel set differs from frozen editable mask")
    if not np.array_equal(cleaned[inside], src[inside]):
        raise RuntimeError("protected source RGBA changed")

    box = bbox_exclusive(cleaned[:, :, 3] > 0)
    bx0, by0, bx1, by1 = box
    subject_w, subject_h = bx1 - bx0, by1 - by0
    ratio = subject_w / subject_h
    ratio_min, ratio_max = spec["cleanup_contract"]["required_cleaned_A1_width_to_height_range"]
    if not (float(ratio_min) <= ratio <= float(ratio_max)):
        raise RuntimeError(f"cleaned A1 ratio rejected: {ratio}")

    margin_fraction = float(spec["cleanup_contract"]["minimum_final_canvas_margin_fraction_each_side"])
    if not (0.0 < margin_fraction < 0.5):
        raise RuntimeError("invalid margin fraction")
    pad_x = int(math.ceil(subject_w * margin_fraction / (1.0 - 2.0 * margin_fraction)))
    pad_y = int(math.ceil(subject_h * margin_fraction / (1.0 - 2.0 * margin_fraction)))
    out_w, out_h = subject_w + 2 * pad_x, subject_h + 2 * pad_y
    out = np.zeros((out_h, out_w, 4), dtype=np.uint8)
    source_crop = cleaned[by0:by1, bx0:bx1]
    out[pad_y:pad_y + subject_h, pad_x:pad_x + subject_w] = source_crop
    dx, dy = pad_x - bx0, pad_y - by0

    output.parent.mkdir(parents=True, exist_ok=True)
    mask_output.parent.mkdir(parents=True, exist_ok=True)
    report_output.parent.mkdir(parents=True, exist_ok=True)
    Image.fromarray(np.where(editable, 255, 0).astype(np.uint8), "L").save(mask_output)
    Image.fromarray(out, "RGBA").save(output)

    saved = np.asarray(Image.open(output).convert("RGBA"))
    if not np.array_equal(saved, out):
        raise RuntimeError("saved output RGBA readback mismatch")
    out_box = bbox_exclusive(saved[:, :, 3] > 0)
    margins = [out_box[0], out_box[1], out_w - out_box[2], out_h - out_box[3]]
    margin_fractions = [margins[0] / out_w, margins[1] / out_h, margins[2] / out_w, margins[3] / out_h]
    if min(margin_fractions) < margin_fraction:
        raise RuntimeError("final A1 margin below contract")
    if sha256_file(source) != spec["source"]["png_sha256"]:
        raise RuntimeError("source bytes changed during processing")

    removed_alpha_hist = alpha_histogram(alpha[editable])
    if any(removed_alpha_hist[i] for i in list(range(0, low)) + list(range(high + 1, 256))):
        raise RuntimeError("editable mask contains disallowed alpha")
    report = {
        "schema_version": 1,
        "change_id": spec["change_id"],
        "status": "MECHANICAL_V3_EXTERNAL_WEAK_ALPHA_CLEANUP_AND_TRANSPARENT_REFRAME_COMPLETE_ART_REVIEW_PENDING",
        "authorization_token_matched": True,
        "source": {
            "path": spec["source"]["path"],
            "png_sha256_before_and_after": sha256_file(source),
            "rgba8_sha256": rgba_sha(src),
            "size_px": [w, h],
            "unchanged": True,
        },
        "protected_rect": {
            "xyxy": [x0, y0, x1, y1],
            "rgba_byte_exact": True,
            "strong_alpha_outside_count": int(np.count_nonzero((alpha >= strong_min) & (~inside))),
        },
        "editable_mask": {
            "path": spec["outputs"]["editable_mask_png"],
            "png_sha256": sha256_file(mask_output),
            "editable_pixels": int(np.count_nonzero(editable)),
            "changed_pixels": int(np.count_nonzero(changed)),
            "source_alpha_range_inclusive": [low, high],
            "removed_alpha_histogram_0_to_255": removed_alpha_hist,
        },
        "output": {
            "path": spec["outputs"]["processed_png"],
            "png_sha256": sha256_file(output),
            "rgba8_sha256": rgba_sha(saved),
            "size_px": [out_w, out_h],
            "cleaned_source_A1_bbox_xyxy": box,
            "complete_A1_bbox_xyxy": out_box,
            "complete_A1_size_px": [subject_w, subject_h],
            "complete_A1_width_to_height": ratio,
            "transparent_margins_ltrb_px": margins,
            "transparent_margin_fractions_ltrb": margin_fractions,
            "source_to_output_translation_px": [dx, dy],
            "subject_resize_crop_rotate_recolor": False,
            "transparent_canvas_reframed": True,
            "output_frame_outside_pasted_crop_all_rgba_zero": True,
        },
        "alpha_proof": {
            "source_histogram_0_to_255": alpha_histogram(alpha),
            "cleaned_source_histogram_0_to_255": alpha_histogram(cleaned[:, :, 3]),
            "output_histogram_0_to_255": alpha_histogram(saved[:, :, 3]),
        },
        "scope_boundary": "No generation, import, engine, scene binding, collision binding, formal deployment, or source overwrite.",
    }
    report_output.write_text(json.dumps(report, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")
    print(json.dumps({"passed": True, "report": str(report_output), "output": str(output)}))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
