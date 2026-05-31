# AGENTS.md · AI 助手项目记忆

> 这是 Cursor / Claude Code / Codex 等 AI agent 工具的**自动加载文件**。  
> 新对话开启时 AI 应当依次读：本文件 → **`docs/current-progress.md`**（快照）→ `docs/ai-rules.md`（AI 开发硬规则）→ `docs/ui-style-guide.md`（当前 UI 规范）→ `docs/agent-workflow.md`（多 Agent 协作规则）→ `docs/module-owners.md`（模块归属）→ `docs/agents/README.md`（角色记忆索引）→ `docs/agents/producer-memory.md`（主控记忆）→ `docs/experience-log.md`→ **`docs/game-design-skills/README.md`**（游戏设计技能参考），然后才回应用户。  
> 维护者（人或 AI）：每完成一个里程碑，更新"已完成"和"待办"。

---

## 📍 一句话现状

漫画 2.5D 武侠 AVG-RPG（玩法致敬《风云之天下会》1998），叙事与设计以 **`docs/world-bible.md` v0.3** 为准。**M1–M5 编码已在工作区落地**；M5 与兜底 UI、SceneRouter 商店接口等详见 **`docs/current-progress.md`（2026-04-28 快照）**。

**当前可玩闭环（偏工程验收）**：
主菜单 → Field 多场景（含商店 `shop:`）→ 对话 / 任务 / 战斗 → **I 背包 · E 装备 · J 任务** → 存档 **v3**（含 `inventory`）。若仓库内无 `game/art/**/*.png`，背景为 **FallbackBg + HintBar**，不再「一片空」。

### 🎯 v0.2.0 总目标（用户拍板 2026-04-26）

完成"开场到第一章结束"的端到端 5-8 分钟可玩 MVP，包含：
- AVG 式点击场景（不做顶视角自由走，更适配 GPT Image 美术）
- 1v1 回合制战斗（已有，本期数据驱动化）
- 背包/装备/任务/对话/商店各一个最小但端到端可用的版本
- 叙事主设定：**冷孤云 / 林西村下山**（`world-bible` v0.3）；`game/data/dialogs/` 中「沈不归」「清风镇」「黑教」已批量替换为「冷孤云」「竹尾村」「茗雾山庄」
- 7 个 milestone（M1-M7），合计约 10 小时编码

详见 `docs/design-mvp-chapter1.md`（决策依据 + 系统模块图 + 数据模型）。

---

## 🗂️ 仓库

- GitHub: <https://github.com/rajqiu2022/cw_rpg>
- 默认分支：`main`
- 工作区路径（任意机器都行）：克隆后随便放

```bash
git clone https://github.com/rajqiu2022/cw_rpg.git
cd cw_rpg
```

---

## 📦 项目两条腿（互不依赖）

```
RPG_GAME/
├── game/             ← Godot 4 项目（双击 game/project.godot 开）
├── scripts/          ← Python 资产管线（pip install -r scripts/requirements.txt）
├── prompts/          ← AI prompt YAML 模板
├── assets/           ← AI 出图原图 + Style Bible
├── images/           ← Lovart 网页版下载的 6 张高质量参考图（中文名）
├── docs/             ← 决策文档 + 经验记录
│   ├── tech-selection.md
│   ├── art-pipeline.md
│   ├── budget.md
│   ├── alapi-image-api.md
│   ├── art-modular-scene-kit-v1.md
│   ├── scene-element-kit-spec.md   ← 4 类场景元素 atlas 规范
│   ├── style-bible-prompts.md
│   ├── godot-demo-howto.md       ← Godot demo 运行手册
│   ├── current-progress.md       ← 当前进展快照（建议每次里程碑后更新）
│   ├── sprite-prompt-playbook.md ← 主角 sprite 分段提示词 + 跑图命令
│   ├── sprite-cost-optimization-plan.md ← sprite 未解决前的低成本优化纪律
│   ├── agent-workflow.md         ← 多 Agent 协作工作流（角色 / 交接 / 验收）
│   ├── module-owners.md          ← 模块写权归属表（避免互相覆盖）
│   ├── agents/                   ← 角色独立长期记忆（producer/lore/system/battle/art/qa/review）
│   ├── game-design-skills/       ← 游戏设计参考技能（基于《游戏设计的100个原理》，7 篇）
│   ├── acceptance-checklists/    ← 各角色验收清单（lore/system/battle/art/qa）
│   └── experience-log.md         ← 所有踩坑记录（必读）
├── .env              ← 本地 API Key（gitignored，新机器需重建）
└── AGENTS.md          ← 本文件（AI 自动读取）
```

