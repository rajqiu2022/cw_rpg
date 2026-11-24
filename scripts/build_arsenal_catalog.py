#!/usr/bin/env python3
"""Build a standalone equipment and martial-arts catalogue from Godot data.

The output is intentionally self-contained so it can be opened directly from
the filesystem. Existing game artwork is referenced with paths relative to the
generated document; missing art is handled by a visible seal-style fallback.
"""

from __future__ import annotations

import argparse
import json
import re
import sys
from html import escape
from collections import defaultdict
from datetime import datetime
from pathlib import Path

from build_quest_catalog import build as build_quests, quest_state_label
from build_skill_vfx_previews import build as build_skill_vfx_previews
from build_storyline_catalog import build as build_stories
from build_resource_gallery import build as build_resource_gallery


ROOT = Path(__file__).resolve().parents[1]
GAME = ROOT / "game"
DATA = GAME / "data"
TEMPLATE = ROOT / "docs" / "equipment-skill-catalog.template.html"
OUTPUT = ROOT / "docs" / "equipment-skill-catalog.html"

SLOT_NAMES = ["兵器", "头部", "衣甲", "护手", "鞋履", "饰品"]
QUALITY_NAMES = ["白色", "绿色", "蓝色", "紫色", "橙色"]
WEAPON_NAMES = {
    "sword": "剑", "dagger": "剑", "short_blade": "剑", "short_sword": "剑",
    "blade": "刀", "axe": "刀", "dao": "刀", "staff": "棍", "palm": "掌",
    "hidden": "暗器", "ring": "暗器", "throwing": "暗器", "": "通用",
}
SCHOOL_NAMES = {
    "generic": "通用",
    "linxi": "林西",
    "wudang": "武当",
    "huashan": "华山",
    "gufeng": "古峰",
    "lingyue": "凌月",
    "mingwu": "茗雾",
    "shaolin": "少林",
    "xingyi": "行义帮",
    "wanderer": "江湖",
    "": "未归属",
}
KIND_NAMES = ["攻击", "治疗", "增益", "减益"]
TARGET_NAMES = ["单个敌人", "全体敌人", "单个队友", "全体队友", "自身"]
DELIVERY_NAMES = ["近身", "远程", "原地范围"]
MOTION_NAMES = ["自动演出", "原地施放", "近身突进", "残影穿身", "多段神影穿插"]
VFX_NAMES = {
    "linxi_sword_one": "林西剑光", "sword_arc": "基础剑弧", "heavy_cleave": "重斩冲击",
    "frost_needle": "寒霜飞针", "taiji": "太极气旋", "shadow": "隐影残光",
    "inner_aura": "内功护体", "crimson_palm": "赤焰掌劲",
    "sword_tier_1": "剑气·一阶", "sword_tier_2": "剑气·二阶", "sword_tier_3": "剑气·三阶",
    "dao_tier_1": "刀罡·一阶", "dao_tier_2": "刀罡·二阶", "dao_tier_3": "刀罡·三阶",
    "staff_tier_1": "棍风·一阶", "staff_tier_2": "棍风·二阶", "staff_tier_3": "棍风·三阶",
    "palm_tier_1": "掌劲·一阶", "palm_tier_2": "掌劲·二阶", "palm_tier_3": "掌劲·三阶",
}
STATUS_NAMES = {
    "poison": "中毒",
    "bleed": "流血",
    "weaken": "虚弱",
    "armor_break": "破防",
    "vulnerable": "易伤",
    "guard": "护体",
    "stun": "眩晕",
    "freeze": "冻结",
    "internal_lock": "内伤封招",
}
UNIQUE_VFX_NAMES = {
    "basic_attack": "掌风冲击", "canglong_three_turns": "三龙换影", "canghai_zhenyue_palms": "盘龙掌雨",
    "defend": "护体罡气",
    "huilan_redirecting_art": "移花换劲", "jingang_tempered_meridians": "易筋炼脉",
    "examiner_staff_sweep": "考校棍风", "gufeng_fuhu": "伏虎刀罡", "gufeng_jingang_buhuai": "金钟罩",
    "gufeng_jingang_li": "金刚拳劲", "gufeng_kaishan_yidao": "破岩刀光", "gufeng_liedi": "裂地刀罡",
    "heavy_swing": "重斩冲击", "huashan_jianduan_qianshan": "千山断剑", "huashan_poyun": "破云剑气",
    "huashan_yijian": "华山刚剑", "huashan_qunfeng_luozhao": "群峰剑阵", "huashan_lanhui_sandie": "岚回三剑",
    "huashan_zixia_ninggang": "紫晶凝罡", "huashan_zixia_shengong": "紫霞云气",
    "lingyue_hanshuang_wan_zhen": "寒潭棍阵", "lingyue_hanshuang_zhen": "回月棍风",
    "lingyue_lingbo_yizhi": "点星棍劲", "lingyue_tayue_lingbo": "月下踏波", "lingyue_yuehua_yin": "月华淬体",
    "linxi_basic_sword_one": "林西平剑光", "linxi_basic_sword_two": "以退为进剑痕", "linxi_inner_breath": "吐纳山岚",
    "mingwu_mingwu_bu": "雾影身法", "mingwu_saofeng": "掠影剑风", "mingwu_wuyin_sanshi": "三重雾刃",
    "mingwu_yinying_duoming": "夺命星芒", "mingwu_yinying_jue": "影身化雾", "palm_strike": "排云掌劲",
    "qinghe_jade_guard": "青木护元阵", "qinghe_returning_breath": "回春灵息", "qinghe_swallow_sword": "燕回剑弧",
    "tang_staff_breaker": "聚点棍劲", "tang_staff_sweep": "扫叶棍风", "toxic_needle": "碧毒飞针",
    "wanxiang_breaking_sword": "孤云破式", "wudang_raozhirou_sword": "绕指剑弧", "wudang_rouyun_sword": "柔云剑气", "wudang_taiji_sword": "太极剑圆",
    "wudang_mianzhang": "绵掌叠劲", "wudang_taiji_chushi": "太极引掌", "wudang_taiji_liangyi": "两仪掌劲", "wudang_taiji_sixiang": "八卦掌阵",
    "wudang_xuanwu_ge": "玄武龟蛇盾", "wudang_xuanwu_xinjing": "玄水龟息",
    "zhao_black_wind_sweep": "黑风刀卷", "zhao_broken_gate_strike": "断门赤刃",
}
SEAL_MARKS = {
    "兵器": "刃", "头部": "冠", "衣甲": "甲", "护手": "护", "鞋履": "履", "饰品": "佩",
    "通用": "武", "林西": "林", "武当": "玄", "华山": "华", "古峰": "岳", "凌月": "月",
    "茗雾": "雾", "江湖": "游", "未归属": "秘",
}


def text(path: Path) -> str:
    return path.read_text(encoding="utf-8")


