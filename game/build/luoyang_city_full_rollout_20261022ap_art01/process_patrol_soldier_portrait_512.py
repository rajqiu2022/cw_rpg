from __future__ import annotations

import argparse
import hashlib
import json
from pathlib import Path

from PIL import Image


EXPECTED_SOURCE_SHA256 = "92C10299A96003A4C7DB3840279AD9FB33B2BD752F9F4420A1C22BA2E8D95040"
EXPECTED_SOURCE_SIZE = (1254, 1254)
OUTPUT_SIZE = (512, 512)


def sha256_file(path: Path) -> str:
    return hashlib.sha256(path.read_bytes()).hexdigest().upper()


def rgba_sha256(image: Image.Image) -> str:
    return hashlib.sha256(image.convert("RGBA").tobytes()).hexdigest().upper()


def main() -> int:
    parser = argparse.ArgumentParser(description="Uniformly resize the approved AP patrol portrait without crop or cleanup.")
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
    output = source.resize(OUTPUT_SIZE, Image.Resampling.LANCZOS)
    if sha256_file(args.source) != source_sha_before:
        raise RuntimeError("Source bytes changed during processing")

    args.output.parent.mkdir(parents=True, exist_ok=True)
    output.save(args.output, format="PNG")
    reloaded = Image.open(args.output).convert("RGBA")
    if reloaded.size != OUTPUT_SIZE or reloaded.tobytes() != output.tobytes():
        raise RuntimeError("Saved PNG RGBA readback differs from in-memory output")

    report = {
        "schema_version": 1,
        "change_id": "luoyang-city-full-rollout-20261022ap",
        "status": "PORTRAIT_MECHANICAL_512_COMPLETE_NOT_RUNTIME_ADMISSION",
        "source": {
            "path": str(args.source),
            "sha256_before": source_sha_before,
            "sha256_after": sha256_file(args.source),
            "rgba_sha256": source_rgba_sha,
            "size_px": list(source.size),
            "mode": source.mode,
        },
        "mechanical_transform": {
            "whole_rgba_uniform_resize": True,
            "resample_filter": "Pillow Image.Resampling.LANCZOS",
            "output_size_px": list(OUTPUT_SIZE),
            "crop": False,
            "paste_or_reframe": False,
            "mask": False,
            "alpha_threshold_or_erasure": False,
            "recolor": False,
            "rotate": False,
        },
        "output": {
            "path": str(args.output),
            "png_sha256": sha256_file(args.output),
            "png_bytes": args.output.stat().st_size,
            "rgba_sha256": rgba_sha256(reloaded),
            "size_px": list(reloaded.size),
            "mode": reloaded.mode,
            "a1_xyxy": list(reloaded.getchannel("A").getbbox() or []),
        },
        "scope_limits": {
            "background_cleanup_performed": False,
            "runtime_dialog_ui_verified": False,
        },
    }
    args.report.parent.mkdir(parents=True, exist_ok=True)
    args.report.write_text(json.dumps(report, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
