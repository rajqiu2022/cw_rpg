from __future__ import annotations

import argparse
import hashlib
import json
from pathlib import Path

from PIL import Image


SOURCE = Path("assets/raw/luoyang_market_two_shops_20261021ao/facade_luoyang_narrow_scholar_study_single_bay_v3_ratio_margin_edit.png")
SOURCE_SHA256 = "AB92ED6CB3F4E8EA15E4A9914A8C12C4BB7B7F8BA1793576F541EB1019B27D26"
SOURCE_SIZE = (1374, 1145)
PROTECTED_RECT = (282, 174, 1092, 1042)
EXPECTED_CHANGED_PIXELS = 245
BOTTOM_PADDING = 8
EXPECTED_OUTPUT_SIZE = (1374, 1153)
EXPECTED_A1_BBOX = (290, 182, 1084, 1034)

OUTPUT = Path("assets/processed/luoyang_market_two_shops_20261021ao/facade_luoyang_narrow_scholar_study_single_bay_v3_local_cleanup_padded.png")
META = OUTPUT.with_suffix(".meta.json")
REPORT = Path("game/build/luoyang_market_two_shops_20261021ao_art01/book_v3_local_cleanup_padding_report.json")


def sha256_bytes(data: bytes) -> str:
    return hashlib.sha256(data).hexdigest().upper()


def sha256_file(path: Path) -> str:
    return sha256_bytes(path.read_bytes())


def require_new(path: Path) -> None:
    if path.exists():
        raise RuntimeError(f"refuse overwrite: {path}")


def alpha_bbox(rgba: bytes, size: tuple[int, int]) -> tuple[int, int, int, int]:
    width, height = size
    xs: list[int] = []
    ys: list[int] = []
    for y in range(height):
        row = y * width * 4
        for x in range(width):
            if rgba[row + x * 4 + 3] != 0:
                xs.append(x)
                ys.append(y)
    if not xs:
        raise RuntimeError("output has no alpha>0 pixels")
    return min(xs), min(ys), max(xs) + 1, max(ys) + 1


