# 当前工作进展（快照）

> **更新日期：2026-05-04**  
> 用途：给协作者 / 新会话 AI 快速对齐「做到哪、卡在哪、下一步是什么」。  
> 详细决策仍以 `docs/world-bible.md`、`docs/design-mvp-chapter1.md`、`docs/experience-log.md` 为准。
> 协作规则：详见 `docs/agent-workflow.md`、`docs/module-owners.md`、`docs/agents/README.md`。

---

## 1. 叙事与世界观

| 文档 | 状态 |
|------|------|
| `docs/world-bible.md` | **v0.3 已定稿**（用户口头确认「后面再细调」）：冷孤云、刑樊天、悦无姮 / 戚云笙、茗雾山庄 / 烈云盟、多结局心向、命名禁忌（无蜘蛛意象等） |
| `docs/design-mvp-chapter1.md` | 已与 v0.3 对齐；**游戏内 `.tres` 对话里 `speaker` 仍大量为旧占位「沈不归」**，与 bible 不一致，属已知技术债，需批量替换为「冷孤云」及新地名文案 |

---

## 2. Godot 程序（`game/`）

### 2.1 里程碑（编码侧）

| 阶段 | 内容 | 状态 |
|------|------|------|
| **M1** | 数据驱动战斗、EventBus、Inventory 基础 | ✅ |
| **M2** | Field、热点、DialogPlayer、SceneRouter `resolve_action` | ✅ |
| **M3** | QuestManager、任务面板、存档 v2（quests + current_field） | ✅ |
| **M4** | 多场景、NPC 对话链、商店 `shop.tscn`、`SceneRouter` `shop:` 动作 | ✅（曾缺 `go_shop()`，已补） |
| **M5** | 背包 / 装备 UI、消耗品 `use_item`、**6 装备槽**（武器/头/甲/手/鞋/饰）、存档 **v3**（`inventory` 块）、Field HUD `I/E/J`、 starter `Inventory.reset_for_new_game()` | ✅ **代码已合入工作区**；人工验收以 `docs/mvp-m5-checklist.md` 为准 |
| **M6** | 章末演出、状态异常、章节结算 UI | ⏳ 未开始 |
| **M7** | 多槽存档 UI、加载流程打磨 | ⏳ 未开始（当前仍为单槽逻辑为主） |

### 2.2 主菜单与版本号

- 主菜单版本文案：**v0.3.0-m5 · inventory + equipment**（见 `main_menu.gd`）
- 标题展示为 **「林記 · 江湖行」**（与旧「风云·天下会」demo 区分）；`project.godot` 里 `config/name` 仍为历史名称，可后续统一

### 2.3 近期缺陷与修复

