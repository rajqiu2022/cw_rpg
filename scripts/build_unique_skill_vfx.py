#!/usr/bin/env python3
"""Build one dedicated 2x2 four-frame VFX sheet for every martial art."""

from __future__ import annotations

import shutil
from pathlib import Path

from PIL import Image


ROOT = Path(__file__).resolve().parents[1]
GAME = ROOT / "game"
RAW = ROOT / "assets" / "raw" / "battle_vfx" / "unique_skill_v1"
OUTPUT = GAME / "art" / "battle_vfx" / "skill_unique_v1"


# Existing sheets are retained only where their visual language already matches
# the move. No source is assigned to more than one skill.
EXISTING: dict[str, str] = {
    "basic_attack": "res://art/battle_vfx/weapon_tiers_v1/vfx_palm_tier1_4frame_v1.png",
    "defend": "res://art/battle_vfx/vfx_inner_aura_4frame_v1.png",
    "examiner_staff_sweep": "res://art/battle_vfx/weapon_tiers_v1/vfx_staff_tier3_4frame_v1.png",
    "gufeng_fuhu": "res://art/battle_vfx/weapon_tiers_v1/vfx_dao_tier2_4frame_v1.png",
    "gufeng_kaishan_yidao": "res://art/battle_vfx/weapon_tiers_v1/vfx_dao_tier1_4frame_v1.png",
    "gufeng_liedi": "res://art/battle_vfx/weapon_tiers_v1/vfx_dao_tier3_4frame_v1.png",
    "heavy_swing": "res://art/battle_vfx/vfx_heavy_cleave_4frame_v1.png",
    "huashan_jianduan_qianshan": "res://art/battle_vfx/weapon_tiers_v1/vfx_sword_tier3_4frame_v1.png",
    "huashan_poyun": "res://art/battle_vfx/weapon_tiers_v1/vfx_sword_tier2_4frame_v1.png",
    "huashan_yijian": "res://art/battle_vfx/weapon_tiers_v1/vfx_sword_tier1_4frame_v1.png",
    "lingyue_hanshuang_zhen": "res://art/battle_vfx/vfx_frost_needle_4frame_v1.png",
    "linxi_basic_sword_one": "res://art/battle_vfx/vfx_linxi_sword_one_4frame_v1.png",
    "mingwu_mingwu_bu": "res://art/battle_vfx/vfx_shadow_4frame_v1.png",
    "palm_strike": "res://art/battle_vfx/weapon_tiers_v1/vfx_palm_tier2_4frame_v1.png",
    "qinghe_swallow_sword": "res://art/battle_vfx/vfx_sword_arc_4frame_v1.png",
    "tang_staff_breaker": "res://art/battle_vfx/weapon_tiers_v1/vfx_staff_tier2_4frame_v1.png",
    "tang_staff_sweep": "res://art/battle_vfx/weapon_tiers_v1/vfx_staff_tier1_4frame_v1.png",
    "wudang_taiji_chushi": "res://art/battle_vfx/weapon_tiers_v1/vfx_palm_tier1_4frame_v1.png",
    "wudang_mianzhang": "res://art/battle_vfx/vfx_crimson_palm_4frame_v1.png",
}

# IDs retained for save compatibility can change martial family. These copies run
# after the old source atlases so the runtime art follows the new palm/staff role.
STYLE_OVERRIDES: dict[str, str] = {
    "wudang_taiji_liangyi": "res://art/battle_vfx/weapon_tiers_v1/vfx_palm_tier3_4frame_v1.png",
    "wudang_taiji_sixiang": "res://art/battle_vfx/weapon_tiers_v1/vfx_palm_tier2_4frame_v1.png",
    "lingyue_lingbo_yizhi": "res://art/battle_vfx/weapon_tiers_v1/vfx_staff_tier1_4frame_v1.png",
    "lingyue_hanshuang_zhen": "res://art/battle_vfx/weapon_tiers_v1/vfx_staff_tier2_4frame_v1.png",
    "lingyue_hanshuang_wan_zhen": "res://art/battle_vfx/weapon_tiers_v1/vfx_staff_tier3_4frame_v1.png",
}