---

## ✅ 已完成

### 1. AI 资产管线（scripts/ + prompts/）
- `gen_assets.py` 异步批量调图，唯一后端：ALAPI（`v3.alapi.cn`，`token` 头）
- 自动重试、预算限流、`meta.json` 完整记录（model/backend/cost/currency）
- ALAPI 使用 `token` 头认证（非 `Authorization: Bearer`），走 POST `.../images/generations`

### 2. 已实测产出（assets/raw/）
- ✅ `portrait_bujingyun_neutral.png` — 主角立绘（已升为 Style Bible）
- ✅ `portrait_bujingyun_angry.png` — 主角愤怒
- ✅ `sprite_bujingyun_idle_south.png` — 精灵图（不太行，已弃用）
- ✅ `ui_button_normal_start.png` — UI 按钮
- ✅ `icon_skill_paiyunzhang.png` — 技能图标
- ✅ `scene_tianxiahui_main_hall.png` — 场景背景

### 3. 已收 Lovart 6 张高质量参考图（images/）
- `游戏主界面UI.png` `装备界面UI.png` `角色创建界面UI.png`
- `1777180910974.png`（场景）`task_1494656_1.png` `task_1494976_1.png`（人物）
- 历史上曾复制进 `game/art/` 作占位；**若 git 未跟踪实际 `.png`，运行时只有 `.import` 不够**，需用 v2 归档图补库或依赖 `FallbackBg`（见 `docs/experience-log.md` §14.4）

### 4. Godot 4 程序骨架（game/）— v0.1.0
完整可跑的最小闭环：**主菜单 → 战斗 → 胜利/失败 → 存档**（2026-04-27 实机验收通过）

### 5. v0.2.0-M1 数据驱动重构（2026-04-26）
- 5 个 autoload：`EventBus` / `GameState` / `Inventory` / `SceneRouter` / `SaveManager`
- 8 个 domain Resource 类：`CharacterStats` / `Skill` / `Item` / `Equipment` / `EnemyDef` / `DialogNode` / `DialogScript` / `SceneScript` / `QuestDef` / `ShopDef`
- 14 个 .tres 数据文件：4 技能 + 3 敌人 + 4 物品 + 2 装备 + 1 商店
- BattleController 重构为数据驱动：
  - 敌人/技能从 .tres 加载，新增敌人/技能 = 加文件不改代码
  - 装备加成自动叠加到攻击/防御/速度
  - 战利品按 EnemyDef.drop_*（必掉 + 概率掉）自动入背包
  - 关键事件广播 EventBus（QuestManager 将订阅）
- 默认主角显示名：`GameState` 已为 **冷孤云**（旧对话 `.tres` 里 speaker「沈不归」已批量替换完成）

### 6. v0.2.0-M2 探索场景 + 对话系统（2026-04-26）

新增 6 个 autoload（含 EventBus / DialogPlayer）+ Field 场景 + 全局 DialogBox：

- `EventBus` 信号枢纽（已 M1 完成，M2 加 `flag_set` / `dialog_started` / `dialog_ended` / `hotspot_triggered`）
- `DialogPlayer` autoload：playstateful 对话流；自动 instantiate `dialog_box.tscn` 加到 root；管理 node 推进、choices、副作用、结束动作
- `DialogBox` UI（`scenes/ui/dialog_box.tscn` + `ui/dialog_box.gd`）：底部立绘 + 名字 + 富文本 + 选项按钮
- `FieldController`（`scenes/field.tscn` + `field/field_controller.gd`）：背景 + 浮动 hotspot 按钮（按 0~1 浮点比例定位）+ HUD 金币
- `SceneRouter` 加 **action 字符串解析中枢** `resolve_action(s)`：支持 `dialog:` / `battle:` / `scene:` / `give_item:` / `give_gold:` / `set_flag:` / `accept_quest:` / `complete_quest:` / `open_inventory` / `open_quest_log`
- DialogNode 拆 **副作用**（give_items / give_gold / set_flags / accept_quest / complete_quest）和 **结束动作**（on_end="next:id" / "battle:id" / "scene:id" / "end"），同节点可叠加多个副作用 + 一条导航
- BattleController 胜利时自动写入 `defeated_<enemy_id>` flag → hotspot 用 `hide_flag` 自动隐藏打过的怪
- `start_battle` → `go_victory` → `go_field` 闭环带 `return_scene`，胜利后回原场景而非主菜单
- 5 个新 .tres 数据：场景 1 `ch1_s1_road` + 4 段对话（进场 / 石碑 / 尸体 / 战后剧情）
- 主菜单从直跳战斗改为 `SceneRouter.go_field("ch1_s1_road")`