| 问题 | 处理 |
|------|------|
| `Parser Error: go_shop() not found` | `SceneRouter` 已补 `go_shop()` + `get_shop_payload()` |
| 「跑完几乎没 UI、很抽象」 | 根因：`game/art/**/*.png` **未进仓库**（仅 `.import`），背景 `TextureRect` 为空。已加 **FallbackBg**、野外 **HintBar**、热点按钮 **StyleBox** 兜底；主菜单运行时检测资源再加载 |
| 经典 Field / 可行走 Field 返回路径不统一 | ✅ 已新增 `SceneRouter.go_field_smart()`；主菜单新游戏/读档、战后继续、战斗逃跑、商店返回、对话 `scene:`、可行走出口均统一按 `SceneScript.is_walkable` 选择容器 |
| q2 任务资源与战后跳转断链 | ✅ 已修复 `q_ch1_main_02_qingfeng.tres` 字段粘连；战后对话从不存在的 `ch1_s2_linxi_road` 改跳 `ch1_s2_qingfeng_walkable`；新游戏恢复从 `ch1_s1_road` 开始 |
| 可行走地图缺少障碍/触发区数据合同 | ✅ `SceneScript` 已新增 `collision_rects` / `trigger_zones`，`field_walkable_controller.gd` 已按数据生成静态碰撞和进入式触发区 |
| `open_inventory` / `open_quest_log` action 仍 warning | ✅ 已新增 `EventBus.ui_requested(panel_id)`；`SceneRouter` 支持 `open_inventory` / `open_equipment` / `open_quest_log`，classic/walkable Field 复用现有 UI 打开逻辑 |
| 主角行走 sprite 白底 | ✅ 新增 `scripts/make_sprite_bg_transparent.py`，已将四张 `lengguyun_walk_*.png` 的边缘连通白底转为 alpha 透明 |
| 主菜单 / 背包 / 装备 / 战斗 UI 仍偏默认控件 | ✅ 新增 `WuxiaTheme`；UI 风格已定为 **寒山玄铁 · 雾蓝侠影**，用户已确认 `assets/raw/ui/cold_wuxia/v1/ui_cold_wuxia_common_kit_v1.png`，后续 UI 美术资产以此为 canonical reference，继续生成属性图标 / 战斗 HUD / 切图接入 |
| 主菜单文字白底/消失/风格不对 | ✅ 2026-05-08 修复：从 `assets/raw/ui/button/main_menu/text/v1` 原始图差分提取文字层，输出透明底 PNG 到 `game/art/ui/main_menu/buttons/text/v1`（420x120）；`main_menu.gd` 文字缩放比例调为 `0.38/0.33`；新增 `_update_continue_button_state()`，无存档时"读取存档"按钮+美术字一起灰化 |
| 主菜单按钮文字与底框不匹配 | ✅ 2026-05-08 处理：移除 `BLEND_MODE_MUL`（导致文字消失）；文字贴图按按钮尺寸动态缩放；lint 检查通过 |
| 前期场景图像 loading 图 | ✅ 新增 `docs/art-modular-scene-kit-v1.md` 与 `scene_module_atlas` 模板；`tasks.yaml` 增加 3 个模块化 kit 任务（默认 skip，需 dry-run 审稿后再出图） |

### 2.4 自动化测试

- `game/tests/test_inventory_m5.gd`：Inventory 使用 / 装备槽 / 序列化 roundtrip（需本机配置 Godot 可执行文件路径，见 `docs/experience-log.md` §14.1）
- `game/tests/test_scene_router_field_smart.gd`：验证 `SceneRouter.get_field_scene_path()` 会按 `SceneScript.is_walkable` 选择 classic / walkable Field 容器。
- 系统设计稿：`docs/system-technical-design-v0.1.md`（2026-05-04），覆盖地图/碰撞/路由/action/存档边界/45° 回合制战斗架构。
- 最新 system 交接文档：`docs/system-handoff-2026-05-04.md`，给下一个 AI 接续地图触发 / M6 前快速对齐最近代码改动、验证缺口和下一步。
- `SceneScript.collision_rects` / `trigger_zones` + `EventBus.ui_requested` 已落地；仍需 Godot 编辑器实机验收碰撞、触发区与 UI action。

---

## 3. 美术与资产管线（仓库根 `scripts/`、`prompts/`、`assets/`）

### 3.1 策略

- **L1**：ChatGPT Plus 网页小批量定风格  
- **L2**：`scripts/gen_assets.py` + DMXAPI，含余额探测 `scripts/ping_dmx.py`、`--skip-ping` 等工程化说明见 `docs/experience-log.md` §12–13

### 3.2 Stage 2（v0.3 角色 + 场景）

- **已通过并归档**：`assets/art_validation_v2/character_v2/`（6 张立绘）、`assets/art_validation_v2/scene_v2/`（3 张场景）
- **全局美术基调**：默认明亮鲜艳；叙事需要的暗调场景（如竹尾密林）保留 dusk + 高饱和（见 `world-bible` §5.8 与 `prompts/templates/_shared.yaml`）

### 3.2.1 主角 Sprite（试验，2026-04-28）

