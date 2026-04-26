# 经验记录 / Lessons Learned

> 按 `user_rules` 第 1、2 条沉淀。每次踩坑或定位复杂数据后追加。

---

## 1. AI 出图 - 大模型与中转商

### 1.1 ChatGPT 订阅 ≠ OpenAI API（最重要的认知陷阱）

**结论**：买 ChatGPT Plus / Pro 完全不能用 API。两者独立计费、互不抵扣。

来源：`help.openai.com/en/articles/6950777`
> ChatGPT Plus is a subscription plan that provides enhanced access to **the ChatGPT web app** for $20/month. **Not included: API usage is separate and billed independently.**

| 想做的事 | 该买什么 |
|---|---|
| 网页/APP 手动聊天/出图 | ChatGPT Plus / Pro |
| 脚本批量调用 | OpenAI API（platform.openai.com，最低 $5 起充）|

### 1.2 gpt-image-2 已上线（2026-04-21）

OpenAI 官方 API 模型 ID：`gpt-image-2`。比 image-1 便宜，原生 4K，支持中文 prompt。

| Quality | 1024×1024 单价 |
|---|---|
| Low | $0.006 (¥0.04) |
| Medium | $0.053 (¥0.38) |
| High | $0.211 (¥1.5) |

调用方法：标准 OpenAI SDK，只需把 `model` 改成 `gpt-image-2`。
- ✅ 原生 2K/4K
- ❌ **不支持透明背景**（仍需 rembg 后处理）
- ⚠️ 高清耗时 ~120 秒/张

### 1.3 Lovart - 没有公开 API，警惕仿冒站

**事实**：lovart.ai 官方定价页明确把 API Access 标记为 **Roadmap**（规划中）。
任何 lovart.pro / lovart.info / lovart.me 自称的 "Lovart API"（如 `api.lovart.pro/v1/generate`）**都是第三方仿冒站**，付费风险高。

**Lovart 的真实价值**：网页版 agent 帮你打磨 5-10 张关键参考图（Style Bible），不要用来量产。

**封号案例**：用户充近 ¥4000 PRO 年费，10 天后封号不退款（网易报道 2026-02）。结论：**只买月付，不要年付**。

### 1.4 中转商对比（国内可用）

| 平台 | gpt-image-1 | gpt-image-2 | 支付 | 注意 |
|---|---|---|---|---|
| **DMXAPI** | ¥1/张 | 应已支持 | 微信/支付宝 | 偶发抖动，连接超时常见 |
| **API易（apiyi.com）**| - | ~¥1.5/张 (high) | 微信/支付宝 | 比 DMXAPI 便宜，docs.apiyi.com 有 gpt-image-2 接入文档 |
| **OpenAI 官方** | $0.011-0.167 | $0.006-0.211 | 海外卡 | 最便宜，但需 VPN |

### 1.5 DMXAPI 超时配置（必须记）

OpenAI SDK 默认 connect_timeout=5s，对 DMXAPI 不够用，会出现 `APIConnectionError`。
必须显式配置：

```python
from openai import AsyncOpenAI
import httpx

client = AsyncOpenAI(
    api_key=os.getenv("OPENAI_API_KEY"),
    base_url=os.getenv("OPENAI_BASE_URL"),
    timeout=httpx.Timeout(300.0, connect=30.0),  # 关键
    max_retries=0,                                 # 用我们自己的重试
)
```

### 1.6 DMXAPI 实际可用模型 ID（不是常见名）

| 通常叫法 | DMXAPI 实际 model 参数 |
|---|---|
| Seedream 3.0 | `doubao-seedream-3-0-t2i-250415` |
| FLUX Kontext Pro | `flux-2-pro` |
| GPT Image 2 | `gpt-image-2`（已上线后）|

### 1.7 GPT Image 容易默认输出繁体字

**触发**：UI 按钮、技能图标的中文标签
**修复**：prompt 模板里同时强调 "简体中文" 和 negative "禁止繁体 / traditional chinese characters"
**已落地**：`prompts/templates/_shared.yaml` `ui_button.yaml` `ui_icon_skill.yaml`

### 1.8 GPT Image 不擅长传统 RPG 精灵图

