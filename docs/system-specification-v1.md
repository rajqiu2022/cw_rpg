# 武林RPG 系统规格说明书 v1

> **基于**: world-bible.md v0.4 + design-mvp-chapter1.md v0.4 + design-character-attributes-v1.md
> **更新日期**: 2026-05-24
> **用途**: 所有子系统的统一数据契约和交互规约，新功能开发前以此为准

---

## 0. 子系统索引

| # | 子系统 | 核心脚本 | 数据文件目录 | 状态 |
|----|--------|----------|------------|------|
| 1 | 剧情系统 | `dialog_player.gd` | `data/dialogs/` | ✅ v0.4 |
| 2 | 角色系统 | `character_stats.gd` | 代码内初始化 | ✅ v1 |
| 3 | 任务系统 | `quest_manager.gd` | `data/quests/` | ✅ v0.4 |
| 4 | 道具系统 | `item.gd` | `data/items/` | ✅ v1 |
| 5 | 装备系统 | `equipment.gd` | `data/equipment/` | ⚠ 待扩充 |
| 6 | 战斗系统 | `battle_controller.gd` | `data/enemies/` + `data/skills/` | ⚠ M6 待做 |
| 7 | 技能系统 | `skill.gd` | `data/skills/` | ⚠ 待清理旧占位 |
| 8 | 商店系统 | `shop_def.gd` | `data/shops/` | ✅ |
| 9 | 背包系统 | `inventory.gd` | 无（纯逻辑） | ✅ |
| 10 | 存档系统 | `save_manager.gd` | 无（纯逻辑） | ✅ M7 待扩 |

---

## 1. 剧情系统

### 1.1 数据契约

**DialogNode** (`dialog_node.gd`):

```
node_id: StringName       # 节点唯一标识
speaker: String           # 说话者名称（空=旁白）
portrait_path: String     # 立绘路径（可空）
text: String              # 对话文本，支持 BBCode
choices: Array[Dict]      # [{text, next, set_flag}]
give_items: Array[Dict]   # [{id, count}]
give_gold: int
set_flags: Array[Dict]    # [{key, value}]
accept_quest: StringName
complete_quest: StringName
on_end: String            # "end" / "next:X" / "battle:X" / "shop:X" / "scene:X" / "dialog:X" / "chapter_end:X"
```

**DialogScript** (`dialog_script.gd`):

```
dialog_id: StringName     # 全局唯一
entry_node_id: StringName # 入口节点
nodes: Array[Resource]    # DialogNode 列表
```

### 1.2 场景路由动作（on_end 支持的全部动作）

```
end             → 关闭对话框，回到场景
next:<node_id>  → 跳转到指定节点
battle:<id>     → 进入战斗
shop:<id>       → 打开商店
scene:<id>      → 跳转场景
dialog:<id>     → 链式播放另一个对话
chapter_end:<n> → 进入章节结算
```

### 1.3 第一章对话文件列表（17个，全部已创建）

| 场景 | 文件 | 功能 |
|------|------|------|
| 黑屏开场 | `ch1_intro_narration` | 5段世界观旁白 |
| 新手关 | `ch1_tutorial_xingfantian` | 刑樊天晨练→送行→赐酒 |
| 新手关 | `ch1_tutorial_duqingshan` | 杜青衫赠铁剑 |
| 新手关 | `ch1_tutorial_stone_altar` | 石坛刻字彩蛋 |
| 主街 | `ch1_main_street_shenbanzhan` | 沈半盏酒馆→商店 |
| 主街 | `ch1_main_street_duqingshan` | 杜青衫已拿剑变体 |
| 主街 | `ch1_main_street_vendor` | 走货郎世界观→商店 |
| 主街 | `ch1_main_street_stone` | 村口石碑 |
| 山道 | `ch1_road_enter` | 进入旁白 |
| 山道 | `ch1_road_stone` | 石碑"小心" |
| 山道 | `ch1_road_corpse` | 尸体→教学战 |
| 山道 | `ch1_road_after_battle` | 战后拾取→跳转密林 |
| 密林 | `ch1_forest_enter` | 进入旁白 |
| 密林 | `ch1_forest_yuewuxing` | 救悦无姮→章末战 |
| 密林 | `ch1_forest_victory` | 胜利剧情→链talk |
| 密林 | `ch1_forest_yuewuxing_talk` | 悦无姮正式对话 |
| 密林 | `ch1_forest_wooden_box` | 木箱拾取彩蛋 |

---

## 2. 角色系统

