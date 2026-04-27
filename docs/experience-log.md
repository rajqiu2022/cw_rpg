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

### 1.5.1 DMXAPI 不稳定模式总览（2026-04-27 一日实测）

⚠ **结论先行**：DMXAPI 适合**冷批量出图**，**不适合开发期实时迭代**。
推荐：开发期手动用 ChatGPT Plus / Lovart 网页出图，DMXAPI 仅在批量阶段做容错路由。

四类失败模式 + 应对：

| # | 错误特征 | 触发条件 | 恢复 | 应对 |
|---|---|---|---|---|
| 1 | `APIConnectionError` + `schannel: SEC_E_INVALID_TOKEN` | 并发 ≥ 4 或短时间高频请求 | 30+ 分钟自动解封 | `--concurrency 1`，避开 IP 封禁 |
| 2 | `BadRequestError 400 moderation_blocked` | 中文武侠 prompt 含"杀/血/绝世/IP 名"等 | 改 prompt 即可 | `extra_body={"moderation":"low"}` + 软化措辞 |
| 3 | `InternalServerError 503: 所有令牌分组 default 下对于模型 X 均无可用渠道` | 不可控（DMXAPI 上游 OpenAI 渠道熔断） | 5–30+ 分钟，无 SLA | 跑批前用 `scripts/ping_dmx.py` 探活；失败任务 fallback 到 `gpt-image-1.5` 或人工 |
| 4 | `RuntimeError: API 未返回图像数据`（HTTP 200 但 `data[]` 空） | 渠道熔断前的过渡态 | 同 #3 | 视为可重试 |

**重要**：错误 #1 vs #3 完全不同：
- #1 客户端 TLS 层失败（`curl` 也连不上） → IP 风控
- #3 应用层 503（`curl` 能通，业务返错）→ 上游渠道问题

诊断脚本：`scripts/ping_dmx.py` 单次最小调用，退出码 0/1 区分渠道存活。

### 1.6 DMXAPI 实际可用模型 ID（不是常见名）

⚠ **2026-04-27 修正**：DMXAPI 的**接口文档页**和**定价页**信息不同步。下结论前必须**两个页面都看，并 curl 实测一次**。

| 通常叫法 | DMXAPI 实际 model 参数 | 状态（2026-04-27 实测）|
|---|---|---|
| GPT Image 2 | `gpt-image-2` | ✅ **已上线**（定价页有，文档页未更新） |
| GPT Image 1.5 | `gpt-image-1.5` | ✅ 已上线 |
| GPT Image 1 | `gpt-image-1` | ✅ 已上线 |
| GPT Image 1 Mini | `gpt-image-1-mini` | ✅ 便宜版 |
| GPT Image 1.5 SSVIP | `gpt-image-1.5-ssvip` | ✅ OpenAI 直连版（更贵） |
| DALL-E 3 | `dall-e-3` | ✅ |
| Seedream 3.0 | `doubao-seedream-3-0-t2i-250415` | 估算可用 |
| FLUX Kontext Pro | `flux-2-pro` | 估算可用 |

**坑**：曾经只看 `doc.dmxapi.cn/img-gpt-image-1.html` 文档表，看到只列 `gpt-image-1.5/1/1-mini/dall-e-3`，
就下结论"DMXAPI 没有 image-2"。**实际定价页 `dmxapi.cn/pricing` 已经有 image-2，且实测可用**。

教训：DMXAPI 文档更新滞后于服务，**永远 curl 一次实测**再下结论。
单图 `gpt-image-2` medium 1024² 实测 **¥0.131/张**（远低于定价表粗估的 ¥1+/张），
具体见 `docs/consistency-test-report.md` 第 4 节。

### 1.7 GPT Image 容易默认输出繁体字

**触发**：UI 按钮、技能图标的中文标签
**修复**：prompt 模板里同时强调 "简体中文" 和 negative "禁止繁体 / traditional chinese characters"
**已落地**：`prompts/templates/_shared.yaml` `ui_button.yaml` `ui_icon_skill.yaml`

### 1.8 GPT Image 不擅长传统 RPG 精灵图

GPT Image 2 的强项是**电影级单张大图**（立绘/海报/场景），弱项是**多帧、低分辨率、统一规格的 sprite**。
回合制 RPG 应该用 **battler（战斗大立绘）** 而不是传统 sprite。

### 1.9 DMXAPI 实测 gpt-image-2 单图成本 ¥0.13（不是 ¥1）

2026-04-27 一致性测试实测：1024×1024 medium quality，**实际单张 ¥0.131**，
不是定价页粗看的 ¥1+/张。原因：image-2 是 token 计费（input ¥24.82/M + output ¥148.92/M），
medium 1024² 实际只用 ~450 input + ~805 output tokens。

**整套 RPG 资源（700 张）成本估从 ¥700 下降到 ~¥100**，AI 出图方案经济性远超预期。
脚本默认估值偏高是好事（保守预算），但要让 `cost_from_usage()` 正确读 usage 字段才能算准实际成本。

### 1.10 DMXAPI 后端是 Azure OpenAI，moderation 默认严

DMXAPI 中转的 gpt-image 系列实际走 Azure OpenAI，而不是 OpenAI 官方端点。
体现：错误信息里有 `Azure support ticket`、`rix_api_error`、`moderation_blocked`。

放宽方法：通过 `extra_body={"moderation": "low"}` 透传给 DMXAPI（其文档支持此参数）。
但即使 `low`，仍会拦截较强的暴力/血腥/版权词。

