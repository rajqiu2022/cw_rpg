"""Authorized alpha-one cleanup and zero padding; no generation/resampling.

Wall: python prepare_media.py --asset wall
Rug: parameters are reserved; supply the explicit approved source, dimensions,
protected rectangle and actual alpha>1 bbox before executing --asset rug.
Coordinates are half-open source-pixel boxes. Source RGB is preserved even when
an authorized alpha-one byte is cleared. All output files must be absent.
"""

from __future__ import annotations

import argparse
import hashlib
import json
from pathlib import Path

from PIL import Image


ROOT = Path(__file__).resolve().parents[3]
WORK = ROOT / "game/build/luoyang_quality_20261101b_art01"
RAW_DIR = ROOT / "assets/raw/luoyang_quality_20261101b"
RUNTIME_DIR = ROOT / "game/art/modules/luoyang_quality_20261101b"
WALL_SOURCE = Path(
    "C:/Users/rajqiu/.codex/generated_images/"
    "019ff02b-0e55-70f3-82bb-5e5410641bf8/"
    "exec-d1c6ed58-b37a-463d-b8f1-a45c42acc39a.png"
)
WALL_SIZE = (1774, 887)
WALL_ALPHA_GT1_BBOX = (51, 65, 1723, 813)
WALL_PROTECTED_BOX = (40, 54, 1734, 824)
WALL_PADDING = 64


def digest(data: bytes) -> str:
    return hashlib.sha256(data).hexdigest()


def alpha_bbox(image: Image.Image, greater_than: int) -> list[int] | None:
    mask = image.getchannel("A").point(
        lambda value: 255 if value > greater_than else 0
    )
    result = mask.getbbox()
    return list(result) if result is not None else None


