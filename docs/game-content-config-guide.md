# 游戏内容配置手册

本手册说明如何通过 `game/data/` 新增和修改游戏内容。配置文件描述内容和关系，脚本负责解析、显示、结算与存档。新增普通内容不应修改核心管理器。

## 配置入口

| 内容 | 配置位置 | 负责人 | ID |
|---|---|---|---|
| 对话剧情 | `game/data/dialogs/*.tres` | `DialogPlayer` | `dialog_id` |
| 主线/支线 | `game/data/quests/*.tres` | `QuestManager` | `quest_id` |
| 道具/装备 | `game/data/items/`、`equipment/` | `Inventory` | `item_id` |
| 招式/心法 | `game/data/skills/*.tres` | Battle / Skill UI | `skill_id` |
| 敌人 | `game/data/enemies/*.tres` | `BattleController` | `enemy_id` |
| NPC 档案 | `game/data/npcs/npc_catalog.tres` | `NPCCatalog` | `npc_id` |
| 场景 | `game/data/scenes/*.tres` | `SceneRouter` / Field | `scene_id` |
| 地图碰撞 | `game/data/maps/*.tres` | `FieldWalkableController` | layout ID |
| 商店 | `game/data/shops/*.tres` | `ShopUI` | `shop_id` |

所有 ID 使用英文 `snake_case`，创建后不要随意修改，否则会影响存档和已有引用。

## 音频与音效

- 素材来源：`game/art/audio/cc0/`（CC0 公版）和 `game/art/audio/free/`（免费授权）
- 战斗与野外已有默认 BGM，切换场景时自动淡入淡出
- 场景 BGM 通过 `SceneScript.bgm_path` 配置即可，AudioManager 自动读取，**不需要额外改代码**
- 战斗音效通过 `EventBus.sfx_requested` 广播，AudioManager 池化播放（8 通道）
- 需要新音效时，直接放 `.ogg`/`.mp3`/`.wav` 到对应目录，Godot 会自动导入

```text
# 对话或 action 中可直接切 BGM / 放音效：
play_bgm:res://art/audio/cc0/bgm_field_bards_tale_cc0.mp3
play_sfx:res://art/audio/free/sfx_attack_free_v1.wav
stop_bgm
```

## 新增任务

在 `game/data/quests/` 新建 `QuestDef` 资源。核心字段：`quest_id`、`title`、`kind`、三个状态描述、`completion_triggers`、`reward_gold`、`reward_exp`、`reward_items`。`kind=0` 是主线，`kind=1` 是支线。

完成条件支持：

```text
enemy_defeated:<enemy_id>
scene_entered:<scene_id>
item_picked_up:<item_id>
flag_set:<flag_key>
npc_talked_to:<npc_id>
defeated:<enemy_id>
```

在对话或场景 action 中接取/完成任务：

```text
accept_quest:q_ch1_side_10_example
complete_quest:q_ch1_side_10_example
```

任务奖励由 `QuestManager` 统一发放。不要在同一段对话里同时写任务奖励和重复的 `give_gold` / `give_item`。

## 新增对话

在 `game/data/dialogs/` 新建 `DialogScript`，由多个 `DialogNode` 组成。节点配置说话人、头像、台词、选项、设置 flag、给道具/金钱、接取/完成任务。

常用结束动作：

```text
end
next:<node_id>
battle:<enemy_id>
scene:<scene_id>
shop:<shop_id>
chapter_end:<chapter_number>
open_inventory
open_equipment
open_quest_log
```

选项产生的 flag 必须写在选项自身，不能写在整个对话节点上，否则玩家选择前就会生效。

## 道具、装备、招式、敌人

道具放在 `game/data/items/`，装备放在 `game/data/equipment/`。配置名称、描述、类别、品质、堆叠、价格、使用场景和数值效果。

物品引用统一使用 ID：

```text
对话：give_item:<item_id>:<count>
任务：QuestDef.reward_items
敌人：EnemyDef.drop_items / drop_random
```

招式放在 `game/data/skills/`，配置类型、内力、威力、目标、学习条件、动画 ID 和音效。武学界面只显示玩家已学会的 `skill_id`。

