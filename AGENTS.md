# AGENTS.md · AI 助手项目记忆

> 这是 Cursor / Claude Code / Codex 等 AI agent 工具的**自动加载文件**。  
> 新对话开启时 AI 应当先读完本文件，再读 `docs/experience-log.md`，然后才回应用户。  
> 维护者（人或 AI）：每完成一个里程碑，更新"已完成"和"待办"。

---

## 📍 一句话现状

漫画 2.5D 武侠 AVG-RPG（致敬《风云之天下会》1998 玩法），**v0.2.0-m1 编码完成**（数据驱动战斗 + EventBus + Inventory），等用户跑 `docs/mvp-m1-checklist.md` 验收 → 进 M2（探索场景 + 对话）。

### 🎯 v0.2.0 总目标（用户拍板 2026-04-26）

完成"开场到第一章结束"的端到端 5-8 分钟可玩 MVP，包含：
- AVG 式点击场景（不做顶视角自由走，更适配 GPT Image 美术）
- 1v1 回合制战斗（已有，本期数据驱动化）
- 背包/装备/任务/对话/商店各一个最小但端到端可用的版本
- 占位剧本：武当弟子沈不归追凶（角色名/世界观可后续完全替换）
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
│   ├── dmxapi-setup.md
│   ├── style-bible-prompts.md
│   ├── godot-demo-howto.md       ← Godot demo 运行手册
│   └── experience-log.md         ← 所有踩坑记录（必读）
├── .env              ← 本地 API Key（gitignored，新机器需重建）
└── AGENTS.md          ← 本文件（AI 自动读取）
```

---

## ✅ 已完成

### 1. AI 资产管线（scripts/ + prompts/）
- `gen_assets.py` 异步批量调图，支持多 backend：DMXAPI / OpenAI 官方 / API易
- 自动重试、预算限流、`meta.json` 完整记录（model/backend/cost/currency）
- 通过 `OPENAI_BASE_URL` + `OPENAI_IMAGE_MODEL` 切后端
- DMXAPI 需要显式 `httpx.Timeout(300, connect=30)` 否则 5s connect 超时

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
- 已复制改名进 `game/art/` 作 demo 占位

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
- 主角更名：主角 → 沈不归（占位，可后续完全替换）

> 👉 等用户跑 `docs/mvp-m1-checklist.md` 7 项验收，全 ✓ 后 M1 关闭，进入 M2。

---

## 🚧 待办（v0.2.0 路线 — 按 milestone 推进）

| M | 时长 | 内容 | 状态 |
|---|---|---|---|
| **M1** | 1.5h | 数据驱动重构 + EventBus + Inventory | ✅ **代码完成**，等验收 |
| **M2** | 2h | 探索场景 Field + 互动热点 + 对话系统 | ⏳ 下一步 |
| **M3** | 1.5h | Quest 系统 + 主线任务 1 | ⏸ |
| **M4** | 1.5h | 多场景跳转 + NPC 对话 + 商店 | ⏸ |
| **M5** | 1h | 背包/装备 UI + 物品使用 | ⏸ |
| **M6** | 1.5h | 章末 Boss + 状态异常 + 章节结算 | ⏸ |
| **M7** | 1h | 5 槽存档 + 加载/继续游戏 | ⏸ |

> 全程不做：动画特效 / BGM / 多人队伍战 / 第二章 / 多语言 / 打包发布。详见 `docs/design-mvp-chapter1.md` §11。

---

## 💡 关键决策（已敲定，不要再讨论）

1. **引擎**：Godot 4 + GDScript（不切换）
2. **美术风格**：以 Lovart 那 6 张为 Style Bible
3. **量产 AI**：用 OpenAI 兼容中转（DMXAPI 主，API易备），**不**买 ChatGPT Plus / Pro（订阅与 API 不通用）
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
请先完整读 AGENTS.md 和 docs/experience-log.md，
然后按 AGENTS.md 里的"待办"清单继续。
我现在想做的是：[填你具体想做啥]
```

---

## 📝 完整会话原始记录（可选）

Cursor 把所有对话以 JSONL 存在本地：

- 当前会话：`%USERPROFILE%\.cursor\projects\f-Code-RPG-GAME\agent-transcripts\<uuid>\<uuid>.jsonl`
- 想 100% 还原历史可以拷贝整个 `agent-transcripts` 文件夹到新机器对应位置

但**新会话其实不需要这个**——AI 启动时会自动读 `AGENTS.md` + `docs/experience-log.md`。

---

_最后更新：2026-04-27（v0.2.0-m1 编码完成）· 维护者：每完成一个里程碑追加"已完成"+ 调整"待办"_
