# Godot 系统技术设计稿 v0.1

> 角色：`system` agent  
> 日期：2026-05-04  
> 范围：地图加载、场景路由、角色碰撞、对话/任务/背包接口、存档边界、45° 回合制战斗架构。  
> 状态：设计稿，尚未进入实现。

## 1. 设计目标

当前项目已经有 M1-M5 的可玩骨架：主菜单、Field、对话、任务、商店、背包装备、1v1 回合战斗和存档 v3。接下来进入“程序主干设计”阶段，目标不是重写，而是把已有模块收束成更稳定的系统边界。

本设计的核心目标：

- 统一地图入口，避免经典热点场景和可行走场景在读档、战后、商店返回时互相错用。
- 把地图数据从“能跑”升级为“可设计”：背景、出生点、NPC、出口、碰撞区、触发区都由 `SceneScript` 描述。
- 保持 `SceneRouter.resolve_action()` 作为内容数据调用系统的唯一入口。
- 为“类似风云天下会的 45° 回合制”预留战斗架构：逻辑继续数据驱动，45° 站位和动画属于表现层。
- 在不破坏当前 MVP 的前提下，给 M6/M7 留出状态异常、章节结算、多槽存档和地图坐标保存的位置。

非目标：

- 本阶段不做 TileMap 编辑器工作流。
- 本阶段不做多人队伍和复杂 AI。
- 本阶段不重做背包/任务已有 UI。
- 本阶段不强行升存档 schema，除非实现时确实需要保存玩家地图坐标。

## 2. 当前模块地图

| 模块 | 当前核心文件 | 当前状态 |
|------|--------------|----------|
| 全局事件 | `game/scripts/autoload/event_bus.gd` | 已作为跨系统事件中心 |
| 全局状态 | `game/scripts/autoload/game_state.gd` | 玩家、金币、flags 已可用 |
| 场景路由 | `game/scripts/autoload/scene_router.gd` | 已支持 field/battle/shop/result，但模式选择不统一 |
| 存档 | `game/scripts/autoload/save_manager.gd` | v3，保存 player/gold/flags/quests/inventory/current_field |
| 对话 | `game/scripts/autoload/dialog_player.gd` | 节点图、副作用、on_end 动作已可用 |
| 任务 | `game/scripts/autoload/quest_manager.gd` | 事件触发式任务状态机已可用 |
| 背包装备 | `game/scripts/autoload/inventory.gd` | 堆叠、使用、装备槽、序列化已可用 |
| 经典探索 | `game/scripts/field/field_controller.gd` | 背景 + 热点按钮 |
| 可行走探索 | `game/scripts/field/field_walkable_controller.gd` | Player/NPC/ExitZone/边界矩形 |
| 玩家 | `game/scripts/field/player.gd` | 四方向 sprite sheet 已接入 |
| 战斗 | `game/scripts/battle/battle_controller.gd` | 单文件 1v1 回合战斗，公式/UI/流程混在一起 |

## 3. 总体运行链路

推荐主链路：

```text
main_menu
  -> SceneRouter.go_field_smart(scene_id, spawn?)
  -> FieldRuntime(classic or walkable)
  -> DialogPlayer / Inventory / QuestManager / Battle
  -> Result / Shop / ChapterEnd
  -> SceneRouter.go_field_smart(return_scene, return_spawn?)
```

关键约束：

- 跨系统事件只通过 `EventBus`。
- 内容侧只写 action 字符串，不直接调用脚本函数。
- 任务状态只通过 `QuestManager.accept/complete/fail` 改。
- 背包装备只通过 `Inventory` 改。
- 战斗胜负必须发 `EventBus.battle_ended`；胜利必须发 `EventBus.enemy_defeated`，不能绕过任务系统。

## 4. 地图与场景加载设计

### 4.1 场景模式统一

当前有两套探索场景：

- 经典模式：`field.tscn` + `field_controller.gd`
- 可行走模式：`field_walkable.tscn` + `field_walkable_controller.gd`