**M2 完整闭环**：主菜单 → 官道 → 进场对话（3 节）→ 点石碑（2 节，set_flag）→ 点尸体（2 节，触发战斗）→ 战斗胜利 → 回官道（尸体按钮消失，"继续前行"按钮出现）→ 看战后剧情（拿地图+麻衣+8 金）。

### 7. v0.2.0-M3 Quest 系统（2026-04-26）

第 7 个 autoload `QuestManager` + 任务面板 UI + 2 个主线任务 + 存档持久化：

- `QuestManager` autoload：
  - 状态机（NOT_STARTED / IN_PROGRESS / COMPLETED / FAILED），单一 source of truth
  - 订阅 EventBus 5 类事件信号（enemy_defeated / scene_entered / item_picked_up / flag_set / npc_talked_to）
  - Trigger 字符串语法：`enemy_defeated:<id>` / `scene_entered:<id>` / `flag_set:<key>` / ...
  - accept(qid) / complete(qid) 唯一对外 API；外部禁止直接 emit `EventBus.quest_accepted`（避免重入循环）
  - complete 时自动通过 `GameState.add_gold` / `player.gain_exp` / `Inventory.add_item` 发奖
- DialogPlayer 改：节点副作用里 `accept_quest` / `complete_quest` 字段直接调 `QuestManager.accept/complete`
- SceneRouter.resolve_action：`accept_quest:<id>` / `complete_quest:<id>` 命令也走 QuestManager
- FieldController 加任务面板：右下角 RichTextLabel 显示当前任务列表，主线任务橙点 ●，实时刷新；右上 HUD 加 「任务 (J)」按钮 / J 键切换面板
- 2 个 quest .tres：
  - `q_ch1_main_01_thug`「风波再起」trigger=`enemy_defeated:thug_lone`，奖励 12 金 + 10 exp
  - `q_ch1_main_02_qingfeng`「打探清风镇」trigger=`scene_entered:ch1_s2_qingfeng`（M4 完成）
- 任务接受时机：`ch1_road_intro` 第 3 节自动接 q1；`ch1_road_after_thug` 第 2 节自动接 q2
- SaveManager 升级 schema 到 version=2：新增 `quests`（QuestManager.to_dict）和 `current_field` 字段
- 主菜单「继续游戏」改为读取存档里的 `current_field` 跳回原场景（不再硬编码回官道）

**M3 完整闭环**：主菜单 → 官道（自动接 q1）→ 战斗（自动完成 q1 + 发奖）→ 回官道 → 战后剧情（自动接 q2）→ 存档 → 重启「继续」回原场景，q1 仍 completed、q2 仍 in_progress。

### 8. v0.2.0-M4 多场景 + NPC + 商店（2026-04）

- 多 `SceneScript` 场景（如清风镇主街 / 城西废宅）、NPC 热点、`ShopDef` + `shop.tscn` 买卖闭环
- **`SceneRouter` 必须同时提供** `go_shop()`、`get_shop_payload()`（曾漏 `go_shop` 导致解析期报错，已修）

### 9. v0.3.0-M5 背包 / 装备 + 存档 v3（2026-04-28）

- Field HUD：**背包 (I) / 装备 (E) / 任务 (J)**；`Inventory.use_item`、**6 装备槽**、`SaveManager` **version 3** 写入 `inventory`
- 主菜单 **新游戏** 调 `Inventory.reset_for_new_game()` 给少量 starter 物品
- **无 PNG 时的 UI 兜底**：`FallbackBg`、野外底部 **HintBar**、热点按钮半透明样式（见 `docs/experience-log.md` §14.4）