GPT Image 2 的强项是**电影级单张大图**（立绘/海报/场景），弱项是**多帧、低分辨率、统一规格的 sprite**。
回合制 RPG 应该用 **battler（战斗大立绘）** 而不是传统 sprite。

---

## 2. PowerShell / Windows 环境踩坑

### 2.1 中文文件名导致 PowerShell ItemNotFoundException

**症状**：`dir /a` 不工作，编码错乱

**修复**：
```powershell
Get-ChildItem -Force                    # 替代 dir /a
Copy-Item "中文.png" "english.png"      # 用引号包裹中文路径
```

### 2.2 Python 脚本 UnicodeEncodeError（PowerShell 输出）

**症状**：`rich` 库或 emoji 在 PS 控制台报 `UnicodeEncodeError`

**修复**：脚本顶部加：
```python
import sys
sys.stdout.reconfigure(encoding="utf-8", errors="replace")
```
另：避免 emoji，改纯文本（`[OK]` `[FAIL]`）

### 2.3 git commit -m 多行 heredoc 在 PowerShell 失败

**修复**：写到临时文件再 `git commit -F tmp.txt`

### 2.4 pip install 失败：requirements.txt 中文注释

**修复**：requirements.txt 全部用英文注释

---

## 3. Godot 4 项目搭建

### 3.1 .tscn / project.godot 必备格式

`project.godot` 顶部必须 `config_version=5`（Godot 4.x）。  
`.tscn` 顶部必须 `format=3`。  
不写 UID 也能跑，Godot 启动时会补。

### 3.2 unique_name_in_owner 配 % 引用

子节点设 `unique_name_in_owner = true` 后，父脚本里可以用 `%NodeName` 直接引用：
```gdscript
@onready var btn_attack: Button = %BtnAttack
```
比 `$ButtonPanel/Vbox/BtnAttack` 路径硬编码稳得多——节点重排不会断引用。

### 3.3 autoload 和 class_name 的初始化顺序

autoload 的 `_ready()` 里直接用 `CharacterStats.new()`（class_name 资源类）OK，
因为 `class_name` 在 Godot 启动早期就被注册到全局 ClassDB。

### 3.4 TextureRect 拉伸适配背景

```gdscript
expand_mode = 1   # IGNORE_SIZE，强制按容器尺寸缩放
stretch_mode = 6  # KEEP_ASPECT_COVERED，保持比例填满（裁剪超出部分）
```

### 3.5 Godot 4 内置全局函数

- `randf_range(0.8, 1.2)` 浮点
- `randi_range(0, 20)` 整数  
- `await get_tree().create_timer(0.7).timeout` 等待
- `get_tree().change_scene_to_file("res://...")` 切场景

---

## 4. 部署 / Git 操作

### 4.1 远程仓库

GitHub: `https://github.com/rajqiu2022/cw_rpg`

### 4.2 大文件 PNG 应走 LFS

> 当前还没启用，资产数量上 50 张时记得 `git lfs install` + `git lfs track "*.png"`。

### 4.3 推荐 commit 节点

| 节点 | 内容 |
|---|---|
| AI 资产管线骨架 | scripts/ + prompts/ + docs/ |
| Godot 项目骨架 | game/ 整个目录 |
| 每次产出 ≥ 5 张新资产 | 单独 commit |

---

## 5. 项目结构关键路径速查

```
f:\Code\RPG_GAME\
├── game\                ← Godot 项目（双击 project.godot 打开）
├── scripts\             ← Python AI 资产管线
├── assets\
│   ├── _style_bible\    ← 风格圣经原图（保留中文/原始名）
│   ├── raw\             ← AI 出图原图
│   └── processed\       ← rembg 抠图后
├── images\              ← Lovart 网页版下载的图（中文名）
├── prompts\templates\   ← 11 个 YAML 模板
├── docs\
│   ├── tech-selection.md
│   ├── art-pipeline.md
│   ├── budget.md
│   ├── dmxapi-setup.md
│   ├── style-bible-prompts.md
│   └── experience-log.md  ← 本文件
└── .env                 ← API Key（已 gitignore）
```

---

## 6. 下一步路线图（v0.2.0 — MVP 第一章）

详见 `docs/design-mvp-chapter1.md`，7 个 milestone 推进：