问题是入口不统一：`go_field()` 总是进入经典模式，`go_field_walkable()` 需要调用方显式知道场景类型。未来所有入口应改为：

```gdscript
SceneRouter.go_field_smart(scene_id: StringName, spawn := null)
```

决策规则：

1. 加载 `res://data/scenes/<scene_id>.tres`。
2. 如果 `SceneScript.is_walkable == true`，进入 `field_walkable.tscn`。
3. 否则进入 `field.tscn`。
4. 如果场景资源不存在，回退到经典 Field 并显示 fallback 信息。

所有入口都应改走 smart：

- 主菜单新游戏/继续游戏
- 对话 `scene:<id>`
- 战斗胜利继续
- 战斗逃跑
- 商店关闭返回
- 出口切换场景
- 章节结算后回主菜单或下一章

保留 `go_field()` 和 `go_field_walkable()` 作为底层兼容 API，但实现侧优先使用 `go_field_smart()`。

### 4.2 SceneScript 数据合同

`SceneScript` 应成为地图数据合同。v0.1 推荐字段分层：

```text
基础：
- scene_id
- display_name
- background_path
- bgm_path
- on_enter_dialog

模式：
- is_walkable
- player_spawn

经典模式：
- hotspots

可行走模式：
- npcs
- exits
- collision_rects
- trigger_zones
```

新增建议字段：

```gdscript
@export var collision_rects: Array[Dictionary] = []
@export var trigger_zones: Array[Dictionary] = []
```

`collision_rects` 示例：

```gdscript
{
  "id": "stall_block",
  "pos": Vector2(0.35, 0.62),
  "size": Vector2(0.20, 0.10)
}
```

`trigger_zones` 示例：

```gdscript
{
  "id": "forest_ambush",
  "pos": Vector2(0.70, 0.55),
  "size": Vector2(0.12, 0.18),
  "action": "battle:masked_killer_leader",
  "require_flag": "",
  "hide_flag": "defeated_masked_killer_leader"
}
```

短期只支持矩形。矩形坐标继续使用归一化坐标，和现有 NPC/出口保持一致。

### 4.3 可行走地图碰撞

v0.1 使用三层碰撞：

1. **场景外边界**：当前已有，防止玩家走出背景。
2. **静态障碍矩形**：树、摊位、建筑、石头等。
3. **交互/触发 Area2D**：NPC、出口、剧情触发区。

不建议立刻做像素级碰撞或导航网格。原因：

- 当前背景是 AI 生成整图，缺少可靠 tile/层级数据。
- 手写少量矩形足够支撑第一章。
- 归一化矩形可适配不同背景尺寸。

### 4.4 FieldRuntime 统一职责

两个 Field controller 的职责应逐渐对齐：

```text
FieldBase responsibilities:
- 加载 SceneScript
- 加载背景或 FallbackBg
- emit scene_entered
- 播放 on_enter_dialog
- 渲染 HUD
- 响应 I/E/J 快捷键
- 管理 BGM

ClassicField:
- 生成 hotspot button

WalkableField:
- 生成 player/npc/exit/collision/trigger
```

实现时可以先不抽基类，先保证调用顺序和行为一致。等重复逻辑明显后再抽 `FieldRuntimeHelper` 或 base controller。

## 5. SceneRouter 与 action 设计

### 5.1 action 字符串是内容接口

内容数据 `.tres` 不应知道具体脚本，只写 action 字符串。

已支持：

```text
dialog:<id>
battle:<enemy_id>
scene:<scene_id>
shop:<shop_id>
give_item:<id>:<count>
give_gold:<count>
set_flag:<key>:<value>
accept_quest:<id>
complete_quest:<id>
end
```

需要补齐：

```text
open_inventory
open_equipment
open_quest_log
chapter_end:<chapter>
```

设计原则：

- action 解析仍集中在 `SceneRouter.resolve_action()`。
- 打开 UI 的动作可以通过 `EventBus` 发请求，由当前 Field controller 响应。
- 不要让 `SceneRouter` 直接持有某个 Field UI 节点引用。