### 1.11 武侠中文 prompt 的 Azure moderation 雷区

实测以下组合**会触发 moderation_blocked**（即使 `moderation: low`）：

- 直接写艺术家或 IP 名："马荣成"、"《风云》" → 用风格特征替代（"中国港式漫画"）
- 极端肢体词："畸形手指"、"多余四肢" → 整段从 `_shared.yaml` 的 negative 里删除
- 强暴力倾向："杀意"、"绝世好剑" → 软化为"气势"、"长剑"
- 血腥联想："血红"、"暗红内衬" → 换"橙红"、"深紫"

**经验法则**：写中文武侠 prompt 时把"负面/血腥/IP 名"全部脱敏，依靠"画面要求"段的正面描述去引导，
比依赖 `negative` 词更稳。

### 1.12 OpenAI SDK 异常优先级：BadRequestError 必须放在 APIError 前

`BadRequestError` 是 `APIError` 的子类。Python 异常匹配是顺序短路，写成：

```python
except (RateLimitError, APIError):  # ← BadRequestError 会先被这里吃掉
    重试
except BadRequestError:              # ← 永远不会执行
    不重试
```

会导致 **moderation_blocked 等"永不可重试"错误也被当限流重试 3 次**，浪费时间和 token。

修复：调换顺序，`BadRequestError` 在前，`APIError` 在后。

### 1.13 cost_from_usage 必须容忍 None 字段

DMXAPI 返回的 usage JSON 里某些字段值是 `None`（不是 0）：

```json
"input_tokens_details": {
  "image_tokens": null,         // ← None
  "text_tokens": 450,
  "cached_tokens_details": {}
},
"output_tokens_details": null,  // ← None（整段是 null）
```

直接 `dict.get("image_tokens", 0)` 会返回 `None`（默认值仅在 key 缺失时生效），
后续 `None * 24.82` 抛 `TypeError: unsupported operand type(s) for *: 'NoneType' and 'float'`，
让脚本进重试循环、再次扣费、再次崩。

修复：所有 token 字段都加 `or 0` 兜底。

```python
text_in = details.get("text_tokens") or 0
image_in = details.get("image_tokens") or 0
image_out = usage_dict.get("output_tokens") or 0
```

### 1.14 DMXAPI 并发 ≥ 4 触发隐性 IP 风控（5-10 分钟）

并发 4 跑 7 张图后，**之后 5-10 分钟内所有连接 RST**：
- curl 报 `schannel: SEC_E_INVALID_TOKEN`（TLS 握手被服务端关）
- OpenAI SDK 报 `APIConnectionError: Connection error.`
- 但 ping 和 443 端口都正常，区分点是"应用层连接立即关闭"

**结论**：`GEN_CONCURRENCY ≤ 2`，最稳是 1。
如果触发了，等 10 分钟再试，期间可继续做其他工作（写报告/读图等）。

### 1.15 纯 prompt 文本锚定足够保持角色一致性

实测：在**不依赖 reference image** 的情况下，gpt-image-2 仅靠 character_appearance 文本描述，
就能让同一角色在 2-3 张不同姿态的图里保持脸型/服装/发型/腰带高度一致（⭐⭐⭐⭐⭐）。
gpt-image-1.5 也行但略差（⭐⭐⭐⭐）。

**项目意义**：
- Style Bible（reference image）从"必须前置"降级为"锦上添花"
- 可以**先批量出 sprite 表情/动作变体验证一致性**，跑得不满意再回头做 Style Bible
- 实测见 `docs/consistency-test-report.md`

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

---

## 8. v0.2.0-M2 阶段经验记录（2026-04-26）

### 8.1 DialogNode 拆"附带效果"和"结束动作"

**坑**：M2.0 之前，`DialogNode.on_end` 一个字段既要表达"给玩家东西"，又要表达"接下来跳哪"。结果同一节点 *既给金币又跳战斗* 写不出来——只能拆成两个 node。

**修复**：把语义分开：
- `give_items` / `give_gold` / `set_flags` / `accept_quest` / `complete_quest`：**节点结束时执行的副作用**，可叠加多个
- `on_end`：**唯一一条**导航指令（`next:id` / `battle:id` / `scene:id` / `end`）

DialogPlayer 推进节点时先 `_apply_node_side_effects(node)`，再 `_resolve_action(on_end)`。

通用经验：**任何"动作字符串"字段，凡涉及副作用 + 流程控制都该拆开**，否则后期组合爆炸。

### 8.2 SceneRouter 作为"动作字符串解析中枢"

**架构**：M2 把"动作字符串解析"集中到 `SceneRouter.resolve_action(s)`，DialogPlayer / FieldController / 未来的 QuestManager 都直接调用。

支持语法（详见 `scene_router.gd` 文件头）：
```
dialog:<id>            打开对话
battle:<id>            进战斗（自动记 _current_field_id 作为 return_scene）
scene:<id>             跳探索场景
give_item:<id>:<n>     发物品
give_gold:<n>          发金币
set_flag:<key>:<v>     置 flag（v=true/false/数字/字符串自动判类型）
accept_quest:<id>      接任务
complete_quest:<id>    完成任务
open_inventory         打开背包（占位）
end / 空                 不做事
```

**好处**：DialogNode/SceneScript .tres 里只写字符串，不写脚本；新增动作只改 SceneRouter 一处。

### 8.3 战斗胜利自动写入 `defeated_<enemy_id>` flag

**痛点**：M2 场景里"打过的尸体不能再点"是高频需求。如果让每段对话手动 `set_flag:defeated_xxx:true`，容易漏。