def rhs(source: str, key: str) -> str:
    match = re.search(rf"(?m)^{re.escape(key)}\s*=\s*(.+)$", source)
    return match.group(1).strip() if match else ""


def string_value(source: str, key: str, default: str = "") -> str:
    value = rhs(source, key)
    match = re.match(r'&?"(.*)"$', value)
    if not match:
        return default
    return match.group(1).replace(r"\n", "\n").replace(r'\"', '"')


def int_value(source: str, key: str, default: int = 0) -> int:
    match = re.match(r"-?\d+", rhs(source, key))
    return int(match.group(0)) if match else default


def float_value(source: str, key: str, default: float = 0.0) -> float:
    match = re.match(r"-?(?:\d+(?:\.\d*)?|\.\d+)", rhs(source, key))
    return float(match.group(0)) if match else default


def bool_value(source: str, key: str, default: bool = False) -> bool:
    value = rhs(source, key)
    return value == "true" if value in {"true", "false"} else default


def string_array(source: str, key: str) -> list[str]:
    value = rhs(source, key)
    return re.findall(r'&?"([^"\\]*(?:\\.[^"\\]*)*)"', value)


def dict_entries(source: str, key: str) -> list[dict]:
    value = rhs(source, key)
    entries: list[dict] = []
    for block in re.findall(r"\{([^{}]*)\}", value):
        item_match = re.search(r'"(?:item_id|id)"\s*:\s*"([^"]+)"', block)
        if not item_match:
            continue
        count_match = re.search(r'"count"\s*:\s*(\d+)', block)
        chance_match = re.search(r'"chance"\s*:\s*([0-9.]+)', block)
        entries.append({
            "id": item_match.group(1),
            "count": int(count_match.group(1)) if count_match else 1,
            "chance": float(chance_match.group(1)) if chance_match else None,
        })
    return entries


def faction_skill_entries(source: str, key: str) -> list[tuple[str, str]]:
    """Parse a one-line Godot Dictionary of faction -> Array[StringName]."""
    value = rhs(source, key)
    entries: list[tuple[str, str]] = []
    for faction_id, skills_raw in re.findall(
        r'"([^"]+)"\s*:\s*Array\[StringName\]\(\[([^]]*)\]\)', value
    ):
        for skill_id in re.findall(r'&"([^"]+)"', skills_raw):
            entries.append((faction_id, skill_id))
    return entries


def resource_image(icon_path: str) -> tuple[str, bool]:
    if not icon_path:
        return "", False
    relative = icon_path.removeprefix("res://")
    exists = (GAME / relative).is_file()
    return f"../game/{relative.replace(chr(92), '/')}", exists


def infer_weapon_name(item_id: str, display_name: str, configured: str) -> str:
    if configured:
        return WEAPON_NAMES.get(configured, configured)
    haystack = f"{item_id} {display_name}".lower()
    rules = [
        (("needle", "dart", "镖", "针", "暗器", "飞刀"), "暗器"),
        (("staff", "棍", "杵", "棒"), "棍"),
        (("axe", "斧"), "刀"),
        (("dagger", "刺", "匕", "短剑", "短刃"), "剑"),
        (("blade", "刀", "刃"), "刀"),
        (("sword", "剑"), "剑"),
        (("ring", "轮"), "暗器"),
    ]
    for needles, label in rules:
        if any(needle in haystack for needle in needles):
            return label
    return "暗器"


def normalized_martial_category(value: str) -> str:
    return WEAPON_NAMES.get(value, value or "通用")


def is_heart_art(skill_id: str, passive: bool, kind_index: int, fixed_damage: int, attack_scaling: int) -> bool:
    """Mirror the runtime martial-panel routing contract.

    Passive techniques and non-damaging heal/buff techniques are heart arts.
    Defend remains a system action and basic attack remains a common action.
    """
    if passive:
        return True
    return skill_id != "defend" and kind_index in (1, 2) and fixed_damage <= 0 and attack_scaling <= 0


def display_context(block: str, fallback: str) -> str:
    speaker = string_value(block, "speaker")
    if speaker:
        return speaker
    body = re.sub(r"\[[^]]+\]", "", string_value(block, "text"))
    if body:
        body = re.sub(r"\s+", "", body)
        return (body[:12] + "…") if len(body) > 12 else body
    return fallback


def add_unique(target: dict[str, list[str]], item_id: str, method: str) -> None:
    if item_id and method not in target[item_id]:
        target[item_id].append(method)


def collect_equipment_acquisition(equipment_ids: set[str]) -> dict[str, list[str]]:
    found: dict[str, list[str]] = defaultdict(list)
    reachable_shops: set[str] = set()
    for folder in ("scenes", "maps", "dialogs"):
        for path in sorted((DATA / folder).glob("*.tres")):
            reachable_shops.update(re.findall(r"shop:([A-Za-z0-9_]+)", text(path)))

    for path in sorted((DATA / "shops").glob("*.tres")):
        source = text(path)
        shop_id = string_value(source, "shop_id", path.stem)
        if shop_id not in reachable_shops:
            continue
        shop_name = string_value(source, "display_name", path.stem)
        for item_id in string_array(source, "stock"):
            if item_id in equipment_ids:
                add_unique(found, item_id, f"商店购买 · {shop_name}")

    for path in sorted((DATA / "quests").glob("*.tres")):
        source = text(path)
        title = string_value(source, "title", path.stem)
        for entry in dict_entries(source, "reward_items"):
            if entry["id"] in equipment_ids:
                suffix = f" ×{entry['count']}" if entry["count"] > 1 else ""
                add_unique(found, entry["id"], f"任务奖励 · 《{title}》{suffix}")

    for path in sorted((DATA / "dialogs").glob("*.tres")):
        source = text(path)
        for block in re.split(r"(?=\n\[(?:sub_)?resource)", source):
            entries = dict_entries(block, "give_items")
            if not entries:
                continue
            context = display_context(block, path.stem)
            scene_label = "场景拾取" if any(word in path.stem for word in ("box", "chest", "supply")) else "剧情获得"
            for entry in entries:
                if entry["id"] in equipment_ids:
                    suffix = f" ×{entry['count']}" if entry["count"] > 1 else ""
                    add_unique(found, entry["id"], f"{scene_label} · {context}{suffix}")

    for path in sorted((DATA / "enemies").glob("*.tres")):
        source = text(path)
        enemy_name = string_value(source, "display_name", path.stem)
        for item_id in string_array(source, "drop_items"):
            if item_id in equipment_ids:
                add_unique(found, item_id, f"敌人必掉 · {enemy_name}")
        for entry in dict_entries(source, "drop_random"):
            if entry["id"] in equipment_ids:
                chance = round((entry["chance"] or 0) * 100)
                add_unique(found, entry["id"], f"敌人掉落 · {enemy_name}（{chance}%）")

    return found


