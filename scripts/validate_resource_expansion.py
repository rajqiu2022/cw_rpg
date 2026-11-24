"""Validate the adopted 2026-08-05 visual resource expansion."""

from __future__ import annotations

import sys
from pathlib import Path

from PIL import Image


ROOT = Path(__file__).resolve().parents[1]
GAME_ART = ROOT / "game" / "art"


def validate_group(
    errors: list[str],
    directory: Path,
    pattern: str,
    expected_count: int,
    expected_sizes: set[tuple[int, int]],
    require_alpha: bool = True,
) -> int:
    files = sorted(directory.glob(pattern))
    if len(files) != expected_count:
        errors.append(
            f"{directory.relative_to(ROOT)}: expected {expected_count} {pattern} files, got {len(files)}"
        )
    for path in files:
        with Image.open(path) as image:
            if image.size not in expected_sizes:
                errors.append(f"{path.relative_to(ROOT)}: unexpected size {image.size}")
            if require_alpha and "A" not in image.getbands():
                errors.append(f"{path.relative_to(ROOT)}: missing alpha channel")
    return len(files)


def main() -> int:
    errors: list[str] = []
    checked = 0

    checked += validate_group(
        errors,
        GAME_ART / "characters" / "portraits" / "street_expansion_v1",
        "*.png",
        4,
        {(512, 512)},
    )
    checked += validate_group(
        errors,
        GAME_ART / "props" / "interactive" / "expansion_v1",
        "*.png",
        12,
        {(512, 512)},
    )
    checked += validate_group(
        errors,
        GAME_ART / "sprites" / "battle" / "standard_v2" / "wulin_examiner",
        "*.png",
        20,
        {(512, 384)},
    )
    checked += validate_group(
        errors,
        GAME_ART / "battle_vfx" / "weapon_tiers_v1",
        "*.png",
        12,
        {(1024, 1024)},
    )

    field_dir = GAME_ART / "characters" / "street_expansion_v1"
    field_files = sorted(field_dir.glob("*.png"))
    if len(field_files) < 9:
        errors.append(f"{field_dir.relative_to(ROOT)}: expected at least 9 field strips")
    for path in field_files:
        with Image.open(path) as image:
            if image.height != 160 or image.width % 160 != 0:
                errors.append(f"{path.relative_to(ROOT)}: invalid 160px field strip {image.size}")
            if "A" not in image.getbands():
                errors.append(f"{path.relative_to(ROOT)}: missing alpha channel")
    checked += len(field_files)

    scene = GAME_ART / "backgrounds" / "bg_luoyang_outer_market_25d_v1.png"
    if not scene.exists():
        errors.append(f"{scene.relative_to(ROOT)}: missing")
    else:
        with Image.open(scene) as image:
            if image.size != (1536, 1024):
                errors.append(f"{scene.relative_to(ROOT)}: expected 1536x1024, got {image.size}")
        checked += 1

    if errors:
        print("RESOURCE_EXPANSION_VALIDATION_FAILED")
        for error in errors:
            print(f"- {error}")
        return 1

    print(f"RESOURCE_EXPANSION_VALIDATION_PASS files={checked}")
    return 0


if __name__ == "__main__":
    sys.exit(main())