### 2.1 CharacterStats 数据契约

```
# 元数据
character_id: String       # "protagonist"
display_name: String       # "冷孤云"
portrait_path: String

# 等级
level: int = 1
exp: int = 0

# 七项核心属性
strength: int = 8      # 筋骨 — 物理伤害、HP加成
agility: int = 7       # 机敏 — 命中、闪避、先手
inner_power: int = 8   # 内劲 — 武学伤害、MP效率
insight: int = 6       # 悟性 — 暴击率、成长修正
vitality: int = 10     # 生命 — HP上限
inner_pool: int = 8    # 内力 — MP上限
guard: int = 7         # 防御 — 伤害减免

# 派生战斗值（由 refresh_derived_stats 计算）
max_hp: int            # = 80 + vitality×8 + strength×3
max_mp: int            # = 20 + inner_pool×6 + inner_power×2 + insight
attack: int            # = strength×2 + inner_power
defense: int           # = guard×2 + strength
speed: int             # = agility×2 + insight

# 技能
skills: Array[StringName]  # 已习得技能ID列表
```

### 2.2 升级成长（每级固定增量）

```
strength +1    agility +1    inner_power +1    insight +1
vitality +2    inner_pool +2    guard +1
→ 升级后 refresh_derived_stats(true)（HP/MP 回满）
```

### 2.3 Lv1 主角默认数据

```
冷孤云 Lv1:
  筋骨=8, 机敏=7, 内劲=8, 悟性=6, 生命=10, 内力=8, 防御=7
  → max_hp=184, max_mp=90, attack=24, defense=22, speed=20
  技能: basic_attack, linxi_basic_sword_one, defend
```

---

## 3. 任务系统

### 3.1 QuestDef 数据契约

```
quest_id: StringName               # 全局唯一
title: String                      # ≤10汉字
kind: int                          # 0=MAIN, 1=SIDE, 2=GUILD, 3=SECRET
desc_not_started / desc_in_progress / desc_completed: String
completion_triggers: Array[String] # ["enemy_defeated:X", "flag_set:Y", "scene_entered:Z"]
reward_gold: int
reward_exp: int
reward_items: Array[Dict]          # [{id, count}]
```

### 3.2 第一章任务列表

| ID | 类型 | 标题 | 触发 | 完成条件 |
|----|------|------|------|----------|
| `q_ch1_main_road` | 主线 | 山道疑云 | 进入山道场景自动 | `enemy_defeated:thug_lone` |
| `q_ch1_main_zhuwei` | 主线 | 前往竹尾村 | 完成山道疑云后自动 | `flag_set:chapter1_complete` |
| `q_ch1_side_yuewuxing` | 支线 | 援手救人 | 密林中选择救悦无姮 | `flag_set:chapter1_complete` |

### 3.3 已废弃的任务（保留文件但不再被引用）

| ID | 原内容 | 废弃原因 |
|----|--------|----------|
| `q_ch1_main_01_thug` | 击退茗雾杀手 | 被 q_ch1_main_road 替代 |
| `q_ch1_side_01_rescue_husband` | 营救丈夫 | 原清风镇占位剧情 |
| `q_ch1_main_02_qingfeng` | 打探清风镇 | 原清风镇占位剧情 |

---

## 4. 道具系统

### 4.1 Item 数据契约

```
item_id: StringName       # 全局唯一，蛇形命名
display_name: String      # ≤8汉字
description: String       # 1-2句说明
icon_path: String         # 图标路径（可空）
category: int             # 0=CONSUMABLE, 1=MATERIAL, 2=KEY_ITEM, 3=EQUIPMENT
stackable: bool
max_stack: int
sell_price: int
buy_price: int
usable_in_battle: bool
usable_in_field: bool
heal_hp: int              # 消耗品效果
heal_mp: int
```

### 4.2 完整道具目录

#### 消耗品

| item_id | 名称 | 效果 | 买价 | 卖价 | 战用 |
|---------|------|------|------|------|------|
| `healing_pill_minor` | 小还丹 | HP +80 | 30 | 12 | ✅ |
| `healing_pill_major` | 大还丹 | HP +200 | 90 | 35 | ✅ |
| `mana_pill` | 凝气丹 | MP +50 | 45 | 18 | ✅ |
| `inner_breath_pill` | 内息丸 | MP +20 | 40 | 16 | ✅ |
| `antidote_pill` | 解毒丹 | 解中毒 | 50 | 20 | ✅ |
| `revive_pill` | 醒神丹 | 解眩晕 | 60 | 24 | ✅ |
| `linxi_jiu` | 林西酒 | HP+5永久 + MP+20战中 | 15 | 5 | — |
| `lingzhi_pill` | 紫府丹 | HP全恢复 | 200 | 80 | ✅ |