def main() -> int:
    parser = argparse.ArgumentParser(description="Prepare the one authorized AO book-v3 cleanup derivative.")
    parser.add_argument(
        "--allow-user-authorized-book-v3-cleanup",
        action="store_true",
        help="Required explicit authorization gate. Without this flag the script refuses to run.",
    )
    args = parser.parse_args()
    if not args.allow_user_authorized_book_v3_cleanup:
        raise RuntimeError("authorization flag missing; no output is permitted")

    for path in (OUTPUT, META, REPORT):
        require_new(path)

    source_file_bytes = SOURCE.read_bytes()
    if sha256_bytes(source_file_bytes) != SOURCE_SHA256:
        raise RuntimeError("source PNG SHA-256 mismatch")

    with Image.open(SOURCE) as opened:
        if opened.mode != "RGBA" or opened.size != SOURCE_SIZE:
            raise RuntimeError(f"source contract mismatch: mode={opened.mode} size={opened.size}")
        source_rgba = opened.tobytes()

    width, height = SOURCE_SIZE
    x1, y1, x2, y2 = PROTECTED_RECT
    cleaned = bytearray(source_rgba)
    changed_offsets: set[int] = set()
    for y in range(height):
        row = y * width * 4
        for x in range(width):
            if x1 <= x < x2 and y1 <= y < y2:
                continue
            offset = row + x * 4
            alpha = cleaned[offset + 3]
            if 1 <= alpha <= 15:
                cleaned[offset : offset + 4] = b"\x00\x00\x00\x00"
                changed_offsets.add(offset)

    if len(changed_offsets) != EXPECTED_CHANGED_PIXELS:
        raise RuntimeError(f"allowed changed-pixel count mismatch: {len(changed_offsets)}")

    for y in range(y1, y2):
        start = (y * width + x1) * 4
        end = (y * width + x2) * 4
        if cleaned[start:end] != source_rgba[start:end]:
            raise RuntimeError("protected rectangle RGBA changed")

    cleaned_image = Image.frombytes("RGBA", SOURCE_SIZE, bytes(cleaned))
    output_image = Image.new("RGBA", EXPECTED_OUTPUT_SIZE, (0, 0, 0, 0))
    output_image.paste(cleaned_image, (0, 0))
    output_rgba = output_image.tobytes()

    if output_rgba[: width * height * 4] == source_rgba:
        raise RuntimeError("expected the 245 authorized cleanup pixels, but none changed")
    for offset in range(0, width * height * 4, 4):
        before = source_rgba[offset : offset + 4]
        after = output_rgba[offset : offset + 4]
        if before == after:
            continue
        if offset not in changed_offsets or after != b"\x00\x00\x00\x00" or not (1 <= before[3] <= 15):
            raise RuntimeError(f"unauthorized source-canvas RGBA change at byte offset {offset}")

    bottom_start = width * height * 4
    if any(output_rgba[bottom_start:]):
        raise RuntimeError("new bottom padding is not fully transparent black")
    actual_bbox = alpha_bbox(output_rgba, EXPECTED_OUTPUT_SIZE)
    if actual_bbox != EXPECTED_A1_BBOX:
        raise RuntimeError(f"A1 bbox mismatch: {actual_bbox}")

    source_sha_before_save = sha256_file(SOURCE)
    if source_sha_before_save != SOURCE_SHA256:
        raise RuntimeError("source changed before output save")

    OUTPUT.parent.mkdir(parents=True, exist_ok=True)
    output_image.save(OUTPUT, format="PNG", optimize=False, compress_level=6)
    with Image.open(OUTPUT) as readback:
        if readback.mode != "RGBA" or readback.size != EXPECTED_OUTPUT_SIZE:
            raise RuntimeError("saved output mode or size mismatch")
        readback_rgba = readback.tobytes()
    if readback_rgba != output_rgba:
        raise RuntimeError("saved PNG whole RGBA readback mismatch")

    source_sha_after_save = sha256_file(SOURCE)
    if source_sha_after_save != SOURCE_SHA256:
        raise RuntimeError("source PNG changed during processing")

    output_png_sha = sha256_file(OUTPUT)
    output_rgba_sha = sha256_bytes(output_rgba)
    margins = [
        actual_bbox[0],
        actual_bbox[1],
        EXPECTED_OUTPUT_SIZE[0] - actual_bbox[2],
        EXPECTED_OUTPUT_SIZE[1] - actual_bbox[3],
    ]
    record = {
        "schema_version": 1,
        "status": "PASS_LOCAL_CLEANUP_PADDING_DERIVATIVE_ONLY",
        "source": {
            "path": SOURCE.as_posix(),
            "png_sha256_before": source_sha_before_save,
            "png_sha256_after": source_sha_after_save,
            "size": list(SOURCE_SIZE),
            "mode": "RGBA",
        },
        "output": {
            "path": OUTPUT.as_posix(),
            "png_sha256": output_png_sha,
            "rgba8_sha256": output_rgba_sha,
            "size": list(EXPECTED_OUTPUT_SIZE),
            "mode": "RGBA",
            "a1_bbox_exclusive": list(actual_bbox),
            "a1_extent": [actual_bbox[2] - actual_bbox[0], actual_bbox[3] - actual_bbox[1]],
            "a1_margins_left_top_right_bottom": margins,
        },
        "mechanical_transform": {
            "protected_rect_xyxy": list(PROTECTED_RECT),
            "protected_rect_rgba_byte_exact": True,
            "outside_weak_alpha_pixels_zeroed": len(changed_offsets),
            "allowed_original_alpha_range": [1, 15],
            "bottom_transparent_rows_added": BOTTOM_PADDING,
            "original_pixels_moved": False,
            "subject_resized_cropped_rotated_recolored": False,
        },
        "credit_boundary": "Mechanical derivative only; no import, author, placement, collision, navigation, Field, or formal visual credit.",
    }
    META.write_text(json.dumps(record, ensure_ascii=False, indent=2) + "\n", encoding="utf-8", newline="\n")
    REPORT.write_text(json.dumps(record, ensure_ascii=False, indent=2) + "\n", encoding="utf-8", newline="\n")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