def collect_skill_acquisition(skill_ids: set[str]) -> tuple[dict[str, list[str]], dict[str, list[str]]]:
    player: dict[str, list[str]] = defaultdict(list)
    usage: dict[str, list[str]] = defaultdict(list)
    state_source = text(GAME / "scripts" / "autoload" / "game_state.gd")

    default_match = re.search(r"var skill_ids: Array\[StringName\]\s*=\s*\[([^]]*)\]", state_source)
    if default_match:
        for skill_id in re.findall(r'&"([^"]+)"', default_match.group(1)):
            if skill_id in skill_ids:
                add_unique(player, skill_id, "主角开局自带")

    faction_names = {"wudang": "武当", "huashan": "华山", "gufeng": "古峰", "lingyue": "凌月", "mingwu": "茗雾", "wanderer": "无门派"}
    faction_block = re.search(r"const FACTION_SKILLS := \{(.*?)\n\}", state_source, re.S)
    if faction_block:
        for faction_id, skills_raw in re.findall(r'"([a-z]+)"\s*:\s*\[([^]]*)\]', faction_block.group(1)):
            for skill_id in re.findall(r'&"([^"]+)"', skills_raw):
                if skill_id in skill_ids:
                    add_unique(player, skill_id, f"加入{faction_names.get(faction_id, faction_id)}派时习得")

    for path in sorted((DATA / "dialogs").glob("*.tres")):
        source = text(path)
        for block in re.split(r"(?=\n\[(?:sub_)?resource)", source):
            context = display_context(block, path.stem)
            for skill_id in string_array(block, "learn_skills"):
                if skill_id in skill_ids:
                    add_unique(player, skill_id, f"剧情领悟 · {context}")

    for path in sorted((DATA / "quests").glob("*.tres")):
        source = text(path)
        title = string_value(source, "title", path.stem)
        for skill_id in string_array(source, "reward_skills"):
            if skill_id in skill_ids:
                add_unique(player, skill_id, f"任务领悟 · 《{title}》")
        for faction_id, skill_id in faction_skill_entries(source, "reward_skills_by_faction"):
            if skill_id in skill_ids:
                faction_name = faction_names.get(faction_id, faction_id)
                add_unique(player, skill_id, f"{faction_name}限定任务领悟 · 《{title}》")
        for flag_id, skill_id in faction_skill_entries(source, "reward_skills_by_flag"):
            if skill_id in skill_ids:
                route_names = {"wudang_route_taiji": "武当太极拳支路", "wudang_route_mian": "武当绵掌支路"}
                add_unique(player, skill_id, f"{route_names.get(flag_id, flag_id)}任务领悟 · 《{title}》")

    for path in sorted((DATA / "companions").glob("*.tres")):
        source = text(path)
        companion_name = string_value(source, "display_name", path.stem)
        for skill_id in string_array(source, "skills"):
            if skill_id in skill_ids:
                add_unique(usage, skill_id, f"队友固有 · {companion_name}")

    for path in sorted((DATA / "enemies").glob("*.tres")):
        source = text(path)
        enemy_name = string_value(source, "display_name", path.stem)
        for skill_id in string_array(source, "skill_ids"):
            if skill_id in skill_ids:
                add_unique(usage, skill_id, f"敌方使用 · {enemy_name}")

    return player, usage


def build_equipment() -> list[dict]:
    paths = sorted((DATA / "equipment").glob("*.tres"))
    ids = {string_value(text(path), "item_id", path.stem) for path in paths}
    acquisition = collect_equipment_acquisition(ids)
    rows: list[dict] = []
    for path in paths:
        source = text(path)
        item_id = string_value(source, "item_id", path.stem)
        slot = int_value(source, "slot")
        weapon_type = string_value(source, "martial_style") or string_value(source, "weapon_type")
        slot_name = SLOT_NAMES[slot] if 0 <= slot < len(SLOT_NAMES) else "装备"
        weapon_name = infer_weapon_name(item_id, string_value(source, "display_name", item_id), weapon_type)
        category = f"{slot_name} · {weapon_name}" if slot == 0 else slot_name
        quality = int_value(source, "quality")
        stats = []
        stat_fields = [
            ("atk_bonus", "攻击"), ("def_bonus", "防御"), ("hp_bonus", "气血"), ("mp_bonus", "内力"),
            ("speed_bonus", "速度"), ("str_bonus", "筋骨"), ("agi_bonus", "机敏"),
            ("inner_bonus", "内劲"), ("insight_bonus", "悟性"), ("vitality_bonus", "生命"),
            ("inner_pool_bonus", "内力池"), ("guard_bonus", "守御"),
        ]
        for field, label in stat_fields:
            value = int_value(source, field)
            if value:
                stats.append({"label": label, "value": f"{value:+d}"})
        crit_chance = float_value(source, "crit_chance_bonus")
        if crit_chance:
            stats.append({"label": "暴击率", "value": f"+{crit_chance * 100:.0f}%"})
        hit_chance = float_value(source, "hit_chance_bonus")
        if hit_chance:
            stats.append({"label": "命中率", "value": f"+{hit_chance * 100:.0f}%"})
        weapon_scaling = int_value(source, "weapon_skill_bonus_scaling")
        if weapon_scaling:
            style_label = {
                "sword": "剑法", "dagger": "剑法", "short_blade": "剑法", "short_sword": "剑法",
                "blade": "刀法", "axe": "刀法", "dao": "刀法", "staff": "棍法",
                "hidden": "暗器武功", "ring": "暗器武功", "throwing": "暗器武功", "palm": "掌法",
            }.get(weapon_type, "兵器武功")
            stats.append({"label": f"{style_label}攻击系数", "value": f"+{weapon_scaling}%"})
        bonus_school = string_value(source, "skill_bonus_school")
        bonus_power = int_value(source, "skill_bonus_scaling")
        bonus_crit = float_value(source, "skill_bonus_crit_mult")
        if bonus_power:
            school_label = "全门派武功" if bonus_school == "all" else f"{SCHOOL_NAMES.get(bonus_school, bonus_school)}武功"
            stats.append({"label": f"{school_label}攻击系数", "value": f"+{bonus_power}%"})
        if bonus_crit:
            stats.append({"label": "暴击倍率", "value": f"+{bonus_crit:.1f}×"})
        icon, icon_exists = resource_image(string_value(source, "icon_path"))
        methods = acquisition.get(item_id, [])
        special_effect = string_value(source, "special_effect_description")
        rows.append({
            "type": "equipment", "id": item_id, "name": string_value(source, "display_name", item_id),
            "category": category, "group": category, "quality": QUALITY_NAMES[quality] if quality < len(QUALITY_NAMES) else f"品质 {quality}",
            "qualityLevel": quality, "description": string_value(source, "description"), "stats": stats,
            "price": {"buy": int_value(source, "buy_price"), "sell": int_value(source, "sell_price")},
            "acquisition": methods or ["当前未配置投放（数据资源已就绪）"],
            "available": bool(methods), "icon": icon, "iconExists": icon_exists,
            "specialEffect": special_effect,
            "seal": SEAL_MARKS.get(slot_name, "装"), "source": f"game/data/equipment/{path.name}",
        })
    return rows