#### 剧情物品

| item_id | 名称 | 说明 |
|---------|------|------|
| `zhuwei_map` | 竹尾村地图 | 标注密林路径，不可丢弃 |
| `lingyue_token` | 凌月信物 | 银月形玉坠，凌月山入场券 |

### 4.3 道具命名规范

- 蛇形命名：`healing_pill_minor`
- ID 必须与文件名一致：`linxi_jiu.tres` ↔ `item_id = &"linxi_jiu"`
- 中文名 ≤ 8 汉字

---

## 5. 装备系统

### 5.1 Equipment 数据契约（继承 Item）

```
# 从 Item 继承
item_id, display_name, description, icon_path
category = 3 (EQUIPMENT)

# 装备专属
slot: int               # 0=WEAPON, 1=HEAD, 2=ARMOR, 3=HANDS, 4=SHOES, 5=ACCESSORY

# 旧兼容字段
atk_bonus, def_bonus, hp_bonus, mp_bonus, speed_bonus

# 七属性加成
str_bonus, agi_bonus, inner_bonus, insight_bonus
vitality_bonus, inner_pool_bonus, guard_bonus
```

### 5.2 装备品质分层

| 品质 | 颜色 | 战力倍率 | Lv1武器ATK | 获取方式 |
|------|------|---------|-----------|----------|
| 凡品 | 白 | 1.0× | +5~7 | 商店/教学掉落 |
| 良品 | 绿 | 1.4× | +8~10 | 章3-4支线 |
| 灵品 | 蓝 | 2.0× | +11~14 | 章5-6 Boss |
| 神品 | 紫 | 3.0× | +15~19 | 章7奖励 |
| 仙品 | 金 | 4.5× | +20~25 | 章8 Boss |

### 5.3 第一章可用装备目录

| item_id | 名称 | 槽位 | 品质 | 加成 | 获取 |
|---------|------|------|------|------|------|
| `linxi_iron_sword` | 林西铁剑 | 武器 | 凡品+1 | ATK+6 | 杜青衫赠送 |
| `cloth_armor` | 粗布麻衣 | 衣甲 | 凡品 | DEF+3 | 教学战掉落/商店 |
| `bamboo_hat` | 竹笠 | 头盔 | 凡品 | DEF+2, HP+10 | 商店 |
| `leather_bracers` | 皮护腕 | 手套 | 凡品 | ATK+2 | 商店 |
| `straw_sandals` | 草鞋 | 鞋子 | 凡品 | SPD+2 | 初始赠送 |
| `jade_ring` | 玉戒 | 饰品 | 凡品 | MP+15 | 密林木箱彩蛋 |

### 5.4 装备槽位解锁节奏

| 章 | 解锁槽位 |
|----|---------|
| 1 | 武器 + 衣甲（2槽 MVP） |
| 2 | +头盔 |
| 3 | +鞋子 |
| 4 | +手套 |
| 5 | +饰品 |

---

## 6. 战斗系统

### 6.1 战斗公式（推荐方案）

```
# 核心公式
基础伤害 = ATK × 技能倍率(power/100)
实际伤害 = max(1, 基础伤害 - DEF)
暴击伤害 = 实际伤害 × 1.5
最终伤害 = 暴击伤害 × 虚弱系数

# 虚弱系数（双向）
敌人HP ≥ 70%  → 1.0
敌人HP 50-70% → 0.85
敌人HP 30-50% → 0.65
敌人HP 10-30% → 0.45
敌人HP < 10%  → 0.25

# 命中/闪避
命中率 = min(95%, max(5%, 60 + 机敏×1.5 - 目标闪避值))
闪避值 = 5 + 机敏×0.8

# 暴击
暴击率 = min(80%, 5% + 悟性×0.5% + 武器暴击加成)
```

### 6.2 EnemyDef 数据契约

```
enemy_id: StringName
display_name: String
portrait_path: String
level: int
max_hp: int
max_mp: int = 0
attack: int
defense: int
speed: int
skill_ids: Array[StringName]
aggression: float           # 0-1，AI激进度
drop_gold_min / drop_gold_max: int
drop_exp: int
drop_items: Array[StringName]         # 必掉物品
drop_random: Array[Dict]              # [{item_id, chance, count}] 概率掉落
```