**做法**：`BattleController._end_battle(true)` 里直接：
```gdscript
var flag_key := "defeated_%s" % String(_enemy_def.enemy_id)
GameState.flags[flag_key] = true
EventBus.flag_set.emit(StringName(flag_key), true)
```

**约定**：所有打过的敌人都自动记 flag，hotspot 用 `hide_flag = "defeated_<enemy_id>"` 隐藏即可。多次刷怪场景用别的字段（M3+ 再加 `kill_count` 字典）。

### 8.4 `start_battle` → `go_victory` → `go_field` 闭环要带 `return_scene`

**陷阱**：玩家在 field 里点战斗，胜利后要回**原 field**，不能弹主菜单。

**实现链**：
1. `SceneRouter.start_battle(id, return_scene_id = "")` 默认用 `_current_field_id`
2. payload 存 `{enemy_id, return_scene}`
3. `go_victory()` 把 `return_scene` 转写到 `_result_payload`
4. `result_victory.gd` 检查 `return_scene` 非空 → `go_field(return_scene)`，否则 `go_main_menu()`

**未来扩展**：败北也应支持 `return_scene`（M6 章末 Boss 输了走"客栈醒来"路径）。

### 8.5 FieldController 在 `flag_set` / `dialog_ended` 时立即重刷热点

**为什么**：玩家点对话 → 对话副作用改了 flag → require/hide 立即生效。如果只在进场 spawn 一次，必须切场景才更新，体验差。

**做法**：`FieldController._ready()` 同时 connect：
- `EventBus.flag_set` → `_spawn_hotspots(_current_scene.hotspots)`
- `EventBus.dialog_ended` → 同上（兜底，对话改了多个 flag 时只刷一次）

**性能**：M2 阶段每场景 ≤ 6 个 hotspot，重 spawn 完全够用；后续场景元素多了再做 diff 增量更新。

### 8.6 .tres 内嵌 `Array[Resource]` 子资源的写法

**做法**：DialogScript 的 `nodes: Array[DialogNode]` 字段，把每个 DialogNode 写成 sub_resource 块，最后用：
```
nodes = Array[Resource]([SubResource("node_a"), SubResource("node_b")])
```

注意：
- 数组类型用 `Array[Resource]` 而**不是** `Array[DialogNode]`——`DialogNode` 是脚本里的 `class_name`，.tres 文本格式里 Godot 4 不认这种自定义类型名
- 每个 sub_resource 头要写 `script = ExtResource("2_dnode")` 显式绑脚本，否则 load 出来 type 是 Resource 而不是 DialogNode

### 8.7 Godot 4 Button 字号不能直接赋字段

**坑**：写 `btn.theme_override_font_sizes_font_size = 18` 不报错但**不生效**。

**修复**：用方法 API：
```gdscript
btn.add_theme_font_size_override("font_size", 18)
```

通用：theme override 字段在 GDScript 里只能用 `add_theme_*_override(name, value)` / `get_theme_*_override(name)` 系列，不能当成属性赋值。

### 8.8 M2 完整闭环测试路径（可复用）

1. 主菜单「开始新游戏」
2. 进官道 → 看进场对话
3. 点 `查看石碑` → 看石碑对话 → 自动结束
4. 点 `路边尸体` → 看尸体对话 → 自动 `battle:thug_lone`
5. 战斗胜利 → 「继续」回到官道
6. 验证：尸体按钮消失，新出现"继续前行"按钮
7. 点「继续前行」→ 看战后剧情 → 拿到地图、麻衣、+8 金
8. 在 Godot Remote 调试器里检查 `Inventory.slots` / `GameState.flags`

任意一步断了都先看 `EventBus` 是否 emit 了对应信号，再看 `SceneRouter.resolve_action` 是否收到正确 action 字符串。

---

## 9. v0.2.0-M3 阶段经验记录（2026-04-26）

### 9.1 Quest source-of-truth：禁止外部 emit `EventBus.quest_accepted`

**反模式（M2 临时代码）**：DialogPlayer 在节点副作用里直接 `EventBus.quest_accepted.emit(qid)`，让"未来的 QuestManager"订阅。

**坑**：QuestManager 一旦在 accept(qid) 内部也 emit `EventBus.quest_accepted`，外部触发 + 内部广播 = **双重事件 + 重入风险**。

**正确**：QuestManager 是任务状态的唯一 source of truth：
- 外部"想接受任务" → **直接调** `QuestManager.accept(qid)`（DialogPlayer / SceneRouter / 未来 NPC 脚本都这样）
- QuestManager 内部 accept/complete 时**统一负责** emit `EventBus.quest_accepted` / `quest_completed` 给 UI / 成就系统等订阅者
- QuestManager 自己**不订阅** `quest_accepted` / `quest_completed`，只订阅"事件类信号"（`enemy_defeated` / `scene_entered` / `flag_set` …）

通用经验：**有"状态机"语义的子系统，状态变更命令走调用，状态变更通知走信号**——不要混一起。

### 9.2 Trigger 字符串语法 ≠ Action 字符串语法

虽然语法很像，但语义完全不同：

| 用途 | 写在哪 | 谁解析 | 例子 |
|---|---|---|---|
| **Action**（命令）| DialogNode.on_end / SceneScript.hotspots | `SceneRouter.resolve_action` | `battle:thug_lone` = 启动战斗 |
| **Trigger**（事件匹配）| QuestDef.completion_triggers | `QuestManager._check_match` | `enemy_defeated:thug_lone` = 监听敌人被击败信号 |