def build_skills() -> list[dict]:
    paths = sorted((DATA / "skills").glob("*.tres"))
    sources = {path: text(path) for path in paths}
    ids = {string_value(source, "skill_id", path.stem) for path, source in sources.items()}
    skill_names = {
        string_value(source, "skill_id", path.stem): string_value(source, "display_name", path.stem)
        for path, source in sources.items()
    }
    player_methods, usage = collect_skill_acquisition(ids)
    for source in sources.values():
        unlock = string_value(source, "mastery_unlock_skill")
        if unlock in ids:
            add_unique(player_methods, unlock, f"练至圆满 · {string_value(source, 'display_name')}")

    rows: list[dict] = []
    for path in paths:
        source = sources[path]
        skill_id = string_value(source, "skill_id", path.stem)
        school_id = string_value(source, "school")
        school = SCHOOL_NAMES.get(school_id, school_id or "未归属")
        passive = bool_value(source, "is_passive")
        kind_index = int_value(source, "kind")
        target_index = int_value(source, "target")
        delivery_index = int_value(source, "delivery")
        motion_style = int_value(source, "motion_style")
        animation_id = string_value(source, "animation_id")
        kind = KIND_NAMES[kind_index] if kind_index < len(KIND_NAMES) else f"类型 {kind_index}"
        fixed_damage = int_value(source, "fixed_damage")
        attack_scaling = int_value(source, "attack_scaling")
        heart_art = is_heart_art(skill_id, passive, kind_index, fixed_damage, attack_scaling)
        martial_category = normalized_martial_category(
            string_value(source, "martial_category") or string_value(source, "required_weapon_type")
        )
        if skill_id in {"basic_attack", "defend"}:
            martial_category = "通用"
        group = "心法" if heart_art else martial_category
        category = f"{school} · {group} · {kind}"
        quality = int_value(source, "quality")
        effect_value = int_value(source, "effect_value")
        stats = [
            {"label": "内力消耗", "value": str(int_value(source, "mp_cost"))},
            {"label": "目标", "value": TARGET_NAMES[target_index] if target_index < len(TARGET_NAMES) else str(target_index)},
            {"label": "施放", "value": DELIVERY_NAMES[delivery_index] if delivery_index < len(DELIVERY_NAMES) else str(delivery_index)},
        ]
        max_level = max(1, int_value(source, "max_level", 10))
        self_practice_cap = max(1, int_value(source, "self_practice_level_cap", max_level))
        evolves_to_skill_id = string_value(source, "evolves_to_skill_id")
        stats.append({"label": "最高境界", "value": f"{max_level}重"})
        if self_practice_cap < max_level:
            stats.append({"label": "自行修炼", "value": f"{self_practice_cap}重封顶"})
        practice_hint = string_value(source, "breakthrough_hint")
        if practice_hint:
            stats.append({"label": "行功手记", "value": practice_hint})
        attribute = string_value(source, "breakthrough_attribute")
        if attribute and attribute != "none":
            label = {"insight": "基础悟性", "inner_pool": "基础内力"}[attribute]
            stats.append({"label": "九重破境", "value": f"{label}达到 {int_value(source, 'breakthrough_attribute_min')}，可用阅历参悟"})
        if string_value(source, "breakthrough_quest"):
            stats.append({"label": "九重破境", "value": "循手记完成支线，与九重修为相印，自悟第十重"})
        unlock = string_value(source, "mastery_unlock_skill")
        if unlock:
            stats.append({"label": "满层领悟", "value": skill_names[unlock]})
        if evolves_to_skill_id:
            stats.append({
                "label": "最终突破",
                "value": skill_names.get(evolves_to_skill_id, evolves_to_skill_id),
            })
        if not heart_art:
            stats.insert(1, {"label": "段数", "value": str(int_value(source, "hit_count", 1))})
        if motion_style > 0 and motion_style < len(MOTION_NAMES):
            motion_label = MOTION_NAMES[motion_style]
        elif passive:
            motion_label = "被动心法"
        else:
            motion_label = ["近身突进", "远程投射", "原地范围"][delivery_index] if delivery_index < 3 else "自动演出"
        if animation_id == skill_id:
            vfx_label = UNIQUE_VFX_NAMES.get(skill_id, f"{string_value(source, 'display_name', skill_id)}·专属特效")
        else:
            vfx_label = VFX_NAMES.get(animation_id, animation_id or "被动心法·无释放特效")
        stats.append({"label": "角色演出", "value": motion_label})
        stats.append({"label": "招式特效", "value": vfx_label})
        if fixed_damage or attack_scaling:
            stats.insert(1, {"label": "固定伤害", "value": str(fixed_damage)})
            stats.insert(2, {"label": "攻击叠加", "value": f"{attack_scaling}%"})
            stats.insert(3, {"label": "伤害类型", "value": "内功" if int_value(source, "damage_type") == 1 else "外功"})
            stats.insert(4, {"label": "基础命中", "value": f"{float_value(source, 'base_hit_chance', 0.90) * 100:.0f}%"})
            skill_crit = float_value(source, "skill_crit_chance_bonus")
            if skill_crit:
                stats.insert(5, {"label": "招式暴击", "value": f"+{skill_crit * 100:.0f}%"})
        if effect_value:
            stats.insert(1, {"label": "固定效果", "value": str(effect_value)})
        if heart_art:
            permanent_parts: list[str] = []
            growth_parts: list[str] = []
            passive_fields = [
                ("生命", "passive_vitality_bonus", "passive_vitality_growth", 8),
                ("内功", "passive_inner_pool_bonus", "passive_inner_pool_growth", 6),
                ("筋骨", "passive_strength_bonus", "passive_strength_growth", 1),
                ("机敏", "passive_agility_bonus", "passive_agility_growth", 1),
                ("内劲", "passive_inner_power_bonus", "passive_inner_power_growth", 1),
                ("悟性", "passive_insight_bonus", "passive_insight_growth", 1),
                ("防御", "passive_guard_bonus", "passive_guard_growth", 2),
            ]
            for label, base_key, growth_key, multiplier in passive_fields:
                base_value = int_value(source, base_key) * multiplier
                growth_value = int_value(source, growth_key) * multiplier
                if base_value:
                    permanent_parts.append(f"{label} {base_value:+d}")
                if growth_value:
                    growth_parts.append(f"{label} {growth_value:+d}")
            if permanent_parts:
                stats.append({"label": "习得常驻", "value": " / ".join(permanent_parts)})
            if growth_parts:
                stats.append({"label": "每层成长", "value": " / ".join(growth_parts)})

            active_description = string_value(source, "active_effect_description")
            active_type = string_value(source, "active_effect_type")
            if not passive and (active_description or active_type or effect_value):
                stats.append({"label": "主动运功", "value": active_description or active_type})
                active_parts: list[str] = []
                active_growth = int_value(source, "active_effect_growth")
                active_duration = int_value(source, "active_duration_turns")
                active_duration_growth = int_value(source, "active_duration_growth")
                if effect_value:
                    active_parts.append(f"基础效果 {effect_value}")
                if active_growth:
                    active_parts.append(f"每层效果 +{active_growth}")
                if active_duration:
                    active_parts.append(f"持续 {active_duration} 回合")
                if active_duration_growth:
                    active_parts.append(f"每层持续 +{active_duration_growth} 回合")
                if active_parts:
                    stats.append({"label": "主动成长", "value": " / ".join(active_parts)})

            equip_categories = string_array(source, "equip_weapon_categories")
            category_names = {
                "sword": "剑系", "blade": "刀系", "staff": "棍系",
                "palm": "掌系", "hidden": "暗器", "all": "全系",
            }
            if equip_categories:
                category_label = "、".join(category_names.get(value, value) for value in equip_categories)
                scope = string_value(source, "equip_damage_scope", "all")
                scope_label = {"external": "外功", "internal": "内功"}.get(scope, "")
                stats.append({"label": "装备流派", "value": f"{category_label}{scope_label}"})

            equip_parts: list[str] = []
            equip_growth_parts: list[str] = []
            equip_scaling = int_value(source, "equip_damage_scaling_bonus")
            equip_scaling_growth = int_value(source, "equip_damage_scaling_growth")
            equip_crit = float_value(source, "equip_crit_chance_bonus")
            equip_crit_growth = float_value(source, "equip_crit_chance_growth")
            equip_injury = int_value(source, "equip_internal_injury_bonus")
            equip_injury_growth = int_value(source, "equip_internal_injury_growth")
            if equip_scaling:
                equip_parts.append(f"伤害系数 +{equip_scaling}%")
            if equip_crit:
                equip_parts.append(f"暴击率 +{equip_crit * 100:.0f}%")
            if equip_injury:
                equip_parts.append(f"内伤积累 +{equip_injury}")
            if equip_scaling_growth:
                equip_growth_parts.append(f"伤害系数 +{equip_scaling_growth}%")
            if equip_crit_growth:
                equip_growth_parts.append(f"暴击率 +{equip_crit_growth * 100:.0f}%")
            if equip_injury_growth:
                equip_growth_parts.append(f"内伤积累 +{equip_injury_growth}")
            if equip_parts:
                stats.append({"label": "装备功效", "value": " / ".join(equip_parts)})
            if equip_growth_parts:
                stats.append({"label": "装备每层", "value": " / ".join(equip_growth_parts)})

            synergy_ids = string_array(source, "synergy_skill_ids")
            if synergy_ids:
                stats.append({
                    "label": "指定招式",
                    "value": "、".join(skill_names.get(value, value) for value in synergy_ids),
                })
                synergy_parts: list[str] = []
                synergy_growth_parts: list[str] = []
                synergy_scaling = int_value(source, "synergy_damage_scaling_bonus")
                synergy_scaling_growth = int_value(source, "synergy_damage_scaling_growth")
                synergy_crit = float_value(source, "synergy_crit_chance_bonus")
                synergy_crit_growth = float_value(source, "synergy_crit_chance_growth")
                synergy_crit_multiplier = float_value(source, "synergy_crit_multiplier_bonus")
                synergy_crit_multiplier_growth = float_value(source, "synergy_crit_multiplier_growth")
                synergy_injury = int_value(source, "synergy_internal_injury_bonus")
                synergy_injury_growth = int_value(source, "synergy_internal_injury_growth")
                synergy_pierce = int_value(source, "synergy_defense_pierce_bonus")
                synergy_pierce_growth = int_value(source, "synergy_defense_pierce_growth")
                synergy_hp = int_value(source, "synergy_self_hp_restore")
                synergy_hp_growth = int_value(source, "synergy_self_hp_restore_growth")
                synergy_mp = int_value(source, "synergy_self_mp_restore")
                synergy_mp_growth = int_value(source, "synergy_self_mp_restore_growth")
                synergy_status = string_value(source, "synergy_target_status")
                synergy_status_chance = float_value(source, "synergy_target_status_chance")
                synergy_status_duration = int_value(source, "synergy_target_status_duration")
                synergy_status_value = int_value(source, "synergy_target_status_value")
                execute_threshold = float_value(source, "synergy_execute_threshold")
                execute_bonus = float_value(source, "synergy_execute_damage_bonus")
                if synergy_scaling:
                    synergy_parts.append(f"伤害系数 +{synergy_scaling}%")
                if synergy_crit:
                    synergy_parts.append(f"暴击率 +{synergy_crit * 100:.0f}%")
                if synergy_crit_multiplier:
                    synergy_parts.append(f"暴击伤害 +{synergy_crit_multiplier * 100:.0f}%")
                if synergy_injury:
                    synergy_parts.append(f"内伤积累 +{synergy_injury}")
                if synergy_pierce:
                    synergy_parts.append(f"额外破防 +{synergy_pierce}%")
                if synergy_hp:
                    synergy_parts.append(f"命中回复生命 {synergy_hp}")
                if synergy_mp:
                    synergy_parts.append(f"命中回复内力 {synergy_mp}")
                if synergy_status:
                    status_label = STATUS_NAMES.get(synergy_status, synergy_status)
                    status_text = f"{synergy_status_chance * 100:.0f}%附加{status_label}{synergy_status_duration}回合"
                    if synergy_status_value:
                        status_text += f"（{synergy_status_value}%）"
                    synergy_parts.append(status_text)
                if execute_threshold and execute_bonus:
                    synergy_parts.append(f"目标生命低于{execute_threshold * 100:.0f}%时伤害 +{execute_bonus * 100:.0f}%")
                if synergy_scaling_growth:
                    synergy_growth_parts.append(f"伤害系数 +{synergy_scaling_growth}%")
                if synergy_crit_growth:
                    synergy_growth_parts.append(f"暴击率 +{synergy_crit_growth * 100:.0f}%")
                if synergy_crit_multiplier_growth:
                    synergy_growth_parts.append(f"暴击伤害 +{synergy_crit_multiplier_growth * 100:.0f}%")
                if synergy_injury_growth:
                    synergy_growth_parts.append(f"内伤积累 +{synergy_injury_growth}")
                if synergy_pierce_growth:
                    synergy_growth_parts.append(f"额外破防 +{synergy_pierce_growth}%")
                if synergy_hp_growth:
                    synergy_growth_parts.append(f"命中回复生命 +{synergy_hp_growth}")
                if synergy_mp_growth:
                    synergy_growth_parts.append(f"命中回复内力 +{synergy_mp_growth}")
                if synergy_parts:
                    stats.append({"label": "招式协同", "value": " / ".join(synergy_parts)})
                if synergy_growth_parts:
                    stats.append({"label": "协同每层", "value": " / ".join(synergy_growth_parts)})

            equipped_description = string_value(source, "equipped_effect_description")
            if equipped_description:
                stats.append({"label": "装备说明", "value": equipped_description})
        weapon = string_value(source, "required_weapon_type")
        if weapon:
            stats.append({"label": "武器需求", "value": WEAPON_NAMES.get(weapon, weapon)})
        complement = string_value(source, "complemented_by")
        if complement and not string_value(source, "breakthrough_internal_art"):
            bonus = int_value(source, "complement_bonus_scaling")
            stats.append({"label": "装备互补心法", "value": skill_names.get(complement, complement)})
            if bonus:
                stats.append({"label": "互补攻击系数", "value": f"+{bonus}%"})
        status_id = string_value(source, "inflicted_status")
        status_chance = float_value(source, "status_chance")
        status_duration = int_value(source, "status_duration")
        internal_injury = int_value(source, "internal_injury_gain")
        status_parts: list[str] = []
        if status_id:
            status_name = STATUS_NAMES.get(status_id, status_id)
            stats.append({"label": "附加状态", "value": status_name})
            if status_chance:
                stats.append({"label": "触发概率", "value": f"{status_chance * 100:.0f}%"})
            if status_duration:
                stats.append({"label": "持续回合", "value": str(status_duration)})
            status_parts.append(
                f"{status_chance * 100:.0f}%概率附加{status_name}，持续{status_duration}回合"
                if status_chance and status_duration else f"附加{status_name}"
            )
        if int_value(source, "damage_type") == 1 and (fixed_damage or attack_scaling):
            injury_value = internal_injury or (12 + quality * 4)
            stats.append({"label": "内伤积累", "value": f"+{injury_value}"})
            status_parts.append(f"命中积累{injury_value}点内伤；满100触发两回合封招")
        icon, icon_exists = resource_image(string_value(source, "icon_path"))
        methods = player_methods.get(skill_id, [])
        use_methods = usage.get(skill_id, [])
        acquisition = list(methods)
        if not acquisition and use_methods:
            acquisition = use_methods + ["暂未配置主角学习途径"]
        if not acquisition:
            acquisition = ["当前未配置获得方式（武学数据已就绪）"]
        rows.append({
            "type": "skill", "id": skill_id, "name": string_value(source, "display_name", skill_id),
            "category": category, "group": group, "passive": passive, "heartArt": heart_art,
            "quality": QUALITY_NAMES[quality] if quality < len(QUALITY_NAMES) else f"品质 {quality}",
            "qualityLevel": quality, "description": string_value(source, "description"), "stats": stats,
            "price": None, "acquisition": acquisition, "available": bool(methods), "usage": use_methods,
            "icon": icon, "iconExists": icon_exists, "seal": SEAL_MARKS.get(school, "武"),
            "animationId": animation_id, "effectName": vfx_label, "motionStyle": motion_style,
            "specialEffect": "；".join(status_parts),
            "motionLabel": motion_label,
            "effectPreview": f"assets/skill-vfx/{animation_id}.webp" if animation_id else "",
            "effectPreviewExists": bool(animation_id and (ROOT / "docs" / "assets" / "skill-vfx" / f"{animation_id}.webp").is_file()),
            "source": f"game/data/skills/{path.name}",
        })
    return rows