### 6.3 第一章敌人完整数据

| enemy_id | 名称 | Lv | HP | ATK | DEF | SPD | 技能 | 掉落 |
|----------|------|----|----|-----|-----|-----|------|------|
| `thug_lone` | 江湖散兵 | 1 | 60 | 8 | 3 | 6 | 普攻 | 粗布麻衣+小还丹(50%) |
| `masked_killer_minion` | 蒙面杀手 | 2 | 80 | 14 | 5 | 9 | 普攻+毒针 | 解毒丹(30%) |
| `masked_killer_leader` | 蒙面首领 | 4 | 150 | 24 | 6 | 10 | 普攻+毒针+重斩 | 大还丹+金80-150 |

> 注意：`masked_killer_leader` 的 enemy_id 是 `masked_killer_ambush`（与 `masked_killer_ambush.tres` 文件名一致），用于 battle 动作：`battle:masked_killer_ambush`

### 6.4 战斗回合验证

```
教学战 (thug_lone)：
  TKK = 60/(15-3) = 5回合 → 降至 HP=40 → 3.3回合 ✓
  TTD = 184/(8-8) = ∞（DEF≥ATK，伤害=1）→ 安全 ✓

章末战 (masked_killer_ambush):
  玩家ATK=15, DEF=8  悦无姮助战≈20/回合
  首领HP=150, ATK=24, DEF=6
  TKK = 150/(15+20-6) = 5.2回合 ✓
  TTD = 184/(24-8) = 11.5回合 → 安全系数 2.2 ✓
```

---

## 7. 技能系统

### 7.1 Skill 数据契约

```
skill_id: StringName
display_name: String
icon_path: String
description: String
kind: int           # 0=ATTACK, 1=HEAL, 2=BUFF, 3=DEBUFF
target: int         # 0=ENEMY_SINGLE, 1=ENEMY_ALL, 2=ALLY_SINGLE, 3=ALLY_ALL, 4=SELF
mp_cost: int
power: int          # 100=普通攻击基线
hit_count: int = 1
animation_id: StringName
```

### 7.2 完整技能列表

#### 主角技能

| skill_id | 名称 | 类型 | MP | Power | 说明 | 获取 |
|----------|------|------|-----|-------|------|------|
| `basic_attack` | 普通攻击 | ATK | 0 | 100 | 基础攻击 | 初始 |
| `linxi_basic_sword_one` | 林西基础剑法·一式 | ATK | 0 | 120 | 刑樊天亲传 | 初始 |
| `defend` | 防御 | BUFF | 0 | — | 本回合DEF×2 | 初始 |

#### 敌人技能

| skill_id | 名称 | 类型 | MP | Power | 效果 | 使用者 |
|----------|------|------|-----|-------|------|--------|
| `toxic_needle` | 毒针 | ATK | 5 | 80 | 40%中毒3回合 | 蒙面杀手 |
| `heavy_swing` | 重斩 | ATK | 8 | 150 | 无特殊效果 | 蒙面首领 |

#### 已废弃

| skill_id | 废弃原因 |
|----------|----------|
| `palm_strike` | 原沈不归占位技能 |

---

## 8. 商店系统

### 8.1 ShopDef 数据契约

```
shop_id: StringName
display_name: String
greeting: String
stock: Array[StringName]          # 出售物品ID列表
sell_back_ratio: float = 0.4     # 回购折扣
```

### 8.2 商店列表

| shop_id | 名称 | 出售物品 | 章节 |
|---------|------|----------|------|
| `linxi_shenbanzhan` | 沈半盏酒馆 | 小还丹、凝气丹、粗布麻衣、解毒丹 | 1 |
| `linxi_vendor` | 走货郎杂货摊 | 解毒丹、粗布麻衣、竹尾村地图 | 1 |

---

## 9. 背包系统

### 9.1 数据结构

```
# Inventory 内存格式
slots: Array[Dict]           # [{"item": Item, "count": int}, ...]
equipped: Dictionary         # {Slot.WEAPON: Equipment, Slot.ARMOR: Equipment, ...}
_item_cache: Dictionary      # {item_id: Item}

# 最大格子数
MAX_SLOTS = 30

# 物品加载路径（按顺序查找）
1. res://data/items/<item_id>.tres
2. res://data/equipment/<item_id>.tres
```

### 9.2 新游戏初始背包

```gdscript
func reset_for_new_game():
    from_dict({})
    add_item(&"healing_pill_minor", 2)
    add_item(&"linxi_jiu", 1)
    add_item(&"straw_sandals", 1)
```