**容易混淆**：写 quest 时手滑写成 `battle:thug_lone`（动作）当 trigger，永远不会触发。

约定：trigger 字符串前缀必须是 EventBus 信号名（`enemy_defeated` / `scene_entered` / `item_picked_up` / `flag_set` / `npc_talked_to`）。

### 9.3 接受任务时立即检查"已满足"

**场景**：玩家先打 boss，再回村触发 NPC 对话才接到"击败 boss"任务——这种边界情况下任务永远完成不了，因为事件已经过去。

**修复**：`QuestManager.accept(qid)` 末尾调 `_check_all_active()`，对 `flag_set` / `defeated_<id>` 类 trigger 做"回看历史"判定（依赖 GameState.flags 里有持久化的状态）。

纯事件型 trigger（`item_picked_up` / `npc_talked_to` 等历史不持久化的）则不会回看，必须保证设计上"先接任务再触发事件"。

### 9.4 SaveManager schema 升版要约定 version 字段

M3 加 `quests` 和 `current_field` 字段时把 `version: 1` 升成 `version: 2`。

**经验**：每次改 save 数据结构都升 version，后续 `load_from_slot` 可以做向后兼容（`if version < 2: ...`）。本期没做兼容（玩家手动删存档），但 version 字段保住了升级窗口。

### 9.5 RichTextLabel 多行任务列表用 `bbcode_enabled = true`

任务面板用 RichTextLabel + bbcode 写：
```gdscript
"%s[b]%s[/b]\n  %s" % [prefix, q.title, q.desc_in_progress]
```

注意：
- `bbcode_enabled = true` 必须在 .tscn 里设，运行时 set 太晚
- `fit_content = true` 让高度自动撑开（替代手动改 size）
- `scroll_active = false` 否则少量内容也出现滚动条
- `theme_override_font_sizes/normal_font_size`（不是 `font_size`）—— RichTextLabel 的字号 override 名字与 Label 不同！

### 9.6 autoload 顺序：QuestManager 在 SceneRouter 后、DialogPlayer 前

```
EventBus → GameState → Inventory → SceneRouter → QuestManager → DialogPlayer → SaveManager
```

理由：
- DialogPlayer._apply_node_side_effects 调 `QuestManager.accept` → QuestManager 必须先 ready
- SceneRouter.resolve_action 也调 QuestManager → SceneRouter 不在 _ready 里调，但保险起见 QuestManager 排在它后面
- SaveManager 调 QuestManager.to_dict / from_dict → 必须最后

实操：autoload _ready 顺序 = project.godot `[autoload]` 段从上到下。出错时先看这个段。

### 9.7 任务奖励发放走 GameState/Inventory，不绕开

**坑**：QuestManager 自己写 `GameState.gold += def.reward_gold` 不 emit `gold_changed`，HUD 不会刷新。

**修复**：必须走 `GameState.add_gold(n)` / `Inventory.add_item(id, n)` / `GameState.player.gain_exp(n)`，让信号链完整传播到 UI。

通用规则：**任何修改 autoload 数据的地方都用 autoload 自己的方法**，不要绕过去直接改字段。

---

## 10. v0.2.0-M4 阶段经验记录（2026-04-27）

### 10.1 SceneScript hotspot 用 require + hide flag 组合实现状态分支

需求：**同一个 NPC 按状态切对话**（哭泣女子：未接 → 含选项；已接未完成 → 哽咽；已完成 → 隐藏）。

**做法**：在 `hotspots[]` 里写多个 **同名 + 同坐标** 的 entry，靠 `require_flag` / `hide_flag` 互斥。`FieldController._spawn_hotspots` 已支持二者并存判定（同时满足 require + 不满足 hide 才显示），无需改代码。

```gdscript
# ch1_s2_qingfeng.tres 节选
{ "label": "哭泣女子", ..., "action": "dialog:ch1_s2_crying_woman",
  "hide_flag": "accepted_rescue_husband" },     # 未接受时显示
{ "label": "哭泣女子", ..., "action": "dialog:ch1_s2_crying_woman_waiting",
  "require_flag": "accepted_rescue_husband",
  "hide_flag": "rescued_husband" },             # 已接受未完成
# 完成（rescued_husband=true）则两者都不显示 → NPC 自动消失
```

替代方案（更复杂）：在对话脚本第一节加 choices/branch 判 flag。**hotspot 分支更解耦**：UI 层可视、对话脚本不污染 if 逻辑。

### 10.2 DialogNode：节点级 `set_flags`（数组）vs 选项级 `set_flag`（单 dict）

**Schema 不对称，写对话时极易混**：

| 字段 | 类型 | 格式 | 触发时机 |
|---|---|---|---|
| `DialogNode.set_flags` | `Array[Dictionary]` | `[{"key": "k", "value": v}, ...]` | 节点无 choices 走"继续"时 |
| `DialogNode.choices[i].set_flag` | `Dictionary`（单层） | `{"k1": v1, "k2": v2}` | 玩家点该选项时 |

`dialog_player.gd` 第 75-79 行直接遍历 `flag_dict.keys()`，所以选项 set_flag 是 **flag_name → value** 字典；节点 set_flags 走 `entry.get("key")` / `entry.get("value")`。

写对话切记：**"我帮你"选项加 flag 用 `set_flag: {accepted_rescue_husband: true}` 不能写成 `[{key: ..., value: ...}]`**。

### 10.3 进商店不污染 `_current_field_id`，关闭时直接复用