建议新增事件：

```gdscript
EventBus.ui_requested(panel_id: StringName)
```

panel_id 可选：

```text
inventory
equipment
quest_log
```

Field controller 订阅该事件，复用现有 I/E/J 面板打开逻辑。

### 5.2 返回场景 payload

战斗、商店、章节结算都需要知道“回来哪里”。

建议统一 payload：

```gdscript
{
  "return_scene": StringName,
  "return_spawn": Vector2,
  "return_mode": "auto"
}
```

短期 `return_mode` 可以省略，统一由 `go_field_smart()` 读取 `SceneScript.is_walkable`。

如果未来存档需要准确恢复玩家位置，`return_spawn` 和当前玩家归一化坐标应进入 SaveManager v4。

## 6. 对话、任务、背包系统边界

### 6.1 对话

`DialogPlayer` 继续做：

- 播放节点
- 展示选项
- 执行节点副作用
- 处理 `next:<id>`
- 其他 `on_end` 交给 `SceneRouter.resolve_action()`

不建议让对话直接操作 UI 节点或场景节点。

### 6.2 任务

`QuestManager` 是任务 source of truth。

保留触发语法：

```text
enemy_defeated:<id>
scene_entered:<id>
item_picked_up:<id>
flag_set:<key>
npc_talked_to:<id>
```

下一步设计补强：

- 支持 `trigger_zones` 发 `flag_set` 或 action。
- NPC 对话时确保 `EventBus.npc_talked_to` 始终发出。
- 任务奖励继续通过 `GameState` / `Inventory` 发放。

### 6.3 背包装备

保持 `Inventory` autoload 作为唯一入口：

- `add_item`
- `remove_item`
- `use_item`
- `equip`
- `unequip`
- `to_dict/from_dict`

战斗只读装备加成，不直接改装备槽。

设计缺口：

- `open_inventory` action 尚未接 UI。
- 战斗中使用物品还没进入战斗 UI。
- 若 M6 加中毒/解毒，`Item` 需要支持 `remove_status` 或 `effects` 字段。

## 7. 存档设计边界

当前 v3 保存：

- `GameState`
- `QuestManager`
- `Inventory`
- `current_field`

v0.1 不强制升 v4。以下需求出现时再升：

- 保存玩家在可行走地图中的坐标
- 保存当前探索模式
- 保存战斗中断状态
- 保存角色状态异常
- 保存章节结算/章节进度

预期 v4 增量：

```gdscript
"field": {
  "scene_id": "ch1_s2_qingfeng_walkable",
  "player_spawn": Vector2 or Array[float],
  "mode": "auto"
},
"chapter": {
  "chapter_id": 1,
  "state": "in_progress"
}
```

存档升版纪律：

- `SaveManager` 增 migration。
- `docs/experience-log.md` 记录。
- 主菜单继续游戏路径实测。

## 8. 45° 回合制战斗架构

### 8.1 当前问题

`battle_controller.gd` 目前同时负责：

- 载入敌人和技能
- 回合状态机
- 伤害公式
- 敌人 AI
- UI 按钮
- 日志展示
- 奖励结算
- 场景跳转

这对 M1-M5 足够，但 M6 要做状态异常、Boss、章节结算和 45° 表现时会膨胀。

### 8.2 推荐拆分

先做逻辑拆分，再做表现升级。

```text
BattleController
  - 场景入口、按钮绑定、调用 session、更新 view

BattleSession
  - 当前战斗状态
  - actor 顺序
  - 回合推进
  - 胜负判断

BattleActor
  - runtime stats
  - side: player/enemy
  - statuses

BattleAction
  - skill/item/defend/flee
  - cost
  - target rule

BattleFormula
  - damage
  - hit/crit（未来）
  - defense/status modifiers

BattleView
  - 45° 站位
  - 动作播片/闪烁/飘字
  - 日志与 HUD
```

M6 可先落：