# Each alpha atlas row is one skill and each column is an animation stage.
GENERATED_ATLASES: dict[str, list[str]] = {
    "atlas_inner_alpha.png": [
        "gufeng_jingang_buhuai", "gufeng_jingang_li",
        "huashan_zixia_ninggang", "huashan_zixia_shengong",
    ],
    "atlas_heal_moon_alpha.png": [
        "qinghe_returning_breath", "qinghe_jade_guard",
        "lingyue_tayue_lingbo", "lingyue_yuehua_yin",
    ],
    "atlas_needles_canglong_alpha.png": [
        "lingyue_hanshuang_wan_zhen", "lingyue_lingbo_yizhi",
        "toxic_needle", "canglong_three_turns",
    ],
    "atlas_shadow_alpha.png": [
        "mingwu_saofeng", "mingwu_wuyin_sanshi",
        "mingwu_yinying_duoming", "mingwu_yinying_jue",
    ],
    "atlas_wudang_alpha.png": [
        "wudang_taiji_liangyi", "wudang_taiji_sixiang",
        "wudang_xuanwu_ge", "wudang_xuanwu_xinjing",
    ],
    "atlas_misc_alpha.png": [
        "linxi_basic_sword_two", "linxi_inner_breath",
        "zhao_black_wind_sweep", "zhao_broken_gate_strike",
    ],
    "atlas_legendary_alpha_v1.png": [
        "wanxiang_breaking_sword", "canghai_zhenyue_palms",
        "jingang_tempered_meridians", "huilan_redirecting_art",
    ],
}


def _res_path(path: str) -> Path:
    return GAME / path.removeprefix("res://")


def _sheet_path(skill_id: str) -> Path:
    return OUTPUT / f"vfx_{skill_id}_4frame_v1.png"


def _fit_square(frame: Image.Image, size: int = 384) -> Image.Image:
    rgba = frame.convert("RGBA")
    rgba.thumbnail((size, size), Image.Resampling.LANCZOS)
    square = Image.new("RGBA", (size, size), (0, 0, 0, 0))
    square.alpha_composite(rgba, ((size - rgba.width) // 2, (size - rgba.height) // 2))
    return square


def _render_generated_row(atlas: Image.Image, row_index: int, row_count: int, skill_id: str) -> None:
    frames: list[Image.Image] = []
    for column in range(4):
        left = round(column * atlas.width / 4)
        right = round((column + 1) * atlas.width / 4)
        top = round(row_index * atlas.height / row_count)
        bottom = round((row_index + 1) * atlas.height / row_count)
        frames.append(_fit_square(atlas.crop((left, top, right, bottom))))
    sheet = Image.new("RGBA", (768, 768), (0, 0, 0, 0))
    for index, frame in enumerate(frames):
        sheet.alpha_composite(frame, ((index % 2) * 384, (index // 2) * 384))
    sheet.save(_sheet_path(skill_id), optimize=True)


def build() -> list[Path]:
    OUTPUT.mkdir(parents=True, exist_ok=True)
    written: list[Path] = []
    for skill_id, source in EXISTING.items():
        source_path = _res_path(source)
        if not source_path.is_file():
            raise FileNotFoundError(source_path)
        destination = _sheet_path(skill_id)
        shutil.copy2(source_path, destination)
        written.append(destination)
    for atlas_name, skill_ids in GENERATED_ATLASES.items():
        atlas_path = RAW / atlas_name
        if not atlas_path.is_file():
            raise FileNotFoundError(atlas_path)
        with Image.open(atlas_path) as source:
            atlas = source.convert("RGBA")
        for row_index, skill_id in enumerate(skill_ids):
            _render_generated_row(atlas, row_index, len(skill_ids), skill_id)
            written.append(_sheet_path(skill_id))
    for skill_id, source in STYLE_OVERRIDES.items():
        shutil.copy2(_res_path(source), _sheet_path(skill_id))
    unique_written = sorted(set(written))
    if len(unique_written) != 47:
        raise ValueError(f"expected 47 unique skill sheets, got {len(unique_written)}")
    return unique_written


if __name__ == "__main__":
    files = build()
    print(f"Wrote {len(files)} dedicated skill VFX sheets to {OUTPUT.relative_to(ROOT)}")