`SceneRouter.go_shop()` **故意不修改** `_current_field_id`（只改 `_shop_payload`）。这样 `shop_ui.gd` 关闭按钮一行就能回原 field：

```gdscript
SceneRouter.go_field(SceneRouter.get_current_field_id())
```

代价：商店本身没法当独立场景做 save（M4 范围内不需要）。如果以后要存档"在商店里"，再扩 _current_view_kind。

### 10.4 hotspot action 链式效果一律放对话节点里

需求："旧木箱"点一下就给铁剑 + 隐藏自身。

**坑**：`hotspot.action` 只解析一个 SceneRouter action，不能链 `give_item:... + set_flag:...`。

**做法**：hotspot.action = `dialog:<id>`，对话节点写 `give_items + set_flags`（同时给物 + 置 flag）。`DialogPlayer._apply_node_side_effects` 一次性执行。

```
ch1_s3_box_iron_sword.tres node_a:
  give_items = [{"id": "iron_sword", "count": 1}]
  set_flags = [{"key": "looted_west_ruin_box", "value": true}]
  on_end = "next:b"
```

通用模式：**hotspot = 触发器，对话节点 = 副作用容器**。

### 10.5 Item.sell_price × ShopDef.sell_back_ratio 是"再次折扣"

字段语义：

- `Item.buy_price` = 玩家**买入价**（店家挂牌）
- `Item.sell_price` = 店家**收购全价**（市场参考价）
- `ShopDef.sell_back_ratio` (0~1) = 实际收购折扣（默认 0.5）

最终 `玩家卖出实收 = floor(item.sell_price × shop.sell_back_ratio)`。

**易错点**：把 sell_price 直接当玩家实拿（不乘 ratio），导致玩家卖物收入翻倍。

### 10.6 `choices` 非空时显式 `Array[Dictionary]([...])` 标注

空数组 `choices = []` Godot 4 自动推断；**非空** 数组建议跟 `nodes`/`set_flags` 一样标显式类型：

```
choices = Array[Dictionary]([
    {"text": "...", "next": "...", "set_flag": {"k": v}}
])
```

否则 Godot 4 偶发"Array of inferred type, expected Array[Dictionary]"warning。

### 10.7 卖装备前必须先 unequip

`Inventory.equipped_weapon` 是直接持有 Equipment Resource 实例的引用，与 `slots` 解耦。所以 `remove_item` 不会自动 `unequip`，会留下"幽灵装备"——卖完铁剑但 atk_bonus 仍 +5。

修复：商店 `_on_sell` 之前判断如果是已穿戴装备先 `Inventory.unequip(slot)`。

### 10.8 M4 完整闭环测试路径

`docs/mvp-m4-checklist.md` §0-§9。关键节点：

1. 进官道 → 接 q1 → 战胜 thug → 进对话 → **走到 ch1_road_after_thug node_c 自动 `scene:ch1_s2_qingfeng`** → 进场景 2
2. 进场景 2 → q2 trigger `scene_entered:ch1_s2_qingfeng` 立即匹配 → q2 ✓
3. 客栈老板对话 → set_flag `rumour_west_ruin` → "前往城西"出口立即出现（FieldController 监听 flag_set 重渲染热点）
4. 神秘商人 → `shop:qingfeng_merchant` → SceneRouter.go_shop → shop.tscn → 关闭回 ch1_s2_qingfeng
5. 哭泣女子选"我帮你" → set_flag accepted_rescue_husband + accept_quest q3 → 哭泣女子 hotspot 切到 waiting 版
6. 进场景 3 → 拾铁剑 → 救丈夫（set_flag rescued_husband → q3 自动 ✓ + 50 gold）→ 大门 → boss 战斗 → 胜利回主菜单

---

## 11. 世界观 / 命名

### 11.1 命名禁区清单（项目级）

> 用户在 review world-bible.md v0.3 时明确删除某些意象。每次踩到记录在此 + 同步到 `docs/world-bible.md §5.7`。后续生成新武功 / 怪物 / 道具 / 美术 prompt 关键词都要查这个表回避。

| 日期 | 禁区 | 触发场景 | 替代思路 |
|---|---|---|---|
| 2026-04-27 | 蜘蛛 / 蛛丝 / 蛛网 | 戚云笙武功原叫"千机蛛丝"，被否 | 用"针 / 镖 / 链 / 索 / 缕"。已改为"离魂针" |

**自检流程**（每次新增内容前 30 秒自查）：

1. 武功名 / 怪物名 / 道具名 / 美术 prompt 关键词
2. 通读一遍是否含禁区表中任何字眼
3. 含 → 立即换；不含 → 通过

> 这个表会增长，所以每次新增意象时也建议反向问用户一次"这个意象有忌讳吗"。

---

## 12. Prompt 模板防腐 / 硬编码污染

### 12.1 模板硬编码"角色专属外貌"会污染所有任务（2026-04-27）

**踩坑**：v0.2 stage 2 跑批前 dry-run 发现，`prompts/templates/character_portrait_textonly.yaml` 里的"画面要求"段落硬编码了：

```yaml
- 五官比例固定：清瘦轮廓 / 眉目俊朗 / 神色沉稳   ← 步惊云特征
- 服装固定：黑色长袍 + 深紫色披风                ← 步惊云服装
- 色调统一：黑、深灰、深紫、银                   ← 步惊云配色
```

这是 v0.1 一致性测试期间为锁住步惊云写的"二次保险"，但当 task 切到冷孤云时，**模板硬编码会直接覆盖 task 自定义的外貌**。如果不 dry-run 验证就直接跑，6 张图全废、白花 ¥7-8。

