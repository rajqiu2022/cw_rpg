from __future__ import annotations

import re
import sys
from pathlib import Path

from PIL import Image


ROOT = Path(__file__).resolve().parents[1]
GAME = ROOT / "game"
ENEMY_DIR = GAME / "data" / "enemies"
REQUIRED_ENEMIES = (
    "thug_lone",
    "bandit_mountain",
    "linxi_dojo_disciple",
    "linxi_dojo_senior",
    "zhuwei_bandit",
    "boss_zhao_wuji",
    "masked_killer_ambush",
    "linxi_wild_beast",
    "wulin_examiner",
)
STATE_FIELDS = (
    "ready_frame_paths",
    "move_frame_paths",
    "attack_frame_paths",
    "hit_frame_paths",
    "defeat_frame_paths",
)


def resource_paths(text: str, field: str) -> list[str]:
    match = re.search(
        rf"^{field}\s*=\s*PackedStringArray\((.*?)\)\s*$",
        text,
        flags=re.MULTILINE,
    )
    if not match:
        return []
    return re.findall(r'"(res://[^"]+)"', match.group(1))


def main() -> int:
    errors: list[str] = []
    checked_frames = 0

    for enemy_id in REQUIRED_ENEMIES:
        path = ENEMY_DIR / f"{enemy_id}.tres"
        if not path.exists():
            errors.append(f"{enemy_id}: missing {path.relative_to(ROOT)}")
            continue

        text = path.read_text(encoding="utf-8")
        for field in STATE_FIELDS:
            paths = resource_paths(text, field)
            if len(paths) != 4:
                errors.append(f"{enemy_id}.{field}: expected 4 frames, got {len(paths)}")
                continue

            for resource_path in paths:
                checked_frames += 1
                disk_path = GAME / resource_path.removeprefix("res://")
                if not disk_path.exists():
                    errors.append(f"{enemy_id}.{field}: missing {resource_path}")
                sprite_owner = resource_path.split("/standard_v2/", 1)[-1].split("/", 1)[0]
                expected_owner = {
                    "boss_zhao_wuji": "zhao_wuji",
                    "linxi_wild_beast": "wild_wolf",
                    "linxi_dojo_disciple": "dojo_disciple",
                    "linxi_dojo_senior": "dojo_senior",
                    "masked_killer_ambush": "masked_killer",
                }.get(enemy_id, enemy_id)
                if sprite_owner != expected_owner:
                    errors.append(
                        f"{enemy_id}.{field}: references {sprite_owner}, expected {expected_owner}"
                    )

    hero_dir = GAME / "art" / "sprites" / "battle" / "standard_v4" / "lengguyun"
    for state in ("ready", "move", "attack", "hit", "defeat"):
        frames = sorted(hero_dir.glob(f"lengguyun_{state}_*.png"))
        checked_frames += len(frames)
        if len(frames) != 4:
            errors.append(f"lengguyun.{state}: expected 4 frames, got {len(frames)}")
        for frame in frames:
            with Image.open(frame) as image:
                if image.size != (512, 384):
                    errors.append(f"lengguyun.{state}: {frame.name} is {image.size}, expected 512x384")
                if image.mode != "RGBA":
                    errors.append(f"lengguyun.{state}: {frame.name} mode is {image.mode}, expected RGBA")
                    continue
                bbox = image.getchannel("A").getbbox()
                if bbox is None:
                    errors.append(f"lengguyun.{state}: {frame.name} has empty alpha")
                elif image.height - bbox[3] < 12:
                    errors.append(f"lengguyun.{state}: {frame.name} bottom margin is below 12px")

    if errors:
        print("BATTLE_SPRITE_VALIDATION_FAILED")
        for error in errors:
            print(f"- {error}")
        return 1

    print(
        "BATTLE_SPRITE_VALIDATION_PASS "
        f"combatants={len(REQUIRED_ENEMIES) + 1} frames={checked_frames}"
    )
    return 0


if __name__ == "__main__":
    sys.exit(main())