def prepare(
    key: str,
    source: Path,
    expected_size: tuple[int, int],
    protected_box: tuple[int, int, int, int],
    expected_alpha_gt1_bbox: tuple[int, int, int, int],
    padding: int,
) -> dict:
    raw = RAW_DIR / f"{key}_v1.png"
    runtime = RUNTIME_DIR / f"{key}_v1.png"
    manifest = WORK / f"{key}_ACTUAL.json"
    assert all(not path.exists() for path in (raw, runtime, manifest)), (
        "NEW_OUTPUTS_ONLY", raw, runtime, manifest
    )
    assert padding in (32, 64), ("AUTHORIZED_PADDING_ONLY", padding)
    assert len(set((source.resolve(), raw.resolve(), runtime.resolve()))) == 3
    original_file = source.read_bytes()
    with Image.open(source) as loaded:
        loaded.load()
        assert loaded.mode == "RGBA", ("RGBA_REQUIRED", loaded.mode)
        image = loaded.copy()
    assert image.size == expected_size, ("SIZE_MISMATCH", image.size)
    width, height = image.size
    left, top, right, bottom = protected_box
    assert 0 <= left < right <= width and 0 <= top < bottom <= height
    original = image.tobytes()
    original_gt1 = alpha_bbox(image, 1)
    assert original_gt1 == list(expected_alpha_gt1_bbox), (
        "ALPHA_GT1_BBOX_MISMATCH", original_gt1
    )
    bx0, by0, bx1, by1 = expected_alpha_gt1_bbox
    assert left <= bx0 < bx1 <= right and top <= by0 < by1 <= bottom, (
        "PROTECTED_BOX_MUST_CONTAIN_ALL_ALPHA_GT1", original_gt1
    )

    cleaned_bytes = bytearray(original)
    cleared = 0
    for y in range(height):
        for x in range(width):
            if left <= x < right and top <= y < bottom:
                continue
            alpha_offset = (y * width + x) * 4 + 3
            if cleaned_bytes[alpha_offset] == 1:
                cleaned_bytes[alpha_offset] = 0
                cleared += 1
    cleaned_data = bytes(cleaned_bytes)
    changed = 0
    for offset, (before, after) in enumerate(zip(original, cleaned_data)):
        if before == after:
            continue
        assert offset % 4 == 3 and before == 1 and after == 0, (
            "ONLY_ALPHA_ONE_TO_ZERO_ALLOWED", offset
        )
        pixel_index = offset // 4
        y, x = divmod(pixel_index, width)
        assert not (left <= x < right and top <= y < bottom)
        changed += 1
    assert changed == cleared, "CHANGED_BYTE_COUNT_MISMATCH"
    cleaned = Image.frombytes("RGBA", image.size, cleaned_data)
    assert cleaned.convert("RGB").tobytes() == image.convert("RGB").tobytes(), (
        "ALL_SOURCE_RGB_MUST_BE_EXACT"
    )
    for y in range(top, bottom):
        start = (y * width + left) * 4
        end = (y * width + right) * 4
        assert cleaned_data[start:end] == original[start:end], (
            "PROTECTED_RGBA_MUST_BE_EXACT", y
        )

    padded_size = (width + padding * 2, height + padding * 2)
    padded = Image.new("RGBA", padded_size, (0, 0, 0, 0))
    # No alpha mask: direct paste preserves alpha-zero hidden RGB as well.
    padded.paste(cleaned, (padding, padding))
    padded_data = padded.tobytes()
    padded_width, padded_height = padded_size
    padded_stride = padded_width * 4
    source_rows = []
    for y in range(padded_height):
        row = padded_data[y * padded_stride:(y + 1) * padded_stride]
        if padding <= y < padding + height:
            assert not any(row[:padding * 4])
            assert not any(row[(padding + width) * 4:])
            source_row = row[padding * 4:(padding + width) * 4]
            original_y = y - padding
            assert source_row == cleaned_data[
                original_y * width * 4:(original_y + 1) * width * 4
            ], ("PADDED_SOURCE_ROW_CHANGED", original_y)
            source_rows.append(source_row)
        else:
            assert not any(row), ("PADDING_NOT_RGBA_ZERO", y)
    assert b"".join(source_rows) == cleaned_data
    assert alpha_bbox(cleaned, 1) == original_gt1
    expected_padded_gt1 = [value + padding for value in original_gt1]
    assert alpha_bbox(padded, 1) == expected_padded_gt1

    for directory in (RAW_DIR, RUNTIME_DIR, WORK):
        directory.mkdir(parents=True, exist_ok=True)
    # Exclusive opens refuse to replace an existing raw/runtime/receipt.
    with raw.open("xb") as output:
        output.write(original_file)
    with runtime.open("xb") as output:
        padded.save(output, format="PNG")
    assert raw.read_bytes() == original_file, "RAW_ORIGINAL_FILE_CHANGED"
    assert source.read_bytes() == original_file, "SOURCE_CHANGED_DURING_PROCESSING"
    with Image.open(runtime) as decoded:
        decoded.load()
        assert decoded.mode == "RGBA" and decoded.size == padded_size
        assert decoded.tobytes() == padded_data, "OUTPUT_PNG_ROUNDTRIP_CHANGED"
    report = {
        "status": "ASSET_PREPARED_NOT_IMPORTED_OR_BOUND",
        "key": key,
        "source": str(source),
        "raw": str(raw),
        "runtime": str(runtime),
        "source_sha256": digest(original_file),
        "raw_sha256": digest(raw.read_bytes()),
        "runtime_sha256": digest(runtime.read_bytes()),
        "source_bytes": len(original_file),
        "runtime_bytes": runtime.stat().st_size,
        "source_size": list(image.size),
        "runtime_size": list(padded_size),
        "source_alpha_gt0_bbox": alpha_bbox(image, 0),
        "source_alpha_gt1_bbox": original_gt1,
        "protected_bbox": list(protected_box),
        "padding_each_side": padding,
        "runtime_alpha_gt0_bbox": alpha_bbox(padded, 0),
        "runtime_alpha_gt1_bbox": alpha_bbox(padded, 1),
        "alpha1_outside_protected_cleared": cleared,
        "changed_original_byte_count": changed,
        "source_rgba_sha256": digest(original),
        "cleaned_source_rect_rgba_sha256": digest(cleaned_data),
        "runtime_rgba_sha256": digest(padded_data),
        "all_source_RGB_exact": True,
        "protected_RGBA_exact": True,
        "only_outside_protected_alpha1_changed": True,
        "all_padding_RGBA_zero": True,
        "raw_original_bytes_exact": True,
        "source_original_bytes_unchanged": True,
        "source_rectangle_retained_at_padding_offset": True,
        "new_generation_calls": 0,
        "resynthesis": False,
        "resampling": False,
        "output_cropping": False,
        "engine_started": False,
        "imports_written": False,
        "runtime_binding_written": False,
    }
    with manifest.open("x", encoding="utf-8", newline="\n") as output:
        output.write(json.dumps(report, ensure_ascii=False, indent=2) + "\n")
    return report


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--asset", choices=("wall", "rug"), default="wall")
    parser.add_argument("--rug-source", type=Path)
    parser.add_argument("--rug-size", type=int, nargs=2, metavar=("W", "H"))
    parser.add_argument("--rug-protected-box", type=int, nargs=4)
    parser.add_argument("--rug-alpha-gt1-bbox", type=int, nargs=4)
    parser.add_argument("--rug-pad", type=int, choices=(32, 64), default=32)
    args = parser.parse_args()
    if args.asset == "wall":
        if any((args.rug_source, args.rug_size, args.rug_protected_box,
                args.rug_alpha_gt1_bbox)):
            parser.error("Rug parameters require --asset rug")
        report = prepare("salon_wall", WALL_SOURCE, WALL_SIZE,
                         WALL_PROTECTED_BOX, WALL_ALPHA_GT1_BBOX, WALL_PADDING)
    else:
        if not all((args.rug_source, args.rug_size, args.rug_protected_box,
                    args.rug_alpha_gt1_bbox)):
            parser.error("Rug is pending explicit source/size/protected-box/alpha-gt1-bbox")
        report = prepare("salon_rug", args.rug_source, tuple(args.rug_size),
                         tuple(args.rug_protected_box),
                         tuple(args.rug_alpha_gt1_bbox), args.rug_pad)
    print(json.dumps(report, ensure_ascii=False, indent=2))


if __name__ == "__main__":
    main()