**修复**：

```yaml
# 改前（v0.1）
- 五官比例固定：清瘦轮廓 / 眉目俊朗 / 神色沉稳
- 服装固定：黑色长袍 + 深紫色披风
- 色调统一：黑、深灰、深紫、银

# 改后（v0.2）
- 五官、发型、服装、配饰、体格、色调：严格遵循上方"外貌（每张图必须严格一致）"段所述，不可偏离
```

把这些"角色专属字段"改成"指向上方 identity_anchor 的引导句"，让 anchor 成为单一真相源。

**经验抽象**：

1. **模板 = 风格层 + 结构层，不应混入"角色身份层"**。角色身份只能由 task 注入的 `character_appearance` 控制。
2. **任何写在模板里的"硬编码细节"都是技术债**——只要主角换人就会污染。
3. **跑批前必须 dry-run 看 1 张实际渲染的 prompt**——这是真正的最后防线，比 yaml 校验、字段对齐这些都重要。读一眼实际拼接出的 prompt 才能发现"模板 vs task" 的语义冲突。

**关联技术债**：`prompts/templates/character_portrait.yaml`（带 reference image 的版本）也有同类问题：
- 引用 `assets/_style_bible/01_protagonist_full.png`（步惊云图）
- 写死"披风颜色与参考图一致"
- 但当前所有调用它的任务都 `skip:true`，故未阻塞 v0.2 stage 2

待 v0.2 主角参考图（`portrait_lengguyun_neutral`）跑通后，**用它替换 _style_bible/ 下的步惊云图**，并把模板里"披风"等专属字眼一起改成中性。

### 12.2 跑批前 dry-run 自检清单（2026-04-27 沉淀）

```
✅ 1. yaml 语法（python -c "yaml.safe_load(...)"）
✅ 2. tasks 数量 / priority 分布
✅ 3. ≥1 个任务的 .meta.json 实际 prompt 内容
✅ 4. 通读 prompt：有无前任 IP / 角色专属 / 旧风格残留
✅ 5. 反向词段是否含 negative 必备项
```

3-4 步必读 1 个完整渲染结果，不能跳。代价就是 1 个 dry-run 调用 ~1s 时间，回报是避免一整批白花钱。

### 12.3 DMXAPI 余额不足必须分类为 fatal（2026-04-27 stage 2 跑批）

**踩坑**：v0.2 stage 2 跑 6 立绘，前 3 张成功（lengguyun / xingfantian / shenbanzhan），第 4 张起触发：

```
PermissionDeniedError: Error code: 403
{"message":"用户额度不足, 剩余额度: $0.499336", "code":"insufficient_user_quota"}
```

`gen_assets.py` 的 `classify_error` 把这种错误归类为 `ERR_TRANSIENT`（默认未识别），导致：

- 主模型 gpt-image-2 重试 3/3 次（每次都失败 + 指数退避，浪费 ~30s/任务）
- 切 fallback gpt-image-1.5 又试 1 次（仍失败）
- **3 个失败任务 × 4 次无意义请求 = 12 次浪费的 API 调用**

虽然额度不足时被拒不扣费（成本无关），但浪费的是**时间**（多耗 ~3-5 分钟）和**信心**（看到一堆 retry 心累）。

**修复**：classify_error 顶部加余额识别，归类 `ERR_FATAL`：

```python
if (
    "insufficient_user_quota" in msg
    or "用户额度不足" in msg
    or "insufficient_quota" in msg
):
    return ERR_FATAL
```

**经验抽象**：

1. **永久错误必须显式识别为 fatal**：余额、密钥失效、账号封停、配额耗尽——这些不会自己恢复，重试和 fallback 都白费。
2. **看到 403 别条件反射重试**：403 ≠ 429（rate limit）。403 一般是权限/账号问题，重试无解。
3. **跑批后第一时间看 failed.log 错误码**：如果整批失败码同质（都是 403 / 都是 insufficient_quota），这是基础设施问题，不是 prompt 问题；先补血再重跑，别尝试改 prompt。

### 12.4 跑批前先查 DMXAPI 余额（建议加 ping_dmx 扩展）

**当前痛点**：DMXAPI 余额不会主动告知；只有触发不足时才在错误消息里露馅。

**改进方向（待补 todo）**：`scripts/ping_dmx.py` 调用余额查询接口（DMXAPI 应该有 `/v1/dashboard/billing/credit_grants` 类似 endpoint），跑批前先打印当前余额 + 估算本次跑批成本 + 是否够。

> **⏩ 已完成于 commit `ac2fded`**：DMXAPI 实际接口是 `GET /api/user/self`（不是 OpenAI 兼容的），需要 `system_token` + `user_id` 两个新认证字段（不同于 OpenAI 兼容的 sk- 密钥）。详见 §13.2。

**临时人工流程**：登录 DMXAPI 控制台首页，记下当前余额。按 ¥0.13-0.15/张（gpt-image-1.5 medium）估算这次需要的总额，余额至少 1.5 倍才放心跑批。

### 12.5 美术总基调：用户审美 vs prompt 写实（2026-04-27）

**用户拍板**：游戏整体偏鲜明光亮（参照 90 年代港漫《风云》、《天子传奇》等），仅特定阴暗场景才暗调。

**触发**：v0.2 stage 2 跑出 3 张立绘后，用户回看觉得人物 OK，但顺势提出风格调整。这种"做出第一波东西后，用户才能具象表达审美偏好"是常态——一开始问用户"你想要什么风格"，得到的答案永远是抽象的"武侠风、港漫风"；只有看到具体图后才能精准定位。

