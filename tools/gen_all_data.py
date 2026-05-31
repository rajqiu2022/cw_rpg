#!/usr/bin/env python3
"""批量生成 RPG_GAME 完整装备数据：按五派武器分型 + 全防具 + 全等级。
用法: python tools/gen_all_data.py
"""
import sys
from pathlib import Path
_TOOLS = Path(__file__).resolve().parent
sys.path.insert(0, str(_TOOLS / "agent_hub"))
from tres_io import save_resource

ROOT = _TOOLS.parent

def eq(eid, name, desc, slot, q=0, atk=0, df=0, hp=0, mp=0, spd=0,
       st=0, ag=0, inn=0, ins=0):
    """创建一件装备并保存为 .tres。q=品质: 0白 1绿 2蓝 3紫 4橙"""
    d = {
        "item_id": eid, "display_name": name, "description": desc, "icon_path": "",
        "category": 3, "stackable": False, "max_stack": 1, "quality": q,
        "sell_price": max(5, (atk*4 + df*3 + hp//12 + mp//12 + spd*3 + (st+ag+inn+ins)*6)),
        "buy_price": max(15, (atk*12 + df*9 + hp//4 + mp//4 + spd*9 + (st+ag+inn+ins)*18)),
        "usable_in_battle": False, "usable_in_field": False, "heal_hp": 0, "heal_mp": 0,
        "slot": slot, "atk_bonus": atk, "def_bonus": df,
        "hp_bonus": hp, "mp_bonus": mp, "speed_bonus": spd,
        "str_bonus": st, "agi_bonus": ag, "inner_bonus": inn, "insight_bonus": ins,
        "vitality_bonus": 0, "inner_pool_bonus": 0, "guard_bonus": 0,
    }
    save_resource(ROOT, "Equipment", d)
    return True

# ══════════════════════════════════════════════════════════
# 武器 (slot=0) — 五派分型
# ══════════════════════════════════════════════════════════

# ── 长剑系 (武当/华山) ──
eq("steel_longsword",        "精锐长剑", "百炼钢锻造的锋利长剑，江湖侠客的首选。", 0, atk=9)
eq("wudang_pine_sword",      "武当松纹剑", "武当道观百年松木剑鞘，剑身清亮如秋水。内劲+1", 0, atk=10, inn=1)
eq("huashan_quick_sword",    "华山快剑", "华山剑宗特制，比常剑窄三分，出鞘无声。机敏+1", 0, atk=10, ag=1)
eq("qingming_sword",         "青冥剑", "天书《青冥录》所载剑形，剑出寒意刺骨。内劲+2", 0, atk=13, inn=2)
eq("wudang_taiji_sword",     "太极真剑", "武当镇派之剑，分阴阳二气，柔中带刚。内劲+2, 防御+2", 0, atk=17, df=2, inn=2)
eq("huashan_zixia_sword",    "紫霞神剑", "以紫霞神功淬炼的宝剑，剑出如霞光万道。机敏+2, 悟性+1", 0, atk=18, ag=2, ins=1)
eq("seven_star_sword",       "七星龙泉剑", "铸剑大师欧冶子遗作，剑身镌七星连珠。全属性+2", 0, atk=22, df=2, hp=50, st=2, ag=2, inn=2)

# ── 重刀系 (古峰) ──
eq("iron_great_blade",       "精铁大刀", "厚背精铁大刀，势大力沉。筋骨为主加成", 0, atk=13)
eq("tiger_roar_blade",       "虎啸刀", "刀背刻猛虎纹，挥动时虎啸生风。筋骨+2", 0, atk=16, st=2)
eq("gufeng_diamond_blade",   "金刚斩马刀", "古峰镇派之刀，金刚不坏的厚重。筋骨+3, 防御+1", 0, atk=20, df=1, st=3)
eq("kaishan_war_axe",        "开天斧", "古峰先祖劈山开路的神兵。筋骨+4, 25%眩晕", 0, atk=24, st=4)

# ── 暗器系 (凌月) ──
eq("silver_moon_needle",     "银月飞针", "凌月独门暗器，细如牛毛快如闪电。机敏+2, 速度+1", 0, atk=8, spd=2, ag=2)
eq("frost_dart",             "寒霜镖", "淬以千年寒泉的飞镖，中者如坠冰窟。机敏+2, 15%冰冻", 0, atk=13, spd=1, ag=2)
eq("moon_blossom_ring",      "月华轮", "凌月至宝环形暗器，月华引加持。机敏+3, 速度+4", 0, atk=16, spd=4, ag=3)
eq("shooting_star",          "流星赶月", "江湖最快的暗器，出手只见星光一闪。机敏+4, 速度+6", 0, atk=20, spd=6, ag=4)

# ── 刺剑/短刃系 (茗雾) ──
eq("shadow_dagger",          "暗影匕", "通体漆黑的短匕，月下不反光。悟性+1", 0, atk=11, ins=1)
eq("hidden_edge",            "隐锋刺", "茗雾秘制刺剑，剑刃藏有肉眼难辨的暗锋。悟性+2", 0, atk=14, ins=2)
eq("assassin_blade",         "暗杀之刃", "茗雾至高暗杀兵器，专攻脉门。悟性+3", 0, atk=18, ins=3)
eq("thousand_year_shadow",   "千年影刃", "茗雾家族千年传承暗杀至宝。悟性+4", 0, atk=22, ins=4)

# ── 稀有武器 (Boss掉落/任务奖励) ──
eq("liuyun_soul_devourer",   "烈云噬魂", "戚云笙于章六赠与的神秘兵器，淬有蚀骨毒。内劲+2, 25%中毒", 0, atk=18, inn=2)
eq("xueying_bone_needle",    "透骨针", "从薛影处缴获的十二枚淬毒透骨针。速度+8", 0, atk=15, spd=8)
eq("suwusheng_teapot",       "紫砂暗器", "苏雾笙随身数十年的紫砂茶壶，暗藏机关。内劲+5, 悟性+3", 0, atk=24, inn=5, ins=3)

# ── 棍系 (少林/通用) ──
eq("wooden_staff",           "木棍", "普通的硬木长棍，练武入门之选。筋骨+1", 0, atk=7, st=1)
eq("iron_staff",             "铁棍", "精铁铸造的长棍，沉稳有力。攻击+10, 防御+2", 0, atk=10, df=2)
eq("bronze_ring_staff",      "铜环棍", "棍身两端套铜环，挥动时铮铮作响。攻击+12, 筋骨+2", 0, atk=12, st=2)
eq("shaolin_fahua_staff",    "少林法华棍", "少林寺武僧所用，棍法精妙。攻击+14, 筋骨+2, 内劲+1", 0, atk=14, st=2, inn=1)
eq("golden_hoop_staff",      "金箍棒", "传说中齐天大圣的神兵仿品，可长可短。攻击+17, 筋骨+3", 0, atk=17, st=3)
eq("dragon_tendon_staff",    "龙筋棍", "以千年龙筋缠绕的宝棍，柔中带刚。攻击+19, 筋骨+3, 内劲+2", 0, atk=19, st=3, inn=2)
eq("buddha_subduing_staff",  "降魔杵", "少林镇寺之宝，专破邪魔外道。攻击+22, 筋骨+4, 内劲+3", 0, atk=22, st=4, inn=3)
eq("heaven_piercing_staff",  "通天棍", "传说中的神兵，一棍可破万法。攻击+26, 全属性+2", 0, atk=26, st=2, ag=2, inn=2, ins=2)

# ══════════════════════════════════════════════════════════
# 头盔 (slot=1)
# ══════════════════════════════════════════════════════════
eq("bamboo_hat",             "竹编斗笠", "挡雨遮阳。防御+2, HP+10", 1, df=2, hp=10)
eq("leather_cap",            "皮帽", "鞣制牛皮缝制。防御+3, HP+20", 1, df=3, hp=20)
eq("iron_helmet",            "铁盔", "洛阳铁匠铺制式头盔。防御+4, HP+30", 1, df=4, hp=30)
eq("steel_helmet",           "精钢盔", "精钢打造的头盔。防御+5, HP+50", 1, df=5, hp=50)
eq("hero_hat",               "侠客斗笠", "江湖侠客常戴的宽檐斗笠。防御+6, 悟性+1", 1, df=6, ins=1)
eq("cloud_crown",            "云纹冠", "绣有祥云暗纹的头冠。防御+7, MP+40", 1, df=7, mp=40)
eq("phoenix_feather_hat",    "凤羽冠", "火凤尾羽为饰的头冠。防御+8, HP+80, 悟性+2", 1, df=8, hp=80, ins=2)
eq("battle_helmet",          "百战盔", "历经百战而不破的头盔。防御+10, HP+120", 1, df=10, hp=120)
eq("dragon_horn_crown",      "龙角冠", "龙骨雕成的头冠。防御+12, 全属性+1", 1, df=12, st=1, ag=1, inn=1, ins=1)
eq("immortal_crown",         "仙尊冠", "传说中仙人所戴。防御+15, HP+200, 悟性+3", 1, df=15, hp=200, ins=3)

# ══════════════════════════════════════════════════════════
# 衣甲 (slot=2)
# ══════════════════════════════════════════════════════════
eq("cloth_armor",            "粗布麻衣", "寻常百姓所穿的布衣。防御+3", 2, df=3)
eq("leather_armor",          "皮甲", "鞣制牛皮缝制的轻甲。防御+6, HP+20", 2, df=6, hp=20)
eq("iron_mail",              "锁子甲", "细密铁环编成的护甲。防御+8, HP+40", 2, df=8, hp=40)
eq("heart_guard_armor",      "护心镜甲", "内嵌精钢护心镜。防御+10, 筋骨+1", 2, df=10, st=1)
eq("jade_scale_armor",       "玉鳞甲", "玉石薄片缀成的鳞甲。防御+12, HP+50", 2, df=12, hp=50)
eq("wudang_robe",            "武当道袍", "太极真气护体的道袍。防御+11, MP+60, 内劲+2", 2, df=11, mp=60, inn=2)
eq("mountain_armor",         "山岳重甲", "厚重如山的战甲。防御+15, HP+80, 筋骨+2", 2, df=15, hp=80, st=2)
eq("mingwu_night_armor",     "茗雾夜行衣", "哑光夜行衣，轻如蝉翼。防御+12, 机敏+3", 2, df=12, ag=3)
eq("dragon_scale_armor",     "龙鳞宝甲", "千年龙鳞所制的宝甲。防御+18, HP+150", 2, df=18, hp=150)
eq("immortal_robe",          "仙蚕衣", "天蚕丝织成的仙衣。防御+22, HP+200, 全属性+2", 2, df=22, hp=200, st=2, ag=2, inn=2, ins=2)

# ══════════════════════════════════════════════════════════
# 手套 (slot=3)
# ══════════════════════════════════════════════════════════
eq("leather_bracers",        "护腕", "练拳时常用的皮质护腕。攻击+2", 3, atk=2)
eq("iron_knuckles",          "铁指虎", "铸铁指虎，近身搏命利器。攻击+4, 筋骨+1", 3, atk=4, st=1)
eq("steel_gauntlets",        "精钢手甲", "精钢打造的手甲。攻击+5, 防御+1", 3, atk=5, df=1)
eq("silk_gloves",            "灵丝手套", "天蚕丝编织的薄手套。攻击+6, 机敏+1", 3, atk=6, ag=1)
eq("dragon_scale_bracers",   "龙鳞护手", "千年蟒鳞镶嵌的护手。攻击+8, 筋骨+2", 3, atk=8, st=2)
eq("thunder_gauntlets",      "雷霆手甲", "蕴含雷电之力的手甲。攻击+10, 机敏+2, 速度+2", 3, atk=10, ag=2, spd=2)
eq("tiger_claw_gloves",      "虎爪手套", "虎皮为面虎爪为刃。攻击+12, 筋骨+3", 3, atk=12, st=3)
eq("phoenix_claw",           "凤爪护手", "火凤利爪所制。攻击+15, 悟性+2", 3, atk=15, ins=2)

# ══════════════════════════════════════════════════════════
# 鞋子 (slot=4)
# ══════════════════════════════════════════════════════════
eq("straw_sandals",          "草编行履", "林西村常见的草鞋。速度+2", 4, spd=2)
eq("cloth_boots",            "布靴", "厚底布靴，比草鞋结实。速度+4, 防御+1", 4, spd=4, df=1)
eq("deer_leather_boots",     "鹿皮靴", "柔软鹿皮缝制的靴子。速度+5, 机敏+1", 4, spd=5, ag=1)
eq("moonwalk_boots",         "踏月靴", "凌月派特质轻靴，月华引加持。速度+7, 机敏+1", 4, spd=7, ag=1)
eq("cloud_boots",            "云履靴", "鹿皮云锦缝制，轻若无物。速度+8, 防御+2", 4, spd=8, df=2)
eq("wind_walker_boots",      "追风靴", "日行千里不倦。速度+10, 机敏+2", 4, spd=10, ag=2)
eq("dragon_flight_boots",    "龙腾靴", "如龙腾九天之势。速度+12, 机敏+3", 4, spd=12, ag=3)
eq("immortal_steps",         "仙履", "踏云而行。速度+15, 机敏+4", 4, spd=15, ag=4)

# ══════════════════════════════════════════════════════════
# 敌人扩展 (按章分布, Lv1~30)
# ══════════════════════════════════════════════════════════
def enemy(eid, name, lv, hp, atk, df, spd, skills, aggro=0.5,
          gold_lo=10, gold_hi=25, exp=20, drops=None, random_drops=None):
    d = {
        "enemy_id": eid, "display_name": name, "portrait_path": "",
        "level": lv, "max_hp": hp, "max_mp": 0,
        "attack": atk, "defense": df, "speed": spd,
        "skill_ids": skills,
        "aggression": aggro,
        "drop_gold_min": gold_lo, "drop_gold_max": gold_hi, "drop_exp": exp,
        "drop_items": drops or [], "drop_random": random_drops or [],
    }
    save_resource(ROOT, "EnemyDef", d)
    return True

# 章1 — 林西村/竹尾
enemy("thug_lone",          "江湖散兵",    1,  40,  8,  3,  6, ["basic_attack"], 0.4, 10,25,15)
enemy("masked_killer_minion","蒙面杀手",   2,  80, 14,  5,  9, ["basic_attack","toxic_needle"], 0.55, 20,40,30,
      random_drops=[{"item_id":"antidote_pill","chance":0.3,"count":1}])
enemy("masked_killer_leader","蒙面杀手首领",4, 150,24,  6, 10, ["basic_attack","toxic_needle","heavy_swing"], 0.65, 80,150,100,
      drops=["healing_pill_major"])

# 章2 — 竹尾/凌月山
enemy("lingyue_guard",      "凌月山守卫",  3,  90, 12,  5, 11, ["basic_attack"], 0.4, 15,30,20,
      random_drops=[{"item_id":"inner_breath_pill","chance":0.3,"count":1}])
enemy("masked_killer_elite","蒙面杀手精英",4, 110, 16,  7, 11, ["basic_attack","toxic_needle"], 0.6, 30,55,35,
      random_drops=[{"item_id":"antidote_pill","chance":0.4,"count":1}])
enemy("zhuwei_bandit",      "竹尾村山贼",  2,  60, 10,  4,  7, ["basic_attack"], 0.45, 10,25,15,
      random_drops=[{"item_id":"healing_salve","chance":0.4,"count":1}])

# 章3 — 武林大会/入派
enemy("wulin_examiner",     "武林大会考官",4, 130, 15,  8, 10, ["basic_attack","huashan_yijian"], 0.5, 20,40,30,
      random_drops=[{"item_id":"healing_pill_minor","chance":0.5,"count":1}])
enemy("mingwu_spy",         "茗雾密探",    5, 120, 18,  6, 12, ["basic_attack","toxic_needle","mingwu_saofeng"], 0.55, 30,60,35)
enemy("wudang_disciple",    "武当弟子",    4, 110, 14,  7, 10, ["basic_attack","wudang_taiji_chushi"], 0.45, 20,40,30)
enemy("gufeng_trainee",     "古峰试炼者",  4, 140, 17,  5,  7, ["basic_attack","gufeng_kaishan_yidao"], 0.55, 25,50,35)

# 章4 — 洛阳
enemy("luoyang_thug",       "洛阳地痞",    5, 100, 16,  5,  8, ["basic_attack"], 0.5, 15,35,25,
      random_drops=[{"item_id":"healing_salve","chance":0.4,"count":1}])
enemy("temple_ambusher",    "古寺埋伏兵",  6, 130, 18,  6,  9, ["basic_attack","toxic_needle"], 0.55, 25,50,30,
      random_drops=[{"item_id":"mana_pill","chance":0.3,"count":1}])
enemy("luoyang_patrol",     "洛阳巡捕",    6, 120, 17,  8,  9, ["basic_attack","huashan_yijian"], 0.5, 30,60,35)
enemy("boss_luoyang_captain","洛阳府衙都头",7, 200, 22, 10, 10, ["basic_attack","heavy_swing"], 0.6, 80,150,80,
      drops=["healing_pill_major"], random_drops=[{"item_id":"leather_armor","chance":0.5,"count":1}])

# 章5 — 古月峰
enemy("gufeng_bandit",      "古峰山贼",    7, 140, 20,  7,  8, ["basic_attack","gufeng_kaishan_yidao"], 0.55, 30,55,35,
      random_drops=[{"item_id":"healing_pill_minor","chance":0.4,"count":2}])
enemy("fake_liuyun_assassin","伪装烈云盟刺客",8,150,22,  8, 12, ["basic_attack","toxic_needle","heavy_swing"], 0.6, 40,70,45,
      random_drops=[{"item_id":"swift_pill","chance":0.3,"count":1}])
enemy("gufeng_elite_guard", "古峰精英守卫",8, 170, 23,  9,  8, ["basic_attack","gufeng_fuhu"], 0.6, 50,90,50)
enemy("boss_xueying_agent", "薛影手下",    9, 260, 26,  9, 13, ["basic_attack","mingwu_saofeng","mingwu_wuyin_sanshi"], 0.65, 100,180,100,
      drops=["healing_pill_major"], random_drops=[{"item_id":"iron_knuckles","chance":0.5,"count":1}])

# 章6 — 师承之谜
enemy("mingwu_siege_guard", "茗雾围困兵", 10, 170, 24,  9, 11, ["basic_attack","mingwu_saofeng"], 0.6, 40,75,50,
      random_drops=[{"item_id":"strength_pill","chance":0.3,"count":1}])
enemy("mingwu_shadow",      "茗雾暗哨",   10, 150, 26,  7, 14, ["basic_attack","mingwu_wuyin_sanshi"], 0.6, 50,90,55)
enemy("linxi_wild_beast",   "林西村外凶兽",9, 200, 28,  6, 12, ["basic_attack","gufeng_fuhu"], 0.7, 60,110,60)

# 章7 — 烈云盟
enemy("liuyun_guard",       "烈云盟守卫", 11, 180, 25, 10, 11, ["basic_attack","toxic_needle"], 0.5, 50,90,55,
      random_drops=[{"item_id":"mana_pill","chance":0.4,"count":1}])
enemy("mingwu_outer_guard", "茗雾外围守卫",12, 200, 28, 11, 12, ["basic_attack","mingwu_wuyin_sanshi"], 0.6, 55,100,60,
      random_drops=[{"item_id":"spirit_gathering_dust","chance":0.3,"count":1}])
enemy("liuyun_elite",       "烈云盟精英", 12, 220, 30, 11, 12, ["basic_attack","gufeng_liedi"], 0.6, 70,130,70)
enemy("mingwu_infiltrator", "茗雾渗透者", 13, 210, 30, 10, 14, ["basic_attack","mingwu_yinying_duoming"], 0.65, 65,120,65)

# 章8 — 茗雾决战
enemy("mingwu_elite_guard", "茗雾精英护卫",14,240, 30, 12, 13, ["basic_attack","mingwu_wuyin_sanshi","mingwu_yinying_jue"], 0.65, 80,140,80,
      random_drops=[{"item_id":"spirit_gathering_dust","chance":0.4,"count":1}])
enemy("mingwu_dark_guard",  "茗雾暗卫",   14, 220, 34, 10, 15, ["basic_attack","mingwu_yinying_duoming"], 0.7, 80,150,85)
enemy("boss_xueying",       "薛影·暗影",  14, 350, 34, 14, 16, ["basic_attack","mingwu_saofeng","mingwu_wuyin_sanshi","mingwu_yinying_duoming"], 0.7, 200,350,200,
      drops=["healing_pill_major"], random_drops=[{"item_id":"lingzhi_pill","chance":0.5,"count":1}])
enemy("boss_su_wusheng",    "苏雾笙·千年伪装者",16,500,40,18,14, ["basic_attack","mingwu_saofeng","mingwu_wuyin_sanshi","mingwu_yinying_duoming"], 0.75, 500,800,500,
      drops=["nine_revive_pill"], random_drops=[{"item_id":"mingwu_dark_stone","chance":1.0,"count":1}])

# 高等级野怪 (Lv18~30, 用于后续扩展/奇遇)
enemy("cave_giant_spider",  "洞穴巨蛛",   18, 350, 36, 14, 16, ["basic_attack","toxic_needle"], 0.7, 100,200,120)
enemy("mountain_bandit_king","山寨大王",   20, 420, 40, 16, 14, ["basic_attack","gufeng_liedi","heavy_swing"], 0.7, 120,250,150)
enemy("wandering_blademaster","流浪刀客",  22, 380, 44, 15, 18, ["basic_attack","gufeng_fuhu","gufeng_kaishan_yidao"], 0.7, 150,300,180)
enemy("ancient_tomb_guard", "古墓守卫",   25, 500, 48, 20, 16, ["basic_attack","mingwu_yinying_duoming"], 0.75, 200,400,250)
enemy("dragon_vein_serpent","龙脉巨蟒",   28, 650, 55, 22, 18, ["basic_attack","toxic_needle","heavy_swing"], 0.8, 300,600,350)
enemy("boss_ancient_demon", "上古魔将",   30, 900, 65, 28, 20, ["basic_attack","mingwu_yinying_duoming","gufeng_liedi","heavy_swing"], 0.85, 800,1500,800,
      drops=["nine_revive_pill","lingzhi_pill"])

# ══════════════════════════════════════════════════════════
# 商店扩展 (按章节/城镇分布)
# ══════════════════════════════════════════════════════════
def shop(sid, name, greeting, stock):
    d = {"shop_id": sid, "display_name": name, "greeting": greeting, "stock": stock, "sell_back_ratio": 0.4}
    save_resource(ROOT, "ShopDef", d)
    return True

shop("linxi_shenbanzhan",   "沈半盏酒馆", "来来来，我这有些路上用得着的东西！", ["healing_pill_minor","inner_breath_pill","cloth_armor","antidote_pill"])
shop("linxi_vendor",        "走货郎杂货摊","都是洛阳来的好货！少侠随便看看。", ["inner_breath_pill","antidote_pill","cloth_armor","zhuwei_map"])
shop("zhuwei_apothecary",   "竹尾药铺",   "疗伤解毒，童叟无欺。", ["healing_salve","healing_pill_minor","antidote_pill","revive_pill","inner_breath_pill"])
shop("lingyue_pavilion",    "凌月阁商坊", "凌月山上最好的丹药和暗器材料。", ["mana_pill","inner_breath_pill","swift_pill","antidote_pill","bamboo_hat","leather_bracers"])
shop("wulin_trade_hall",    "武林商会",   "五派齐聚，四方珍品皆在此处。", ["healing_pill_minor","healing_pill_major","mana_pill","strength_pill","cloth_boots","leather_armor","iron_helmet"])
shop("luoyang_armory",      "洛阳军械铺","朝廷官造兵器，童叟无欺。", ["healing_pill_minor","mana_pill","antidote_pill","revive_pill","cloth_boots","iron_knuckles"])
shop("gufeng_smithy",       "古峰铁匠铺","山野豪侠，兵器都是真货！", ["healing_pill_major","strength_pill","inner_breath_pill","leather_armor","iron_knuckles"])
shop("liuyun_secret_shop",  "烈云密市",   "正派不卖的东西，这里都有。", ["healing_pill_major","spirit_gathering_dust","clarity_dew","swift_pill","strength_pill"])
shop("mingwu_ruins_vendor", "茗雾废墟商人","决战前夕，最后的补给。", ["healing_pill_major","lingzhi_pill","spirit_gathering_dust","clarity_dew","revive_pill"])

# ══════════════════════════════════════════════════════════
# 道具扩展
# ══════════════════════════════════════════════════════════
def item(iid, name, desc, hp=0, mp=0, buy=10, sell=4, battle=True, field=True, stack=99):
    d = {
        "item_id": iid, "display_name": name, "description": desc, "icon_path": "",
        "category": 0, "stackable": True, "max_stack": stack,
        "sell_price": sell, "buy_price": buy,
        "usable_in_battle": battle, "usable_in_field": field,
        "heal_hp": hp, "heal_mp": mp,
    }
    save_resource(ROOT, "Item", d)

def keyitem(iid, name, desc):
    d = {
        "item_id": iid, "display_name": name, "description": desc, "icon_path": "",
        "category": 2, "stackable": False, "max_stack": 1,
        "sell_price": 0, "buy_price": 0,
        "usable_in_battle": False, "usable_in_field": False,
        "heal_hp": 0, "heal_mp": 0,
    }
    save_resource(ROOT, "Item", d)

# ── HP 恢复 (分级) ──
item("healing_salve",       "金创药",   "最便宜的刀伤药。回复 40 点 HP。", hp=40, buy=15, sell=6)
item("healing_pill_minor",  "小还丹",   "江湖游医的常用伤药。回复 80 点 HP。", hp=80, buy=30, sell=12)
item("blood_activator",     "活血散",   "以当归、三七调配的良品伤药。回复 150 点 HP。", hp=150, buy=55, sell=22)
item("healing_pill_major",  "大还丹",   "名门正派秘制丹药。回复 200 点 HP。", hp=200, buy=90, sell=35)
item("life_extend_pill",    "续命丹",   "危急时刻救命用的灵品丹药。回复 350 点 HP。", hp=350, buy=150, sell=60)
item("lingzhi_pill",        "紫府丹",   "极为珍贵的神品丹药。HP 全恢复。", hp=9999, buy=200, sell=80, stack=5)
item("nine_revive_pill",    "九转还魂丹","传说级仙品丹药，武林中仅存数枚。HP 全恢复，解所有状态。", hp=9999, buy=500, sell=200, stack=3)

# ── MP 恢复 (分级) ──
item("inner_breath_pill",   "内息丸",   "行走江湖的常备丹药。回复 20 点 MP。", mp=20, buy=40, sell=16)
item("mana_pill",           "凝气丹",   "助修真气的良品丹药。回复 50 点 MP。", mp=50, buy=45, sell=18)
item("spirit_gathering_dust","聚灵散",  "以百年灵芝为主料的灵品丹药。回复 120 点 MP。", mp=120, buy=100, sell=40)
item("soul_return_dew",     "回元露",   "采自深山灵泉的灵品药露。回复 200 点 MP。", mp=200, buy=160, sell=64, stack=30)
item("heaven_element_pill", "天元丹",   "神品丹药，服后内力如泉涌。回复 400 点 MP。", mp=400, buy=300, sell=120, stack=20)

# ── 状态解除 ──
item("antidote_pill",       "解毒丹",   "江湖常见的解毒丹药。解除中毒状态。", buy=50, sell=20, stack=10)
item("revive_pill",         "醒神丹",   "专治眩晕。解除眩晕状态。", buy=60, sell=24, stack=10)
item("anti_weak_powder",    "祛弱散",   "以黄芪、党参研磨而成。解除虚弱状态（攻防恢复）。", buy=40, sell=16, stack=10)
item("thaw_warm_pill",      "融冰丸",   "以内火之力炼制的丹药。解除冰冻状态。", buy=50, sell=20, stack=10)
item("clarity_dew",         "清心露",   "采自茗雾山巅千年寒泉。解除所有负面状态（中毒/眩晕/冰冻/虚弱）。", buy=150, sell=60, stack=20)

# ── 战斗Buff ──
item("strength_pill",       "强骨丹",   "古峰派独门丹药。战中临时筋骨 +5，持续 3 回合。", buy=80, sell=32, stack=10, field=False)
item("swift_pill",          "轻身散",   "凌月派秘传方子。战中临时机敏 +5，持续 3 回合。", buy=80, sell=32, stack=10, field=False)
item("diamond_powder",      "金刚散",   "战中临时防御 +5，持续 3 回合。", buy=70, sell=28, stack=10, field=False)
item("ki_gather_pill",      "聚气丹",   "战中临时内劲 +5，持续 3 回合。", buy=70, sell=28, stack=10, field=False)

# ── 特殊/剧情 ──
item("linxi_jiu",           "林西酒",   "刑樊天赠酒，壶底有夹层。饮用回复 20 点 MP。", mp=20, buy=15, sell=5, stack=10, battle=False)
keyitem("zhuwei_map",       "竹尾村地图","散兵身上搜出的地图，标有'快走'警示。章1获得。")
keyitem("lingyue_token",    "凌月信物", "银月玉坠，悦无姮所赠。凌月山入场凭证。")
keyitem("wulin_invitation", "武林大会请柬","五派武林大会入场凭证。章3获得。")
keyitem("qingming_fragment","青冥录残页","天书第一卷线索。武当藏经阁所得。章4获得。")
keyitem("xuanshuang_script","玄霜诀",   "天书第二卷。冷家秘藏内功心法，永久内力+30。章6获得。")
keyitem("yuanming_jade",    "渊冥子玉佩","冷孤云身世铁证。天书封印之钥。章8揭晓。")

# ── 更新敌人掉落引用新道具 ──
enemy("thug_lone",          "江湖散兵",    1,  40,  8,  3,  6, ["basic_attack"], 0.4, 10,25,15,
      random_drops=[{"item_id":"healing_salve","chance":0.5,"count":1}])
enemy("zhuwei_bandit",      "竹尾村山贼",  2,  60, 10,  4,  7, ["basic_attack"], 0.45, 10,30,18,
      random_drops=[{"item_id":"healing_salve","chance":0.4,"count":1}])
enemy("luoyang_thug",       "洛阳地痞",    5, 100, 16,  5,  8, ["basic_attack"], 0.5, 15,40,25,
      random_drops=[{"item_id":"blood_activator","chance":0.3,"count":1}])

# ══════════════════════════════════════════════════════════
# 饰品 (slot=5)
# ══════════════════════════════════════════════════════════
eq("jade_ring",              "青玉戒", "青玉打磨的旧戒指。MP+15", 5, mp=15)
eq("iron_wristband",         "铁腕环", "简单的铁质护身符。HP+40, 防御+1", 5, hp=40, df=1)
eq("silver_moon_necklace",   "银月链", "悦无姮的贴身项链。MP+30, 悟性+1", 5, mp=30, ins=1)
eq("liuyun_talisman",        "烈云护符", "戚云笙亲手编织的护身符。HP+60, MP+40, 内劲+1", 5, hp=60, mp=40, inn=1)
eq("crimson_jade_pendant",   "赤琼佩", "千年赤玉雕成的佩饰。HP+100, MP+60", 5, hp=100, mp=60)
eq("ice_heart_jade",         "冰心玉", "万年寒玉，清心明目。MP+80, 悟性+3", 5, mp=80, ins=3)
eq("thunder_amulet",         "雷霆护符", "引天雷之力加持。HP+120, 筋骨+2", 5, hp=120, st=2)
eq("mingwu_dark_stone",      "茗雾暗石", "茗雾密窟黑色晶石。悟性+3", 5, ins=3)
eq("phoenix_heart",          "凤凰心", "火凤涅槃所化的宝石。HP+200, MP+100, 全属性+1", 5, hp=200, mp=100, st=1, ag=1, inn=1, ins=1)

# ── 品质自动分配 ──
def _auto_quality():
    """根据装备数值总和自动分配品质: 0白 1绿 2蓝 3紫 4橙"""
    for f in sorted((ROOT / "game/data/equipment").glob("*.tres")):
        from tres_io import parse_tres
        parsed = parse_tres(f)
        d = parsed["data"]
        # 计算战力总分
        score = (d.get("atk_bonus",0)*3 + d.get("def_bonus",0)*2 +
                 d.get("hp_bonus",0)//10 + d.get("mp_bonus",0)//10 +
                 d.get("speed_bonus",0)*2 +
                 (d.get("str_bonus",0)+d.get("agi_bonus",0)+
                  d.get("inner_bonus",0)+d.get("insight_bonus",0))*5)
        if score >= 100: q = 4       # 橙
        elif score >= 60: q = 3      # 紫
        elif score >= 30: q = 2      # 蓝
        elif score >= 12: q = 1      # 绿
        else: q = 0                  # 白
        d["quality"] = q
        save_resource(ROOT, "Equipment", d)

# ── 执行 ──
if __name__ == "__main__":
    _auto_quality()
    equip = len(list((ROOT / "game/data/equipment").glob("*.tres")))
    enemies = len(list((ROOT / "game/data/enemies").glob("*.tres")))
    shops = len(list((ROOT / "game/data/shops").glob("*.tres")))
    print(f"装备:{equip}  敌人:{enemies}  商店:{shops}")
