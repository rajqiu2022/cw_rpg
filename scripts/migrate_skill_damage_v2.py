"""One-shot, idempotent migration for martial-arts damage v2 resources.

The explicit table is the balance contract: every damaging move has fixed damage
plus an effective-attack percentage, and every skill has a real quality tier.
"""

from __future__ import annotations

import re
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]
SKILL_DIR = ROOT / "game" / "data" / "skills"
EQUIPMENT_DIR = ROOT / "game" / "data" / "equipment"

# quality: 0 white, 1 green, 2 blue, 3 purple, 4 orange
QUALITY = {
    "basic_attack": 0, "defend": 0,
    "linxi_basic_sword_one": 1, "heavy_swing": 1, "examiner_staff_sweep": 1,
    "wudang_taiji_chushi": 1, "huashan_yijian": 1, "gufeng_kaishan_yidao": 1,
    "lingyue_lingbo_yizhi": 1, "mingwu_saofeng": 1,
    "linxi_basic_sword_two": 2, "palm_strike": 2, "toxic_needle": 2,
    "qinghe_jade_guard": 2, "qinghe_returning_breath": 2, "qinghe_swallow_sword": 2,
    "tang_staff_breaker": 2, "tang_staff_sweep": 2,
    "wudang_taiji_sixiang": 2, "huashan_poyun": 2, "gufeng_fuhu": 2,
    "lingyue_hanshuang_zhen": 2, "mingwu_wuyin_sanshi": 2,
    "zhao_black_wind_sweep": 3, "zhao_broken_gate_strike": 3,
    "wudang_xuanwu_ge": 3, "huashan_zixia_ninggang": 3,
    "gufeng_jingang_buhuai": 3, "lingyue_tayue_lingbo": 3, "mingwu_mingwu_bu": 3,
    "gufeng_jingang_li": 3, "linxi_inner_breath": 3,
    "lingyue_yuehua_yin": 3, "mingwu_yinying_jue": 3,
    "wudang_taiji_liangyi": 4, "huashan_jianduan_qianshan": 4,
    "gufeng_liedi": 4, "lingyue_hanshuang_wan_zhen": 4,
    "mingwu_yinying_duoming": 4, "wudang_xuanwu_xinjing": 4,
    "huashan_zixia_shengong": 4,
}

DAMAGE = {
    "basic_attack": (2, 100),
    "linxi_basic_sword_one": (10, 100), "linxi_basic_sword_two": (18, 115),
    "heavy_swing": (12, 110), "examiner_staff_sweep": (12, 110),
    "gufeng_kaishan_yidao": (10, 105), "gufeng_fuhu": (20, 120), "gufeng_liedi": (44, 140),
    "huashan_yijian": (8, 105), "huashan_poyun": (18, 115), "huashan_jianduan_qianshan": (50, 145),
    "lingyue_lingbo_yizhi": (7, 100), "lingyue_hanshuang_zhen": (14, 105),
    "lingyue_hanshuang_wan_zhen": (34, 100),
    "mingwu_saofeng": (7, 100), "mingwu_wuyin_sanshi": (18, 115),
    "mingwu_yinying_duoming": (54, 150),
    "wudang_taiji_chushi": (8, 100), "wudang_taiji_sixiang": (18, 115),
    "wudang_taiji_liangyi": (40, 135),
    "palm_strike": (20, 120), "toxic_needle": (12, 95),
    "qinghe_swallow_sword": (14, 110),
    "tang_staff_breaker": (18, 115), "tang_staff_sweep": (12, 70),
    "zhao_black_wind_sweep": (20, 80), "zhao_broken_gate_strike": (30, 125),
}

EFFECT = {"qinghe_jade_guard": 16, "qinghe_returning_breath": 24}

