"""Apply the 2026-08 weapon identity and power-budget pass.

This is intentionally data-only: item ids and save compatibility stay unchanged.
Run from the repository root with ``python scripts/rebalance_weapon_stats.py``.
"""

from __future__ import annotations

import re
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]
EQUIPMENT_DIR = ROOT / "game" / "data" / "equipment"


def weapon(quality: int, weapon_type: str, atk: int, *, defense: int = 0,
           speed: int = 0, strength: int = 0, agility: int = 0,
           inner: int = 0, insight: int = 0, guard: int = 0,
           crit: float = 0.0, scaling: int | None = None) -> dict[str, object]:
    row: dict[str, object] = {
        "quality": quality,
        "weapon_type": weapon_type,
        "atk_bonus": atk,
        "def_bonus": defense,
        "speed_bonus": speed,
        "str_bonus": strength,
        "agi_bonus": agility,
        "inner_bonus": inner,
        "insight_bonus": insight,
        "guard_bonus": guard,
        "crit_chance_bonus": crit,
        "weapon_skill_bonus_scaling": (4, 6, 10, 15, 22)[quality],
    }
    if scaling is not None:
        row["skill_bonus_scaling"] = scaling
    return row


# Quality budget: common 10+, uncommon 14+, rare 22+, epic 34+, legendary 50+ ATK.
# Swords/daggers trade some attack for speed and crit; blades/axes trade speed for
# the highest attack and defense; staves sit between both; hidden weapons are fast.
WEAPONS: dict[str, dict[str, object]] = {
    "iron_sword": weapon(0, "sword", 10, speed=1, agility=1, crit=.03),
    "linxi_iron_sword": weapon(1, "sword", 16, speed=2, agility=2, crit=.06, scaling=12),
    "sharp_steel_sword": weapon(1, "sword", 17, speed=2, agility=1, crit=.05),
    "steel_longsword": weapon(1, "sword", 15, speed=3, agility=2, crit=.06),
    "huashan_quick_sword": weapon(2, "sword", 24, speed=4, agility=3, crit=.10),
    "huashan_sword": weapon(2, "sword", 22, speed=5, agility=3, crit=.12, scaling=12),
    "wudang_pine_sword": weapon(2, "sword", 25, speed=4, agility=3, inner=2, crit=.10, scaling=10),
    "wudang_sword": weapon(2, "sword", 23, speed=4, agility=3, inner=2, crit=.09),
    "heavy_iron_sword": weapon(3, "sword", 44, defense=6, speed=-2, strength=3, guard=2, crit=.03),
    "qingming_sword": weapon(3, "sword", 40, speed=6, agility=4, inner=3, crit=.16),
    "huashan_zixia_sword": weapon(3, "sword", 38, speed=6, agility=4, insight=2, crit=.18, scaling=18),
    "wudang_taiji_sword": weapon(3, "sword", 40, defense=4, speed=5, agility=3, inner=4, crit=.16, scaling=18),
    "yuanming_sword": weapon(3, "sword", 42, speed=7, strength=2, agility=4, inner=3, insight=3, crit=.18, scaling=12),
    "seven_star_sword": weapon(4, "sword", 60, defense=3, speed=9, strength=2, agility=5, inner=2, insight=3, crit=.25, scaling=12),
    "zhouju_bronze_sword": weapon(4, "sword", 66, speed=10, agility=6, insight=4, crit=.28, scaling=24),

    "lingyue_dagger": weapon(2, "dagger", 22, speed=7, agility=4, crit=.14),
    "mingwu_dagger": weapon(2, "dagger", 23, speed=5, agility=3, crit=.15, scaling=10),
    "hidden_edge": weapon(2, "dagger", 27, speed=7, agility=4, crit=.18, scaling=18),
    "shadow_dagger": weapon(2, "dagger", 24, speed=7, agility=4, crit=.17),
    "assassin_blade": weapon(3, "dagger", 38, speed=8, agility=5, crit=.22),

    "gufeng_blade": weapon(2, "blade", 28, defense=3, strength=3, guard=2, scaling=12),
    "gufeng_diamond_blade": weapon(3, "blade", 44, defense=6, strength=5, guard=3, scaling=22),
    "hanjia_canal_blade": weapon(2, "blade", 30, defense=4, strength=3, guard=2),
    "iron_great_blade": weapon(2, "blade", 32, defense=3, strength=3, guard=2),
    "kaishan_war_axe": weapon(3, "axe", 48, defense=7, strength=6, guard=3),
    "liuyun_soul_devourer": weapon(3, "blade", 43, defense=4, strength=3, inner=4, guard=2),
    "tiger_roar_blade": weapon(2, "blade", 34, defense=4, strength=4, guard=2),
    "thousand_year_shadow": weapon(3, "blade", 45, defense=2, strength=2, guard=1, crit=.08),

    "wooden_staff": weapon(1, "staff", 15, defense=3, strength=2, guard=2),
    "bronze_ring_staff": weapon(2, "staff", 26, defense=4, strength=3, guard=2),
    "iron_staff": weapon(2, "staff", 25, defense=5, strength=3, guard=3),
    "shaolin_fahua_staff": weapon(2, "staff", 28, defense=5, strength=3, inner=2, guard=3),
    "dragon_tendon_staff": weapon(3, "staff", 40, defense=6, strength=5, inner=3, guard=3),
    "golden_hoop_staff": weapon(4, "staff", 58, defense=9, strength=7, guard=5),
    "buddha_subduing_staff": weapon(4, "staff", 58, defense=10, strength=7, inner=5, guard=4),
    "heaven_piercing_staff": weapon(4, "staff", 62, defense=8, strength=5, agility=3, inner=4, insight=3, guard=4),

    "frost_dart": weapon(2, "hidden", 25, speed=6, agility=4, crit=.12, scaling=16),
    "silver_moon_needle": weapon(2, "hidden", 23, speed=8, agility=5, crit=.15, scaling=12),
    "moon_blossom_ring": weapon(3, "ring", 38, speed=10, agility=6, inner=2, crit=.20),
    "shooting_star": weapon(3, "hidden", 40, speed=10, agility=6, crit=.20),
    "xueying_bone_needle": weapon(3, "hidden", 36, speed=12, agility=6, crit=.24),
    "suwusheng_teapot": weapon(4, "hidden", 55, speed=6, inner=7, insight=6, crit=.20),
}