- 新增模板 `sprite_protagonist_idle` / `sprite_protagonist_parts_sheet`（分段提示词，参考外部分享文结构）。
- **动画帧**：`sprite_protagonist_idle_anim`（2 帧）、`sprite_protagonist_walk`（行走 f01）+ `sprite_protagonist_walk_ref`（f02～f04，锁 f01 外观）、`sprite_protagonist_attack`（3 帧），**896×896**、**侧向 Field 镜头**（对齐 `Sprite2D.flip_h`，非 45° 地砖等距），任务 id 见 `docs/sprite-prompt-playbook.md`。
- **最新出图**（2026-04-29）：按老式武侠 RPG 侧向移动观感，使用 `gpt-image-2`（禁 fallback 到 1.5）重跑主角 sprite 10 张：idle 1、idle_anim 2、walk 4、attack 3；输出在 `assets/raw/sprite/v2/`。
- **四向行走 sheet**（2026-04-30）：新增 `sprite_protagonist_walk_4dir_sheet` / `sprite_lengguyun_walk_4dir_sheet`，参考用户提供的武侠 sprite sheet，一次生成 **4 方向 × 4 帧**；输出在 `assets/raw/sprite/v3/`。
- **低成本优化规则**（2026-04-30）：sprite 尚未最终解决，新增 `docs/sprite-cost-optimization-plan.md`；付费出图前必须先跑 QA / 固定锚点 GIF / dry-run，避免盲目消耗 API。
- **主角 walk 状态更新**（2026-05-04）：Seedance 视频方案因 DMXAPI 无通道、火山方舟模型未开通/成本偏高而暂停；MVP 改为 image 方式混合帧数接入：右 / 左 8 帧 `stable_from_4f`，上 / 下 4 帧 `balanced_slow`。已复制到 `game/art/characters/lengguyun_walk_*.png` 并接入 `player.gd`。详见 `docs/sprite-prompt-playbook.md` 与 `docs/experience-log.md` §19.24-§19.33。
- 默认任务：`sprite_lengguyun_idle_south`（priority 2）；拆件总图 `sprite_lengguyun_parts_sheet` 默认 **`skip: true`**。
- 操作说明：`docs/sprite-prompt-playbook.md`。

### 3.3 未决 / 技术债

| 项 | 说明 |
|----|------|
| `assets/_style_bible/` 下 3 张 v0.3 主角参考图 | **用户选择暂留不归档**；工作区可能仍有 modified/untracked |
| `prompts/templates/character_portrait.yaml` | 仍可能引用旧 IP 参考图路径；等 v0.3 主角参考正式归档后再改 |
| **游戏内背景路径** | `SceneScript.background_path` 仍指向 `res://art/backgrounds/*.png`；若仓库无 PNG，依赖 **FallbackBg**；长期应把 v2 场景图复制进 `game/art/backgrounds/` 或改路径 |

---

## 4. 建议的下一步（优先级）

> 全部下一步都按 `docs/agent-workflow.md` 走：producer 拆任务 → 单模块 agent 实现 → qa 跑回归 → review 审。

1. **内容（lore）**：批量将 `game/data/dialogs/*.tres` 中 `speaker`/文案从「沈不归 / 清风镇…」迁到 **world-bible v0.3**（可与第一章 checklist 分段做）  
2. **验收（qa/system）**：用 Godot 编辑器打开项目，让新增 `game/art/characters/lengguyun_walk_*.png` 生成 `.import`，并实机检查 Player 四方向行走、`go_field_smart()`、walkable 障碍碰撞、触发区 `set_flag`、以及 `open_inventory` / `open_equipment` / `open_quest_log` action。  
3. **系统设计（system）**：进入 `docs/system-technical-design-v0.1.md` Step 4，先抽 `BattleFormula.gd` / 最小 `StatusEffect.gd`，为 M6 章末 Boss 与状态异常铺路。  
4. **自动化（system）**：配置 `GODOT_BIN` 后跑 `game/tests/test_scene_router_field_smart.gd`、`game/tests/test_player_walk_animation.gd` 与 `game/tests/test_inventory_m5.gd`；必要时新增 trigger zone/UI action 测试。

---

## 5. 启动游戏（备忘）

- Godot 4：**导入** `F:\Code\RPG_GAME\game\project.godot` → `F5`  
- 命令行：`Godot*.exe --path <仓库>\game`

---

## 6. 多 Agent 协作（v0.1）