敌人放在 `game/data/enemies/`，配置属性、技能组、AI、掉落、金币、经验、战斗精灵、动作帧和音效。

## NPC 配置

NPC 分两层：

1. 全局档案：`game/data/npcs/npc_catalog.tres`。配置 `npc_id`、`display_name`、`default_dialog_id`、`sprite_path`、`movement_mode`（`idle`/`patrol`/`seated`）、`quest_ids` 和 `role`。
2. 场景摆放：`game/data/scenes/<scene>.tres`。只配置 `npc_id`、`pos`、局部缩放、`require_flag`、`hide_flag` 和局部行为覆盖。

同一个 NPC 出现在多个地图时只维护一份全局档案。当前历史场景仍有少量重复填写姓名、精灵和对话的旧数据；新增 NPC 不要继续复制这些字段。

NPC 对话会广播 `npc_talked_to:<npc_id>`，任务条件必须引用 ID，不要引用显示名称。

## 新增场景和交互

1. 在 `game/data/scenes/` 创建 `SceneScript`，配置场景 ID、名称、背景、BGM、进场对话和地图 layout。
2. 在 `game/data/maps/` 配置可行走区域、建筑/树木/箱子脚底碰撞、交互区、出口和触发区。
3. 场景 NPC 只写 `npc_id + pos`。
4. 交互使用 action，例如 `dialog:xxx`、`battle:xxx`、`give_item:xxx:1`、`scene:xxx`。
5. 出口 `target_pos` 必须落在目标地图可行走区域内，不能只对准视觉门框。
6. 建筑、树木、门框需要层级时使用独立透明 `scene_objects`，碰撞只覆盖脚底。

## 新增商店

在 `game/data/shops/` 创建 `ShopDef`，商品引用物品或装备 ID。NPC 或场景使用 `shop:<shop_id>` 打开商店，商品列表不要硬编码到 UI。

## 推荐制作顺序

新增一条完整支线：先准备道具/敌人 -> 创建任务 -> 创建 NPC 档案 -> 创建对话 -> 摆放 NPC 和交互区 -> 全文搜索 ID 确认引用一致。

## 验证

```powershell
& 'C:\Program Files\Godot\Godot.exe' --headless --editor --path game --quit
& 'C:\Program Files\Godot\Godot.exe' --headless --path game --script test/validate_content_completeness.gd
& 'C:\Program Files\Godot\Godot.exe' --headless --path game --script test/validate_chapters_1_4_flow.gd
& 'C:\Program Files\Godot\Godot.exe' --headless --path game --script test/validate_chapters_1_4_balance.gd
& 'C:\Program Files\Godot\Godot.exe' --headless --path game --script test/validate_walkable_map_v2.gd
```

涉及 NPC 或场景摆放时，还要用 `test/capture_ui.gd` 截图检查人物比例、碰撞、出口、对话和交互位置：

```powershell
# 截取野外场景 (检查 NPC 摆放、碰撞、出口)
godot --headless --script test/capture_ui.gd -- field=ch1_s2_qingfeng_walkable

# 截取战斗界面 (检查敌人/角色位置、HUD)
godot --headless --script test/capture_ui.gd -- battle=thug_lone

# 截取任务/技能面板 (检查 UI 控件对齐、贴图)
godot --headless --script test/capture_ui.gd -- scene=quest
godot --headless --script test/capture_ui.gd -- scene=skill
```

截图输出到 `screenshots/` 目录。可用于 AI 视觉对比——把截图发给 AI，让它判断控件是否错位、重叠、缺失。

## 什么时候需要改代码

只有新增全新的 trigger、action、物品效果、任务状态、NPC 行为或场景对象类型时，才需要修改 `game/scripts/`。如果只是新增任务、奖励、对话、NPC、道具、敌人、技能、商店或场景实例，不应修改核心管理器。

相关设计：[游戏数据索引](game-data-index.md)、[系统技术设计](system-technical-design-v0.1.md)、[可行走地图 V2](walkable-map-v2.md)、[世界观与剧情圣经](world-bible.md)、[道具总表](item-master-table.md)。