def validate_unique_display_names(rows: list[dict], label: str) -> None:
    grouped: dict[str, list[str]] = defaultdict(list)
    for row in rows:
        grouped[row["name"].strip()].append(row["id"])
    duplicates = {name: ids for name, ids in grouped.items() if not name or len(ids) > 1}
    if duplicates:
        details = "; ".join(f"{name or '<empty>'}: {', '.join(ids)}" for name, ids in duplicates.items())
        raise ValueError(f"duplicate {label} display names: {details}")


def validate_skill_previews(skills: list[dict], allow_missing_previews: bool = False) -> None:
    # Preserve the strict attack/support-preview contract: passive arts and
    # internal arts are exempt, not mislabeled as unfinished attack artwork.
    for row in skills:
        row["effectPreviewMissing"] = bool(
            not row["passive"] and not row["heartArt"] and not row["effectPreviewExists"]
        )
    missing = [row["id"] for row in skills if row["effectPreviewMissing"]]
    if not missing:
        return
    message = f"active skills missing VFX previews: {', '.join(missing)}"
    if not allow_missing_previews:
        raise ValueError(message)
    print(f"WARNING: {message} (diagnostic export: --allow-missing-previews)", file=sys.stderr)


def render_static_card(item: dict, index: int) -> str:
    quality_colors = ["#aeb8b5", "#7ecb8d", "#71acd7", "#b08adb", "#dfb65c"]
    quality_index = max(0, min(int(item["qualityLevel"]), len(quality_colors) - 1))
    color = quality_colors[quality_index]
    if item["iconExists"]:
        icon = (
            f'<img src="{escape(item["icon"], quote=True)}" '
            f'alt="{escape(item["name"], quote=True)}图标" loading="lazy">'
        )
        icon_class = "has-image"
        art_note = ""
    else:
        icon = ""
        icon_class = ""
        art_note = '<span class="art-note">篆印占位</span>'
    stats = "".join(
        f'<div class="stat"><span>{escape(str(stat["label"]))}</span><b>{escape(str(stat["value"]))}</b></div>'
        for stat in item["stats"]
    ) or '<div class="stat"><span>属性</span><b>暂无数值</b></div>'
    prices = ""
    if item["price"] is not None:
        prices = f'<span class="badge">买 {item["price"]["buy"]} / 售 {item["price"]["sell"]}</span>'
    methods = "".join(
        f'<li class="{"unavailable" if "未配置" in method or "暂未" in method else ""}">{escape(method)}</li>'
        for method in item["acquisition"]
    )
    effect_preview = ""
    if item["type"] == "skill" and item.get("effectPreviewExists"):
        effect_preview = (
            f'<figure class="skill-vfx-preview"><img src="{escape(item["effectPreview"], quote=True)}" '
            f'alt="{escape(item["name"], quote=True)}招式特效动态预览" loading="lazy">'
            f'<figcaption><span>{escape(item["effectName"])}</span><b>{escape(item["motionLabel"])}</b></figcaption></figure>'
        )
    elif item["type"] == "skill" and item.get("effectPreviewMissing"):
        effect_preview = '<p class="desc"><span class="badge quality">特效待补 · 尚无动态预览</span></p>'
    special_effect = ""
    if item.get("specialEffect"):
        special_effect = f'<div class="special-effect"><span>特殊效果</span>{escape(item["specialEffect"])}</div>'
    return f'''<article class="card" data-type="{item["type"]}" data-group="{escape(item["group"], quote=True)}" style="--quality-color:{color};animation-delay:{min(index, 18) * 24}ms">
      <header class="card-head"><div class="icon {icon_class}">{icon}<span class="fallback" aria-hidden="true">{escape(item["seal"])}</span>{art_note}</div>
      <div><p class="kicker">{"装备" if item["type"] == "equipment" else "武学"} · {escape(item["category"])}</p><h3>{escape(item["name"])}</h3><p class="item-id">{escape(item["id"])}</p><div class="badges"><span class="badge quality">{escape(item["quality"])}</span><span class="badge">{escape(item["group"])}</span>{prices}</div></div></header>
      {effect_preview}<p class="desc">{escape(item["description"] or "暂无说明。")}</p><div class="stats">{stats}</div>{special_effect}
      <section class="acquisition"><h4>获得方式</h4><ul>{methods}</ul></section><div class="source">{escape(item["source"])}</div></article>'''