**修改面（一次性）**：

| 文件 | 改动 |
|---|---|
| `prompts/templates/_shared.yaml#style_anchor` | "苍凉壮阔"→"明亮通透、光影对比鲜明、阳光感强、色彩活力充沛"|
| `prompts/templates/_shared.yaml#negative` | 新增反向词："整体灰暗，雾蒙蒙，低饱和，沉郁压抑，黯淡无光，灰蒙蒙的色调"|
| `prompts/templates/scene_background_45deg.yaml` | "画面边缘可适度暗角"→"默认场景：明亮通透、阳光感强、暖色调主导（除非已声明为洞穴 / 夜战）"；删除 v0.1 残留的 isometric 参考图引用 |
| `prompts/tasks.yaml` 场景 task | 林西村主街 / 山道：升级描述为"明亮阳光"系；竹尾密林：保留暗调但明确"高饱和、不灰暗、绝非整体灰暗压抑" |
| `docs/world-bible.md §5.8` | 新增"美术总基调"项目级约定（跟 §5.7 命名禁区同级）|

**踩到的隐式陷阱**：

1. **"苍凉壮阔"是审美毒药**：这种文学化形容词容易让模型出图低饱和、灰蒙蒙。AI 出图 prompt 里要避开"苍凉、萧瑟、沉郁、苍茫、悠远"等词，改用具体的色彩 / 光感描述（"鲜红"、"橙红炉火"、"翠绿竹林"、"蔚蓝天空"）。
2. **暗调场景 ≠ 灰暗场景**：黄昏密林、夜战、洞穴这些**叙事上偏暗**的场景，仍要靠"高饱和 + 强对比"维持港漫风格，不能让模型理解成"低饱和+灰蒙蒙"。在 prompt 里明确加"**绝非整体灰暗压抑**"这种粗暴反向指令是有效的。
3. **negative 段是有效杠杆**：把"整体灰暗，雾蒙蒙，低饱和，沉郁压抑"加进 negative，比改正向描述更有效——AI 对 negative 的服从度更高。

**后续约定**：
- 任何场景 task 写 `time_of_day` / `weather` 时，默认 morning/noon + clear；用 dusk/night/overcast 必须在 scene_desc 里同步明确"高饱和"和"不要灰暗"。
- `world-bible.md §5.8` 是单一真相源，新风格调整都要回到这里更新。

### 12.6 隐藏 bug：getattr(dict, key) 永远拿不到值（2026-04-27）

`gen_assets.py` 第 586 行原写法：

```python
if out_png.exists() and not getattr(task, "_force", False):
```

`task` 是 dict，`getattr` 用于访问对象 attribute，对 dict 的 key 永远返回 default。结果：`--force` 参数完全无效，已存在的 png 永远 skip。

**修复**：`getattr(task, "_force", False)` → `task.get("_force", False)`

**经验**：dict 取值用 `.get()` / `.[ ]`，对象取属性用 `getattr` / `.x`。Python 这两个 API 容易眼瞎写错——尤其是当对象同时支持两种访问时（比如某些 ORM 模型）。**code review 时遇到 dict 看见 getattr 必停 0.5 秒检查**。

---

## 13. stage 2 完整批跑复盘（2026-04-27 22:17 ~ 23:30）

### 13.1 实测数据：9 任务 100% 成功，单图均价 ¥0.49

**任务清单**：6 张主线角色立绘（v0.3 阵营，character_portrait_textonly 模板）+ 3 张场景背景（45° 等距，scene_background_45deg 模板）。

| 阶段 | 时间 | 结果 |
|---|---|---|
| 第一波（充值前） | 22:09 ~ 22:13 | 3 张立绘成功（冷孤云 / 刑樊天 / 沈半盏），余额耗尽，3 张 fatal 失败 |
| 充值 + B2 跑批 | 23:17 ~ 23:30 | 9 任务全部处理：3 跳过 + 6 成功 + 0 失败 |

**第二波关键指标**：

| 指标 | 实测值 | 预估值 | 偏差 |
|---|---|---|---|
| 总耗时 | 757.5s（12'37") | ~10 min | 准 |
| 总花费 | ¥2.9337 | ~¥7.2（按 ¥1.2/张 × 6） | **超预期：仅花 41%** |
| 单图均价 | ¥0.489 | ¥1.20 | **比预估便宜 60%** |
| 成功率 | 100%（6/6） | ≥ 80% | 超预期 |
| 单张耗时 | 立绘 ~110s / 场景 ~150s | – | – |

**便宜的原因推测**：`gpt-image-2 medium` 实际消耗的 token 比 `gpt-image-1.5 medium` 低，DMXAPI 价格表（¥24.82 / ¥148.92 per M tokens）对 medium 质量产生约 ¥0.4-0.5/张实际成本。我们之前 ¥1.2/张的预估是**按 high 质量算的**，没区分质量档。

**结论**：M5-M7 阶段（约 30-50 张资产）总成本 ≈ **¥15-25**，比之前预估的 ¥36-60 大幅下调。

### 13.2 ping_dmx 实现：DMXAPI 余额查询接口非 OpenAI 标准

**接口确认（doc.dmxapi.cn/yuer.html）**：

```
GET https://www.dmxapi.cn/api/user/self
Headers:
  Authorization: <system_token>     ← 不是 sk-... API 密钥！
  Rix-Api-User: <user_id>
  Accept: application/json
Response:
  data.quota                        ← 整数，单位需 / 500000 得人民币
```