- `BattleFormula.gd`
- `StatusEffect.gd`
- `BattleAction` 可以先用 Dictionary，不急着 Resource 化

### 8.3 45° 表现层

“类似风云天下会的 45° 回合制”在本项目应解释为：

- 战斗背景是 2.5D/45° 场景图。
- 玩家站左下，敌人站右上或右侧。
- 角色仍用 2D sprite/立绘，不做格子移动。
- 回合制逻辑不变，表现时播放攻击前移、受击闪烁、技能特效和日志。

不要把 45° 写进伤害公式或任务逻辑。它只是 `BattleView` 的布局和动画规则。

### 8.4 状态异常

M6 状态系统字段：

```text
status_id
display_name
duration
stack_rule
tick_timing: turn_start / turn_end / on_hit
effect_type: poison / stun / defend / weaken
power
remove_condition
ui_icon_path
```

第一批只建议：

- `poison`：回合结束扣固定 HP
- `defend`：一回合减伤

不要一开始做眩晕、流血、内伤、连击等复杂状态。

## 9. 设计后的实施顺序

推荐 5 个小步，每步都可单独验收。

### Step 1：统一场景入口

目标：

- 新增 `SceneRouter.go_field_smart()`。
- `scene:<id>`、战后继续、商店返回、读档继续走 smart。

验收：

- `is_walkable=true` 的场景进入 `field_walkable.tscn`。
- `is_walkable=false` 的场景进入 `field.tscn`。
- 战斗胜利后回到正确模式。

### Step 2：地图碰撞数据化

目标：

- `SceneScript` 增 `collision_rects`、`trigger_zones`。
- `field_walkable_controller` 根据数据生成 CollisionShape2D / Area2D。

验收：

- 玩家不能穿过指定矩形障碍。
- 走进触发区可触发 action。
- 旧场景不填字段也能正常运行。

### Step 3：UI action 补齐

目标：

- `open_inventory`、`open_equipment`、`open_quest_log` 不再 warning。
- 通过 `EventBus.ui_requested` 交给 Field UI 打开。

验收：

- 对话节点可通过 action 打开背包/任务。
- 快捷键 I/E/J 继续可用。

### Step 4：战斗逻辑拆分第一步

目标：

- 抽出 `BattleFormula.gd`。
- 抽出最小状态异常模型。
- 保持现有 UI 和战斗体验不变。

验收：

- 现有教学战仍能胜利。
- `enemy_defeated:<id>` 任务触发不变。
- 装备加成仍生效。

### Step 5：45° 战斗表现设计落地

目标：

- 战斗场景布局改为 45° 站位。
- 增加 player/enemy battle sprite 容器。
- 先做攻击闪烁/前移/飘字，不做复杂技能动画。

验收：

- 回合节奏不变。
- 视觉上有明确左下对右上站位。
- 不影响战斗结算、任务、掉落。

## 10. 风险与约束

- `SceneRouter` 是关键路径，改动必须配测试和手测。
- `.tres` 是系统合同，字段新增必须保证旧数据默认值可运行。
- 背包、任务、战斗都依赖 `EventBus`，不能随意改信号名。
- 战斗数值归 `battle` agent，系统 agent 只设计架构与接口。
- 美术资源归 `art` agent，系统 agent 不应临时改最终资源路径。
- 新增 PNG 需要 Godot 编辑器生成 `.import`，提交前要检查资源完整性。

## 11. 待确认问题

1. 第一阶段是否正式把“可行走 Field”作为主探索模式，经典热点模式作为兼容/特殊场景？
2. 战斗 45° 表现是否仍保持 1v1，还是预留 1vN 敌人站位？
3. 地图障碍是否接受“手配矩形”作为第一章方案？
4. v4 存档是否在地图坐标落地时一起做，还是先保持 v3 只存 scene id？

建议默认答案：

- 第一章主流程用可行走 Field。
- 战斗先保持 1v1，但 `BattleView` 预留多敌人容器。
- 地图障碍先用手配矩形。
- v4 存档等玩家坐标确实需要持久化时再做。