def render_static_quest_card(quest: dict, index: int) -> str:
    maps = "".join(f"<span>{escape(name)}</span>" for name in quest["maps"]) or "<span>未关联地图</span>"
    starts = "".join(
        f'<li><strong>{escape(node["label"])}</strong><small>{escape(node["text"] or "无节点摘要")}</small></li>'
        for node in quest["starts"]
    )
    triggers = "".join(
        f'<li><strong>{escape(trigger["label"])}</strong><small><code>{escape(trigger["raw"])}</code></small></li>'
        for trigger in quest["triggers"]
    )
    finishes = "".join(
        f'<li><strong>{escape(node["label"])}</strong><small>{escape(node["text"] or "无节点摘要")}</small></li>'
        for node in quest["finishes"]
    ) or '<li><strong>自动结算</strong><small>满足完成条件后由 QuestManager 结算</small></li>'
    rewards: list[str] = []
    if quest["rewards"]["gold"]:
        rewards.append(f'{quest["rewards"]["gold"]} 金')
    if quest["rewards"]["exp"]:
        rewards.append(f'{quest["rewards"]["exp"]} 经验')
    rewards.extend(f'{item["name"]} ×{item["count"]}' for item in quest["rewards"]["items"])
    reward_text = " · ".join(rewards) or "无数值奖励"
    state_label = quest_state_label(quest)
    return f'''<article class="card quest-card" data-type="quest" data-group="{escape(quest["chapter"], quote=True)}" style="--quality-color:#d2b873;animation-delay:{min(index, 18) * 24}ms">
      <header class="card-head"><div class="icon quest-seal"><span class="fallback" aria-hidden="true">卷</span></div>
      <div><p class="kicker">任务 · {escape(quest["chapter"])} · {escape(quest["kind"])}</p><h3>{escape(quest["title"])}</h3><p class="item-id">{escape(quest["id"])}</p>
      <div class="badges"><span class="badge quality">{escape(state_label)}</span><span class="badge">{escape(quest["kind"])}</span></div></div></header>
      <p class="desc">{escape(quest["descriptions"]["active"] or "暂无进行中说明。")}</p><div class="quest-maps">{maps}</div>
      <div class="quest-flow">
        <section><h4>壹 · 接取</h4><ul>{starts}</ul></section>
        <section><h4>贰 · 条件</h4><ul>{triggers}</ul></section>
        <section><h4>叁 · 结案</h4><ul>{finishes}</ul></section>
      </div>
      <div class="quest-reward"><span>奖励</span><strong>{escape(reward_text)}</strong></div>
      <div class="source">{escape(quest["source"])}</div></article>'''