### 10. 资产目录重组（2026-05-08）

#### 10.1 新目录结构

```
assets/
├── raw/                  # AI 生成原始输出
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
│   └── audio/
├── adopted/              # 游戏实际采用的（从 library 复制进来）
├── previews/             # GIF 预览动画（保留）
├── _style_bible/        # 风格参考（暂留）
└── _archive/             # 已淘汰/废弃（移入这里，不删除）
```

`game/art/` 同步对齐：
```
game/art/
├── ui/button/、ui/dialog/、ui/icon/、ui/frame/、ui/cursor/
├── backgrounds/、characters/、sprites/、audio/
```

#### 10.2 调度台改动

- `artifacts` 表新增字段：`category`、`adopted_status`（adopted/candidate/rejected）
- `scanner.py` 新增 `_category_for_asset()` + `_adopted_status_for_path()`
- `app.py` `/artifacts` 路由支持 `category` + `adopted_status` 筛选
- 前端新增"采用/拒绝/重置"操作按钮，自动复制到 `game/art/` 对应目录

#### 10.3 已迁移文件

| 原路径 | 新路径 |
|---------|---------|
| `assets/raw/character/*` | `assets/_archive/raw_character_old/` |
| `assets/raw/ui/button/main_menu/*` | `assets/raw/ui_button/` |
| `assets/raw/sprite/*` | `assets/raw/sprite_sheet/` |
| `assets/raw/ui/cold_wuxia/**` | 按类型分发到 `raw/` 各分类目录 |
| `game/art/ui/buttons/*` | `game/art/ui/button/`（规范用单数）|
| `game/art/ui/cursors/*` | `game/art/ui/cursor/` |
| `game/art/ui/cold_wuxia/v1/*` | 按类型迁入 `game/art/ui/icon/` 或 `game/art/ui/frame/` |

### 11. 游戏设计技能参考引入（2026-05-08）