**关键认知陷阱**：DMXAPI 的"系统令牌"和"API 密钥（sk-...）"是**两个独立凭证**：

| 凭证 | 用途 | 入口 |
|---|---|---|
| **API 密钥** sk-... | OpenAI 兼容接口（图像、对话） | DMXAPI → 创建令牌 |
| **系统令牌** 32 字符 | DMXAPI 自有 API（余额、日志、统计） | DMXAPI → 个人设置 → 系统访问令牌 |
| **用户 ID** 数字 | 配合系统令牌使用 | DMXAPI → 个人设置 → 用户 ID |

我曾以为 sk- 密钥就能查余额，会节省一次配置步骤——错了。**这是中转商常见模式**：自有 API（订单 / 配额 / 日志）需要 system_token；OpenAI 兼容 API（业务调用）用 sk-。

**ping_dmx.py v0.2 设计**（commit `ac2fded`）：

- `query_balance()` 三档告警：< ¥0.5 critical / < ¥5 low / ≥ ¥5 ok
- 优雅降级：未配置 system_token 时跳过余额、仍执行 ping
- 余额接口走 DMXAPI 自有 API（不上游 OpenAI），**IP 风控期间仍能查**——这反而是个意外收获，下一次 IP 风控时可以先看余额避免误判
- 退出码 0 / 1 / 2 / 3 分别表示 ok / connection-fail / empty-data / quota-exhausted，方便上层脚本编排

### 13.3 ping 失败 ≠ 跑批失败：--skip-ping 反而稳

**反直觉现象**：22:57 / 23:06 两次 `python scripts/ping_dmx.py` 分别报 `APIConnectionError`（30s）和 `APITimeoutError`（90s = OpenAI SDK 默认 max_retries=2，30s × 3）；但 23:17 立刻用 `--skip-ping` 跑 9 任务批，**0 失败一次过**。

**可能解释**：

1. **ping 路径自身瞬时拥塞**：探活调用次数极低（一次一张图），渠道分配可能命中"冷"通道；批跑过程中 SDK 可能复用 connection pool 命中"热"通道。
2. **重试机制差异**：ping_dmx.py 简单调用没有 backoff/重试；gen_assets.py 内有 transient 类错误的指数退避，能扛过短暂抖动。
3. **DMXAPI 渠道队列动态变化**：1 分钟内的可用通道可能不一样。

**新流程建议**（写入工作流）：

| ping 结果 | 行动 |
|---|---|
| OK ✅ | 直接跑 |
| 1 次失败（transient） | 立刻试 `--skip-ping` 跑 1 个任务验证 |
| 连续 2 次失败（30 分钟内） | 等 30 分钟再试；或转 ChatGPT Plus 网页 |
| 余额 critical | 充值后再跑（不必 retry） |

**教训**：这次差点因为两次 ping 失败劝退用户改用 ChatGPT Plus 手贴 30 分钟，实际**直接 --skip-ping 12 分钟全搞定**，省了不少工。下次类似情况要更激进一点。

### 13.4 美术基调 v0.2 验证：场景"明亮 / 暗调特例"双轨制可行

stage 2 的 3 张场景是**v0.2 美术基调拍板后第一次实测**：

| 场景 | 设计意图 | prompt 关键词 | 验收 |
|---|---|---|---|
| 林西村主街 | 明亮鲜艳（默认） | morning + clear + 鲜艳明亮 + 阳光感 | 待用户审 |
| 林西村外山道 | 明亮鲜艳（默认） | morning + clear + 蓝天 + 翠绿竹林 | 待用户审 |
| 竹尾村外密林 | 暗调特例 | dusk + foggy + **高饱和、不灰暗** | 待用户审 |

如果 3 张场景都通过，说明**"_shared.yaml 全局明亮 + 单 task 暗调反向覆盖"** 双轨制可推广到 M5-M7 后续场景；如果竹尾密林仍偏灰暗压抑，则需要在场景任务级补更激进的反向词。

> 用户最终验收：**全部合格**（2026-04-27 23:37）。归档到 `assets/art_validation_v2/character_v2/` 和 `scene_v2/`。双轨制确认可行。

### 13.5 存档约定：通过的 PNG 必须从 raw/ 拷到 art_validation_v2/

**问题**：`assets/raw/` 在 `.gitignore` 里被排除（避免巨量草图入库），但 stage 2 的 6 张通过立绘 + 3 张场景默认输出到 `assets/raw/character/v2/` 和 `raw/scene/v2/`，**git 看不到**——意味着磁盘故障会丢这 ¥6.5 的成果。

**约定（沿用 stage 1 模式）**：

```
assets/
├── raw/                          # gitignore，工作区，gen_assets.py 默认输出
│   ├── character/v2/*.png        # 工作中 / 草稿 / 待审
│   └── scene/v2/*.png
└── art_validation_v2/            # 进 git，已通过的归档
    ├── npc/                      # stage 1 通过：5 NPC（commit 1559978）
    ├── character_v2/             # stage 2 通过：6 主线立绘
    └── scene_v2/                 # stage 2 通过：3 场景背景
```

**操作**：用户审阅通过 → `Copy-Item raw/.../X.png art_validation_v2/X_v2/` → `git add` 进归档 commit。**meta.json 不入库**（包含的是工作区状态，归档版本不需要追踪 prompt 漂移）。

**未来改进**：可以加个 `scripts/archive_passed.py`，参数 `--task <id>` 一键拷贝到归档区，并写一份 archive_log（哪张图哪天通过、谁审的）。当前 ≤ 10 张手工拷贝够用。