def render_static_story_card(story: dict, index: int) -> str:
    status_class = "implemented" if story["available"] else "planned"
    regions = "".join(f"<span>{escape(region)}</span>" for region in story["regions"])
    route_maps = "".join(
        f'<li><strong>{escape(scene["name"])}</strong><code>{escape(scene["id"])}</code></li>'
        for scene in story["maps"]
    )
    map_route = (
        f'<ol class="story-map-route">{route_maps}</ol>'
        if route_maps
        else '<div class="story-map-planned">规划区域尚未建立 SceneScript；地图 ID 将在章节制作时补入。</div>'
    )
    characters = "".join(
        f'<li><strong>{escape(character["name"])}</strong><small>{escape(character["role"])}</small></li>'
        for character in story["characters"]
    )
    actions = "".join(f"<li>{escape(action)}</li>" for action in story["playerActions"])
    stages = "".join(
        f'''<li class="story-stage {"branch" if stage["branch"] else ""}">
          <span class="stage-mark">{"支" if stage["branch"] else str(stage_index + 1).zfill(2)}</span>
          <div><div class="stage-title"><strong>{escape(stage["title"])}</strong><code>{escape(stage["id"])}</code></div>
          <p>{escape(stage["summary"] or "暂无节点摘要。")}</p>
          <small>{escape(" · ".join(stage["maps"] or stage["triggers"]) or "任务资源已接入")}</small></div></li>'''
        for stage_index, stage in enumerate(story["stages"] + story["branchStages"])
    )
    if story["plannedStages"]:
        stages = "".join(
            f'<li class="story-stage planned"><span class="stage-mark">{stage_index + 1:02d}</span><div><div class="stage-title"><strong>{escape(title)}</strong></div><p>新版剧情节点，等待场景、对话与任务资源接入。</p></div></li>'
            for stage_index, title in enumerate(story["plannedStages"])
        )
    choices = "".join(
        f'''<section class="choice-block"><header><span>抉择 {choice_index + 1:02d}</span><h4>{escape(choice["title"])}</h4></header>
          <p class="choice-prompt">{escape(choice["prompt"])}</p>
          <div class="choice-options">{"".join(f'<article><b>{escape(option["text"])}</b><p>{escape(option["impact"])}</p></article>' for option in choice["options"])}</div>
          <p class="converges"><span>汇流</span>{escape(choice["converges"])}</p></section>'''
        for choice_index, choice in enumerate(story["choices"])
    ) or f'<div class="choice-empty">{escape(story["choiceNote"])}</div>'
    sources = " · ".join(story["sources"])
    design_gap = f'<div class="design-gap"><span>设计缺口</span>{escape(story["designGap"])}</div>' if story.get("designGap") else ""
    migration = ""
    if story["legacyQuestCount"]:
        migration = f'<div class="migration-note">检测到 {story["legacyQuestCount"]} 个同章旧任务定义，可在任务卷宗的「兼容旧线」中查阅。</div>'
    return f'''<article class="card story-card {status_class}" data-type="story" data-group="{escape(story["group"], quote=True)}" style="--quality-color:{"#78c9bd" if story["available"] else "#d2b873"};animation-delay:{min(index, 12) * 34}ms">
      <header class="story-head"><div class="chapter-number"><span>第</span><b>{story["number"]}</b><span>章</span></div>
        <div><p class="kicker">主线篇章 · 案卷：{escape(story.get("caseName", story["title"]))}</p><h3>{escape(story["title"])}</h3><p class="story-subtitle">{escape(story["subtitle"])}</p>
        <div class="badges"><span class="badge quality">{escape(story["statusLabel"])}</span><span class="badge">{len(story["stages"])} 个实装节点</span><span class="badge">{story["choiceCount"]} 处关键抉择</span></div></div></header>
      <div class="story-thesis"><section><span>本章目标</span><p>{escape(story["objective"])}</p></section><section><span>章末疑问</span><p>{escape(story["chapterQuestion"])}</p></section></div>
      <div class="quest-maps story-regions">{regions}</div>{map_route}{design_gap}{migration}
      <div class="story-columns"><section><h4>遇见角色</h4><ul class="character-list">{characters}</ul></section><section><h4>主角可以做什么</h4><ul class="action-list">{actions}</ul></section></div>
      <section class="story-timeline"><div class="section-heading"><span>剧情推进</span><small>{"当前可玩流程" if story["available"] else "新版策划节点"}</small></div><ol>{stages}</ol></section>
      <section class="story-choices"><div class="section-heading"><span>分支选择与后果</span><small>{escape(story["choiceNote"])}</small></div>{choices}</section>
      <div class="source">{escape(sources)}</div></article>'''