```
M1 数据驱动重构  ──→ M2 探索场景+对话  ──→ M3 任务系统
M4 多场景+商店    ──→ M5 背包/装备 UI   ──→ M6 章末 Boss+结算
M7 5 槽存档
```

每个 M 完成都跟一份验收清单（如 `docs/mvp-m1-checklist.md`），用户 F5 跑一遍点完所有 ✓ 才进下一个 M。

---

## 7. v0.2.0-M1 阶段经验记录（2026-04-27）

### 7.1 Godot 4 类型化数组在 .tres 里的写法

**坑**：直接写 `drop_random = [{...}]` 给类型化字段 `Array[Dictionary]` 赋值，Godot 4 加载时会报 type mismatch 警告，运行时字段可能为空。

**修复**：必须显式包装类型构造器：
```
drop_random = Array[Dictionary]([{ "item_id": "...", "chance": 0.5 }])
skill_ids = Array[StringName]([&"basic_attack", &"palm_strike"])
drop_items = Array[StringName]([])         # 空数组也得包
```

`StringName` 字面量用 `&"name"` 前缀（`@""` 是 unique node path，不通用）。

### 7.2 typed array 字段的 GDScript 赋值

**坑**：`stats.skills = [&"a", &"b"]` 给 `Array[StringName]` 字段赋 untyped array literal 在 Godot 4 会触发 implicit conversion warning。

**修复**：先建好类型化局部变量再赋：
```gdscript
var skill_ids: Array[StringName] = [&"basic_attack", &"palm_strike"]
stats.skills = skill_ids
party = [stats] as Array[CharacterStats]    # 或用 as 强制 cast
```

### 7.3 函数命名要避开 Godot 内置方法

**坑**：在 `DialogScript`（继承 Resource）里写 `func get_node(id)` 起初不报错，但若未来改继承 Node 就立即与 `Node.get_node()` 冲突；同理 `Inventory.has()` 与 Dictionary/Array 内置 `has` 在某些上下文有歧义。

**修复**：用更具体的方法名：
- `DialogScript.get_node()` → `find_node_by_id()`
- `Inventory.has()` → `has_item()`

通用规则：autoload / Resource 子类的公开方法**避开** `get_node` / `has` / `clear` / `add_child` 等节点/容器内置名。

### 7.4 全局信号枢纽 EventBus 模式

**架构选择**：所有"游戏事件"统一从 `EventBus` 发出（`enemy_defeated` / `item_picked_up` / `scene_entered` 等），任务/成就/统计系统都订阅 EventBus 而不是直接跨模块连接信号。

**好处**：
- 任务系统不需要知道谁触发了"杀敌"——只看 `enemy_defeated.emit(id)`
- 战斗/场景代码不需要 import 任务系统
- 加新订阅者（成就/统计/录像）零侵入

**autoload 顺序**：`EventBus` 必须排在所有依赖它的 autoload **之前**，因为 GameState/Inventory 在 `_ready()` 里就可能 `EventBus.xxx.emit()`。

```
EventBus → GameState → Inventory → SceneRouter → SaveManager
```

### 7.5 装备加成不能写进 CharacterStats.attack 字段

**坑**：很容易把"装备 +5 攻"直接累加进 `_player.attack`，但脱装备时复原会算错（已经升级过的话）。

**正确做法**：`CharacterStats.attack` 永远只代表"裸值"，装备加成在战斗运行时即查即算：

```gdscript
func _player_effective_attack() -> int:
    return _player.attack + Inventory.get_atk_bonus()
```

`Inventory.get_atk_bonus()` 遍历当前 equipped_weapon / equipped_armor 求和。脱装备只需 `Inventory.unequip(slot)`，不动 stats 字段。

### 7.6 .tres 单文件多 Resource 引用

`@export var on_enter_dialog: DialogScript = null` 这种 Resource 字段，在 .tres 编辑器里可以"内嵌"或"引用外部 .tres"。

**约定**：`SceneScript` 的对话引用统一用外部 .tres（`res://data/dialogs/<id>.tres`），便于：
- 单独编辑对话不动场景
- 多个场景复用同一段对话
- diff 友好（一个文件一个改动）