| 项 | 状态 |
|----|------|
| `docs/agent-workflow.md`（角色 / 标准流程 / 交接格式 / 试运行示例） | ✅ 2026-04-30 落地 |
| `docs/module-owners.md`（模块写权归属表） | ✅ 2026-04-30 落地 |
| `docs/agents/`（7 个角色独立长期记忆 + README + 模板） | ✅ 2026-04-30 落地 |
| `docs/acceptance-checklists/{lore,system,battle,art,qa}.md`（5 张验收清单） | ✅ 2026-04-30 落地 |
| `AGENTS.md` 增「多 Agent 协作」速查节与角色 memory 读取顺序 | ✅ 2026-04-30 落地 |
| `docs/experience-log.md` §16「多 Agent 协作启动」与 §17「角色独立记忆」 | ✅ 2026-04-30 追加 |
| **首次试运行**：8 帧右走 sprite 闭环（producer → art → qa → review） | ✅ 已完成：9 格 loop-check 版 QA PASS，旧 8 帧仅保留历史对照（详见 `docs/pilot-handoff-sprite-walk-right-8f.md`） |
| `tools/agent_hub/` 本地 Web 调度台（handoff 生成 + 产出/QA/成本扫描） | ✅ 2026-05-01 第一版落地；不调用独立大模型，实际执行仍由 Cursor agent 完成 |
| Agent Hub 中文化与专业视觉升级 | ✅ 2026-05-01 完成：页面中文标签 + 武侠项目驾驶舱风格；主要路由 smoke test 全 200 |
| Agent Hub 故事剧情总览页 | ✅ 2026-05-01 完成：角色、门派势力、八章主线、四结局路线；`/story` 本地服务返回 200 |
| Agent Hub 需求列表页 | ✅ 2026-05-05 完成：新增 `/requirements`，按大模块 / 子模块 / 功能需求跟踪，支持新增需求、更新状态、从需求拆任务；并新增“工作证明门禁”（摘要+证据链接）后才可标记完成；初始数据来自 `docs/requirements.yaml` |

| 主角四方向 walk sprite | ✅ 2026-05-04 MVP 接入：右 / 左 8 帧 `stable_from_4f` + 上 / 下 4 帧 `balanced_slow`，已绑定到 `player.gd`；仍需 Godot 编辑器生成 `.import` 并实机验收 |
| system 交接文档 | ✅ 2026-05-04 新增 `docs/system-handoff-2026-05-04.md`；Agent Hub 扫描后归属 `system`，可在 system 角色页的重要文档预览中查看 |

> 任意 agent 在新会话开始时必须先读 `agent-workflow.md`、`module-owners.md`、`agents/README.md` 与自己的 `docs/agents/<role>-memory.md`，再按任务领取角色。

---

## 6. 资产目录重组（2026-05-08）

### 6.1 新目录结构

```
assets/
├── raw/                  # AI 生成原始输出（gen_assets.py 直接写这里）
│   ├── ui_button/
│   ├── ui_dialog/
│   ├── ui_icon/
│   ├── ui_frame/
│   ├── scene_background/
│   ├── character_portrait/
│   └── sprite_sheet/
├── library/              # 资产库（整理后，含 meta.json）
│   ├── ui_button/ / ui_dialog/ / ui_icon/ / ui_frame/
│   ├── scene_background/ / character_portrait/ / sprite_sheet/
│   └── audio/           # 未来
├── adopted/              # 游戏实际采用的（从 library 复制进来）
├── previews/             # GIF 预览动画（保留）
├── _style_bible/        # 风格参考（暂留）
└── _archive/             # 已淘汰/废弃（移入这里，不删除）
```

`game/art/` 同步更新子目录：`ui/button/`、`ui/dialog/`、`ui/icon/`、`ui/frame/`、`ui/cursor/`、`backgrounds/`、`characters/`、`sprites/`、`audio/`

### 6.2 调度台改动

- `artifacts` 表新增字段：`category`（资产分类）、`adopted_status`（采用状态：adopted/candidate/rejected）
- `scanner.py` 新增 `_category_for_asset()` 和 `_adopted_status_for_path()` 自动识别分类
- `app.py` `/artifacts` 路由支持 `category` + `adopted_status` 筛选
- `artifacts.html` 模板新增分类筛选下拉 + 表格列展示