def catalogue_quests() -> list[dict]:
    quests = build_quests()
    for quest in quests:
        quest.update({
            "type": "quest",
            "name": quest["title"],
            "group": quest["chapter"],
            "category": "兼容旧线" if quest.get("retired") else ("规划已处理" if quest.get("resolved") else quest["kind"]),
            "available": quest["linked"],
        })
    return quests


def main(argv: list[str] | None = None) -> None:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--allow-missing-previews", action="store_true",
                        help="诊断导出：明确标记缺失的主动招式预览；默认仍严格拒绝")
    parser.add_argument("--sync-resources-only", action="store_true",
                        help="仅同步分类资源库及缩略图，保留现有装备/招式/任务/剧情数据")
    parser.add_argument("--sync-story-only", action="store_true",
                        help="同步剧情和任务，保留现有武学预览和资源图库")
    args = parser.parse_args(argv)
    if args.sync_resources_only or args.sync_story_only:
        match = re.search(r'<script id="catalogData" type="application/json">(.*?)</script>',
                          text(OUTPUT), re.DOTALL)
        if not match:
            raise ValueError("Existing catalogData is required for --sync-resources-only")
        payload = json.loads(match.group(1))
        if args.sync_resources_only:
            payload["resources"] = build_resource_gallery()
        if args.sync_story_only:
            quests = catalogue_quests()
            stories = build_stories()
            payload.update(quests=quests, stories=stories, generatedAt=datetime.now().strftime("%Y-%m-%d %H:%M"))
            payload["summary"].update(quests=len(quests), stories=len(stories),
                                      questsLinked=sum(q["linked"] for q in quests),
                                      storiesImplemented=sum(s["available"] for s in stories),
                                      storyChoices=sum(s["choiceCount"] for s in stories))
        write_catalog(payload)
        return
    build_skill_vfx_previews()
    equipment = build_equipment()
    skills = build_skills()
    quests = catalogue_quests()
    stories = build_stories()
    validate_unique_display_names(equipment, "equipment")
    validate_unique_display_names(skills, "skill")
    # 主动心法可能只有数值/状态演出，不强制要求一套攻击型 VFX 预览。
    # 攻击、治疗与减益招式仍必须有动态预览，防止网页把缺失素材静默隐藏。
    validate_skill_previews(skills, allow_missing_previews=args.allow_missing_previews)
    payload = {
        "generatedAt": datetime.now().strftime("%Y-%m-%d %H:%M"),
        "equipment": equipment,
        "skills": skills,
        "quests": quests,
        "stories": stories,
        "summary": {
            "equipment": len(equipment), "skills": len(skills), "quests": len(quests), "stories": len(stories),
            "equipmentIcons": sum(row["iconExists"] for row in equipment),
            "skillIcons": sum(row["iconExists"] for row in skills),
            "skillEffectPreviews": sum(row["effectPreviewExists"] for row in skills),
            "equipmentAvailable": sum(row["available"] for row in equipment),
            "skillsAvailable": sum(row["available"] for row in skills),
            "questsLinked": sum(row["linked"] for row in quests),
            "storiesImplemented": sum(row["available"] for row in stories),
            "storyChoices": sum(row["choiceCount"] for row in stories),
        },
    }
    payload["resources"] = build_resource_gallery()
    write_catalog(payload)


def write_catalog(payload: dict) -> None:
    equipment, skills, quests, stories = (payload[key] for key in ["equipment", "skills", "quests", "stories"])
    encoded = json.dumps(payload, ensure_ascii=False, separators=(",", ":")).replace("</", "<\\/")
    static_cards = "\n".join(render_static_card(item, index) for index, item in enumerate(equipment + skills))
    static_cards += "\n" + "\n".join(
        render_static_quest_card(quest, index + len(equipment) + len(skills))
        for index, quest in enumerate(quests)
    )
    static_cards += "\n" + "\n".join(
        render_static_story_card(story, index + len(equipment) + len(skills) + len(quests))
        for index, story in enumerate(stories)
    )
    replacements = {
        "__CATALOG_DATA__": encoded,
        "__RESOURCE_GALLERY_STYLE__": text(ROOT / "docs/assets/resource-gallery.css"),
        "__RESOURCE_GALLERY_SCRIPT__": text(ROOT / "docs/assets/resource-gallery.js"),
        "__STATIC_CARDS__": static_cards,
        "__EQUIPMENT_TOTAL__": str(payload["summary"]["equipment"]),
        "__SKILL_TOTAL__": str(payload["summary"]["skills"]),
        "__QUEST_TOTAL__": str(payload["summary"]["quests"]),
        "__QUEST_LINKED_TOTAL__": str(payload["summary"]["questsLinked"]),
        "__STORY_TOTAL__": str(payload["summary"]["stories"]),
        "__STORY_IMPLEMENTED_TOTAL__": str(payload["summary"]["storiesImplemented"]),
        "__STORY_CHOICE_TOTAL__": str(payload["summary"]["storyChoices"]),
        "__AVAILABLE_TOTAL__": str(payload["summary"]["equipmentAvailable"] + payload["summary"]["skillsAvailable"]),
        "__ICON_TOTAL__": str(payload["summary"]["equipmentIcons"] + payload["summary"]["skillIcons"]),
        "__RESULT_TOTAL__": str(len(equipment) + len(skills) + len(quests) + len(stories)),
        "__GENERATED_AT__": payload["generatedAt"],
    }
    html = text(TEMPLATE)
    for marker, value in replacements.items():
        html = html.replace(marker, value)
    OUTPUT.write_text(html, encoding="utf-8", newline="\n")
    print(
        f"Wrote {OUTPUT.relative_to(ROOT)}: {len(equipment)} equipment, "
        f"{len(skills)} skills, {len(quests)} quests, {len(stories)} story chapters"
    )


if __name__ == "__main__":
    main()