ICON_REPLACEMENTS = {
    "huashan_zixia_sword": "res://art/ui/inventory/icons/icon_huashan_zixia_sword_v2.png",
    "tiger_roar_blade": "res://art/ui/inventory/icons/icon_tiger_roar_blade.png",
    "wudang_taiji_sword": "res://art/ui/inventory/icons/icon_wudang_taiji_sword_v2.png",
}


def value_text(value: object) -> str:
    if isinstance(value, str):
        return f'&"{value}"'
    if isinstance(value, float):
        return f"{value:.2f}"
    return str(value)


def set_field(source: str, field: str, value: object) -> str:
    replacement = f"{field} = {value_text(value)}"
    pattern = re.compile(rf"^{re.escape(field)}\s*=.*$", re.MULTILINE)
    if pattern.search(source):
        return pattern.sub(replacement, source, count=1)
    return source.rstrip() + "\n" + replacement + "\n"


def main() -> None:
    changed = 0
    for path in sorted(EQUIPMENT_DIR.glob("*.tres")):
        source = path.read_text(encoding="utf-8")
        match = re.search(r'^item_id\s*=\s*&?"([^"]+)"', source, re.MULTILINE)
        if not match or match.group(1) not in WEAPONS:
            continue
        item_id = match.group(1)
        for field, value in WEAPONS[item_id].items():
            source = set_field(source, field, value)
        if item_id in ICON_REPLACEMENTS:
            source = set_field(source, "icon_path", ICON_REPLACEMENTS[item_id])
        path.write_text(source, encoding="utf-8", newline="\n")
        changed += 1

    if changed != len(WEAPONS):
        raise RuntimeError(f"expected {len(WEAPONS)} weapons, updated {changed}")
    print(f"updated {changed} weapon resources")


if __name__ == "__main__":
    main()
