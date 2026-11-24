# 资源扩充目录（2026-08-05）

本批资源遵循 2.5D 武侠正式资源规范。原始生成图保留在 `assets/raw/`，审核、切片、透明化后的运行时资源放入 `game/art/`。场景与角色资源禁止拉伸使用。

## 1. 城市与任务 NPC

统一 Field 单帧画布为 160×160，有效人物高度约 140px。站立角色使用 4 帧轻微呼吸/衣摆动作；巡逻角色使用 8 帧行走条。

| NPC ID | 用途 | Field 资源 | 头像资源 |
|---|---|---|---|
| `merchant` | 行商、传闻、普通商店 | `res://art/characters/street_expansion_v1/npc_street_merchant_idle_down_4f.png` | `res://art/characters/portraits/street_expansion_v1/portrait_street_merchant_v1.png` |
| `vegetable_vendor` | 街市闲聊、生活支线 | `res://art/characters/street_expansion_v1/npc_vegetable_seller_idle_down_4f.png` | `res://art/characters/portraits/street_expansion_v1/portrait_vegetable_seller_v1.png` |
| `inn_waiter` | 客栈引导、跑堂任务 | `res://art/characters/street_expansion_v1/npc_inn_waiter_idle_down_4f.png` | `res://art/characters/portraits/street_expansion_v1/portrait_inn_waiter_v1.png` |
| `patrol_scout` | 护商、护送、武馆挑战 | `res://art/characters/street_expansion_v1/npc_escort_guard_idle_down_4f.png` | `res://art/characters/portraits/street_expansion_v1/portrait_escort_guard_v1.png` |

行商另有四方向 8 帧行走资源：`npc_street_merchant_{down,left,right,up}_walk_8f.png`。NPC 的头像、站立图、行走图和缩放统一在 `game/data/npcs/npc_catalog.tres` 配置；场景只需给出 `npc_id`、位置和剧情对话 ID。

## 2. 交互物件

目录：`res://art/props/interactive/expansion_v1/`

### 宝箱等级

- `chest_common_wood_v1.png`：普通木箱，药物、铜钱、基础材料。
- `chest_advanced_iron_v1.png`：高级铁箱，精良装备、完整秘籍。
- `chest_rare_jade_v1.png`：稀有玉饰箱，门派武学、稀有装备。
- `chest_legendary_gold_v1.png`：传说宝箱，绝世武功残卷、神兵线索。

### 剧情线索

- `clue_bloodied_cloth_v1.png`
- `clue_broken_sword_v1.png`
- `clue_sealed_message_tube_v1.png`
- `clue_wanted_notice_v1.png`

### 武功秘籍与残页

- `manual_stitched_common_v1.png`
- `manual_diagram_page_v1.png`
- `manual_burnt_fragment_v1.png`
- `manual_supreme_scroll_v1.png`

交互物件在 `WalkableMapLayout.visual_objects` / `interactions` 中引用。碰撞盒只覆盖物件脚底，交互范围独立配置，不得用整张透明画布尺寸作为碰撞范围。

## 3. 场景背景

`res://art/backgrounds/bg_luoyang_outer_market_25d_v1.png`

- 原生尺寸 1536×1024，30°俯视 2.5D 预渲染。
- 建筑、棚架、树木均有体积和接触阴影。
- 主路连续，预留 NPC 摆位、建筑入口和支线交互区域。
- 已接入 `ch4_s3_luoyang_market.tres`，保持原生比例显示。

## 4. 敌人战斗精灵

`wulin_examiner` 已按战斗精灵 V2 标准制作并接入：

- 目录：`res://art/sprites/battle/standard_v2/wulin_examiner/`
- 状态：`ready` / `move` / `attack` / `hit` / `defeat`
- 每种状态 4 帧，共 20 张 512×384 透明 PNG。
- 敌方朝屏幕左侧，完整显示头、脚和武器，不复用其他角色动作。
- 配置：`game/data/enemies/wulin_examiner.tres`
- 场景待机条：`res://art/characters/street_expansion_v1/npc_wulin_examiner_idle_down_4f.png`，第三章不再借用师傅外观。

新增技能 `examiner_staff_sweep` 使用二阶棍法特效，配置位于 `game/data/skills/examiner_staff_sweep.tres`。

## 5. 分武器、分等级技能特效

目录：`res://art/battle_vfx/weapon_tiers_v1/`

支持 12 个 `animation_id`：

| 武器 | 一阶 | 二阶 | 三阶 |
|---|---|---|---|
| 剑 | `sword_tier_1` | `sword_tier_2` | `sword_tier_3` |
| 刀 | `dao_tier_1` | `dao_tier_2` | `dao_tier_3` |
| 棍 | `staff_tier_1` | `staff_tier_2` | `staff_tier_3` |
| 掌 | `palm_tier_1` | `palm_tier_2` | `palm_tier_3` |

每套为 4 帧透明动画。一级强调清晰的小范围轮廓；二级增加范围、残影和能量层；三级增加大范围爆发、地面冲击或高阶意象。技能只需在 `.tres` 中设置对应 `animation_id`。

## 6. 后处理工具

- `scripts/slice_fixed_grid_atlas.py`：固定网格切片、统一画布、保留最大连通区域和重叠安全边。
- `scripts/build_field_sprite_strips.py`：构建 160×160 Field 动画条并清除邻格穿帮。
- `scripts/build_vfx_tier_sheets.py`：把 4×3 武器等级图集转换成 Godot 运行时 2×2 动画表。
- `scripts/validate_resource_expansion.py`：检查本批 Field、头像、物件、场景、战斗帧与特效表的数量、尺寸和 Alpha。

生成图必须先进入候选目录，完成透明边缘、比例、方向、肢体和跨格穿帮审核后，才允许复制到 `game/art/`。
