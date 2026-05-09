# System Handoff - 2026-05-04

> 给下一个 AI / system agent 接续用。  
> 当前重点：Godot 系统路由、可行走地图、主角四方向 sprite 接入后的实机验收。

## 接续前必读

- `AGENTS.md`
- `docs/current-progress.md`
- `docs/agent-workflow.md`
- `docs/module-owners.md`
- `docs/agents/README.md`
- `docs/agents/system-memory.md`
- `docs/system-technical-design-v0.1.md`
- `docs/experience-log.md`

## 当前项目状态

项目路径：`F:\Code\RPG_GAME`

Godot 项目路径：`game/project.godot`

当前可玩系统主链路：

- 主菜单
- Field 场景
- 对话 / 任务 / 战斗 / 商店
- 背包 / 装备 / 任务 UI
- 单槽存档 v3，包含 `inventory`

当前技术主线已经从 sprite 生成转入 `system` agent 的 Godot 模块设计与落地。

## 最近已完成

### 主角四方向行走 sprite MVP 接入

主角行走采用混合帧数策略：

- 右 / 左：8 帧 `stable_from_4f`
- 上 / 下：4 帧 `balanced_slow`

已接入到 Godot：

- 资源已复制到 `game/art/characters/lengguyun_walk_*.png`
- `game/scripts/field/player.gd` 已按方向切换 sprite sheet 和帧数
- `game/scenes/player.tscn` 已使用真实 sprite sheet 默认纹理
- `game/scripts/field/field_walkable_controller.gd` 已避免旧 `portrait_path` 逻辑覆盖玩家方向动画
- 新增 `game/tests/test_player_walk_animation.gd`

待验收：

- 需要用 Godot 编辑器打开项目，让新增 PNG 生成 `.import`
- 需要实机检查四方向移动节奏，尤其是上 / 下 4 帧是否够自然

### 系统技术设计 v0.1

已新增 `docs/system-technical-design-v0.1.md`，覆盖：

- 地图与场景加载
- classic Field / walkable Field 的路由边界
- 角色碰撞、出口、spawn 数据约定
- Dialog / Quest / Inventory / SaveManager 边界
- 45 度回合制战斗的分层设计
- 分步实施顺序

### Agent Hub 文档预览

Web 调度台已支持 Markdown 预览：

- `.md` 文档默认显示渲染预览
- `?raw=1` 可看源码
- 角色详情页会嵌入 role memory 和重要文档正文

本地部署注意：

- `8765` 端口曾被 Cursor 旧监听占用
- 新版本发布在 `http://127.0.0.1:8766`

## 最新代码改动：Step 1-3 系统主干收束

已完成 `docs/system-technical-design-v0.1.md` 的 Step 1，并补齐 Step 2 / Step 3 的第一版实现。

核心新增：

- `SceneRouter.go_field_smart(scene_id, player_spawn?)`
- `SceneRouter.get_field_scene_path(scene_id)`
- `SceneScript.collision_rects` / `SceneScript.trigger_zones`
- `EventBus.ui_requested(panel_id)`

行为：

- 读取 `res://data/scenes/<scene_id>.tres`
- 如果 `SceneScript.is_walkable == true` 且 `field_walkable.tscn` 存在，进入 `res://scenes/field_walkable.tscn`
- 否则进入 classic `res://scenes/field.tscn`
- 可选 `player_spawn` 只在 walkable 容器下生效

已改入口 / 数据：

- 主菜单新游戏恢复从 `ch1_s1_road` 开始，避免绕过 q1/q2
- 主菜单继续游戏 / 读档
- `SceneRouter.resolve_action("scene:<id>")`
- 战斗胜利继续
- 战斗逃跑返回
- 商店关闭返回
- 可行走场景出口跳转
- `ch1_road_after_thug.tres` 战后跳转改为 `scene:ch1_s2_qingfeng_walkable`
- `q_ch1_main_02_qingfeng.tres` 修复字段粘连，完成触发改为 `scene_entered:ch1_s2_qingfeng_walkable`
- `ch1_s2_qingfeng_walkable.tres` 增加最小 `collision_rects` / `trigger_zones` 样例

相关文件：

- `game/scripts/autoload/scene_router.gd`
- `game/scripts/ui/main_menu.gd`
- `game/scripts/ui/result_victory.gd`
- `game/scripts/ui/shop_ui.gd`
- `game/scripts/battle/battle_controller.gd`
- `game/scripts/field/field_walkable_controller.gd`
- `game/scripts/field/field_controller.gd`
- `game/scripts/domain/scene_script.gd`
- `game/scripts/autoload/event_bus.gd`
- `game/data/quests/q_ch1_main_02_qingfeng.tres`
- `game/data/dialogs/ch1_road_after_thug.tres`
- `game/data/scenes/ch1_s2_qingfeng_walkable.tres`
- `game/tests/test_scene_router_field_smart.gd`

## 验证状态

已做：

- Cursor lints：相关 GDScript 文件无新增错误
- 搜索确认：`game/` 下没有残留直接调用 `SceneRouter.go_field(` / `SceneRouter.go_field_walkable(`
- 搜索确认：不存在 `ch1_s2_linxi_road` 残留和 `desc_completed = ...completion_triggers` 字段粘连
- PowerShell `Get-Command Godot,godot` 未找到可执行文件

未做：

- 当前 shell 找不到 `godot` / `Godot`
- `GODOT_BIN` 未设置
- 因此 Godot SceneTree 测试尚未实际运行

后续需补跑：

```powershell
Godot --headless --path game --script res://tests/test_scene_router_field_smart.gd
Godot --headless --path game --script res://tests/test_player_walk_animation.gd
Godot --headless --path game --script res://tests/test_inventory_m5.gd
```

## 下一步建议

Step 2 / Step 3 已编码完成，下一步先做 Godot 实机验收，再进入 Step 4 / M6。

优先任务：

1. 用 Godot 编辑器打开项目，确认无 Parser Error / Resource Load Error，并生成新增 sprite `.import`。
2. 实机验收 `go_field_smart()` 的所有入口：新游戏、读档、战斗胜利、战斗逃跑、商店返回、对话切场景、出口切场景。
3. 实机验收 `ch1_s2_qingfeng_walkable.tres` 的 `collision_rects`：玩家不能穿过两个样例障碍。
4. 实机验收 `trigger_zones`：走入 `town_gate_notice` 后应触发 `set_flag:visited_linxi_gate:true`，且不应把玩家瞬移回默认出生点。
5. 实机验收 action UI：对话 / 数据中触发 `open_inventory`、`open_equipment`、`open_quest_log` 时，应打开现有背包 / 装备 / 任务面板。
6. 通过后进入 Step 4：抽 `BattleFormula.gd` 与最小 `StatusEffect.gd`，为 M6 章末 Boss / 状态异常 / 章节结算铺路。

## 注意事项

- 当前工作区有大量 modified / untracked 文件，很多是用户或之前 agent 的产出。不要随意 revert、删除或清理。
- `SceneRouter.go_field()` 和 `go_field_walkable()` 仍作为底层兼容入口存在，但新业务入口应优先使用 `go_field_smart()`。
- `docs/system-*.md` 会被 Agent Hub 归属到 `system` agent，并在 system 角色页的重要文档里显示。
- 每次遇到问题修复后，继续追加 `docs/experience-log.md`，避免反复踩坑。