### 6.3 已迁移文件

| 原路径 | 新路径 |
|---------|---------|
| `assets/raw/character/*` | `assets/_archive/raw_character_old/` |
| `assets/raw/ui/button/main_menu/*` | `assets/raw/ui_button/` |
| `assets/raw/ui/icon/*` | `assets/raw/ui_icon/` |
| `assets/raw/ui/dialog/*` | `assets/raw/ui_dialog/` |
| `assets/raw/ui/cold_wuxia/v2/cursors/*` | `assets/raw/ui_button/` |
| `assets/raw/ui/cold_wuxia/v2/*bg*` | `assets/raw/scene_background/` |
| `assets/raw/ui/cold_wuxia/v2/*screen*` | `assets/raw/ui_dialog/` |
| `assets/raw/sprite/*` | `assets/raw/sprite_sheet/` |
| `assets/raw/consistency_test/*` | `assets/_archive/` |
| `assets/_diagnostic/*` | `assets/_archive/` |
| `assets/processed/sprite/*` | `assets/library/sprite_sheet/` |
| `assets/processed/ui/*` | `assets/library/ui_button/` |
| `assets/art_validation_v2/*.png` | `assets/library/`（按类型分发）|

### 6.4 待处理

- [x] `assets/raw/ui/cold_wuxia/` 剩余文件需手工确认分类（已完成：`cold_wuxia/` 已不存在，文件已迁移）
- [x] `game/art/` 中现有文件需按新子目录分类移动（已完成：`button/`、`cursor/` 统一单数，`cold_wuxia/` 已清理）
- [x] 调度台页面：`/artifacts` 分类筛选后分页链接需验证（已完成：`artifact_url` 正确包含 category + adopted_status 参数）
- [x] `assets/adopted/` 流程：标记某个 asset 为"已采用"时自动复制到 `game/art/` 对应目录（已完成：后端 API + 前端按钮 + 自动复制逻辑）

### 6.5 正式场景/UI 进入生产（2026-05-08）

已完成准备工作：
- [x] `prompts/tasks.yaml` 新增 4 个生产任务：`scene_zhuwei_main_street`（竹尾村主街）、`scene_west_ruin`（城西废宅）、`scene_battle_bamboo_road`（竹林战斗场）、`ui_cold_wuxia_dialog_box_v1`（冷色对话框）
- [x] `ui_cold_wuxia_common_kit_v1` 从 `skip: true` 改为 `skip: false`
- [x] 场景 `.tres` 文件 `background_path` 已更新为正式文件名（不再使用占位图）：
  - `ch1_s1_road.tres` → `res://art/backgrounds/bg_ch1_s1_road.png`
  - `ch1_s2_qingfeng.tres` → `res://art/backgrounds/bg_zhuwei_main_street.png`
  - `ch1_s3_west_ruin.tres` → `res://art/backgrounds/bg_west_ruin.png`
- [x] `prompts/templates/ui_cold_wuxia_kit.yaml` 参考图路径已清理（原图已归档）
- [x] dry-run 验证通过（5 任务全部正确解析）

**阻塞项**：DMXAPI 账户欠费（-$0.20），需充值后方可执行。

充值后一键生成命令：
```bash
cd f:\Code\RPG_GAME
python scripts/gen_assets.py --task scene_ch1_s1_road --task scene_zhuwei_main_street --task scene_west_ruin --task scene_battle_bamboo_road --task ui_cold_wuxia_dialog_box_v1 --task ui_cold_wuxia_common_kit_v1 --skip-ping
```

生成后还需：
1. 复制场景背景到 `game/art/backgrounds/`：
   - `scene_ch1_s1_road.png` → `bg_ch1_s1_road.png`
   - `scene_zhuwei_main_street.png` → `bg_zhuwei_main_street.png`
   - `scene_west_ruin.png` → `bg_west_ruin.png`
   - `scene_battle_bamboo_road.png` → `bg_battle_default.png`（覆盖占位）
2. 对话框 UI 切图并接入 `dialog_box.tscn`
3. 通用 UI kit 切图接入 WuxiaTheme

