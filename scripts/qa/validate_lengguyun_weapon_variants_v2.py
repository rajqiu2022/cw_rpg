from __future__ import annotations

import sys
import hashlib
import json
from pathlib import Path

from PIL import Image, ImageChops


ROOT = Path(__file__).resolve().parents[2]
FIELD_ROOT = ROOT / "game" / "art" / "characters" / "weapon_variants" / "lengguyun" / "v7_idle_stable"
BATTLE_ROOT = ROOT / "game" / "art" / "sprites" / "battle" / "weapon_variants_v3" / "lengguyun"
STYLES = ("sword", "dao", "staff", "palm", "hidden")
DIRECTIONS = ("down", "up", "left", "right")
BATTLE_STATES = ("ready", "move", "attack", "hit", "defeat")
FIELD_STAFF_MANIFEST = ROOT / "assets/raw/sprite/field/weapon_variants/lengguyun/codex_builtin_v6_staff_back/manifest.json"
BATTLE_STAFF_MANIFEST = ROOT / "assets/raw/sprite/battle/weapon_variants/lengguyun/codex_builtin_v3_staff_twohand/manifest.json"


def alpha_bbox(image: Image.Image) -> tuple[int, int, int, int] | None:
    if image.mode != "RGBA":
        return None
    return image.getchannel("A").getbbox()


def tree_sha256(root: Path) -> str:
    digest = hashlib.sha256()
    for path in sorted(root.glob("*.png")):
        digest.update(path.name.encode("utf-8"))
        digest.update(path.read_bytes())
    return digest.hexdigest()


def validate_staff_manifest(path: Path, runtime_root: Path, required_review: tuple[str, ...], errors: list[str]) -> None:
    if not path.exists():
        errors.append(f"missing staff approval manifest: {path.relative_to(ROOT)}")
        return
    data = json.loads(path.read_text(encoding="utf-8"))
    if data.get("status") != "adopted" or data.get("backend") != "codex_builtin":
        errors.append(f"{path.name}: staff batch is not an adopted Codex built-in asset")
    source = path.parent / str(data.get("source_file", ""))
    if not source.exists() or hashlib.sha256(source.read_bytes()).hexdigest() != data.get("source_sha256"):
        errors.append(f"{path.name}: raw source hash drifted")
    actual_tree_hash = tree_sha256(runtime_root)
    if actual_tree_hash != data.get("runtime_tree_sha256"):
        errors.append(f"{path.name}: runtime tree hash drifted ({actual_tree_hash})")
    review = data.get("review", {})
    for key in required_review:
        if review.get(key) is not True:
            errors.append(f"{path.name}: missing approved review flag {key}")


def main() -> int:
    errors: list[str] = []
    ready_heights: dict[str, list[int]] = {style: [] for style in STYLES}

    for style in STYLES:
        for direction in DIRECTIONS:
            for state, frame_count in (("idle", 4), ("walk", 8)):
                path = FIELD_ROOT / style / f"lengguyun_{style}_{state}_{direction}_25d_{frame_count}f.png"
                if not path.exists():
                    errors.append(f"missing field strip: {path.relative_to(ROOT)}")
                    continue
                with Image.open(path) as image:
                    expected_size = (160 * frame_count, 160)
                    if image.size != expected_size or image.mode != "RGBA":
                        errors.append(f"{path.name}: got {image.mode} {image.size}, expected RGBA {expected_size}")
                        continue
                    frame_hashes: list[str] = []
                    lower_alpha: list[Image.Image] = []
                    for index in range(frame_count):
                        frame = image.crop((index * 160, 0, (index + 1) * 160, 160))
                        frame_hashes.append(hashlib.sha256(frame.tobytes()).hexdigest())
                        lower_alpha.append(frame.crop((0, 80, 160, 160)).getchannel("A"))
                        bbox = alpha_bbox(frame)
                        if bbox is None:
                            errors.append(f"{path.name}[{index}]: empty alpha")
                            continue
                        bottom_margin = 160 - bbox[3]
                        visible_height = bbox[3] - bbox[1]
                        if not 6 <= bottom_margin <= 20:
                            errors.append(f"{path.name}[{index}]: bottom margin {bottom_margin}, expected 6..20")
                        if not 124 <= visible_height <= 140:
                            errors.append(f"{path.name}[{index}]: visible height {visible_height}, expected 124..140")
                    if state == "walk":
                        if len(set(frame_hashes)) != 8:
                            errors.append(f"{path.name}: walk cycle must contain 8 unique frames")
                        motion_ratios: list[float] = []
                        for index, current in enumerate(lower_alpha):
                            following = lower_alpha[(index + 1) % len(lower_alpha)]
                            difference = ImageChops.difference(current, following)
                            changed = sum(1 for value in difference.get_flattened_data() if value > 20)
                            motion_ratios.append(changed / (160 * 80))
                        if sum(motion_ratios) / len(motion_ratios) < 0.035:
                            errors.append(
                                f"{path.name}: lower-body motion is too small ({motion_ratios})"
                            )
                    else:
                        planted_hashes = [hashlib.sha256(alpha.tobytes()).hexdigest() for alpha in lower_alpha]
                        if len(set(planted_hashes)) != 1:
                            errors.append(f"{path.name}: idle feet must remain planted across all frames")

        for state in BATTLE_STATES:
            for index in range(1, 5):
                path = BATTLE_ROOT / style / f"lengguyun_{style}_{state}_{index:02d}.png"
                if not path.exists():
                    errors.append(f"missing battle frame: {path.relative_to(ROOT)}")
                    continue
                with Image.open(path) as image:
                    if image.size != (512, 384) or image.mode != "RGBA":
                        errors.append(f"{path.name}: got {image.mode} {image.size}, expected RGBA (512, 384)")
                        continue
                    bbox = alpha_bbox(image)
                    if bbox is None:
                        errors.append(f"{path.name}: empty alpha")
                        continue
                    bottom_margin = 384 - bbox[3]
                    if bottom_margin < 12:
                        errors.append(f"{path.name}: bottom margin {bottom_margin}, expected >=12")
                    if state == "ready":
                        ready_heights[style].append(bbox[3] - bbox[1])

    ready_medians = {
        style: sorted(values)[len(values) // 2]
        for style, values in ready_heights.items()
        if values
    }
    if len(ready_medians) == len(STYLES):
        spread = max(ready_medians.values()) - min(ready_medians.values())
        if spread > 12:
            errors.append(f"battle ready scale spread is {spread}px (>12): {ready_medians}")

    validate_staff_manifest(
        FIELD_STAFF_MANIFEST,
        FIELD_ROOT / "staff",
        ("healthy_front_skin_tone", "full_length_staff_on_back", "hands_empty", "idle_feet_planted", "no_cell_bleed"),
        errors,
    )
    validate_staff_manifest(
        BATTLE_STAFF_MANIFEST,
        BATTLE_ROOT / "staff",
        ("healthy_skin_tone", "single_long_staff", "ready_two_hand_grip", "move_two_hand_grip", "attack_two_hand_grip_all_frames", "no_cell_bleed"),
        errors,
    )

    if errors:
        print("LENGGUYUN_WEAPON_VARIANTS_V2_FAILED")
        for error in errors:
            print(f"- {error}")
        return 1
    print(f"LENGGUYUN_WEAPON_VARIANTS_V7_IDLE_PASS ready_heights={ready_medians}")
    return 0


if __name__ == "__main__":
    sys.exit(main())