DESCRIPTION = {
    "basic_attack": "挥拳击向敌人。伤害：固定 2 + 攻击力 × 100%。",
    "linxi_basic_sword_one": "刑樊天亲传的基础剑式，剑势平稳有力。伤害：固定 10 + 攻击力 × 100%。",
    "linxi_basic_sword_two": "刑樊天亲传的第二式，以退为进，剑随身走。伤害：固定 18 + 攻击力 × 115%。",
    "heavy_swing": "敌人专用，横刀挥砍。伤害：固定 12 + 攻击力 × 110%。",
    "examiner_staff_sweep": "考校官沉腰进步，以棍势横扫对手。伤害：固定 12 + 攻击力 × 110%。",
    "gufeng_kaishan_yidao": "古峰入门刀法，势大力沉。伤害：固定 10 + 攻击力 × 105%。",
    "gufeng_fuhu": "如伏虎之势劈下，25% 概率使敌人虚弱 2 回合。伤害：固定 20 + 攻击力 × 120%。",
    "gufeng_liedi": "一刀裂地开山，50% 概率使敌人虚弱 2 回合。伤害：固定 44 + 攻击力 × 140%。",
    "huashan_yijian": "华山入门剑法，刚猛直接，并附带额外暴击机会。伤害：固定 8 + 攻击力 × 105%。",
    "huashan_poyun": "一剑破云穿空，30% 概率使敌人虚弱 2 回合。伤害：固定 18 + 攻击力 × 115%。",
    "huashan_jianduan_qianshan": "华山至高绝学，一剑断千山，必定暴击。伤害：固定 50 + 攻击力 × 145%。",
    "lingyue_lingbo_yizhi": "指尖凝气为针的基础远程招式。伤害：固定 7 + 攻击力 × 100%。",
    "lingyue_hanshuang_zhen": "淬寒霜之毒的秘传暗器，30% 概率中毒 3 回合。伤害：固定 14 + 攻击力 × 105%。",
    "lingyue_hanshuang_wan_zhen": "万针齐发如寒霜天降，必中毒 3 回合并附加虚弱。全体伤害：固定 34 + 攻击力 × 100%。",
    "mingwu_saofeng": "以步带剑，攻击后自身进入爆发 1 回合。伤害：固定 7 + 攻击力 × 100%。",
    "mingwu_wuyin_sanshi": "三式连环如雾中魅影，攻击后自身进入爆发 1 回合。伤害：固定 18 + 攻击力 × 115%。",
    "mingwu_yinying_duoming": "一击夺命直取脉门，对残血敌人必定暴击。伤害：固定 54 + 攻击力 × 150%。",
    "wudang_taiji_chushi": "武当入门剑法，以柔克刚并附带反伤。伤害：固定 8 + 攻击力 × 100%。",
    "wudang_taiji_sixiang": "分四象方位攻敌，额外提高命中。伤害：固定 18 + 攻击力 × 115%。",
    "wudang_taiji_liangyi": "阴阳相生一剑，招式必中。伤害：固定 40 + 攻击力 × 135%。",
    "palm_strike": "凝气于掌，重击单个敌人。伤害：固定 20 + 攻击力 × 120%。",
    "toxic_needle": "敌人专用，细针袭穴并有概率使目标中毒。伤害：固定 12 + 攻击力 × 95%。",
    "qinghe_swallow_sword": "轻灵回身剑，对单个敌人出招。伤害：固定 14 + 攻击力 × 110%。",
    "tang_staff_breaker": "凝劲于棍端直取一点。伤害：固定 18 + 攻击力 × 115%。",
    "tang_staff_sweep": "旅途中悟出的横扫棍势。全体伤害：固定 12 + 攻击力 × 70%。",
    "zhao_black_wind_sweep": "赵无忌旋身催动连环刀风。全体伤害：固定 20 + 攻击力 × 80%。",
    "zhao_broken_gate_strike": "赵无忌压箱底的单体杀招，刀势沉猛。伤害：固定 30 + 攻击力 × 125%。",
}


def replace_property(text: str, name: str, value: int) -> str:
    line = f"{name} = {value}"
    pattern = rf"(?m)^{re.escape(name)} = .*$"
    if re.search(pattern, text):
        return re.sub(pattern, line, text)
    marker = re.search(r"(?m)^power = .*$", text)
    if marker:
        return text[: marker.start()] + line + "\n" + text[marker.start() :]
    raise ValueError(f"Cannot place {name}")


def main() -> None:
    paths = sorted(SKILL_DIR.glob("*.tres"))
    seen: set[str] = set()
    for path in paths:
        text = path.read_text(encoding="utf-8")
        match = re.search(r'^skill_id = &"([^"]+)"$', text, re.MULTILINE)
        if not match:
            raise ValueError(f"No skill_id in {path}")
        skill_id = match.group(1)
        seen.add(skill_id)
        if skill_id not in QUALITY:
            raise ValueError(f"Missing quality mapping: {skill_id}")
        fixed, scaling = DAMAGE.get(skill_id, (0, 0))
        effect = EFFECT.get(skill_id, 0)
        text = replace_property(text, "quality", QUALITY[skill_id])
        text = replace_property(text, "fixed_damage", fixed)
        text = replace_property(text, "attack_scaling", scaling)
        text = replace_property(text, "effect_value", effect)
        text = re.sub(r"(?m)^power = .*$\n?", "", text)
        text = text.replace("complement_bonus_power =", "complement_bonus_scaling =")
        text = text.replace("power+15", "攻击系数+15%")
        if skill_id in DESCRIPTION:
            desc = DESCRIPTION[skill_id].replace('"', '\\"')
            text = re.sub(r'(?m)^description = ".*"$', f'description = "{desc}"', text)
        path.write_text(text, encoding="utf-8", newline="\n")

    expected = set(QUALITY)
    if seen != expected:
        raise ValueError(f"Skill table mismatch: missing={sorted(expected-seen)}, extra={sorted(seen-expected)}")
    equipment_count = 0
    for path in sorted(EQUIPMENT_DIR.glob("*.tres")):
        text = path.read_text(encoding="utf-8")
        if "skill_bonus_power =" not in text and "skill_bonus_scaling =" not in text:
            continue
        if "skill_bonus_power =" in text:
            text = text.replace("skill_bonus_power =", "skill_bonus_scaling =")
        text = text.replace("招式威力", "招式攻击系数")
        text = text.replace("提升all招式攻击系数", "提升全门派招式攻击系数")
        path.write_text(text, encoding="utf-8", newline="\n")
        equipment_count += 1
    print(
        f"Migrated {len(paths)} skills; damaging={len(DAMAGE)}; "
        f"effects={len(EFFECT)}; equipment bonuses={equipment_count}"
    )


if __name__ == "__main__":
    main()