### 9.3 装备穿戴/卸下逻辑

- 穿戴：`equipped[slot] = item`, 物品仍在背包格中（只是标记为已装备）
- 卸下：`equipped.erase(slot)`, 物品回到背包可用状态
- 旧兼容字段：`equipped_weapon` / `equipped_armor` 保留仅供旧战斗代码用

---

## 10. 存档系统

### 10.1 存档数据结构 (v3)

```json
{
  "version": 3,
  "timestamp": "ISO8601",
  "chapter": 1,
  "gold": 0,
  "player": {
    "level": 1, "exp": 0,
    "strength": 8, "agility": 7, "inner_power": 8, "insight": 6,
    "vitality": 10, "inner_pool": 8, "guard": 7,
    "hp": 184, "mp": 90,
    "skills": ["basic_attack", "linxi_basic_sword_one", "defend"]
  },
  "inventory": {
    "slots": [{"item_id": "...", "count": 1}],
    "equipped": {"0": "linxi_iron_sword", "2": "cloth_armor"}
  },
  "quests": {
    "q_ch1_main_road": 2,
    "q_ch1_side_yuewuxing": 1
  },
  "flags": {
    "master_farewell_done": true,
    "got_sword": true
  },
  "current_scene": "ch1_s1_road"
}
```

### 10.2 存档槽

- M7 前：单槽（`active_slot`）
- M7 目标：5槽 + 存档预览（场景名、章节、等级、时间戳）

---

## 附录A：已废弃/待清理的文件清单

| 文件 | 理由 | 建议 |
|------|------|------|
| `data/dialogs/ch1_road_intro.tres` | 沈不归旧剧情 | 保留不引用 |
| `data/dialogs/ch1_s2_*.tres` | 清风镇占位 | 保留不引用 |
| `data/dialogs/ch1_s3_intro.tres` | 旧清风镇 | 保留不引用 |
| `data/dialogs/ch1_s3_bound_man.tres` | 旧营救丈夫 | 保留不引用 |
| `data/dialogs/ch1_s3_door_to_boss.tres` | 旧Boss门 | 保留不引用 |
| `data/dialogs/ch1_s2_crying_woman*.tres` | 旧哭泣女子 | 保留不引用 |
| `data/dialogs/ch1_corpse_examine.tres` | 旧尸体检查 | 保留不引用 |
| `data/dialogs/ch1_tutorial_blacksmith.tres` | 旧铁匠刘 | 保留不引用 |
| `data/quests/q_ch1_main_01_thug.tres` | 旧任务 | 保留不引用 |
| `data/quests/q_ch1_side_01_rescue_husband.tres` | 旧任务 | 保留不引用 |
| `data/quests/q_ch1_main_02_qingfeng.tres` | 旧任务 | 保留不引用 |
| `data/skills/palm_strike.tres` | 沈不归技能 | 保留不引用 |
| `data/enemies/bandit_mountain.tres` | 旧山贼 | 保留不引用 |
| `data/enemies/boss_zhao_wuji.tres` | 旧赵无忌 | 保留不引用 |
| `data/shops/qingfeng_merchant.tres` | 旧清风镇商店 | 保留不引用 |
| `data/scenes/ch1_s2_qingfeng*.tres` | 旧清风镇场景 | 保留不引用 |
| `data/scenes/ch1_s3_west_ruin.tres` | 旧废宅场景 | 保留不引用 |

> 原则：旧文件**保留在磁盘上但不再被任何新代码引用**。删除可能破坏 Git 历史中的分支/变体，所以仅标记废弃。

---

## 附录B：命名规范（项目级）

| 类型 | 规范 | 示例 |
|------|------|------|
| item_id | 蛇形英文 | `healing_pill_minor` |
| enemy_id | 蛇形英文 | `thug_lone` |
| skill_id | 蛇形英文 | `linxi_basic_sword_one` |
| quest_id | `q_ch<N>_<type>_<name>` | `q_ch1_main_road` |
| dialog_id | `ch<N>_<scene>_<npc>` | `ch1_tutorial_xingfantian` |
| scene_id | `ch<N>_<sN>_<location>` | `ch1_s3_zhuwei_forest` |
| shop_id | 蛇形英文 | `linxi_shenbanzhan` |
| flag_key | 蛇形英文 | `master_farewell_done` |
| portrait_path | `portrait_<name>_<mood>.png` | `portrait_xingfantian_master.png` |