- 从 [OrangeViolin/Game Design Skill](https://gist.github.com/OrangeViolin/53ad898cdbc8734d8bb5c6a6ddf5cec4) 下载 7 篇关键技能文件到 `docs/game-design-skills/`
- 每篇均含「对本项目的应用」章节，直接映射到 M6/M7 开发
- 覆盖：动态难度调整、角色属性平衡、心流设计、叙事节奏、环境叙事、加倍减半数值法、奖励反馈循环
- 后续 M6（章末 Boss）开发时需优先阅读 `dynamic-difficulty-adjustment.md` + `doubling-halving-balance.md`

---

## 🚧 待办（v0.2.0 路线 — 按 milestone 推进）

| M | 时长 | 内容 | 状态 |
|---|---|---|---|
| **M1** | 1.5h | 数据驱动重构 + EventBus + Inventory | ✅ 已完成 |
| **M2** | 2h | 探索场景 Field + 互动热点 + 对话系统 | ✅ 已完成 |
| **M3** | 1.5h | Quest 系统 + 主线任务 1 | ✅ 已完成 |
| **M4** | 1.5h | 多场景跳转 + NPC 对话 + 商店 | ✅ 已完成 |
| **M5** | 1h | 背包/装备 UI + 物品使用 | ✅ **已验收** |
| **M6** | 1.5h | 章末 Boss + 状态异常 + 章节结算 | ⏳ 下一步 |
| **M7** | 1h | 5 槽存档 + 加载/继续游戏 | ⏸ |

> 全程不做：动画特效 / BGM / 多人队伍战 / 第二章 / 多语言 / 打包发布。详见 `docs/design-mvp-chapter1.md` §11。

---

## 🤝 多 Agent 协作（v0.1，2026-04-30）

> 详见 `docs/agent-workflow.md`、`docs/module-owners.md`、`docs/agents/README.md`。本节是给 AI 的速查。

- **8 个固定角色**：`producer`（主控）/ `lore`（剧情）/ `system`（Godot 系统）/ `battle`（战斗数值）/ `art`（美术管线）/ `art-review`（UI 美术审核）/ `qa`（测试）/ `review`（代码审查）。
- **独立角色记忆**：每个角色都有 `docs/agents/<role>-memory.md`。领取任务前必须读取自己的 memory；完成后只把角色相关经验写回自己的 memory。跨角色决策写入 `producer-memory.md`，耐久踩坑仍写 `docs/experience-log.md`。
- **写权归属**：见 `docs/module-owners.md`，**同一模块同时只允许一个 agent 写改**。其他角色只读，发现需改要走 producer 排队。
- **每次开口先声明角色**：`[handoff] from: ... to: ... memory_files: ... goal: ... acceptance: ...`，缺 `memory_files` 或 acceptance 不开工。
- **复杂任务必走流程**：producer 拆 2~4 子任务 → 探索 agents 并行调研 → 实现 agents 串行落地 → qa 跑回归 → review 跨模块审 → producer 汇总验收。
- **新坑必写**：任何角色发现新踩坑都要追加 `docs/experience-log.md`；越界场景也写。
- **模型分层**（建议非强制）：producer / review 用强推理；system / battle 用代码型；lore / 文档归档用快模型；art prompt 设计用强推理，实际出图由 `scripts/gen_assets.py` 控制图像模型。

---

## 💡 关键决策（已敲定，不要再讨论）

1. **引擎**：Godot 4 + GDScript（不切换）
2. **美术风格**：以 Lovart 那 6 张为 Style Bible
3. **量产 AI**：批量出图以 `scripts/gen_assets.py` 为准，**唯一后端 ALAPI**（`v3.alapi.cn`，`token` 头，见 `docs/alapi-image-api.md`）；**不**买 ChatGPT Plus / Pro 当 API 用（订阅与 API 不通用）
4. **Lovart**：只用网页版手工出关键图，**不**信任何 lovart.pro / lovart.info 自称的 API（仿冒站）
5. **预算**：当前阶段单次 ¥20-50 实验，量产期总盘 ¥300-500 控顶

详见 `docs/experience-log.md` 第 1 节。

---

## 🌐 跨设备恢复步骤

### 新机器上首次设置

```bash
# 1. 克隆代码
git clone https://github.com/rajqiu2022/cw_rpg.git
cd cw_rpg

# 2. 重建 .env（仓库不传 API Key）
copy .env.example .env       # Windows
# cp .env.example .env       # macOS/Linux
# 编辑 .env 填入 OPENAI_API_KEY 和 OPENAI_BASE_URL

# 3. Python 资产管线（如果要继续出图）
python -m pip install -r scripts/requirements.txt
python scripts/smoke_test.py   # 不烧钱的冒烟测试

# 4. Godot 程序框架
# 下载 Godot 4.3 Standard: https://godotengine.org/download/windows
# 双击 .exe → Import → 选 game/project.godot → F5
```

### 让 AI 接续这次对话

复制粘贴这段给新会话的 AI：

```
请先完整读 AGENTS.md、docs/current-progress.md、docs/agent-workflow.md、docs/module-owners.md、docs/agents/README.md、docs/agents/producer-memory.md 和 docs/experience-log.md，
然后按 AGENTS.md 里的"待办"清单继续。具体任务确定后，再读取对应角色的 docs/agents/<role>-memory.md。
我现在想做的是：[填你具体想做啥]
```

---

## 📝 完整会话原始记录（可选）

Cursor 把所有对话以 JSONL 存在本地：

- 当前会话：`%USERPROFILE%\.cursor\projects\f-Code-RPG-GAME\agent-transcripts\<uuid>\<uuid>.jsonl`
- 想 100% 还原历史可以拷贝整个 `agent-transcripts` 文件夹到新机器对应位置

但**新会话其实不需要这个**——AI 启动时会自动读 `AGENTS.md` + `docs/current-progress.md` + `docs/agents/` 下对应角色记忆 + `docs/experience-log.md`。

---

_最后更新：2026-04-30（新增多 Agent 独立角色记忆：`docs/agents/`；协作 v0.1：`docs/agent-workflow.md` + `docs/module-owners.md` + `docs/acceptance-checklists/`）· 维护者：每完成一个里程碑更新 `docs/current-progress.md` + 本文件「现状 / 待办表」_
