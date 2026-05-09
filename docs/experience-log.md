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

---

## 14. M5 背包 / 装备 UI 实现经验（2026-04-28）

### 14.1 Godot CLI 不一定在 PATH，自动验证要先定位可执行文件

**问题**：本机 PowerShell 执行 `godot --version` / `where.exe godot` 均失败，说明 Godot 编辑器可用不等于 CLI 已加入 PATH。

**经验**：后续要跑 `game/tests/*.gd` 自动校验时，先确认 Godot 可执行文件路径；如果没有 PATH，需让用户提供编辑器安装路径，或在项目脚本中配置 `GODOT_BIN`。否则只能用 `ReadLints` 做静态检查，不能声称 Godot headless 测试已通过。

建议命令：

```powershell
$env:GODOT_BIN="C:\path\to\Godot_v4.x-stable_win64.exe"
& $env:GODOT_BIN --headless --path game --script res://tests/test_inventory_m5.gd
```

### 14.2 GDScript 静态类型调用自定义 scene 方法要谨慎

**问题模式**：如果变量声明为 `Control`，但实际实例是挂了自定义脚本的 `inventory_panel.tscn`，直接调用 `.open()` / `.close()` 可能被静态检查认为 `Control` 没有这些方法。

**修复**：这类动态实例变量要么保持未显式收窄类型，要么用 `call("open")`，要么为面板脚本定义 `class_name` 后使用真实类型。

**经验**：Godot UI 场景脚本之间互调时，类型标注别为了"看起来严谨"而标到父类；父类没有的方法会让 IDE / linter 报错。

### 14.3 SceneRouter action 新增分支时必须补完整三件套

**问题**：启动 Godot 后报 `Parser Error: Function "go_shop()" not found in base self.`。根因是 `resolve_action("shop:<id>")` 已经接入了 `"shop"` 分支，`shop_ui.gd` 也调用 `SceneRouter.get_shop_payload()`，但 `scene_router.gd` 里只声明了 `_shop_payload`，漏了 `go_shop()` / `get_shop_payload()` 两个方法。

**修复**：在 `SceneRouter` 中补：

```gdscript
func go_shop(shop_id: StringName) -> void:
	_shop_payload = {"shop_id": shop_id}
	get_tree().change_scene_to_file(SCENE_SHOP)

func get_shop_payload() -> Dictionary:
	return _shop_payload
```

**经验**：以后给 `SceneRouter.resolve_action()` 新增动作时，必须同时检查：

1. `const SCENE_*` 或数据目录常量是否存在；
2. `go_*()` 是否存在；
3. `get_*_payload()` 是否存在（如果目标场景要读 payload）。

只补 action 分支不补跳转 API，会在 Godot 解析期直接炸，甚至进不了游戏。

### 14.4 仓库只有 `.import` 没有 PNG：主菜单 / 野外会像「没有 UI」

**现象**：能进游戏，但主菜单与野外几乎一片空或很「抽象」，热点按钮像飘在虚空里。

**根因**：`res://art/**/*.png` 未进仓库（常见：大图 gitignore / 未提交），只剩 Godot 生成的 `*.png.import`。`TextureRect.texture` 为空时，叠上半透明遮罩后对比度极差。

**修复策略**：

1. 场景里加 **FallbackBg**（纯色或渐变感的 ColorRect）垫底；
2. 代码里 `ResourceLoader.exists` 再 `load`，缺失则 `push_warning`；
3. 野外热点按钮加 **StyleBoxFlat** 半透明底，保证在纯色底上也能看见；
4. 底部加 **HintBar** 文案，告诉玩家「点按钮推进 + 快捷键」。

**长期**：把通过的背景 PNG 按 `art_validation_v2` 约定归档进 git，或导出 WebP 小体积进库。

---

## 15. 主角 Sprite 提示词：外部分享文结构 + 本项目画风（2026-04-28）

**来源**：微信文章 [游戏元素拆分 gpt-image2](https://mp.weixin.qq.com/s/eLTx7bCpckLHfefR2M9l4Q)（分段写「整体 / 部位清单 / 排版 / 反向」）。

**适配**：

- 原文偏 **像素拆件**；本项目 `style_anchor` 是 **港漫厚涂 2.5D**，新模板 `sprite_protagonist_idle` / `sprite_protagonist_parts_sheet` 写明非像素、并与 `_shared.yaml` 明亮基调一致。
- 拆件总图在 **1024×1024** 下部件不能贪多，否则易糊、粘连；拆件任务默认 **`skip: true`**，避免误跑批烧钱。
- **无参考图**：不写 `reference_images`，走 `generations`，与 `character_portrait_textonly` 同一策略。

**验证**：`python scripts/gen_assets.py --task sprite_lengguyun_idle_south --dry-run` 已通过。

**文档**：`docs/sprite-prompt-playbook.md`。

### 15.2 批量 sprite 帧时 DMXAPI 全链路 `APIConnectionError`（2026-04-28）

**现象**：同机此前单张 `sprite_lengguyun_idle_south` 可成功；同一晚对 9 个 `--task` 连续跑批时，`gpt-image-2` 与 fallback `gpt-image-1.5` 均报 `APIConnectionError: Connection error.`，无扣费。

**处理**：任务与模板已落库；网络恢复后**缩小批次**（1～2 张/次）或错峰重试；详见 `docs/sprite-prompt-playbook.md` §2.2。

**后续成功样本（2026-04-29）**：同一 9 任务在约 **18 分钟**后 **9/9 成功**，总花费 **¥1.2428**（`--skip-ping`），输出均在 `assets/raw/sprite/v2/`。

### 15.3 行走 4 帧帧间「换装」：纯文不足、须关键帧 + edits（2026-04-28）

**现象**：`walk_south_f01`～`f04` 各走独立 `generations` 时，衣裤肤色酒葫芦鞋子等跨帧不一致。

**原因**：模型无视觉记忆，仅靠 prompt「序列一致」不足以锁住细部。

**处理**：

1. `sprite_protagonist_walk.yaml` 增补 **外观硬锁定** 清单（色阶、葫芦釉色、靴型、肤色等），专用于 **f01** 锚帧。
2. 新增 `sprite_protagonist_walk_ref.yaml`：`reference_images` 指向已产出的 `sprite_lengguyun_walk_south_f01.png`，`tasks.yaml` 中 **f02～f04** 改用该模板，走 **`images.edit`**。
3. `gen_assets.py`：模板可设 `require_reference_images: true`，参考图缺失时 **报错**，禁止静默清空参考后退回纯文生成。

**操作**：重出行走时先跑（或保留满意）**f01**，再跑 f02～f04；批量时 **f01 必须排在 f02 前**。

### 15.4 主角 sprite 画幅改为 896×896（2026-04-28）

**动机**：游戏内 sprite 不需要 1024²；略小画幅省 token / 省时间，Godot 里再按目标格缩放即可。

**实现**：`sprite_protagonist_idle` / `idle_anim` / `walk` / `walk_ref` / `attack` / `parts_sheet` 的模板 `size` 与 prompt 内画幅说明统一为 **896×896**（满足 gpt-image-2 文档「总像素 ≥ 655360」约束；512² 过小不可用）。`gen_assets.py` 的 `PRICE_OPENAI_USD` 增加 `896x896` 粗估档位。

**注意**：行走链式参考仍读 `sprite_lengguyun_walk_south_f01.png`；**续帧输出尺寸须与模板一致**，故重出 f01 后 f02～f04 才会与参考同分辨率；跑批建议 **`GEN_CONCURRENCY=1`**。

### 15.5 Field sprite 镜头与 45° 场景解耦（2026-04-28）

**现象**：行走 4 帧一致性尚可，但观感像 **45° 等距地砖 RPG**，与当前 Field（`Sprite2D` + 立绘缩放 + `flip_h`）不一致。

**处理**：`sprite_protagonist_*` 模板与冷孤云相关 `facing` 文案改为 **正交侧向、略俯视、身体朝画幅左**（明确禁止 45° 等距地砖假三维）；`docs/sprite-prompt-playbook.md` v0.3 说明任务 id 中 `_south_` 仅为历史命名。场景背景仍可继续用 `scene_background_45deg` 等 **插画透视**，与角色小贴图镜头分开约定。

### 15.6 行走 f03 外衣偏浅（2026-04-29）

**现象**：链式 edits 后仍出现 **f03 袍色比其它帧浅**（交叉步、大块袍面易被模型整体提亮）。

**处理**：`sprite_protagonist_walk` / `walk_ref` 增补 **外衣明度与灰阶锁定**；`walk_ref` 增加可选变量 `color_stability_hint`，在 `sprite_lengguyun_walk_south_f03` 写入 **严禁整袍提浅** 的帧专用句；f02/f04 置 `color_stability_hint: ""` 占位。

### 15.7 行走像站桩 + 跨帧色差（2026-04-29）

**现象**：续帧颜色仍看得出差别；**脚步几乎不变**，不像走路。

**原因**：模板中「双脚落在同一水平线」易被模型理解成 **钉死脚位**；`leg_phase` 偏含蓄时 **edits** 为保脸会弱化下肢；色温未与明度一起锁。

**处理**：`walk` / `walk_ref` 改为强调 **水平地面上的前后错步与承重切换**、禁止站桩；`walk_ref` 写明 **须改变脚底落点**、允许小幅整体平移；补 **冷灰色相** 防偏褐偏紫；`tasks.yaml` 四帧 `leg_phase` 改为 **接触/过渡/镜像接触/回环** 的可读描述；禁忌加 **站桩行走**。

### 15.8 仅使用 gpt-image-2、禁用自动 fallback（2026-04-29）

**需求**：重跑时不要用 `gpt-image-1.5` 兜底。

**做法**：`gen_assets.py` 传 **`--fallback-model gpt-image-2`**（与主模型同名），则 `fallback_model != primary_model` 不成立，**不会**再切 1.5。已写入 `docs/sprite-prompt-playbook.md` 示例注释。

### 15.9 主角 sprite 全量重跑顺序（2026-04-29）

**需求**：参考老式武侠 RPG 侧向场景移动观感，完成冷孤云现有主角 sprite 批次。

**命令顺序**：先单独跑 `sprite_lengguyun_walk_south_f01`，再跑 idle / idle_anim / walk f02～f04 / attack，且设置 `GEN_CONCURRENCY=1` 与 `--fallback-model gpt-image-2`。这样 f02～f04 读到的是最新 f01 参考图，并且全程只用 `gpt-image-2`。

**结果**：10 张成功（walk f01 单张 + 其余 9 张），总花费约 **¥1.3869**，输出在 `assets/raw/sprite/v2/`。

### 15.10 参考传统武侠 sprite sheet 改成四向行走表（2026-04-30）

**反馈**：此前单帧图仍像缩小立绘，不像可播放的游戏 sprite；`idle_south` 等还可能出现头巾/额带这种明显错误。

**处理**：新增 `sprite_protagonist_walk_4dir_sheet.yaml` 与任务 `sprite_lengguyun_walk_4dir_sheet`（`sprite/v3`）。使用用户提供的传统武侠 sprite sheet 作为 **动作节奏/小人比例/四向排布参考**，但角色身份仍以冷孤云锚点为准；prompt 明确禁止头巾、额带、红头绳、蓝衣、文字标签。

**结果**：`gpt-image-2` 成功生成 1 张 **4 方向 × 4 帧** 行走表，花费约 **¥0.1762**，输出 `assets/raw/sprite/v3/sprite_lengguyun_walk_4dir_sheet.png`。后续应优先从这种 sheet 裁切/缩放，而不是继续用“单帧大立绘”做 sprite。

### 15.11 从四向行走 sheet 生成 GIF 预览（2026-04-30）

**做法**：把 `assets/raw/sprite/v3/sprite_lengguyun_walk_4dir_sheet.png` 按 4×4 网格裁切，生成单方向 GIF 与四方向同屏预览。

**输出**：`assets/previews/sprite/`

- `sprite_lengguyun_walk_down_4f.gif`
- `sprite_lengguyun_walk_left_4f.gif`
- `sprite_lengguyun_walk_right_4f.gif`
- `sprite_lengguyun_walk_up_4f.gif`
- `sprite_lengguyun_walk_4dir_4f_preview.gif`

**经验**：先用 GIF 看“是否像走路”，再决定是否扩到 8 帧；不要只看静态 sheet 判断动作连贯性。

### 15.12 单方向 8 帧右走 strip（2026-04-30）

**反馈**：4 帧行走跳帧，且原 sheet 单元格里角色中心/脚线不稳定；大部分帧都是跨开腿，缺少 passing / up 过程态。

**处理**：新增 `sprite_protagonist_walk_right_8f_strip.yaml` 与任务 `sprite_lengguyun_walk_right_8f_strip`（`sprite/v3`），输出 **1536×512 单行 8 帧**；prompt 强制 8 相位（contact/down/passing/up × 双腿）、同一脚底基线、同一格内身体中心、角色高度 110～140px，并继续禁止头巾/额带。

**结果**：`gpt-image-2` 成功生成 1 张右走 8 帧 strip，花费约 **¥0.2234**；输出 `assets/raw/sprite/v3/sprite_lengguyun_walk_right_8f_strip.png`。预览 GIF：`assets/previews/sprite/sprite_lengguyun_walk_right_8f.gif` 与 `_raw.gif`。当前观感比 4 帧顺，但角色仍偏大，过渡帧仍需继续压小人与均匀步态。

### 15.13 GIF 跳帧：固定锚点导出而不是逐帧白边裁切（2026-04-30）

**现象**：预览 GIF 中每帧画布/角色位置不一致，动画看起来跳；等分裁切还会因为模型未严格对齐格子而切到衣摆或剑。

**处理**：新增 `scripts/build_sprite_preview.py`。流程：先可选按非白像素列分割角色块（`--segment-columns`），再将每帧放入统一画布并以 **底部居中** 为锚点；需要检查原始比例时用 `--preserve-scale`，需要游戏小图时统一 `--sprite-height`。

**输出样例**：

- 固定 160×160 / 统一高度版：`assets/previews/sprite/sprite_lengguyun_walk_right_8f_segmented_fixed.gif`
- 保留原比例 / 底部锚定版：`assets/previews/sprite/sprite_lengguyun_walk_right_8f_segmented_anchor.gif`

**经验**：游戏中使用 sprite 时必须导出 **同尺寸帧 + 同 anchor（通常 bottom-center）**；不要直接把自动裁白边后的不同尺寸 PNG 串成 GIF，否则一定跳。

### 15.14 8 帧右走闭环接缝：加第 9 格校验帧（2026-04-30）

**现象**：固定锚点后，第 8 帧回第 1 帧仍明显跳，说明源动作本身没有闭环。

**处理**：新增 `sprite_protagonist_walk_right_8f_loop_strip.yaml` 与任务 `sprite_lengguyun_walk_right_8f_loop_strip`。生成 **9 格**：第 1～8 格为动画，第 9 格必须复制第 1 格姿态，作为 loop check，迫使第 8 格成为可接回第 1 格的过渡。

**结果**：`gpt-image-2` 成功生成，花费约 **¥0.2226**。输出：

- 原图：`assets/raw/sprite/v3/sprite_lengguyun_walk_right_8f_loop_strip.png`
- 8 帧预览：`assets/previews/sprite/sprite_lengguyun_walk_right_8f_loopcheck.gif`
- 9 格校验预览：`assets/previews/sprite/sprite_lengguyun_walk_right_9f_with_loopcheck.gif`

**经验**：AI 生成动画 strip 时，仅写“8 帧循环”不够；必须显式要求 **首尾闭环校验帧**，否则最后一帧经常不是回到第一帧前的过渡。

---

## 16. 多 Agent 协作启动（2026-04-30）

### 16.1 现象与触发

单 agent 同时跑剧情 / Godot 系统 / 战斗 / 任务 / 美术 / 测试，长链路下出现：
- 上下文污染（美术 prompt 残留进 Godot 脚本）
- 风格漂移（同一 NPC 口吻变化）
- 经验记录遗漏（解决了不写 `experience-log`）
- 重复试错（同一种 fallback 反复触发）

### 16.2 处理

落地多 Agent 协作 v0.1：
- 新增 `docs/agent-workflow.md`：固定 7 角色（producer / lore / system / battle / art / qa / review）、标准流程、`[handoff]` 交接格式、模型分层建议、并行串行规则。
- 新增 `docs/module-owners.md`：把 `game/` `prompts/` `scripts/` `assets/` `docs/` 下每个目录的写权 agent 写死。
- 新增 `docs/acceptance-checklists/{lore,system,battle,art,qa}.md`：各角色提交前自检清单。
- `AGENTS.md` 加「多 Agent 协作」速查节，并把读文件清单更新为：
  `AGENTS.md → current-progress → agent-workflow → module-owners → experience-log`。
- `docs/current-progress.md` §6 新增「多 Agent 协作」状态行，列出当前唯一进行中的试运行任务。
- 试运行：当前主角 sprite 8 帧右走闭环作为首个走完整流程的任务，handoff 模板见 `docs/pilot-handoff-sprite-walk-right-8f.md`。

### 16.3 经验

- **不要按文件随便分 agent**，按「写权目录」分；同一文件的字段也要按字段拆 owner（如 `q_*.tres` 文案归 lore，trigger 字段归 system，奖励数值归 battle）。
- **acceptance 必填**：任何收到不带可验证 acceptance 的请求，agent 应当先把 acceptance 补齐再开工，否则容易又跑回主控代为决策。
- **写权串行 + 探索并行**：探索 agents 可以并行调研多模块，但同一文件的写改任何时候只能一个 agent 持有。
- **新坑必写**：包括「越界」也算坑（如 art agent 改了 Godot 脚本），写到本文件下一节，由 producer 决定边界是否需要调整。

---

## 17. 多 Agent 独立角色记忆（2026-04-30）

### 17.1 现象与触发

用户指出：如果只是同一个 agent 在同一会话中“扮演不同角色”，长期仍然会共享同一套上下文窗口和即时记忆，容易把剧情、美术、系统、战斗、QA 的经验混在一起；持续开发时，角色经验无法稳定累积。

### 17.2 处理

在 `docs/agents/` 下落地独立角色记忆系统：

- `docs/agents/README.md`：角色记忆索引、读写协议、handoff 需要新增 `memory_files`。
- `docs/agents/producer-memory.md`：优先级、sprint 状态、跨角色决策和集成风险。
- `docs/agents/lore-memory.md`：世界观、角色口吻、禁忌、旧名替换规则。
- `docs/agents/system-memory.md`：Godot autoload、路由、存档、UI 和系统坑。
- `docs/agents/battle-memory.md`：技能、敌人、装备数值、战斗节奏和状态异常准备。
- `docs/agents/art-memory.md`：prompt、sprite 规格、出图模型、后处理、GIF/QA 经验。
- `docs/agents/qa-memory.md`：测试命令、手测清单、bug 复现格式、sprite strip QA。
- `docs/agents/review-memory.md`：审查关注点、历史回归、角色越界风险。
- `docs/agents/memory-template.md`：新增角色时复制的模板。

同步更新：

- `AGENTS.md`：新会话读取顺序增加 `docs/agents/README.md` 与 `producer-memory.md`；具体角色领取任务前读自己的 memory。
- `docs/agent-workflow.md`：handoff 格式新增 `memory_files`；增加 §5.1 角色记忆读写规则。
- `docs/module-owners.md`：明确 `docs/agents/*.md` 的写权归属。
- `docs/current-progress.md`：§6 增加角色记忆系统状态。

### 17.3 经验

- **角色记忆不是聊天记录**：只记录长期有用的规则、命令、坑点、当前模块状态；不要复制整段对话。
- **短结论写 memory，完整复盘写 experience-log**：例如 sprite 基线跳帧的完整原因仍写 §15，art-memory 只保留可执行结论。
- **每个 handoff 必须带 `memory_files`**：否则下一棒不知道该读哪份长期记忆，仍会退回“一个 agent 混合记忆”。
- **producer 记忆只收跨角色决策**：不要把 lore/art/system 的细节全部塞进 producer-memory，否则主控又会变成新的混合记忆池。

---

## 18. Sprite 未解决前的低成本优化纪律（2026-04-30）

### 18.1 现象与触发

主角 sprite 已经做过多轮：v2 单帧 / 4 帧 edits、v3 四向 sheet、8 帧右走 strip、9 格 loop-check strip。虽然方向更接近游戏 sprite，但仍未最终解决：角色比例、过渡帧、闭环、脚底基线、参考图稳定性都还需要优化。

继续凭肉眼感觉反复重跑，会浪费 API 成本。

### 18.2 处理

新增 `docs/sprite-cost-optimization-plan.md`，把后续 sprite 出图改成三段式：

1. **零 API**：先跑 `scripts/qa/check_sprite_strip.py`、`scripts/build_sprite_preview.py`，用现有 raw 判断是裁切/锚点问题还是源动作问题。
2. **dry-run**：付费前用 `python scripts/gen_assets.py --task <id> --dry-run --force` 看 prompt 和参考图，不让旧图跳过掩盖新 prompt。
3. **最小付费实验**：一次只跑 1 个 task；右走方向稳定后再复制到其他方向；不批量盲跑四方向。

同时把依赖外部参考图的两个 v3 模板加上 `require_reference_images: true`：

- `prompts/templates/sprite_protagonist_walk_4dir_sheet.yaml`
- `prompts/templates/sprite_protagonist_walk_right_8f_loop_strip.yaml`

这样参考图丢失时会在 dry-run / render 阶段报错，不会静默无参考烧钱出图。

另外修正 `scripts/gen_assets.py` 的 dry-run 行为：dry-run meta 改写到 `logs/dry_run/<task_id>.meta.json`，不再覆盖 `assets/raw/**/*.meta.json` 的真实出图成本记录。

### 18.3 经验

- **先归因再出图**：GIF 跳帧可能是裁切/锚点问题，不一定是 prompt 问题；必须先用固定锚点预览验证。
- **8 帧循环默认带第 9 格校验**：第 9 格复制第 1 格只用于验收，导入游戏时只用前 8 格。
- **QA 命令必须匹配格数**：普通 8 帧 `--expected 8`；9 格 loop-check `--expected 9`。
- **参考图路径是成本风险**：依赖本机 `workspaceStorage` 绝对路径的模板不可长期复用；重要参考图应归档进仓库或至少让模板 `require_reference_images` 失败保护。
- **dry-run 不能污染真实元数据**：真实 `.meta.json` 是成本与模型记录，dry-run 只能写 `logs/dry_run/`。
- **场景/角色经验已保存，但要区分历史 prompt**：`style-bible-prompts.md` 仍有早期旧 IP 提示词，当前新图不要直接沿用，应以 `world-bible` 与 `art-memory` 为准。

---

## 19. Agent Hub 本地 Web 调度台（2026-05-01）

### 19.1 现象与触发

多 agent 规范和角色记忆已经落地，但文档、产物、QA、成本、handoff 仍然分散在 `docs/`、`assets/`、`logs/`、`prompts/` 中。用户希望有一个 Web 管理系统，能看全整个项目，也能按不同职能 agent 管理任务与产出。

同时用户明确不想第一版就单独部署多个 agent 或分别配置大模型；Web 上发布任务后，实际仍由 Cursor 中的当前 agent 按角色规范执行。

### 19.2 处理

新增 `tools/agent_hub/`：

- `app.py`：FastAPI 本地 Web 应用。
- `db.py`：SQLite 初始化与通用查询。
- `scanner.py`：扫描 `docs/agents/`、`docs/`、`prompts/`、`assets/`、`logs/qa/`、`logs/dry_run/` 等产出。
- `templates/`：Dashboard、Agents、Tasks、Handoffs、Artifacts、QA、Costs 页面。
- `static/style.css`：本地 UI 样式。
- `verify_agent_hub.py`：不启动服务的扫描验收脚本。
- `README.md`：启动方式与第一版边界。

第一版边界：

- Web 不调用大模型，不保存模型 key，不自动触发外部 agent。
- Web 创建任务、生成标准 `[handoff]`，用户复制到 Cursor 执行。
- Cursor 执行后写回仓库文档 / 产物 / 日志，Web 重新扫描更新状态。
- 本地 SQLite `tools/agent_hub/agent_hub.sqlite3` 加入 `.gitignore`，避免把个人看板状态提交。

### 19.3 验证

已执行：

```powershell
python -m py_compile tools/agent_hub/app.py tools/agent_hub/db.py tools/agent_hub/scanner.py tools/agent_hub/verify_agent_hub.py
python -m tools.agent_hub.verify_agent_hub
python -c "from fastapi.testclient import TestClient; from tools.agent_hub.app import app; client=TestClient(app); paths=['/health','/','/agents','/tasks','/handoffs','/artifacts?owner_agent=art&kind=image','/qa','/costs']; [print(p, client.get(p).status_code) for p in paths]"
```

扫描结果：

- agents: 7
- artifacts: 162
- qa_runs: 2
- cost_records: 42
- tasks: 48

路由 smoke test 全部 200。

### 19.4 经验

- **Web 是调度台，不是 agent runtime**：第一版只做任务 / handoff / 扫描 / 状态，不解决模型调用。
- **先用 SQLite 做本地事实索引**：Markdown/YAML/目录仍是源数据，SQLite 是本地视图层。
- **本地文件服务也要最小授权**：`/repo/{path}` 不能直接开放仓库任意文件；只能返回已扫描 artifact，且必须拒绝 `.env`、`*.key`、本地 SQLite 等敏感文件。
- **成本不能跨币种直接相加**：DMXAPI 是 CNY，OpenAI 官方是 USD；Dashboard 必须按 `currency` 分组展示。
- **Jinja/Starlette 版本要注意 `TemplateResponse` 签名**：当前环境使用 `templates.TemplateResponse(request, "template.html", context)`；旧写法会触发 `TypeError: unhashable type: 'dict'`。
- **包内导入要用相对导入**：`tools.agent_hub.app` 被 uvicorn 作为模块导入时，应使用 `from .db import ...`，否则会报 `ModuleNotFoundError: No module named 'db'`。
- **不要整包安装重依赖**：验证 Web 只需安装 `fastapi uvicorn jinja2 python-multipart`，避免顺带拉 `rembg/onnxruntime` 等大包。

### 19.5 中文化与界面升级（2026-05-01）

用户反馈 Agent Hub 页面仍有较多英文，且视觉效果偏基础。处理方式：

- `tools/agent_hub/app.py` 增加 Jinja 过滤器：`status_label`、`agent_label`、`kind_label`、`yes_no`，数据库仍保存英文状态值，页面显示中文。
- `tools/agent_hub/templates/*.html` 将导航、标题、表单、表格列名、状态、成本 dry-run 标记等改为中文；handoff 协议正文仍保留固定字段，避免破坏复制给 Cursor 的格式。
- `tools/agent_hub/static/style.css` 重新设计为暗色宣纸 + 描金 + 朱砂点缀的“武侠项目驾驶舱”风格，强化顶栏、卡片、表格、状态胶囊和表单层次。
- 验证命令：

```powershell
python -m compileall "tools\agent_hub"
python -m tools.agent_hub.verify_agent_hub
python -c "from fastapi.testclient import TestClient; from tools.agent_hub.app import app; c=TestClient(app); paths=['/','/agents','/tasks','/handoffs','/artifacts','/qa','/costs']; print({p: c.get(p).status_code for p in paths})"
```

结果：编译通过，`agents: 7`、`artifacts: 162`、`qa_runs: 2`、`cost_records: 42`、`tasks: 49`，主要页面均返回 200。运行中的 uvicorn `--reload` 进程曾短暂保留旧 Jinja 环境导致 `/` 500（`No filter named 'status_label'`），重启 Agent Hub 后线上本地服务 `/`、`/agents`、`/tasks`、`/handoffs`、`/artifacts`、`/qa`、`/costs` 均返回 200。

经验：

- **显示中文，不要改内部枚举**：`planned/in_progress/qa/review/blocked/done` 等内部值继续用于查询和表单提交，Jinja filter 只负责展示层翻译。
- **协议字段与用户界面分离**：`[handoff] from/to/goal/...` 是跨 Agent 的标准协议，不应为了中文化改掉字段名；页面标题、按钮和说明可以中文化。
- **主题要贴合项目语境**：普通深色后台容易显得临时；本项目可使用暗色、金色、朱砂、宣纸纹理，形成更像“江湖制作中枢”的识别度。
- **新增 Jinja filter 后要确认运行中服务**：TestClient 通过不等于浏览器里的旧 uvicorn 进程已刷新；若模板新增 filter 后页面 500，应查看服务日志并重启本地服务。

### 19.6 故事剧情总览页（2026-05-01）

用户希望 Agent Hub 增加“故事剧情”页面，把主要角色、门派介绍以及每章剧情概要展示清楚。处理方式：

- 新增 `tools/agent_hub/story_data.py`，把 `docs/world-bible.md`、`docs/design-mvp-chapter1.md`、`docs/agents/lore-memory.md` 中的核心剧情整理为只读结构化数据。
- 新增 `/story` 路由与 `tools/agent_hub/templates/story.html`，展示：
  - 一句话世界观与核心悬念节奏
  - 主要角色名帖
  - 七大门派 / 势力榜
  - 八章主线时间线
  - A/B/C/D 四结局路线
- `tools/agent_hub/templates/base.html` 导航新增“故事”入口。
- `tools/agent_hub/static/style.css` 增加故事页专属样式：卷宗 hero、人物名帖、势力榜、卷轴时间线、结局卡。

验证命令：

```powershell
python -m compileall "tools\agent_hub"
python -m tools.agent_hub.verify_agent_hub
python -c "from fastapi.testclient import TestClient; from tools.agent_hub.app import app; c=TestClient(app); paths=['/','/story','/agents','/tasks','/handoffs','/artifacts','/qa','/costs']; print({p: c.get(p).status_code for p in paths})"
python -c "import urllib.request; paths=['/story','/']; print({p: urllib.request.urlopen('http://127.0.0.1:8765'+p, timeout=5).status for p in paths})"
```

结果：编译通过，TestClient 主要页面全部 200；运行中的本地服务重启后 `/story` 与 `/` 均返回 200。

经验：

- **剧情页先做只读总览，不急着做编辑器**：当前目标是让项目管理时看清角色、势力、章节和结局全貌；编辑功能会牵涉 canonical source、冲突合并和验收，后续再做。
- **剧情数据应独立于路由文件**：大量角色 / 章节文案不要直接堆进 `app.py`，单独放 `story_data.py`，未来迁移到 YAML 或 SQLite 更容易。
- **Web 总览要标注资料来源**：页面中保留 `world-bible`、`design-mvp-chapter1`、`lore-memory` 链接，避免后续不知道剧情展示来自哪里。
- **新增路由后要验证真实运行服务**：TestClient 通过后仍要访问本地 uvicorn；若 `--reload` 没刷新路由，需重启服务。

### 19.6.1 Agent Hub 需求列表页（2026-05-05）

用户希望 Agent Hub 增加“需求列表”页面，用“大模块 + 子模块 + 功能需求”来跟进进度。

处理：

- 新增 `docs/requirements.yaml`，作为仓库内可追踪的初始需求源。
- `tools/agent_hub/db.py` 增加 `requirements` 表。
- `tools/agent_hub/scanner.py` 增加 `import_requirements()`，从 `docs/requirements.yaml` 导入需求；扫描时不覆盖 Web 中已更新的 `status`。
- `tools/agent_hub/app.py` 增加 `/requirements`、新增需求、更新需求状态、从需求拆任务的路由。
- `tools/agent_hub/templates/requirements.html` 增加需求页，支持按大模块 / 子模块分组查看。
- `tools/agent_hub/templates/base.html` 导航新增“需求”。
- `tools/agent_hub/verify_agent_hub.py` 增加 requirements 表和 `/requirements` 路由验证。

经验：

- **需求和任务要分层**：需求是产品/模块目标，任务是分派给 agent 的执行项；Web 上应能从需求拆任务，但不要混为同一张表。
- **需求源要进仓库**：只存在 SQLite 会随本地状态丢失；用 `docs/requirements.yaml` 做初始事实源，SQLite 做状态视图。
- **扫描导入不要覆盖状态**：YAML 提供需求定义，页面更新的进度状态应保留，避免每次扫描把状态重置回 planned。

### 19.6.2 Agent Hub 工作证明门禁（2026-05-05）

背景：

- 需求页和任务页虽然能跟进状态，但“直接点完成”缺少可追溯证据，容易造成口头完成、后续难复盘。

处理：

- `requirements` 与 `tasks` 表新增 `proof_summary`、`proof_links`、`proof_updated_at` 字段。
- `db.py` 增加兼容迁移逻辑：老库启动时自动 `ALTER TABLE` 补列，不需要手动删库。
- 新增接口：`POST /requirements/{id}/proof`、`POST /tasks/{id}/proof`。
- 状态门禁：`/requirements/{id}/status` 与 `/tasks/{id}/status` 在置为 `done` 前强校验“摘要 + 证据链接”都非空。
- `requirements.html`、`tasks.html` 增加工作证明卡片与“已齐全/未齐全”标识，并显示成功/失败反馈。

经验：

- **完成态必须有证据**：没有证据的“完成”在多人协作里不可审计，后续交接和回归会反复踩坑。
- **门禁要后端兜底**：不能只靠前端按钮禁用，必须在状态更新接口再次校验。
- **迁移优先无破坏**：已有 SQLite 数据应自动补字段，避免要求团队先手工清库。

### 19.7 Agent Hub 字号缩放（2026-05-01）

用户反馈 Web 系统整体字体偏大。处理方式：

- 在 `tools/agent_hub/static/style.css` 中将 `body` 基础字号降为 `14px`。
- 同步下调导航、主标题、二级标题、表格头、状态标签、路径、表单标签、故事页 lead、角色 / 门派 / 章节 / 结局卡标题，避免只缩正文导致视觉层级失衡。

验证：

```powershell
python -c "from fastapi.testclient import TestClient; from tools.agent_hub.app import app; c=TestClient(app); paths=['/','/story','/agents','/tasks','/handoffs','/artifacts','/qa','/costs']; print({p: c.get(p).status_code for p in paths})"
python -c "import urllib.request; paths=['/static/style.css','/story','/']; print({p: urllib.request.urlopen('http://127.0.0.1:8765'+p, timeout=5).status for p in paths})"
```

结果：主要页面和 `style.css` 均返回 200，linter 无报错。

经验：

- **后台类页面要优先信息密度**：故事 / 任务 / 产出页面内容很多，基础字号用 14px 更适合长时间浏览。
- **缩放字号要成组处理**：正文、标题、标签、表格、故事页专属组件要同步缩放，否则会出现正文小、标题仍压迫的失衡感。

### 19.8 Agent Hub 下拉框可读性（2026-05-01）

用户反馈产出页面下拉框字体呈金色，不容易看清。处理方式：

- 在 `tools/agent_hub/static/style.css` 中显式设置 `select` 和 `select option` 的前景色为浅色、背景为深色，避免被强调色或浏览器默认样式影响。

验证：`/artifacts` 与 `/static/style.css` 均返回 200，linter 无报错。

经验：

- **select 要单独设 option 颜色**：只设置 `select` 本体不一定能覆盖展开选项，尤其在深色主题下需要同时设置 `select option`。

### 19.9 主角四方向 walk sprite 一次过 PASS（2026-05-01）

目标：在 `docs/sprite-cost-optimization-plan.md` 的纪律下，把主角 Field 四方向行走素材一次性补齐。

策略：

- 右走沿用已有 9 格 loop-check PASS 基准，不重生成。
- 上走 / 下走各新增一个 `prompts/templates/sprite_protagonist_walk_<dir>_8f_loop_strip.yaml`，结构、画幅、对齐、身份硬锁与右走完全一致，只重写运动方向描述。
- 左走由右走通过 `scripts/mirror_sprite_strip.py` 做逐格水平镜像得到，0 API 成本。

验证命令（关键步骤）：

```powershell
# 1) dry-run，输出在 logs/dry_run/
python scripts/gen_assets.py --task sprite_lengguyun_walk_down_8f_loop_strip --dry-run --force
python scripts/gen_assets.py --task sprite_lengguyun_walk_up_8f_loop_strip   --dry-run --force

# 2) 单方向付费生成（一个一个跑，先下再上）
python scripts/gen_assets.py --task sprite_lengguyun_walk_down_8f_loop_strip --fallback-model gpt-image-2 --skip-ping
python scripts/gen_assets.py --task sprite_lengguyun_walk_up_8f_loop_strip   --fallback-model gpt-image-2 --skip-ping

# 3) QA + 固定锚点 GIF / processed sheet
python scripts/qa/check_sprite_strip.py --source assets/raw/sprite/v3/sprite_lengguyun_walk_down_8f_loop_strip.png --expected 9 --baseline-tolerance 12 --height-tolerance 24 --report logs/qa/sprite_walk_down_8f_loop_strip.json
python scripts/qa/check_sprite_strip.py --source assets/raw/sprite/v3/sprite_lengguyun_walk_up_8f_loop_strip.png   --expected 9 --baseline-tolerance 12 --height-tolerance 24 --report logs/qa/sprite_walk_up_8f_loop_strip.json
python scripts/build_sprite_preview.py --source assets/raw/sprite/v3/sprite_lengguyun_walk_down_8f_loop_strip.png --cols 9 --segment-columns --sprite-height 96 --canvas-width 160 --canvas-height 160 --duration-ms 90 --output-gif assets/previews/sprite/sprite_lengguyun_walk_down_9f_check.gif --output-sheet assets/processed/sprite/sprite_lengguyun_walk_down_9f_check.png
python scripts/build_sprite_preview.py --source assets/raw/sprite/v3/sprite_lengguyun_walk_up_8f_loop_strip.png   --cols 9 --segment-columns --sprite-height 96 --canvas-width 160 --canvas-height 160 --duration-ms 90 --output-gif assets/previews/sprite/sprite_lengguyun_walk_up_9f_check.gif --output-sheet assets/processed/sprite/sprite_lengguyun_walk_up_9f_check.png

# 4) 左走镜像（不消耗 API）
python scripts/mirror_sprite_strip.py --source assets/raw/sprite/v3/sprite_lengguyun_walk_right_8f_loop_strip.png --output assets/processed/sprite/sprite_lengguyun_walk_left_8f_loop_strip_mirror.png --expected 9
python scripts/qa/check_sprite_strip.py --source assets/processed/sprite/sprite_lengguyun_walk_left_8f_loop_strip_mirror.png --expected 9 --baseline-tolerance 12 --height-tolerance 24 --report logs/qa/sprite_walk_left_8f_loop_strip.json
python scripts/build_sprite_preview.py --source assets/processed/sprite/sprite_lengguyun_walk_left_8f_loop_strip_mirror.png --cols 9 --segment-columns --sprite-height 96 --canvas-width 160 --canvas-height 160 --duration-ms 90 --output-gif assets/previews/sprite/sprite_lengguyun_walk_left_9f_check.gif --output-sheet assets/processed/sprite/sprite_lengguyun_walk_left_9f_check.png
```

QA 结果：

| 方向 | 检出 | 基线极差 | 高度极差 | 状态 |
|------|------|----------|----------|------|
| 右 | 9/9 | 7 px | 7 px | PASS |
| 下 | 9/9 | 5 px | 5 px | PASS |
| 上 | 9/9 | 3 px | 3 px | PASS |
| 左（镜像） | 9/9 | 7 px | 7 px | PASS |

成本：下 ¥0.1522 + 上 ¥0.1526 = **¥0.3048**，左走 0 元。

经验：

- **方向模板要在右走 PASS 之后再写，不要四方向并行造**：一旦右走的对齐 / 身份锁仍在跳动，复制到三个方向只会把同一个错放大三倍。
- **正面 / 背面方向必须显式禁止侧向行走**：默认 prompt 里所有“前后步幅、剑挂腰侧”等描述容易被模型重解读为侧向走，模板里要把“正面朝镜头 / 背朝镜头”当硬约束写。
- **左走永远走镜像，别二次出图**：镜像继承右走基线和身份，QA 数据完全一致；任何 prompt 重写都可能引入身份漂移和成本支出。
- **镜像产物属于 `processed/`**：`assets/processed/sprite/...mirror.png` 不要污染 `assets/raw/sprite/v3/`，便于回溯它来自后处理而非 API。
- **dry-run + 单方向付费 + QA 立即跑**：付费完后必须当场跑 `check_sprite_strip` 才决定是否进入下一方向，而不是“四方向连发再回头看”。
- **`--fallback-model gpt-image-2`** 锁主模型不降级；`--skip-ping` 在 DMXAPI 偶尔抖动时也能把单方向跑掉，但不要把它当默认开。

### 19.10 Agent Hub 产出页索引滞后（2026-05-01）

现象：主角四方向 sprite 已经生成到 `assets/raw/`、`assets/processed/`、`assets/previews/` 和 `logs/qa/`，但 Agent Hub 的 `/artifacts` 产出页没有立刻显示最新图片。

根因：

- `tools/agent_hub/app.py` 只在 FastAPI startup 或手动 POST `/scan` 时调用 `scan_all()`。
- 出图是在服务运行期间完成的，SQLite 中的 `artifacts` 表仍是旧索引；页面渲染只读旧表，不会主动扫描文件系统。
- 直接运行 `python -m tools.agent_hub.verify_agent_hub` 能刷新索引，所以不是文件缺失，也不是图片类型过滤错误。

处理：

- 新增 `_refresh_index(conn)`，统一包装 `scan_all(conn)`。
- `/`、`/artifacts`、`/qa`、`/costs` 在查询前主动刷新索引，保证仓库派生产物页面与磁盘同步。
- 保留 `/scan` 手动刷新入口，但不再依赖用户每次产图后手动点刷新。

验证：

```powershell
python -m compileall tools\agent_hub
python -c "from fastapi.testclient import TestClient; from tools.agent_hub.app import app; c=TestClient(app); resp=c.get('/artifacts?owner_agent=art&kind=image'); html=resp.text; print(resp.status_code); print('sprite_lengguyun_walk_down_9f_check.gif' in html, 'sprite_lengguyun_walk_up_9f_check.gif' in html, 'sprite_lengguyun_walk_left_9f_check.gif' in html, 'sprite_lengguyun_walk_right_9f_check.gif' in html)"
python -c "import urllib.request; html=urllib.request.urlopen('http://127.0.0.1:8765/artifacts?owner_agent=art&kind=image', timeout=10).read().decode('utf-8', errors='replace'); print('sprite_lengguyun_walk_down_9f_check.gif' in html, 'sprite_lengguyun_walk_up_9f_check.gif' in html, 'sprite_lengguyun_walk_left_9f_check.gif' in html, 'sprite_lengguyun_walk_right_9f_check.gif' in html)"
```

结果：TestClient 和真实本地服务均返回 200，四张 `_9f_check.gif` 都能在产出页 HTML 中找到。

经验：

- **仓库扫描型页面不能只靠 startup 索引**：AI 出图、QA 报告、成本 meta 都是在服务运行时追加的，列表页应在查询前刷新或提供明确刷新动作。
- **先判断是“文件没生成”还是“索引没更新”**：先跑 `verify_agent_hub` 或直接查页面 HTML，避免误以为图片路径、缩略图或过滤条件有问题。
- **PowerShell 不支持 Bash `python - <<'PY'` heredoc**：Windows 下临时 Python 查询用 `python -c "..."` 或脚本文件，避免把排查时间浪费在 shell 语法上。
- **本机 PowerShell 也不要假设可用 `&&`**：需要串联验证命令时用 `;`，或拆成多次 Shell 调用。

### 19.11 9 格 loop-check GIF 不应当作播放版（2026-05-01）

用户反馈主角四方向 walk 的动作不连贯，两只脚卡顿明显。排查结果：

- `check_sprite_strip.py` 只验证检出数、脚底基线、角色高度，不能证明“腿部相位连续”。
- 产出页最先看到的是 `_9f_check.gif`，它包含第 9 格 loop-check；第 9 格本来就应该复制第 1 格，用来证明 8 → 1 能闭环。
- 把 9 格校验 GIF 当动画播放，会在循环点出现“第 1 帧停两拍”的视觉卡顿。
- 排除第 9 帧后，循环点卡顿会减轻；若仍卡，才说明原始 1～8 帧本身的步态相位不均匀。

处理：

- `scripts/build_sprite_preview.py` 新增 `--frame-count` 参数，可从 9 格 loop-check 源图只取前 8 帧生成真正播放版。
- 新增四方向播放预览：
  - `assets/previews/sprite/sprite_lengguyun_walk_right_8f_play.gif`
  - `assets/previews/sprite/sprite_lengguyun_walk_left_8f_play.gif`
  - `assets/previews/sprite/sprite_lengguyun_walk_down_8f_play.gif`
  - `assets/previews/sprite/sprite_lengguyun_walk_up_8f_play.gif`
- 对应 fixed sheet：
  - `assets/processed/sprite/sprite_lengguyun_walk_right_8f_play.png`
  - `assets/processed/sprite/sprite_lengguyun_walk_left_8f_play.png`
  - `assets/processed/sprite/sprite_lengguyun_walk_down_8f_play.png`
  - `assets/processed/sprite/sprite_lengguyun_walk_up_8f_play.png`

验证：

```powershell
python scripts/build_sprite_preview.py --source assets/raw/sprite/v3/sprite_lengguyun_walk_down_8f_loop_strip.png --cols 9 --segment-columns --frame-count 8 --sprite-height 96 --canvas-width 160 --canvas-height 160 --duration-ms 80 --output-gif assets/previews/sprite/sprite_lengguyun_walk_down_8f_play.gif --output-sheet assets/processed/sprite/sprite_lengguyun_walk_down_8f_play.png
python -m compileall scripts\build_sprite_preview.py
python -c "import urllib.request; html=urllib.request.urlopen('http://127.0.0.1:8765/artifacts?owner_agent=art&kind=image', timeout=10).read().decode('utf-8', errors='replace'); print('sprite_lengguyun_walk_down_8f_play.gif' in html, 'sprite_lengguyun_walk_up_8f_play.gif' in html, 'sprite_lengguyun_walk_left_8f_play.gif' in html, 'sprite_lengguyun_walk_right_8f_play.gif' in html)"
```

经验：

- **文件名区分 QA 版和播放版**：`_9f_check.gif` 只给 QA / review 看闭环，第 9 帧不要导入 Godot；`_8f_play.gif` 才给用户看真实播放效果。
- **对齐 PASS 不等于动作 PASS**：脚底稳定只能说明没有上下跳，不能说明两脚动作连贯；后续需要增加“相位 QA”或人工标注。
- **若 8 帧播放版仍卡，别靠调 GIF 时长硬救**：那是原始帧姿态分布问题，应改 prompt / 工作流。推荐先生成 4 个强约束关键姿态，再用 edits 补 4 个过渡帧，而不是一次自由生成 8 帧。

### 19.12 Walk sprite 改用 4 帧稳定策略（2026-05-01）

用户确认 8 帧播放版仍“不连贯、抖动走动”。结论：现有 8 帧源图动作相位本身不连续，不能再靠裁切、锚点或播放时长修复。

处理路径：

1. 新增 `prompts/templates/sprite_protagonist_walk_right_4f_stable_strip.yaml`。
   - 只做单行 4 格：左脚前 / 中立 / 右脚前 / 中立。
   - 重点约束“头、躯干、腰带、剑、酒葫芦稳定”，只让腿和手臂轻微变化。
   - 新增 task：`sprite_lengguyun_walk_right_4f_stable_strip`。
2. dry-run 通过，参考图存在，prompt 没有旧 IP / 头巾 / 45° 等距。
3. 付费生成时 DMXAPI 返回 `APIConnectionError`，三次重试失败，未扣费。
4. `python scripts/ping_dmx.py` 也返回 `APIConnectionError`，提示连续失败通常是 IP 风控 / 渠道临时不可用，建议等待 30+ 分钟后再试。
5. 为避免空等，先从已有 `assets/raw/sprite/v3/sprite_lengguyun_walk_4dir_sheet.png` 零成本导出 4 帧固定锚点候选。

新增 / 更新的本地工具能力：

- `scripts/build_sprite_preview.py` 支持：
  - `--frame-count`：从 9 格 loop-check 只取前 N 帧；
  - `--cell-top-inset` / `--cell-bottom-inset`：从等分 grid cell 裁掉跨行残留。

4 帧候选产物：

| 方向 | GIF | QA |
|------|-----|----|
| 右 | `assets/previews/sprite/sprite_lengguyun_walk_right_4f_sheet_play.gif` | `logs/qa/sprite_walk_right_4f_sheet_play.json` |
| 左（右走镜像） | `assets/previews/sprite/sprite_lengguyun_walk_left_4f_sheet_mirror_play.gif` | `logs/qa/sprite_walk_left_4f_sheet_mirror.json` |
| 下 | `assets/previews/sprite/sprite_lengguyun_walk_down_4f_sheet_play.gif` | `logs/qa/sprite_walk_down_4f_sheet_play.json` |
| 上 | `assets/previews/sprite/sprite_lengguyun_walk_up_4f_sheet_play.gif` | `logs/qa/sprite_walk_up_4f_sheet_play.json` |

QA 结果：

| 方向 | 检出 | 基线极差 | 高度极差 | 状态 |
|------|------|----------|----------|------|
| 右 | 4/4 | 1 px | 1 px | PASS |
| 左（镜像） | 4/4 | 1 px | 1 px | PASS |
| 下 | 4/4 | 0 px | 0 px | PASS |
| 上 | 4/4 | 0 px | 0 px | PASS |

经验：

- **8 帧源图动作不连续时，直接降到 4 帧比继续补救更可靠**：4 帧经典 RPG 循环牺牲细腻度，换稳定和可用。
- **QA 要分层**：`check_sprite_strip` 只能证明对齐；动作顺不顺仍要看 GIF / sheet，后续可考虑增加相邻帧差异评分。
- **现有 4dir sheet 可做低成本候选**：它虽然比例偏大，但缩到 96px 后角色一致性好，适合作临时可用版本。
- **左走优先镜像右走**：原 4dir sheet 的左走行顶部有跨行残留；镜像右走可以避免左右动作节奏和裁切残留不一致。
- **DMXAPI 连接失败时不要连续烧时间重试**：dry-run 通过但 ping 失败，说明是渠道/网络层；记录失败，保留模板，等 30+ 分钟后单任务重试。

### 19.13 右走 4 帧稳定版重试仍为连接失败（2026-05-02）

用户要求继续重试 `sprite_lengguyun_walk_right_4f_stable_strip`。执行顺序：

```powershell
python scripts/ping_dmx.py
python scripts/gen_assets.py --task sprite_lengguyun_walk_right_4f_stable_strip --fallback-model gpt-image-2 --skip-ping
```

结果：

- `ping_dmx.py` 仍返回 `APIConnectionError: Connection error.`。
- 付费任务三次 attempt 全部为 `APIConnectionError`。
- 结果汇总：成功 0，失败 1，总花费 ¥0.0000，未扣费。
- 失败明细已追加到 `logs/failed.log`。

判断：

- dry-run 已通过，参考图存在，因此不是 prompt / 任务配置问题。
- 错误发生在网络 / 渠道层，当前继续立即重试收益很低。
- 后续应等网络 / VPN / DMXAPI 渠道恢复后再跑同一个单任务；恢复判断以 `python scripts/ping_dmx.py` 能通过为准。

### 19.14 右走 4 帧稳定版按小时自动重试（2026-05-02）

用户要求：每隔 1 小时尝试一次，连续 3 次不行就停止。

执行策略：

- 后台 PowerShell 循环最多尝试 3 次。
- 每次先跑 `python scripts/ping_dmx.py`。
- ping 成功后才跑：
  `python scripts/gen_assets.py --task sprite_lengguyun_walk_right_4f_stable_strip --fallback-model gpt-image-2 --skip-ping`
- 如果生成成功，立即跑 QA、右走固定锚点 GIF / sheet、左走镜像和左走预览，然后停止循环。
- 如果 ping 或生成失败，失败计数 +1；未满 3 次则 `Start-Sleep -Seconds 3600`。
- 日志写入 `logs/dmx_retry_right_4f.log`。

当前状态：

- 第 1 次尝试已执行，`ping_dmx.py` 仍为 `APIConnectionError`。
- 后台任务已进入第 1 次 3600 秒等待。
- 预计后续第 2 / 第 3 次在下一小时和再下一小时自动执行；连续 3 次失败后自动停止。

经验：

- **长间隔重试要先 ping 后生成**：避免渠道明显不可达时直接进入付费生成请求。
- **后台重试必须写独立日志**：跨小时任务不能只靠终端滚动输出，需落到 `logs/` 方便后续恢复和复盘。
- **成功后立即做 QA / 预览 / 镜像**：不要等人工回来再补后处理，否则容易忘记该产物是否已验收。

### 19.15 右走 4 帧稳定版再次手动重试失败（2026-05-02）

用户要求“现在继续试试”。执行顺序：

```powershell
python scripts/ping_dmx.py
python scripts/gen_assets.py --task sprite_lengguyun_walk_right_4f_stable_strip --fallback-model gpt-image-2 --skip-ping
```

结果：

- `ping_dmx.py` 仍为 `APIConnectionError: Connection error.`。
- 付费生成任务 3 次 attempt 全部为 `APIConnectionError`。
- 结果汇总：成功 0，失败 1，总花费 ¥0.0000，未扣费。

判断：

- `sprite_lengguyun_walk_right_4f_stable_strip` 模板和 dry-run 仍可用，问题继续发生在 DMXAPI 网络 / 渠道层。
- 该问题已持续跨多个小时窗口，后续更建议先修网络 / VPN / DMXAPI 渠道连通性，或临时切换可用图像后端，再继续烧生成尝试。

### 19.16 右走 4 帧稳定版第三轮手动重试失败（2026-05-03）

用户继续要求重试。执行：

```powershell
python scripts/ping_dmx.py
python scripts/gen_assets.py --task sprite_lengguyun_walk_right_4f_stable_strip --fallback-model gpt-image-2 --skip-ping
```

结果：

- `ping_dmx.py` 仍为 `APIConnectionError`。
- 生成任务 3 次 attempt 全部为 `APIConnectionError`。
- 总花费 ¥0.0000，未扣费。

判断：DMXAPI 连接问题仍未恢复；继续短间隔重试意义很低，应先解决网络 / VPN / DMXAPI 渠道，或切换后端。

### 19.17 右走 4 帧稳定版第四轮手动重试失败（2026-05-03）

用户继续要求尝试。执行：

```powershell
python scripts/ping_dmx.py
python scripts/gen_assets.py --task sprite_lengguyun_walk_right_4f_stable_strip --fallback-model gpt-image-2 --skip-ping
```

结果：

- `ping_dmx.py` 仍为 `APIConnectionError`。
- 生成任务 3 次 attempt 全部为 `APIConnectionError`。
- 总花费 ¥0.0000，未扣费。

判断：问题继续稳定复现为 DMXAPI 网络 / 渠道不可达，模板无需再改；后续应优先换网络 / VPN / 后端。

### 19.18 DMXAPI `.com` 域名可达但 token 不通（2026-05-03）

用户建议改用 `https://www.dmxapi.com/`。未修改 `.env`，只在当前命令临时覆盖：

```powershell
$env:OPENAI_BASE_URL='https://www.dmxapi.com/v1'
python scripts/ping_dmx.py
```

结果：

- `.com` 域名不再出现 `APIConnectionError`，说明网络可达。
- 返回 `AuthenticationError: 401 Invalid token`。
- 判断：当前 `.env` 中的 `OPENAI_API_KEY` 可能是 `.cn` 站点令牌，不能直接用于 `.com` 的 New API 后端；需要在 `dmxapi.com` 对应控制台确认 / 新建 token 后再重试。

经验：

- **换域名要同时验证 token 归属**：同一品牌不同域名可能不是同一个 token 系统；连接可达不代表认证可用。
- **测试新域名先用临时环境变量，不要直接改 `.env`**：确认连通性和认证都通过后，再把 `OPENAI_BASE_URL` 持久化到 `.env`。

### 19.19 `.com` 新 token 生成右走 4 帧稳定版成功（2026-05-03）

用户提供 `dmxapi.com` 对应新 token 后，将本地 `.env` 更新为：

- `OPENAI_BASE_URL=https://www.dmxapi.com/v1`
- `OPENAI_API_KEY=<dmxapi.com 新 token>`（不在日志记录明文）

过程：

1. `python scripts/check_dmxapi.py --no-image --timeout 30 --connect 10`
   - 成功读取 `.com` base_url 和新 key，说明本地配置已生效。
2. 第一次正式生成返回 `BadRequestError: Invalid size '1024x512'. Requested resolution is below the current minimum pixel budget.`
   - 说明 `.com` 和新 key 已成功打到图像接口，问题转为模板尺寸。
3. 将 `sprite_protagonist_walk_right_4f_stable_strip.yaml` 从 `1024x512` 改为 `1024x1024`。
4. dry-run 通过后重新生成：
   `python scripts/gen_assets.py --task sprite_lengguyun_walk_right_4f_stable_strip --fallback-model gpt-image-2 --skip-ping`

结果：

- 右走 4 帧稳定版生成成功，成本 ¥0.3241。
- `assets/raw/sprite/v3/sprite_lengguyun_walk_right_4f_stable_strip.png`
- `assets/processed/sprite/sprite_lengguyun_walk_right_4f_stable_play.png`
- `assets/previews/sprite/sprite_lengguyun_walk_right_4f_stable_play.gif`
- QA：4/4 检出，基线极差 1px，高度极差 1px，PASS。

左走：

- 从右走 fixed sheet 镜像生成：
  `assets/processed/sprite/sprite_lengguyun_walk_left_4f_stable_mirror.png`
- 预览：
  `assets/previews/sprite/sprite_lengguyun_walk_left_4f_stable_mirror_play.gif`
- QA：4/4 检出，基线极差 0px，高度极差 0px，PASS。

经验：

- **`.com` 域名解决了 `.cn` 的连接问题，但 token 必须换成 `.com` 对应 token**。
- **gpt-image-2 不能用 1024×512 这种低像素画幅**：4 帧 strip 也应使用 `1024x1024`，让角色占中下部，上方留白。
- **遇到 400 invalid size 是模板问题，不是渠道问题**：修模板后 dry-run，再正式跑。
- **生成成功后立刻做 QA / GIF / 镜像**：这次右走成功后马上产出左走镜像，避免漏掉配套产物。

### 19.20 从 4 帧稳定版扩展右走 8 帧试验（2026-05-03）

用户反馈 4 帧比之前好，希望扩展到 8 帧试试看。策略：

- 不再使用旧 8 帧自由生成模板。
- 新增 `prompts/templates/sprite_protagonist_walk_right_8f_stable_from_4f.yaml`。
- 参考图直接使用已通过的 `assets/processed/sprite/sprite_lengguyun_walk_right_4f_stable_play.png`。
- 提示词明确：参考图第 1/2/3/4 帧对应新图第 1/3/5/7 帧，第 2/4/6/8 帧只做中间插补。
- 画幅使用 `1536x1024`，8 列单行，每格约 192px 宽。

执行：

```powershell
python scripts/gen_assets.py --task sprite_lengguyun_walk_right_8f_stable_from_4f --dry-run --force
python scripts/gen_assets.py --task sprite_lengguyun_walk_right_8f_stable_from_4f --fallback-model gpt-image-2 --skip-ping
python scripts/qa/check_sprite_strip.py --source assets/raw/sprite/v3/sprite_lengguyun_walk_right_8f_stable_from_4f.png --expected 8 --baseline-tolerance 12 --height-tolerance 24 --report logs/qa/sprite_walk_right_8f_stable_from_4f.json
python scripts/build_sprite_preview.py --source assets/raw/sprite/v3/sprite_lengguyun_walk_right_8f_stable_from_4f.png --cols 8 --segment-columns --sprite-height 96 --canvas-width 160 --canvas-height 160 --duration-ms 90 --output-gif assets/previews/sprite/sprite_lengguyun_walk_right_8f_stable_from_4f.gif --output-sheet assets/processed/sprite/sprite_lengguyun_walk_right_8f_stable_from_4f.png
```

结果：

- 右走 8 帧生成成功，成本 ¥0.2483。
- QA：8/8 检出，基线极差 4px，高度极差 4px，PASS。
- 产物：
  - `assets/raw/sprite/v3/sprite_lengguyun_walk_right_8f_stable_from_4f.png`
  - `assets/previews/sprite/sprite_lengguyun_walk_right_8f_stable_from_4f.gif`
  - `assets/processed/sprite/sprite_lengguyun_walk_right_8f_stable_from_4f.png`
  - `logs/qa/sprite_walk_right_8f_stable_from_4f.json`

左走镜像：

- `assets/processed/sprite/sprite_lengguyun_walk_left_8f_stable_from_4f_mirror.png`
- `assets/previews/sprite/sprite_lengguyun_walk_left_8f_stable_from_4f_mirror.gif`
- `assets/processed/sprite/sprite_lengguyun_walk_left_8f_stable_from_4f_mirror_play.png`
- `logs/qa/sprite_walk_left_8f_stable_from_4f_mirror.json`
- QA：8/8 检出，基线极差 1px，高度极差 1px，PASS。

经验：

- **8 帧扩展必须以 4 帧稳定版为参考图**：否则模型容易再次自由重画，回到抖动问题。
- **偶数帧插补能改善对齐，但仍需人工看节奏**：本轮 QA 数据好，但 sheet 中仍有中立帧偏近的可能；最终是否优于 4 帧要以 GIF 观感为准。
- **左走仍然镜像，不单独生成**：镜像继承右走节奏，避免再次引入左右不一致。

### 19.21 右走 8 帧 polish 细节优化（2026-05-03）

用户认为 `stable_from_4f` 已经非常接近，希望再优化一点细节。观察 sheet 后判断：主要可优化点是第 2/3 帧、第 6/7 帧略接近，容易产生轻微停顿；其它体块稳定性已经较好。

策略：

- 新增 `prompts/templates/sprite_protagonist_walk_right_8f_polish_from_8f.yaml`。
- 参考图使用 `assets/processed/sprite/sprite_lengguyun_walk_right_8f_stable_from_4f.png`。
- prompt 明确要求：
  - 保持角色、构图、脚底基线、剑、酒葫芦不变；
  - 只优化腿部过渡；
  - 第 2/4/6/8 帧不能复制第 1/3/5/7 帧；
  - 衣摆和头发只轻微随动，不大幅换形。

执行：

```powershell
python scripts/gen_assets.py --task sprite_lengguyun_walk_right_8f_polish_from_8f --dry-run --force
python scripts/gen_assets.py --task sprite_lengguyun_walk_right_8f_polish_from_8f --fallback-model gpt-image-2 --skip-ping
python scripts/qa/check_sprite_strip.py --source assets/raw/sprite/v3/sprite_lengguyun_walk_right_8f_polish_from_8f.png --expected 8 --baseline-tolerance 12 --height-tolerance 24 --report logs/qa/sprite_walk_right_8f_polish_from_8f.json
python scripts/build_sprite_preview.py --source assets/raw/sprite/v3/sprite_lengguyun_walk_right_8f_polish_from_8f.png --cols 8 --segment-columns --sprite-height 96 --canvas-width 160 --canvas-height 160 --duration-ms 90 --output-gif assets/previews/sprite/sprite_lengguyun_walk_right_8f_polish_from_8f.gif --output-sheet assets/processed/sprite/sprite_lengguyun_walk_right_8f_polish_from_8f.png
```

结果：

- 右走 8 帧 polish 生成成功，成本 ¥0.2506。
- QA：8/8 检出，基线极差 3px，高度极差 3px，PASS。
- 产物：
  - `assets/raw/sprite/v3/sprite_lengguyun_walk_right_8f_polish_from_8f.png`
  - `assets/previews/sprite/sprite_lengguyun_walk_right_8f_polish_from_8f.gif`
  - `assets/processed/sprite/sprite_lengguyun_walk_right_8f_polish_from_8f.png`
  - `logs/qa/sprite_walk_right_8f_polish_from_8f.json`

左走镜像：

- `assets/processed/sprite/sprite_lengguyun_walk_left_8f_polish_from_8f_mirror.png`
- `assets/previews/sprite/sprite_lengguyun_walk_left_8f_polish_from_8f_mirror.gif`
- `assets/processed/sprite/sprite_lengguyun_walk_left_8f_polish_from_8f_mirror_play.png`
- `logs/qa/sprite_walk_left_8f_polish_from_8f_mirror.json`
- QA：8/8 检出，基线极差 0px，高度极差 0px，PASS。

经验：

- **polish prompt 要指出具体帧问题**：笼统写“更流畅”不如明确“第 2/3 和第 6/7 太接近，偶数帧必须更像过渡帧”。
- **轻微优化时只跑 1 张右走**：右走通过后镜像左走即可，不需要为左走单独付费。
- **不要只看 QA**：polish 版 QA 比 stable 版略好，但是否最终采用仍要由 GIF 动作观感决定。

### 19.21.1 复核：8 帧 polish 不如 stable_from_4f（2026-05-03）

用户指出 `sprite_lengguyun_walk_left_8f_stable_from_4f_mirror.gif` 效果更好，后面的 polish 反而没这么好。复核后确认用户判断正确。

对比：

- `stable_from_4f` 左走：
  - QA：8/8，基线极差 1px，高度极差 1px。
  - bbox 宽度变化更有节奏：85 / 70 / 67 / 82 / 75 / 64 / 65 / 77。
  - 第 1/4/5/8 帧步幅轮廓更明确，行走节奏更自然。
- `polish_from_8f` 左走：
  - QA：8/8，基线极差 0px，高度极差 0px。
  - bbox 宽度更平滑但也更相似：79 / 70 / 70 / 79 / 74 / 66 / 65 / 77。
  - 第 2/3 帧几乎同宽，第 6/7 也接近，动态轮廓被“抹平”，观感不如 stable。

结论：

- 当前推荐基准改为 `stable_from_4f`：
  - `assets/previews/sprite/sprite_lengguyun_walk_left_8f_stable_from_4f_mirror.gif`
  - `assets/previews/sprite/sprite_lengguyun_walk_right_8f_stable_from_4f.gif`
- `polish_from_8f` 只保留为实验对照，不作为当前推荐版本。

经验：

- **动作资源不能只按 QA 数字选版本**：polish 的基线 / 高度更稳，但动态步幅轮廓变弱，实际观感下降。
- **bbox 宽度节奏可辅助判断步态**：宽度变化过于平滑或重复，可能意味着步幅被抹平；适度的 contact / passing 宽度差更像行走。
- **用户目视反馈优先级高于脚本评分**：脚本只做底线检查，最终动画采用必须以 GIF 观感为准。

### 19.22 Agent Hub 产出页分页（2026-05-03）

用户反馈产出列表一页太多。处理：

- `/artifacts` 增加 `page` 和 `per_page` 查询参数。
- 默认 `per_page=20`。
- 可选 `20 / 50 / 100 / all`。
- 筛选条件 `owner_agent`、`kind` 与分页参数互相保留。
- 页面顶部显示总数和当前显示范围，顶部 / 底部提供分页导航。

验证：

```powershell
python -m compileall tools\agent_hub
python -c "from fastapi.testclient import TestClient; from tools.agent_hub.app import app; c=TestClient(app); checks={'default':'/artifacts','50':'/artifacts?owner_agent=art&kind=image&per_page=50','100':'/artifacts?per_page=100&page=2','all':'/artifacts?per_page=all'}; print({k:c.get(v).status_code for k,v in checks.items()})"
python -c "from fastapi.testclient import TestClient; from tools.agent_hub.app import app; c=TestClient(app); html=c.get('/artifacts').text; body=html.split('<tbody>',1)[1].split('</tbody>',1)[0]; print('default_rows', body.count('<tr>')); html50=c.get('/artifacts?per_page=50').text; body50=html50.split('<tbody>',1)[1].split('</tbody>',1)[0]; print('rows_50', body50.count('<tr>')); htmlall=c.get('/artifacts?per_page=all').text; bodyall=htmlall.split('<tbody>',1)[1].split('</tbody>',1)[0]; print('rows_all', bodyall.count('<tr>'))"
python -c "import urllib.request; paths=['/artifacts','/artifacts?per_page=50','/artifacts?per_page=100&page=2','/artifacts?per_page=all']; print({p: urllib.request.urlopen('http://127.0.0.1:8765'+p, timeout=10).status for p in paths})"
```

结果：

- TestClient：默认 / 50 / 100 / all 均 200。
- 默认行数 20，`per_page=50` 行数 50，`per_page=all` 显示全部。
- 真实本地服务重启后四个 URL 均 200。

经验：

- **分页参数要在后端校验**：`per_page` 只允许固定值，避免任意大 LIMIT 或非法输入。
- **筛选和分页必须共存**：分页链接要带上当前 `owner_agent`、`kind`、`per_page`，否则翻页会丢筛选条件。
- **FastAPI reload 可能出现“模板新、Python 旧”的半刷新**：这次 TestClient 正常但真实服务 500，栈显示模板访问 `total_pages` 未定义；重启 uvicorn 后恢复。以后改模板 + 路由上下文时，TestClient 通过后仍要测真实服务，失败就重启。

### 19.23 上 / 下走 8 帧 stable_from_4f 生成（2026-05-03）

目标：沿用右走已验证的 `stable_from_4f` 策略，把现有 4 帧上 / 下方向候选扩展成 8 帧播放版。

新增：

- `prompts/templates/sprite_protagonist_walk_down_8f_stable_from_4f.yaml`
- `prompts/templates/sprite_protagonist_walk_up_8f_stable_from_4f.yaml`
- `prompts/tasks.yaml` 任务：
  - `sprite_lengguyun_walk_down_8f_stable_from_4f`
  - `sprite_lengguyun_walk_up_8f_stable_from_4f`

流程：

```powershell
python scripts/gen_assets.py --dry-run --task sprite_lengguyun_walk_down_8f_stable_from_4f --task sprite_lengguyun_walk_up_8f_stable_from_4f
python scripts/gen_assets.py --task sprite_lengguyun_walk_down_8f_stable_from_4f
python scripts/ping_dmx.py
python scripts/gen_assets.py --skip-ping --task sprite_lengguyun_walk_down_8f_stable_from_4f
python scripts/qa/check_sprite_strip.py --source assets/raw/sprite/v3/sprite_lengguyun_walk_down_8f_stable_from_4f.png --expected 8 --baseline-tolerance 12 --height-tolerance 24 --report logs/qa/sprite_walk_down_8f_stable_from_4f.json
python scripts/build_sprite_preview.py --source assets/raw/sprite/v3/sprite_lengguyun_walk_down_8f_stable_from_4f.png --cols 8 --segment-columns --sprite-height 96 --canvas-width 160 --canvas-height 160 --duration-ms 90 --output-gif assets/previews/sprite/sprite_lengguyun_walk_down_8f_stable_from_4f.gif --output-sheet assets/processed/sprite/sprite_lengguyun_walk_down_8f_stable_from_4f.png
python scripts/gen_assets.py --skip-ping --task sprite_lengguyun_walk_up_8f_stable_from_4f
python scripts/qa/check_sprite_strip.py --source assets/raw/sprite/v3/sprite_lengguyun_walk_up_8f_stable_from_4f.png --expected 8 --baseline-tolerance 12 --height-tolerance 24 --report logs/qa/sprite_walk_up_8f_stable_from_4f.json
python scripts/build_sprite_preview.py --source assets/raw/sprite/v3/sprite_lengguyun_walk_up_8f_stable_from_4f.png --cols 8 --segment-columns --sprite-height 96 --canvas-width 160 --canvas-height 160 --duration-ms 90 --output-gif assets/previews/sprite/sprite_lengguyun_walk_up_8f_stable_from_4f.gif --output-sheet assets/processed/sprite/sprite_lengguyun_walk_up_8f_stable_from_4f.png
```

结果：

- 下走：`assets/previews/sprite/sprite_lengguyun_walk_down_8f_stable_from_4f.gif`
  - QA：8/8，基线极差 1px，高度极差 1px。
  - 成本：¥0.2496。
- 上走：`assets/previews/sprite/sprite_lengguyun_walk_up_8f_stable_from_4f.gif`
  - QA：8/8，基线极差 0px，高度极差 0px。
  - 成本：¥0.2494。

问题与处理：

- 第一次正式跑下走时，启动探活 `gpt-image-2` 超时（>60s），fallback `gpt-image-1.5` 返回 `insufficient_quota`。
- 独立 `scripts/ping_dmx.py` 也返回 `APITimeoutError: Request timed out.`，说明模板 / 任务配置不是根因。
- 由于 dry-run 已通过、参考图存在，且目标任务本身就是要生成这一张图，改为单任务 `--skip-ping` 做最小验证；正式生成成功，说明当时是探活请求不稳定，不是编辑生成完全不可用。

经验：

- **探活超时不等于正式编辑一定失败**：DMXAPI 有时最小生成探活超时，但带参考图的实际任务可成功；可以在 dry-run 通过后做一次单任务 `--skip-ping` 验证。
- **跳过探活必须小步执行**：只能一张一张跑，不能批量跳过探活，避免通道真实异常时浪费预算。
- **fallback 配额不足不要继续依赖 fallback**：当前 `gpt-image-1.5` 返回配额不足，后续 sprite 生成应继续以 `gpt-image-2` 为主，必要时显式 `--fallback-model gpt-image-2` 禁掉降级。

### 19.24 上 / 下走 8 帧视觉验收失败（2026-05-03）

用户复核后指出：上 / 下方向新做的 8 帧 `stable_from_4f` 不行，不如前面左右行走。

复核结论：用户判断正确。问题不是 QA 对齐，而是动作可读性。

对比：

- 右走 `stable_from_4f`：
  - bbox 宽度节奏约 166 / 131 / 123 / 162 / 141 / 115 / 117 / 152。
  - contact / passing 差异明显，腿部跨步读得出来。
- 左走镜像：
  - bbox 宽度节奏约 61 / 46 / 43 / 58 / 51 / 40 / 41 / 53。
  - 与右走一致，横向步幅轮廓明确。
- 下走 `stable_from_4f`：
  - bbox 宽度节奏约 148 / 147 / 145 / 143 / 142 / 142 / 144 / 144。
  - 8 帧轮廓过于接近，像原地轻微踏步。
- 上走 `stable_from_4f`：
  - bbox 宽度节奏约 107 / 117 / 113 / 117 / 116 / 117 / 120 / 120。
  - 背面方向保持正确，但步幅变化弱，整体不如左右方向。

根因：

- 上 / 下使用的 4 帧候选本身腿部 key pose 不够强，脚向画面前后方向的位移在正面 / 背面视角里很难读。
- `stable_from_4f` 策略会继承参考图优点，也会放大参考图缺点：参考姿态弱时，插补只会更平滑、更接近，不会自动产生更强步幅。
- QA 的 baseline / height spread 只能证明“不跳”，不能证明“走得好”。这次下 1px/1px、上 0px/0px 反而说明模型过度稳定。

处理：

- 文档已改为：右 / 左 `stable_from_4f` 是当前推荐；上 / 下 `stable_from_4f` 仅保留为失败对照，不作为推荐基准。
- 下一步不要直接继续扩 8 帧；应先重做上 / 下 4 帧关键姿态，要求更明确的脚部前后错位、衣摆摆动和左右肩/手臂节奏，再由用户看 4 帧 GIF 后决定是否扩展到 8 帧。

经验：

- **正面 / 背面 walk 不能照搬侧向策略**：侧向靠横向腿部轮廓读步幅；正面 / 背面必须靠脚掌前后位置、左右肩摆、衣摆和武器摆动共同读动作。
- **过稳也是失败**：baseline / height 越稳不一定越好，若 bbox 节奏几乎不变，动画会像抖动或站桩。
- **上 / 下方向先验收 4 帧 key pose**：4 帧不明显时不要扩 8 帧，否则只会把弱动作平滑成更弱的 8 帧。

### 19.25 上 / 下 4 帧强关键姿态候选（2026-05-03）

基于 §19.24 的结论，按用户选择的推荐路线，先重做上 / 下 4 帧 key pose，不再直接扩 8 帧。

新增：

- `prompts/templates/sprite_protagonist_walk_down_4f_strong_keypose.yaml`
- `prompts/templates/sprite_protagonist_walk_up_4f_strong_keypose.yaml`
- `prompts/tasks.yaml` 任务：
  - `sprite_lengguyun_walk_down_4f_strong_keypose`
  - `sprite_lengguyun_walk_up_4f_strong_keypose`

关键改动：

- 不再只引用弱 4 帧参考。
- 同时引用：
  - 已目视通过的 `sprite_lengguyun_walk_right_8f_stable_from_4f.png` 学习 contact / passing 轮廓节奏。
  - 旧上 / 下 `*_8f_play.png` 学习正面 / 背面方向感。
- Prompt 明确要求强 key pose：contact 帧宽、passing 帧窄，脚掌前后深度、手臂反摆、衣摆摆动必须读得出来。

执行：

```powershell
python scripts/gen_assets.py --dry-run --task sprite_lengguyun_walk_down_4f_strong_keypose --task sprite_lengguyun_walk_up_4f_strong_keypose
python scripts/gen_assets.py --skip-ping --task sprite_lengguyun_walk_down_4f_strong_keypose
python scripts/qa/check_sprite_strip.py --source assets/raw/sprite/v3/sprite_lengguyun_walk_down_4f_strong_keypose.png --expected 4 --baseline-tolerance 12 --height-tolerance 24 --report logs/qa/sprite_walk_down_4f_strong_keypose.json
python scripts/build_sprite_preview.py --source assets/raw/sprite/v3/sprite_lengguyun_walk_down_4f_strong_keypose.png --cols 4 --segment-columns --sprite-height 96 --canvas-width 160 --canvas-height 160 --duration-ms 120 --output-gif assets/previews/sprite/sprite_lengguyun_walk_down_4f_strong_keypose.gif --output-sheet assets/processed/sprite/sprite_lengguyun_walk_down_4f_strong_keypose.png
python scripts/gen_assets.py --skip-ping --task sprite_lengguyun_walk_up_4f_strong_keypose
python scripts/qa/check_sprite_strip.py --source assets/raw/sprite/v3/sprite_lengguyun_walk_up_4f_strong_keypose.png --expected 4 --baseline-tolerance 12 --height-tolerance 24 --report logs/qa/sprite_walk_up_4f_strong_keypose.json
python scripts/build_sprite_preview.py --source assets/raw/sprite/v3/sprite_lengguyun_walk_up_4f_strong_keypose.png --cols 4 --segment-columns --sprite-height 96 --canvas-width 160 --canvas-height 160 --duration-ms 120 --output-gif assets/previews/sprite/sprite_lengguyun_walk_up_4f_strong_keypose.gif --output-sheet assets/processed/sprite/sprite_lengguyun_walk_up_4f_strong_keypose.png
```

结果：

- 下走 4 帧强 keypose：
  - `assets/previews/sprite/sprite_lengguyun_walk_down_4f_strong_keypose.gif`
  - QA：4/4，基线极差 11px，高度极差 11px。
  - bbox 宽度节奏约 180 / 128 / 187 / 133，比失败 8 帧的 148 / 147 / 145 / 143 / 142 / 142 / 144 / 144 明显更有 contact / passing 差异。
  - 成本：¥0.3118。
- 上走 4 帧强 keypose：
  - `assets/previews/sprite/sprite_lengguyun_walk_up_4f_strong_keypose.gif`
  - QA：4/4，基线极差 5px，高度极差 5px。
  - bbox 宽度节奏约 162 / 135 / 162 / 141，比失败 8 帧更有轮廓变化。
  - 成本：¥0.3121。

状态：两者只作为候选，需用户目视确认后再决定是否扩展到 8 帧。

经验：

- **用“成功方向 + 旧方向感”双参考，比单独引用弱方向 4 帧更好**：右走基准提供节奏，旧上 / 下提供朝向，prompt 再约束不要复制旧缺点。
- **4 帧候选也要看 baseline spread 的语义**：下走 11px 接近阈值，但这是强 key pose 带来的动作幅度，不一定是坏事；最终仍以 GIF 观感为准。
- **下一步扩 8 帧前必须人工确认 4 帧**：如果 4 帧仍不满意，应继续改 4 帧 prompt，而不是进入 8 帧插补。

### 19.26 上 / 下 4 帧强关键姿态仍视觉失败：左右晃动 + 速度偏快（2026-05-03）

用户复核 `sprite_lengguyun_walk_down_4f_strong_keypose.gif` / `sprite_lengguyun_walk_up_4f_strong_keypose.gif` 后指出：不行，左右晃动，而且速度过快了一点。

复核：

- 当前 GIF 是 120ms/帧，4 帧一轮约 480ms，对 walk cycle 偏快。
- 已零成本重建慢速版，180ms/帧：
  - `assets/previews/sprite/sprite_lengguyun_walk_down_4f_strong_keypose_slow.gif`
  - `assets/previews/sprite/sprite_lengguyun_walk_up_4f_strong_keypose_slow.gif`
- processed sheet 的 bbox 中心基本固定：
  - 下走 center_x：80.0 / 79.5 / 79.5 / 79.5。
  - 上走 center_x：80.0 / 79.5 / 80.0 / 80.0。
- 因此“左右晃动”不是简单的后处理整帧错位，而是素材内部躯干 / 袍摆 / 肩线摆动过强，尤其 contact 帧为了强化轮廓，把身体和大袍摆做成左右摇摆。

结论：

- `strong_keypose` 解决了 §19.24 的“步幅太弱”，但引入新问题：动作通过左右摇摆读出来，而不是通过稳定躯干 + 脚步深度读出来。
- 该组只保留为失败对照，不作为推荐基准，也不要扩 8 帧。

下一版要求：

- GIF 默认速度改为 160-180ms/帧，4 帧 cycle 约 640-720ms。
- Prompt 必须锁住中轴：
  - 头、胸口 / 背脊、腰带中心、酒葫芦挂点的水平位置几乎不动。
  - 左右肩摆动小于 2px，只允许手臂和脚变化。
  - 袍摆只能小幅摆，不要用大面积侧向披风制造步幅。
  - contact / passing 差异主要来自脚掌前后深度、膝盖弯曲和脚尖露出，不来自身体左右晃。
- 生成后先做 4 帧慢速 GIF，并对比普通 / 慢速两个版本；用户确认前不扩 8 帧。

经验：

- **强 keypose 不能等于左右摆**：正面 / 背面 walk 的核心是脚步深度和稳定中轴，不是身体左右摇。
- **预览速度会放大缺陷**：4 帧 120ms/帧太快，晃动会更明显；上 / 下 4 帧候选应默认 160-180ms/帧审片。
- **中心漂移要区分外部 bbox 与内部躯干**：bbox 居中不代表观感不晃，袍摆或肩线变化仍会造成躯干视觉摆动。

### 19.27 上 / 下 4 帧 balanced 候选（2026-05-03）

基于 §19.26，继续参考左右方向经验优化：

- 不是继续加强大 keypose，而是在两个失败极端之间取平衡：
  - `strong_keypose`：步幅明显，但靠身体 / 袍摆左右摇。
  - `locked_axis`：中心稳定，但四帧太接近，像站桩。
- 新模板要求：
  - 头 / 胸 / 腰带中轴稳定。
  - contact 比 passing 下半身轮廓宽约 8-18px。
  - 脚底最低点不跳，默认 180ms/帧慢速审片。

新增：

- `prompts/templates/sprite_protagonist_walk_down_4f_balanced.yaml`
- `prompts/templates/sprite_protagonist_walk_up_4f_balanced.yaml`
- `prompts/tasks.yaml` 任务：
  - `sprite_lengguyun_walk_down_4f_balanced`
  - `sprite_lengguyun_walk_up_4f_balanced`

执行：

```powershell
python scripts/gen_assets.py --dry-run --task sprite_lengguyun_walk_down_4f_balanced
python scripts/gen_assets.py --skip-ping --task sprite_lengguyun_walk_down_4f_balanced
python scripts/qa/check_sprite_strip.py --source assets/raw/sprite/v3/sprite_lengguyun_walk_down_4f_balanced.png --expected 4 --baseline-tolerance 12 --height-tolerance 24 --report logs/qa/sprite_walk_down_4f_balanced.json
python scripts/build_sprite_preview.py --source assets/raw/sprite/v3/sprite_lengguyun_walk_down_4f_balanced.png --cols 4 --segment-columns --sprite-height 96 --canvas-width 160 --canvas-height 160 --duration-ms 180 --output-gif assets/previews/sprite/sprite_lengguyun_walk_down_4f_balanced_slow.gif --output-sheet assets/processed/sprite/sprite_lengguyun_walk_down_4f_balanced_slow.png
python scripts/gen_assets.py --dry-run --task sprite_lengguyun_walk_up_4f_balanced
python scripts/gen_assets.py --skip-ping --task sprite_lengguyun_walk_up_4f_balanced
python scripts/qa/check_sprite_strip.py --source assets/raw/sprite/v3/sprite_lengguyun_walk_up_4f_balanced.png --expected 4 --baseline-tolerance 12 --height-tolerance 24 --report logs/qa/sprite_walk_up_4f_balanced.json
python scripts/build_sprite_preview.py --source assets/raw/sprite/v3/sprite_lengguyun_walk_up_4f_balanced.png --cols 4 --segment-columns --sprite-height 96 --canvas-width 160 --canvas-height 160 --duration-ms 180 --output-gif assets/previews/sprite/sprite_lengguyun_walk_up_4f_balanced_slow.gif --output-sheet assets/processed/sprite/sprite_lengguyun_walk_up_4f_balanced_slow.png
```

结果：

- 下走 balanced：
  - `assets/previews/sprite/sprite_lengguyun_walk_down_4f_balanced_slow.gif`
  - raw QA：4/4，baseline spread 17px（FAIL），height spread 17px（PASS）。
  - processed 慢速预览：center_x 79.5 / 79.5 / 79.5 / 80.0，center_y 全 104.0，width 47 / 39 / 49 / 40。
  - 成本：¥0.3103。
- 上走 balanced：
  - `assets/previews/sprite/sprite_lengguyun_walk_up_4f_balanced_slow.gif`
  - raw QA：4/4，baseline spread 10px（PASS），height spread 10px（PASS）。
  - processed 慢速预览：center_x 79.5 / 80.0 / 79.5 / 79.5，center_y 全 104.0，width 47 / 38 / 43 / 37。
  - 成本：¥0.3104。

状态：

- 两张只作为候选，待用户目视确认。
- 不扩 8 帧，直到用户确认 4 帧慢速 GIF 的节奏和左右稳定性。

经验：

- **processed 预览是最终观感口径，raw QA 是风险提示**：下走 raw baseline fail，但 processed 慢速预览中心和高度稳定；仍需人工看 GIF 判断是否可接受。
- **上 / 下方向的有效节奏目标**：中心固定 + 高度固定 + contact/passing 宽度差约 8-12px，比“强 keypose”的大幅差异更稳。
- **每轮只推进通过的方向策略正确**：`locked_axis` 下走暴露“太弱”后没有继续生成上走，节省了一张图成本。

### 19.28 上 / 下 8 帧 balanced_from_4f 扩展（2026-05-04）

用户确认 §19.27 的上 / 下 4 帧 balanced 候选「这次可以」，要求扩充到 8 帧。

新增：

- `prompts/templates/sprite_protagonist_walk_down_8f_balanced_from_4f.yaml`
- `prompts/templates/sprite_protagonist_walk_up_8f_balanced_from_4f.yaml`
- `prompts/tasks.yaml` 任务：
  - `sprite_lengguyun_walk_down_8f_balanced_from_4f`
  - `sprite_lengguyun_walk_up_8f_balanced_from_4f`

策略：

- 直接引用用户确认的 processed 4 帧 slow sheet：
  - `assets/processed/sprite/sprite_lengguyun_walk_down_4f_balanced_slow.png`
  - `assets/processed/sprite/sprite_lengguyun_walk_up_4f_balanced_slow.png`
- 明确把参考图第 1 / 2 / 3 / 4 格映射为 8 帧中的第 1 / 3 / 5 / 7 格。
- 第 2 / 4 / 6 / 8 格只补小过渡，避免重新生成新动作或重回左右摇。
- 同时输出 120ms 与 140ms 预览；基于用户之前反馈「速度过快」，建议优先看 140ms。

执行：

```powershell
python scripts/gen_assets.py --dry-run --task sprite_lengguyun_walk_down_8f_balanced_from_4f --task sprite_lengguyun_walk_up_8f_balanced_from_4f
python scripts/gen_assets.py --skip-ping --task sprite_lengguyun_walk_down_8f_balanced_from_4f
python scripts/qa/check_sprite_strip.py --source assets/raw/sprite/v3/sprite_lengguyun_walk_down_8f_balanced_from_4f.png --expected 8 --baseline-tolerance 12 --height-tolerance 24 --report logs/qa/sprite_walk_down_8f_balanced_from_4f.json
python scripts/build_sprite_preview.py --source assets/raw/sprite/v3/sprite_lengguyun_walk_down_8f_balanced_from_4f.png --cols 8 --segment-columns --sprite-height 96 --canvas-width 160 --canvas-height 160 --duration-ms 120 --output-gif assets/previews/sprite/sprite_lengguyun_walk_down_8f_balanced_from_4f_120ms.gif --output-sheet assets/processed/sprite/sprite_lengguyun_walk_down_8f_balanced_from_4f.png
python scripts/build_sprite_preview.py --source assets/raw/sprite/v3/sprite_lengguyun_walk_down_8f_balanced_from_4f.png --cols 8 --segment-columns --sprite-height 96 --canvas-width 160 --canvas-height 160 --duration-ms 140 --output-gif assets/previews/sprite/sprite_lengguyun_walk_down_8f_balanced_from_4f_140ms.gif --output-sheet assets/processed/sprite/sprite_lengguyun_walk_down_8f_balanced_from_4f_140ms.png
python scripts/gen_assets.py --skip-ping --task sprite_lengguyun_walk_up_8f_balanced_from_4f
python scripts/qa/check_sprite_strip.py --source assets/raw/sprite/v3/sprite_lengguyun_walk_up_8f_balanced_from_4f.png --expected 8 --baseline-tolerance 12 --height-tolerance 24 --report logs/qa/sprite_walk_up_8f_balanced_from_4f.json
python scripts/build_sprite_preview.py --source assets/raw/sprite/v3/sprite_lengguyun_walk_up_8f_balanced_from_4f.png --cols 8 --segment-columns --sprite-height 96 --canvas-width 160 --canvas-height 160 --duration-ms 120 --output-gif assets/previews/sprite/sprite_lengguyun_walk_up_8f_balanced_from_4f_120ms.gif --output-sheet assets/processed/sprite/sprite_lengguyun_walk_up_8f_balanced_from_4f.png
python scripts/build_sprite_preview.py --source assets/raw/sprite/v3/sprite_lengguyun_walk_up_8f_balanced_from_4f.png --cols 8 --segment-columns --sprite-height 96 --canvas-width 160 --canvas-height 160 --duration-ms 140 --output-gif assets/previews/sprite/sprite_lengguyun_walk_up_8f_balanced_from_4f_140ms.gif --output-sheet assets/processed/sprite/sprite_lengguyun_walk_up_8f_balanced_from_4f_140ms.png
```

结果：

- 下走 8 帧：
  - GIF：`assets/previews/sprite/sprite_lengguyun_walk_down_8f_balanced_from_4f_120ms.gif`
  - GIF：`assets/previews/sprite/sprite_lengguyun_walk_down_8f_balanced_from_4f_140ms.gif`
  - fixed sheet：`assets/processed/sprite/sprite_lengguyun_walk_down_8f_balanced_from_4f.png`
  - QA：8/8，baseline spread 1px，height spread 1px。
  - 成本：¥0.2476。
- 上走 8 帧：
  - GIF：`assets/previews/sprite/sprite_lengguyun_walk_up_8f_balanced_from_4f_120ms.gif`
  - GIF：`assets/previews/sprite/sprite_lengguyun_walk_up_8f_balanced_from_4f_140ms.gif`
  - fixed sheet：`assets/processed/sprite/sprite_lengguyun_walk_up_8f_balanced_from_4f.png`
  - QA：8/8，baseline spread 6px，height spread 6px。
  - 成本：¥0.2478。

经验：

- **用户确认的 4 帧 processed sheet 是更好的 8 帧参考**：比引用 raw 或旧方向图更能保留最终观感。
- **8 帧扩展会自然变平滑，步幅可能略弱**：因此 prompt 要明确保留第 1/3/5/7 的关键姿态差异，避免模型把动作全部抹平。
- **速度输出应保留多版本**：120ms 适合较快移动，140ms 更接近当前用户偏好的审片速度。

### 19.29 上 / 下 8 帧 balanced_from_4f 脚步相位仍不协调（2026-05-04）

用户仔细复核 §19.28 的 8 帧上 / 下走后指出：两只脚走路还是有点不协调。

复核：

- 整体锚点 / baseline 数字没有问题：
  - 下走 8 帧：QA 8/8，baseline spread 1px，height spread 1px。
  - 上走 8 帧：QA 8/8，baseline spread 6px，height spread 6px。
- 下半身 processed 量化：
  - 下走 8 帧 width：47 / 41 / 39 / 44 / 49 / 44 / 41 / 44。
  - 上走 8 帧 width：46 / 39 / 39 / 43 / 44 / 44 / 37 / 38。
  - 对比 4 帧 balanced：下走 47 / 39 / 49 / 40；上走 47 / 38 / 43 / 37。

结论：

- 4 帧 balanced 的 contact / passing 关系是清楚的。
- 8 帧扩展时模型把部分中间帧插得过于相似，脚步相位没有真正形成“左脚 contact → passing → 右脚 contact → passing”的自然交替。
- 这不是整体锚点或播放速度问题，而是 AI 插补的脚部语义问题。

建议：

- 不要继续盲目扩 8 帧。若目标是尽快接入游戏，上 / 下方向优先用 4 帧 `balanced` 慢速版，视觉上比当前 8 帧更可靠。
- 若坚持做 8 帧，需要换策略：
  - 不是“由 4 帧整张图自由插补”，而是更强约束每一格脚步语义；
  - 或者分阶段生成 / 单独修中间帧，但成本和失败风险更高。

经验：

- **QA PASS 不代表脚步相位 PASS**：baseline / height 只能说明不跳，不能判断左右脚是否自然交替。
- **正面 / 背面 8 帧插补比侧向更难**：侧向腿部轮廓清楚，模型较容易读；正 / 背面脚步深度容易被抹平成同脚小动。
- **4 帧可比 8 帧更可靠**：如果 8 帧中间帧语义不稳定，宁可用清楚的 4 帧慢速循环。

### 19.30 下走 8 帧 strict_phase 尝试仍未解决脚步相位（2026-05-04）

用户选择继续尝试 8 帧，但加强逐帧脚步相位约束。

新增：

- `prompts/templates/sprite_protagonist_walk_down_8f_strict_phase.yaml`
- `prompts/templates/sprite_protagonist_walk_up_8f_strict_phase.yaml`
- `prompts/tasks.yaml` 任务：
  - `sprite_lengguyun_walk_down_8f_strict_phase`
  - `sprite_lengguyun_walk_up_8f_strict_phase`

执行：

```powershell
python scripts/gen_assets.py --dry-run --task sprite_lengguyun_walk_down_8f_strict_phase --task sprite_lengguyun_walk_up_8f_strict_phase
python scripts/gen_assets.py --skip-ping --task sprite_lengguyun_walk_down_8f_strict_phase
python scripts/qa/check_sprite_strip.py --source assets/raw/sprite/v3/sprite_lengguyun_walk_down_8f_strict_phase.png --expected 8 --baseline-tolerance 12 --height-tolerance 24 --report logs/qa/sprite_walk_down_8f_strict_phase.json
python scripts/build_sprite_preview.py --source assets/raw/sprite/v3/sprite_lengguyun_walk_down_8f_strict_phase.png --cols 8 --segment-columns --sprite-height 96 --canvas-width 160 --canvas-height 160 --duration-ms 140 --output-gif assets/previews/sprite/sprite_lengguyun_walk_down_8f_strict_phase_140ms.gif --output-sheet assets/processed/sprite/sprite_lengguyun_walk_down_8f_strict_phase.png
```

结果：

- `assets/previews/sprite/sprite_lengguyun_walk_down_8f_strict_phase_140ms.gif`
- `assets/processed/sprite/sprite_lengguyun_walk_down_8f_strict_phase.png`
- QA：8/8，baseline spread 6px，height spread 6px。
- 成本：¥0.2501。

复核：

- strict_phase 的下半身宽度节奏：44 / 43 / 38 / 38 / 45 / 40 / 43 / 42。
- balanced_from_4f 的下半身宽度节奏：47 / 41 / 39 / 44 / 49 / 44 / 41 / 44。
- 4 帧 balanced 的下半身宽度节奏：47 / 39 / 49 / 40。

结论：

- strict_phase 虽逐帧写清左右脚状态，但模型仍把中间帧画得相似，脚步相位没有明显改善。
- 因下走验证未明显优于 balanced_from_4f，取消上走 strict_phase，避免继续浪费。

经验：

- **自然语言逐帧约束不一定能控制正面 / 背面脚步语义**：模型会满足“稳定”和“同人”，但仍可能把脚步动作抹平。
- **继续整张 8 帧出图收益低**：若要真正修 8 帧脚相位，可能需要单独修中间帧或换更可控的动画管线；当前项目阶段优先使用 4 帧 balanced 更稳。

### 19.31 Seedance 视频试跑未进入生成：当前 DMXAPI 分组无视频通道（2026-05-04）

用户提出“生成视频再转 GIF”的方案，并确认先试一个下走方向。

新增：

- `scripts/gen_seedance_video.py`：独立 Seedance 试跑脚本，不接入 `gen_assets.py`；支持 `/v1/responses` 与 `/v1/videos` 两种异步视频 API 形态，使用 `.env` 的 `OPENAI_API_KEY` / `OPENAI_BASE_URL`，可轮询并下载 mp4。
- 脚本默认从 `assets/processed/sprite/sprite_lengguyun_walk_down_4f_balanced_slow.png` 裁出第 1 格作为首帧，避免把整张 4 帧 sheet 当作多个角色。

执行与结果：

```powershell
python scripts/gen_seedance_video.py --direction down --poll-seconds 10 --timeout-seconds 420
python scripts/gen_seedance_video.py --direction down --endpoint "https://www.dmxapi.cn/v1/responses" --model "doubao-seedance-1-5-pro-responses" --poll-model "seedance-get" --poll-seconds 10 --timeout-seconds 420
python scripts/gen_seedance_video.py --direction down --model "doubao-seedance-1-5-pro-responses" --poll-model "seedance-get" --poll-seconds 10 --timeout-seconds 420
python scripts/gen_seedance_video.py --direction down --api-mode videos --endpoint "https://www.dmxapi.com/v1/videos" --model "doubao-seedance-1-0-pro-fast-251015" --poll-seconds 10 --timeout-seconds 420
```

- `.com /v1/responses` + `doubao-seedance-2-0-260128`：`model_not_found`。
- `.cn /v1/responses`：本机 Python TLS 握手失败，未提交成功。
- `.com /v1/responses` + `doubao-seedance-1-5-pro-responses`：`model_not_found`。
- `.com /v1/videos` + `doubao-seedance-1-0-pro-fast-251015`：`model_not_found`。
- `/v1/models` 查询当前 `.com` 默认分组只看到 Doubao 文本模型与 `doubao-seedream-4-0-250828`，没有 `seedance` 视频模型。
- 本机 PATH 没有 `ffmpeg`，即使生成 mp4，视频抽帧/GIF 也需要另补解码方案或安装 ffmpeg。

结论：

- 本次没有拿到 Seedance task id，也没有产生 mp4；失败点在提交前的模型通道/网络层，不是 prompt 或视频质量问题。
- 继续试同一 API key 的 Seedance 模型名收益低；需要先在 DMXAPI 后台确认/开通 Seedance 视频通道，或拿到可用的视频模型名与 endpoint。

经验：

- **先查 `/v1/models` 再试视频模型**：如果当前分组没有 `seedance`，直接提交会反复 `model_not_found`，可能浪费排查时间。
- **视频 API 与图片 API 不应混进同一生成脚本**：端点、轮询、结果解析、后处理都不同，独立脚本更容易控制风险。
- **视频转 sprite 需要预置抽帧工具**：Windows 环境没有 `ffmpeg` 时，应先准备抽帧方案，否则 mp4 下载后还不能直接进现有 `build_sprite_preview.py`。

### 19.32 火山方舟 Seedance 2.0 试跑被模型未开通拦截（2026-05-04）

用户提供火山方舟 API key，并说明有免费额度，希望尝试 Seedance 2.0。

新增：

- `scripts/gen_volcengine_seedance_video.py`：独立火山方舟 Seedance 2.0 试跑脚本。
  - 支持 `contents/generations/tasks` 与 `videos` 两种 API 形态。
  - 从 `assets/processed/sprite/sprite_lengguyun_walk_down_4f_balanced_slow.png` 裁第 1 格做首帧，避免整张 4 帧 sheet 被识别为多角色。
  - 从 `VOLCENGINE_API_KEY` 或 `ARK_API_KEY` 读取凭据；本地 `.env.local` 已被 `.gitignore` 忽略。

执行：

```powershell
python scripts/gen_volcengine_seedance_video.py --direction down --api-mode tasks --poll-seconds 10 --timeout-seconds 600
python scripts/gen_volcengine_seedance_video.py --direction down --api-mode tasks --model "doubao-seedance-2-0-fast-260128" --poll-seconds 10 --timeout-seconds 600
```

结果：

- API key 鉴权成功，请求到达火山方舟账户。
- 标准模型 `doubao-seedance-2-0-260128` 返回 `ModelNotOpen`：账号尚未开通该模型服务。
- Fast 模型 `doubao-seedance-2-0-fast-260128` 同样返回 `ModelNotOpen`。
- 未拿到 task id，未产生视频，也未发生视频质量评估。

下一步：

- 需要先在火山方舟控制台开通 Seedance 2.0 / Seedance 2.0 Fast 模型服务，然后重新运行同一脚本。

经验：

- **免费额度不等于模型已开通**：火山方舟即使 key 有效、账户有额度，具体模型仍可能需要在控制台单独开通。
- **`ModelNotOpen` 是控制台开通问题，不是 prompt / payload 问题**：不要在这个错误下反复改提示词或重试生成。

### 19.33 四方向行走 MVP 改为混合帧数接入（2026-05-04）

用户决定暂停 Seedance 视频方案，回到 image 方式，并按“左右 8 帧、上下 4 帧慢速 balanced”的低成本策略继续。

接入：

- 复制 processed sprite 到 Godot 跟踪资源目录：
  - `game/art/characters/lengguyun_walk_right_8f.png`
  - `game/art/characters/lengguyun_walk_left_8f.png`
  - `game/art/characters/lengguyun_walk_down_4f.png`
  - `game/art/characters/lengguyun_walk_up_4f.png`
- `game/scripts/field/player.gd` 从占位翻转图改为四方向 sprite sheet 播放：
  - 右 / 左：8 帧，0.10s/帧；
  - 上 / 下：4 帧，0.18s/帧；
  - 停止移动时停在当前方向第 1 帧。
- `game/scenes/player.tscn` 默认贴图改为下走 4 帧 sheet。
- `game/scripts/field/field_walkable_controller.gd` 保留旧立绘覆盖逻辑，但当 Player 已启用方向行走 sprite 时不再覆盖其 texture。
- 新增 `game/tests/test_player_walk_animation.gd`，用于校验 Player 能选择右 8 帧与下 4 帧贴图。

验证：

- PNG 尺寸确认：
  - 右 / 左：1280×160，即 8×160；
  - 上 / 下：640×160，即 4×160。
- `ReadLints` 无报错。
- 当前环境没有 `godot` 命令，未能运行 `game/tests/test_player_walk_animation.gd`；需要在装有 Godot CLI 的环境执行。

经验：

- **MVP 可以接受混合帧数**：左右方向轮廓清楚，8 帧收益明显；正 / 背面 8 帧脚相位不自然时，4 帧慢速反而更稳定。
- **Player 代码必须允许每方向不同帧数/速度**：不要假设四方向统一 8 帧，否则会上下方向播放越界或节奏过快。
- **行走 sprite 接入后要阻止旧立绘覆盖**：否则 FieldController 可能把 Player 的 movement sheet 替换成 portrait，导致动画消失。
- **新 PNG 接入 Godot 需要关注 `.import`**：首次用编辑器打开会生成 import 文件，提交资源前应检查是否需要一并纳入。

### 19.34 Agent Hub 系统设计文档归属错误（2026-05-04）

现象：

- `system` agent 已产出 `docs/system-technical-design-v0.1.md`，但 Agent Hub Web 的 system/Godot 产出列表中看不到该记录。

原因：

- `tools/agent_hub/scanner.py` 的 `_owner_for_path()` 规则把 `docs/*.md` 默认归到 `producer`。
- 系统设计文档虽然文件名以 `system-` 开头，但不在 `game/**` 下，因此没有归到 `system`。

修复：

- 在 `_owner_for_path()` 中增加规则：`docs/system-*` 归属 `system`。
- 重新运行扫描验证。

验证：

```powershell
python -m py_compile tools/agent_hub/scanner.py
python -m tools.agent_hub.verify_agent_hub
python -c "from tools.agent_hub.db import connect, init_db; from tools.agent_hub.scanner import scan_all; conn=connect(); init_db(conn); scan_all(conn); row=conn.execute('select path, kind, owner_agent from artifacts where path=?', ('docs/system-technical-design-v0.1.md',)).fetchone(); print(dict(row) if row else 'NOT_FOUND')"
```

结果：

- `verify_agent_hub` 通过：agents 7、artifacts 320、qa_runs 25、cost_records 74、tasks 66。
- `docs/system-technical-design-v0.1.md` 已记录为 `kind=doc`、`owner_agent=system`。

经验：

- **Web 产出页依赖扫描归属规则**：新增角色专属设计文档时，文件路径命名要能被 `_owner_for_path()` 识别。
- **system 设计文档建议使用 `docs/system-*.md` 命名**，这样可自动归到 Godot/system agent。

### 19.35 Agent Hub Markdown 产出默认应展示预览（2026-05-04）

现象：

- Agent Hub 产出库中点击 `.md` 文件会通过 `/repo/<path>` 直接返回原始文件，浏览器显示 Markdown 源码。
- 用户希望默认看到渲染后的预览，而不是源码。

修复：

- `tools/agent_hub/app.py`：
  - `/repo/{path}` 对 `.md` 文件默认渲染 `markdown_preview.html`。
  - 保留 `?raw=1` 查看源码。
  - 增加 Markdown 渲染；如果本地缺少 `Markdown` 包，则降级为安全转义的基础预览。
- `tools/agent_hub/templates/markdown_preview.html`：新增文档预览页，提供“查看源码”和“返回产出库”。
- `tools/agent_hub/static/style.css`：新增 Markdown 正文、表格、代码块、引用块样式。
- `scripts/requirements.txt`：增加 `Markdown>=3.6`。
- `tools/agent_hub/verify_agent_hub.py`：增加路由验证，确保默认是预览页，`?raw=1` 是源码。

验证：

```powershell
python -m py_compile tools/agent_hub/app.py tools/agent_hub/scanner.py tools/agent_hub/verify_agent_hub.py
python -m tools.agent_hub.verify_agent_hub
```

结果：

- 验证通过：agents 7、artifacts 320、qa_runs 25、cost_records 74、tasks 66。

经验：

- **产出库链接不应等同原始文件下载**：文档类产出默认预览更适合 Web 管理系统；源码入口应作为显式选项。
- **验证脚本要覆盖关键 UI 路由行为**：否则页面行为回退成源码打开时，扫描数量仍会通过。
- **角色详情页也要内嵌 memory 预览**：只修 `/repo/*.md` 不够；`/agents/<role>` 原本仍用 `<pre>` 显示摘要，用户会感觉角色页面还在看源码。应在角色详情页渲染 `memory_path` 对应 Markdown，并保留“查看源码”按钮。
- **角色详情页要置顶关键文档**：只把设计稿放进“最近产出”表格不够明显。按角色筛出 `kind=doc` 的重要文档并单独展示，system 设计稿如 `docs/system-technical-design-v0.1.md` 应在 system 页面可直接看到。
- **重要文档要直接展示正文**：只列出链接仍不够。角色页应提供“重要文档预览”，并默认展开第一篇关键设计稿，避免用户需要二次点击才能看到内容。

### 19.36 Agent Hub 重发布时 8765 被 Cursor 旧监听占用（2026-05-04）

现象：

- 修改 Agent Hub Markdown 预览后，`python -m tools.agent_hub.verify_agent_hub` 通过，但浏览器访问 `http://127.0.0.1:8765/repo/docs/system-technical-design-v0.1.md` 仍返回 Markdown 源码。
- 多次新启动 `uvicorn --port 8765` 报 `WinError 10048`，端口被占用。

排查：

```powershell
netstat -abno | Select-String -Context 1,1 ":8765"
```

结果显示：

- `127.0.0.1:8765` 的监听归属显示为 `[Cursor.exe]` / PID `73976`。
- `taskkill /PID 73976 /F` 与 `Stop-Process -Id 73976` 都提示找不到进程，说明这是 Cursor 管理的旧监听/端口代理，不能在不关闭 Cursor 的情况下可靠清理。

处理：

- 不强杀 Cursor。
- 将新版本 Agent Hub 发布到备用端口：

```powershell
python -m uvicorn tools.agent_hub.app:app --reload --host 127.0.0.1 --port 8766
```

验证：

```powershell
Invoke-WebRequest http://127.0.0.1:8766/health
Invoke-WebRequest http://127.0.0.1:8766/repo/docs/system-technical-design-v0.1.md
Invoke-WebRequest "http://127.0.0.1:8766/repo/docs/system-technical-design-v0.1.md?raw=1"
```

结果：

- `/health` 正常。
- `.md` 默认预览返回 `markdown-preview`。
- `?raw=1` 返回源码。

经验：

- **本地 Web 发布先验端口再验功能**：如果 8765 返回旧行为，不要只看 `verify_agent_hub`，还要打真实浏览器端口。
- **Cursor 旧监听可能无法单独 taskkill**：此时优先用备用端口发布，避免误杀 Cursor。


### 19.39 SceneRouter 需要统一经典 Field / 可行走 Field 入口（2026-05-04）

现象：

- 项目同时存在 `field.tscn`（经典热点模式）和 `field_walkable.tscn`（可行走模式）。
- 新游戏入口可以显式进入可行走场景，但读档、战后继续、商店返回、对话 `scene:`、可行走出口等路径如果各自调用不同入口，容易把同一个 `SceneScript` 放进错误容器。

修复：

- `SceneRouter` 新增 `go_field_smart(scene_id, player_spawn?)`：
  - 读取 `res://data/scenes/<scene_id>.tres`。
  - 若 `SceneScript.is_walkable == true` 且 `field_walkable.tscn` 存在，进入可行走容器。
  - 否则进入经典 `field.tscn`。
- 新增 `get_field_scene_path(scene_id)` 作为可测试的纯查询方法。
- 改造入口：
  - 主菜单新游戏 / 继续游戏。
  - 战斗胜利继续 / 逃跑返回。
  - 商店关闭返回。
  - `SceneRouter.resolve_action("scene:<id>")`。
  - `field_walkable_controller.gd` 的出口跳转。
- 新增测试：`game/tests/test_scene_router_field_smart.gd`，覆盖 walkable 与 classic 两类场景路径选择。

验证：

- Cursor lint：相关 GDScript 文件无新增诊断。
- 搜索确认：游戏代码里没有残留 `SceneRouter.go_field(` / `SceneRouter.go_field_walkable(` 调用。
- 当前 shell 找不到 `godot` / `Godot` 可执行文件，未能运行 Godot SceneTree 测试；后续配置 `GODOT_BIN` 后应补跑：

```powershell
Godot --headless --path game --script res://tests/test_scene_router_field_smart.gd
```

经验：

- **路由选择逻辑必须集中在 SceneRouter**：调用方不应凭经验决定 classic / walkable 容器；只传场景 ID 和可选出生点。
- **可行走出口也属于跨场景入口**：只改读档和战后不够，出口若固定调用 `go_field_walkable()`，目标经典场景也会被错误装进可行走容器。
- **给路由选择拆出纯查询方法**：`get_field_scene_path()` 让无法启动完整场景树的情况下也能写最小测试。


### 19.40 转交给另一个 AI 时需要固定交接文档并进入 Agent Hub（2026-05-04）

现象：

- 只在聊天里整理交接内容，另一个 AI 不一定能稳定获得完整上下文。
- Agent Hub 虽然会扫描 `docs/**/*.md`，但如果文档命名不归属具体角色，角色页的重要文档不一定明显展示。

处理：

- 新增 `docs/system-handoff-2026-05-04.md`，集中记录：
  - 当前项目状态。
  - 最近完成项。
  - `SceneRouter.go_field_smart()` 改动范围。
  - 验证状态与 Godot CLI 缺口。
  - 下一步 Step 2 建议。
- 更新 `docs/current-progress.md` 与 `docs/agents/system-memory.md`，把交接文档列为 system 入口文档。
- 更新 `tools/agent_hub/verify_agent_hub.py`，检查：
  - `/repo/docs/system-handoff-2026-05-04.md` 能以 Markdown 预览渲染。
  - `/agents/system` 能展示这份交接文档。

经验：

- **交接内容要落地成 docs 文件**：聊天摘要适合即时沟通，但跨 AI 接续要用仓库内稳定路径。
- **命名要配合 Agent Hub 归属规则**：`docs/system-*.md` 会自动归属 `system` 并进入 system 角色页重要文档，比普通 `docs/handoff-*.md` 更容易被下一位 agent 看到。
- **Web 展示规则要有验证**：新增交接文档后，把预览路由和角色页展示加入验证脚本，避免“文档存在但网页看不到”。

### 19.41 可行走地图 Step 2 数据化与 UI action 补齐（2026-05-04）

现象：

- `SceneScript` 已有 `is_walkable` / `player_spawn` / `npcs` / `exits`，但缺少静态障碍和剧情触发区，第一章可行走地图只能靠边界碰撞。
- `SceneRouter.resolve_action()` 注释中已有 `open_inventory` / `open_quest_log`，但实现仍是 warning；对话数据无法通过 action 打开现有 I/E/J UI。
- `q_ch1_main_02_qingfeng.tres` 中 `desc_completed` 与 `completion_triggers` 粘在同一行，可能导致 Godot 资源解析失败。
- `ch1_road_after_thug.tres` 跳转到不存在的 `ch1_s2_linxi_road`。

修复：

- `SceneScript` 新增 `collision_rects`、`trigger_zones` 两个 `Array[Dictionary]` 字段，均使用归一化 `Vector2` 坐标。
- `field_walkable_controller.gd` 根据 `collision_rects` 生成 `StaticBody2D` 障碍，根据 `trigger_zones` 生成 `Area2D` 触发区并调用 `SceneRouter.resolve_action()`。
- flag 变化重建可行走场景时保留玩家当前位置，避免触发区 `set_flag` 后瞬移回出生点。
- `EventBus` 新增 `ui_requested(panel_id)`；`SceneRouter` 将 `open_inventory` / `open_equipment` / `open_quest_log` 转成事件，由 classic / walkable Field 复用现有 UI 打开逻辑。
- 新游戏恢复从 `ch1_s1_road` 开始；战后对话跳到 `ch1_s2_qingfeng_walkable`；q2 完成条件改为 `scene_entered:ch1_s2_qingfeng_walkable`。

验证：

- `read_lints` 检查 `game/` 无新增诊断。
- 搜索确认 `game/` 下没有残留直接调用 `SceneRouter.go_field(` / `SceneRouter.go_field_walkable(`。
- 搜索确认不存在 `ch1_s2_linxi_road` 与 `desc_completed = ...completion_triggers` 粘连。
- 当前 PowerShell 环境仍找不到 `Godot` / `godot`，未能运行 headless SceneTree 测试。

经验：

- **触发区 action 若会 set_flag，必须考虑 flag 刷新副作用**：如果刷新场景直接用默认 spawn，会造成玩家走进触发区后瞬移，应保留当前归一化位置。
- **UI action 不应让 SceneRouter 持有 UI 节点引用**：用 `EventBus.ui_requested` 让当前 Field 响应，classic / walkable 两套容器都能复用。
- **场景 ID 和任务 trigger 要一起改**：从 classic 场景迁到 walkable 场景时，只改 `scene:` 跳转不够，`scene_entered:<id>` 任务条件也要同步。

### 19.42 Sprite 白底透明化与场景美术方向转向模块化（2026-05-04）

现象：

- 主角已经可以移动，但行走 sprite 在 Godot 中显示白色底，说明源 PNG 是不透明 RGB/RGBA 白底，不是透明背景。
- 当前几个场景图更像 loading / splash / 概念图，不像可行走游戏场景；继续逐场景生成整张大背景会复用差、交互弱、成本高。

处理：

- 新增 `scripts/make_sprite_bg_transparent.py`，只移除从图片边缘连通的近白背景，避免把冷孤云白色内衫误删。
- 已处理四张 Godot 使用中的行走图：
  - `game/art/characters/lengguyun_walk_right_8f.png`
  - `game/art/characters/lengguyun_walk_left_8f.png`
  - `game/art/characters/lengguyun_walk_down_4f.png`
  - `game/art/characters/lengguyun_walk_up_4f.png`
- 处理后四张图均为 RGBA，alpha 范围为 `(0, 255)`。
- 将角色移动经验写入 `docs/agents/art-memory.md`：NPC 后续复用 Player 的每方向帧数/速度/底部锚点策略。

调研结论：

- Godot 4 官方 `TileMapLayer` 适合用 `TileSet` 做多层模块化地图：地面、装饰、建筑、碰撞、导航等可拆层。
- Tiled 是成熟的开源 2D 地图编辑器，支持多图层、对象层、地形工具、Automapping 和 JSON 导出，也适合外部生产地图数据。
- 本项目短期不应马上切纯像素 tilemap；更推荐“模块化美术 kit + Godot 组合摆放”：道路、建筑、植物、装饰物、前景遮挡物做成可复用 PNG/atlas，场景通过数据摆放。

经验：

- **透明化不能全局扣白**：角色衣物有白色区域，必须 edge-connected 或手工 mask。
- **场景不要再以单张 loading 图为目标**：后续 prompt 应生成可拼装模块，而不是一张完整电影概念图。
- **模块资产要同时服务画面和玩法**：建筑/树/摊位不仅是视觉元素，还应能附带碰撞矩形、遮挡层、NPC 锚点和触发区。

### 19.43 正式 UI 第一轮：统一武侠主题 + 主菜单/背包/装备/战斗换肤（2026-05-04）

处理：

- 新增 `game/scripts/ui/wuxia_theme.gd`，集中管理墨色、金边、朱印、玉色等 UI 配色和 StyleBox。
- `main_menu.gd` 不再只依赖大背景图观感，运行时叠加标题纸、菜单卷轴、朱印和墨色遮罩；按钮改为“启程 / 续卷 / 归隐”。
- `inventory_panel.gd` 改为“行囊”风格，行项目使用金边暗色卡片，按钮统一武侠样式。
- `equipment_panel.gd` 改为“武备”风格，6 槽装备行使用同一套卡片样式。
- `battle_controller.gd` 对战斗日志、按钮、HP/MP 条、姓名标签做统一样式处理；暂不做技能特效。
- 新增 `docs/art-modular-scene-kit-v1.md` 与 `prompts/templates/scene_module_atlas.yaml`；`prompts/tasks.yaml` 增加 3 个默认 `skip:true` 的模块化场景 kit 任务。

验证：

- `read_lints` 检查改动 GDScript 无新增诊断。
- `python -c "import yaml..."` 验证 `prompts/tasks.yaml` 语法通过。
- 当前仍未运行 Godot 编辑器实机验收。

经验：

- **正式 UI 先建统一主题工具**：不要每个界面散落 StyleBox 常量，否则背包、装备、战斗会再次风格漂移。
- **主菜单应由 UI 自身成立**：背景图只做氛围，不应承担全部视觉质量。
- **第一轮 UI 换肤先动脚本和样式，不重写业务逻辑**：这样不会影响背包、装备、战斗的功能闭环。

### 19.44 主界面 / 装备界面参考图风格校正（2026-05-04）

反馈：

- 第一版主菜单只是按钮更正式，但整体仍太简单，不像 `images/游戏主界面UI.png` 的完整武侠主界面。
- 装备界面需要参考 `images/装备界面UI.png`，而不是普通列表。
- 风格要中国武侠浓郁，不要外国神话、妖魔鬼怪元素。

处理：

- `WuxiaTheme` 增强为木纹深棕 + 金边 + 朱印 + 玉色点缀的中国武侠 UI 基调。
- `main_menu.gd` 增加顶梁、底梁、标题匾、红/金丝带、木质菜单板、角色卡框、左右竖牌等结构，尽量贴近参考图的“标题大匾 + 木牌菜单 + 角色卡 + 山水背景”构图。
- `equipment_panel.gd` 从单列装备列表改为三栏：左侧角色立绘、中间 3×2 装备槽、右侧纸张详情卡、下方 attributes 文本，贴近参考装备页布局。

经验：

- **参考图的关键不是按钮样式，而是构图层级**：顶部大标题匾、木牌按钮组、人物/装备卡、竖向角色标签、底部宣言共同构成“武侠游戏 UI”。
- **装备页不能只是列表**：RPG 装备界面应有角色展示区、装备槽位区、详情纸张区和属性区，列表只是临时实现。
- **禁止妖魔化装饰**：本项目 UI 装饰应使用山水、云纹、木牌、金边、朱印、绸带、屋檐纹样；避免骷髅、恶魔、西幻符文等元素。

### 19.45 UI 色调修正：从暖木金边转为寒山玄铁冷色（2026-05-05）

反馈：

- 用户明确不要橙黄色，整体要更阴沉、冷色调。

处理：

- `WuxiaTheme` 统一改为寒夜黑、深墨蓝、玄铁、冷钢边、霜蓝、寒玉、暗血红；保留常量名兼容旧代码，但数值已不再是暖金色。
- `main_menu.gd` / `main_menu.tscn` 的背景叠色、暗角、标题匾、菜单板、角色卡、丝带和文字高光改为雾蓝/冷白。
- `inventory_panel.gd`、`equipment_panel.gd`、`battle_controller.gd` 中散落的暖色 StyleBox 改为冷色玄铁卡片、灰白冷宣纸、寒蓝 MP、暗血 HP。
- `tools/ui_style_preview.html` 升级为 UI Kit v2「寒山玄铁」，覆盖主菜单、按钮、对话框、buff/debuff、血条、装备槽、详情卡和冷色板。
- `docs/ui-style-v1.md` 与 `docs/agents/art-memory.md` 已记录：禁止大面积橙黄 / 暖金 / 喜庆红绸，参考图只取构图，不取暖色调。

经验：

- **统一主题常量不够**：之前不少界面脚本里有散落的硬编码暖色，改色调时必须全局搜索并同步替换。
- **常量名可暂时兼容，语义要在文档里修正**：`GOLD` 等旧常量名短期保留以降低代码改动，但文档和预览里要明确它现在代表“冷钢边 / 霜蓝高光”。
- **冷色武侠不等于西幻暗黑**：装饰仍用山水、云纹、匾额、宣纸、寒玉，避免骷髅、恶魔、符文等西幻/妖魔元素。

### 19.46 UI 从 HTML 风格稿推进到 art agent 美术资产 brief（2026-05-05）

反馈：

- 当前 UI 方向接近，但 `tools/ui_style_preview.html` 只是 HTML 风格稿，不是真正游戏美术资产。
- 需要 art agent 基于「寒山玄铁 · 雾蓝侠影」去画带武侠元素的 UI。
- UI 内不要英文；属性体系为：筋骨、机敏、内劲、悟性、生命、内力、防御。

处理：

- 新增 `docs/art-ui-asset-kit-v1.md`，明确第一批 UI 美术资产：通用框架 atlas、属性图标 atlas、状态条 / Buff / 战斗 HUD。
- 新增 `prompts/templates/ui_cold_wuxia_kit.yaml`：生成无字 UI 组件 atlas（匾额、按钮、对话框、冷宣纸卡、装备槽、状态条框等）。
- 新增 `prompts/templates/ui_cold_wuxia_icon_atlas.yaml`：生成无字属性 / 状态图标 atlas，并为 7 个属性定义视觉意象。
- `prompts/tasks.yaml` 增加 3 个默认 `skip:true` 的 UI 美术任务：`ui_cold_wuxia_common_kit_v1`、`ui_cold_wuxia_attribute_icons_v1`、`ui_cold_wuxia_battle_hud_v1`。
- `docs/agents/art-memory.md` 记录：UI 图片不要英文、不要拉丁字母，优先无字，中文标签由 Godot 渲染。

经验：

- **正式 UI 资产不要依赖 AI 写字**：属性名、按钮文案、标题最好由 Godot 字体渲染；美术只画无字框体和图标，避免错字/英文/乱码。
- **属性图标要有中文语义映射**：图标本身无字，但 brief 必须写清筋骨/机敏/内劲/悟性/生命/内力/防御各自的意象，方便切图命名和程序接入。
- **生成任务默认 skip**：UI atlas 属于付费生成任务，先审 prompt / 小批次试跑，避免一次性烧钱和风格跑偏。

### 19.47 UI 风格确认：`ui_cold_wuxia_common_kit_v1` 作为后续基准（2026-05-05）

结果：

- 已生成 `assets/raw/ui/cold_wuxia/v1/ui_cold_wuxia_common_kit_v1.png`。
- 用户确认“这个风格可以，按照这个来做”。

处理：

- `ui_cold_wuxia_common_kit_v1.png` 设为后续 UI 美术 canonical reference。
- `prompts/templates/ui_cold_wuxia_kit.yaml` 和 `ui_cold_wuxia_icon_atlas.yaml` 已把该图加入 `reference_images`，后续属性图标 / 战斗 HUD 生成都会参考这张。
- `docs/art-ui-asset-kit-v1.md`、`docs/ui-style-v1.md`、`docs/agents/art-memory.md`、`docs/current-progress.md` 已同步记录。

经验：

- **风格确认后立刻固化引用图**：不要只在聊天里说“按这个做”，要把成功图写进模板 `reference_images`，否则下一批生成容易漂移。
- **后续生成顺序**：先属性图标 atlas，再战斗 HUD；通过后再切图进 `game/art/ui/cold_wuxia/`。

### 19.48 主菜单按钮最终方案：从参考素材裁切 + 书法字体合成（2026-05-08）

反馈：

- 此前所有方案（差分提取文字、系统字体重出图、gpt-image-2 重新生成）都无法一步到位
- 用户明确要求：风格对标 `assets/raw/ui/cold_wuxia/v2/ui_cold_wuxia_main_menu_hover_load_gpt_v1.png`
- 按钮底框已有现成素材 `assets/raw/ui/btn_menu_3states.png`（三态并排）

**最终成功方案**：

1. 从 `btn_menu_3states.png` 裁切三态底框（不用 AI 重新生成）
2. 去除灰色背景（素材不是透明底，而是灰色 (218,217,217) 实底）
3. 用华文行楷（STXINGKA.TTF）渲染白色书法文字 + 黑色阴影
4. 合成 9 张最终按钮（3 个按钮 × 3 态），输出透明底 PNG
5. 更新 `main_menu.gd` 和 `main_menu.tscn` 适配新贴图

脚本：`scripts/gen_menu_buttons_from_ref.py`

关键技术细节：

| 步骤 | 要点 |
|------|------|
| 灰色背景去除 | `remove_gray_background()`: 检测 R≈G≈B 且亮度>180 的像素，设 alpha=0 |
| 三态裁切 | 原图水平三等分（normal/hover/pressed），getbbox() 裁掉透明边缘 |
| 文字渲染 | 华文行楷 56px，白色 (240,240,255) + 黑色阴影 GaussianBlur(3) |
| 尺寸 | 底框 resize 到 550×165，文字 y 偏移 +8px（避开顶部宝石装饰） |
| 输出 | `game/art/ui/main_menu/buttons/final/btn_<key>_<state>.png`，共 9 张 |

**为什么这次成功了**：

1. **不依赖 API 调用**：不用 gpt-image-2，不怕余额不足或连接超时
2. **底框直接复用参考素材**：保证视觉风格 100% 一致
3. **背景去除算法正确**：不是简单 threshold，而是灰度+亮度双条件
4. **字体选择正确**：华文行楷是系统自带的书法字体，风格匹配武侠
5. **文字合成方式正确**：shadow + text 分层合成，不用混合模式

经验：

- **已有高质量参考素材时，优先裁切复用，不要重新生成**：AI 生成容易风格漂移，裁切能保证 100% 一致。
- **素材可能不是透明底**：不要假设 PNG 就是透明底，要检查四角像素值。灰底素材需要先做背景去除。
- **背景去除要用多条件判断**：单纯按阈值扣色会误伤正常像素；应同时判断"通道一致性"（R≈G≈B）和"亮度"（>180），避免误删按钮装饰。
- **按钮合成比整图出图更可控**：底框+文字分层合成，每一层都可独立调整，不需要重新烧 API。
- **文字用系统自带中文字体**：华文行楷/隶书/彩云都是 Windows 内置，不需要额外下载字体。
- **文字渲染加黑色阴影**：白字直接放在暗色底框上对比度足够，但加 GaussianBlur 阴影可以增加深度感和可读性。
- **后续所有 UI 按钮都应按此流程**：先确认有没有参考素材可裁切，有则裁切+合成；没有再考虑 AI 生成。

### 19.48.1 主菜单文字白底/消失/风格问题修复（2026-05-08 旧方案，已弃用）

反馈：

- 主菜单按钮文字显示白底块，不是透明文字
- 尝试用 `CanvasItemMaterial.BLEND_MODE_MUL` 去除白底，导致文字在深色背景上消失
- 重出图（系统字体）后风格不对，太饱满，不是原来的美术字风格
- 需要调整文字大小适配底框

处理：

- **错误做法（已弃用）**：使用 `BLEND_MODE_MUL` 混合模式，试图"吃掉"白底 → 文字完全消失，因为深色背景下乘法混合会使所有像素变黑
- **错误做法（已弃用）**：用系统字体（STZHONGS.TTF）重出文字贴图 → 风格与原始美术字不符，太饱满
- **正确做法**：从 `assets/raw/ui/button/main_menu/text/v1/` 原始图差分提取文字层
  - 用 `assets/raw/ui/button/main_menu/frame/v1/ui_btn_main_frame_normal_v1.png` 作为底框基准
  - 计算 `text_rgb - frame_rgb` 的差异，提取差异像素作为文字
  - 生成透明底 PNG（RGBA），保留原始美术字的颜色和质感
  - 输出到 `game/art/ui/main_menu/buttons/text/v1/`（420x120）
- **文字缩放**：在 `main_menu.gd` 的 `_apply_button_art_text()` 中，按按钮尺寸动态缩放文字贴图
  - 当前比例：`half_w = btn_width * 0.38`，`half_h = btn_height * 0.33`
  - 可根据视觉效果微调这两个系数
- **读取存档灰态**：新增 `_update_continue_button_state()` 函数
  - 无存档时，`btn_continue.disabled = true`
  - 同时灰化按钮底框和美术字（`modulate = Color(0.58, 0.60, 0.64, 0.94)`）
- **脚本**：新增 `scripts/extract_menu_text_from_source.py`，可复用

经验：

- **不要滥用混合模式**：`BLEND_MODE_MUL` 会使所有像素向黑色偏移，不适合去除白底。正确做法是生成真正的透明底贴图。
- **保留原始美术资产**：当原始素材（带文字的按钮图）存在时，优先从原始图提取，而不是重新生成。差分提取可以保留原始风格。
- **文字贴图尺寸要适配底框**：文字贴图输出尺寸（420x120）要小于底框尺寸（496x149），留出边距；显示时用动态缩放，方便微调。
- **灰态要同时影响多个节点**：无存档时，不仅要 `disabled=true`，还要同时调整按钮和美术字节点的 `modulate`，让用户清楚看到"不可点击"状态。
- **Windows 控制台编码问题**：Python `print()` 中的 Unicode 字符（如 ✓）会导致 `UnicodeEncodeError`，改用 ASCII 字符（如 `[OK]`）。

### 19.49 ALAPI 生成主菜单按钮层需要压缩参考图并短退避（2026-05-09）

现象：

- 使用 ALAPI `https://v3.alapi.cn/api/ai/images/generations` 生成主菜单按钮底框和文字层时，第一次批量请求全部出现：
  - `RemoteProtocolError: peer closed connection without sending complete message body`
  - `502 Bad Gateway`
- `gen_assets.py` 原先把 `RemoteProtocolError` 归类为 DMXAPI 风控 / TLS 错误，触发全局 30 分钟暂停；这对 ALAPI 不合适。

原因：

- ALAPI 的 generations 接口使用 `token` header，不是标准 `Authorization: Bearer`。
- ALAPI 可传 `image` base64 参考图，但原始 PNG 直接 base64 后 payload 偏大，容易断流。
- ALAPI 的 502 / incomplete chunked read 更像临时网络 / payload 问题，应短退避重试，不应进入 DMXAPI 的 30 分钟风控暂停。

修复：

- `scripts/gen_assets.py`：
  - 新增 ALAPI 直连分支，支持完整 endpoint 和 `token` header。
  - ALAPI 参考图先压缩为 JPEG（最长边 1280，quality 88）再放入 payload。
  - ALAPI 下 `RemoteProtocolError` / TLS 连接类错误走短退避 transient。
  - ALAPI 下 502 / 503 / 504 也走短退避 transient，不走长时间 channel/IP pause。
- `prompts/templates/ui_button_frame_cold_main_menu.yaml` 与 `ui_button_text_cold_main_menu.yaml` 改为参考 `assets/raw/scene_background/ui_main_menu_full_v5.png`。
- 新增 `scripts/process_main_menu_button_layers.py`：
  - 将 AI 原图白底转透明。
  - 裁切并统一输出 512x128 的底框三态和文字层。
  - 输出到 `game/art/ui/button/btn_menu_frame_*.png` 与 `btn_menu_text_*.png`。
  - 生成 `tools/main_menu_button_layers_preview.png`。

验证：

- 6 张按钮资产均由 ALAPI + `gpt-image-2` 生成，`fallback_used=false`。
- 每张成本记录约 ¥1.2，总计约 ¥7.2。
- 输出层尺寸均为 512x128。
- Cursor lint：相关 GDScript / Python 无新增诊断。
- `python -m py_compile scripts/gen_assets.py scripts/process_main_menu_button_layers.py` 通过。

经验：

- **ALAPI 不能直接套 OpenAI SDK 认证方式**：必须使用 `token` header；通用管线要单独分支。
- **参考图先压缩再传**：ALAPI generations 接口对大 JSON payload 不稳定，压缩参考图能显著降低断流概率。
- **不同后端的错误退避不能混用**：DMXAPI 的 TLS 风控经验不应直接套到 ALAPI；否则会误等 30 分钟。
- **主菜单按钮适合底框 + 文字分层**：底框三态复用，文字单独贴图，Godot 只负责 StyleBoxTexture 状态切换和热区。

### 19.50 Godot Button 设置 flat=true 会隐藏 StyleBoxTexture 底框（2026-05-09）

现象：

- 主菜单按钮分层方案中，文字贴图正常显示，但按钮底图 / 三态底框完全看不到。
- `game/art/ui/button/btn_menu_frame_*.png` 与 `.import` 都存在，文字资源也能加载。

原因：

- `game/scripts/ui/main_menu.gd` 在 `_apply_frame_text_button()` 里设置了 `btn.flat = true`。
- Godot 的 `Button.flat=true` 会让按钮不绘制背景装饰，导致已经设置的 `normal` / `hover` / `pressed` `StyleBoxTexture` 不显示。
- 文字是子节点 `TextureRect`，不受 `flat` 影响，所以出现“只有字体，没有底图”。

修复：

- 将 `btn.flat = true` 改为 `btn.flat = false`。
- 保留原生文字透明化，仍由子节点 `TextureRect` 显示文字。

验证：

- `ReadLints` 检查 `game/scripts/ui/main_menu.gd` 无新增错误。
- 资源尺寸检查确认 3 张底框 + 3 张文字均为 `512x128`。

经验：

- **Button 使用 StyleBoxTexture 做正式底图时不能 flat=true**：需要透明文字可以隐藏 font color，但不要关掉按钮背景绘制。
- **分层 UI 排查顺序**：先确认资源存在和 import，再确认脚本加载路径，最后确认控件属性是否禁止绘制。

### 19.51 主菜单按钮三态不能分别让 AI 自由生成轮廓（2026-05-09）

现象：

- `assets/raw/ui/button/main_menu/frame/v1/ui_btn_main_frame_normal_v1.png` 的 normal 底框形状和 hover / pressed 差异过大。
- Godot Button 状态切换时，按钮外轮廓会跳变，动画效果不稳定。

原因：

- 三态底框分别由 AI 生成，即使提示词描述一致，装饰件、边角曲线、宝石位置也会发生漂移。
- 对 UI 交互态来说，三态应该共享同一透明轮廓，只改变亮度、颜色、描边、辉光或按压明暗。

修复：

- `scripts/process_main_menu_button_layers.py` 改为只使用 normal 原图作为底框母版。
- hover / pressed 不再读取各自 AI 原图，而是由程序从 normal 母版派生：
  - hover：提高亮度和饱和度，叠加轻微青色调。
  - pressed：降低亮度，保留同一 alpha 轮廓。
- 重新生成：
  - `game/art/ui/button/btn_menu_frame_normal.png`
  - `game/art/ui/button/btn_menu_frame_hover.png`
  - `game/art/ui/button/btn_menu_frame_pressed.png`
  - `tools/main_menu_button_layers_preview.png`

验证：

- `python scripts/process_main_menu_button_layers.py` 通过。
- 三态输出尺寸均为 `512x128`。
- 三态 alpha 非透明像素数均为 `34784`，bbox 均为 `(63, 6, 449, 122)`。
- mask 验证：
  - `normal_vs_hover_mask_equal=True`
  - `normal_vs_pressed_mask_equal=True`
- `ReadLints` 检查 `scripts/process_main_menu_button_layers.py` 无新增错误。

经验：

- **按钮三态要同源派生**：AI 可生成母版，但 hover / pressed 更适合程序调色和明暗处理，不能让 AI 分别重新设计轮廓。
- **交互态优先检查 alpha mask**：视觉预览之外，要验证三态透明轮廓、bbox、尺寸完全一致，避免 Godot 状态切换时跳形。

### 19.52 主菜单文字层不能只按亮度扣白底（2026-05-09）

现象：

- 主菜单按钮文字叠到底框后，金色笔画内部能看到底框绿色透出。
- 尤其是 `读取存档` 这类较暗文字，看起来像被底图染绿。

原因：

- `scripts/process_main_menu_button_layers.py` 原来对文字层复用了 `white_to_alpha()`。
- 该函数按亮度把接近白色的像素转透明，但金色文字高光本身也很亮，导致部分笔画被误处理成半透明。
- 缩放后还会产生更多半透明像素，叠加到底框时就露出绿色。

修复：

- 为文字层新增 `white_to_alpha_keep_colored()`：
  - 只把“高亮且低饱和”的像素视作白底。
  - 对高饱和金色、深棕阴影、暗描边保持不透明。
- 新增 `harden_text_alpha()`：
  - 缩放后将文字主体 alpha 固化为 255。
  - 只保留最外沿少量抗锯齿半透明。
- 重新生成：
  - `game/art/ui/button/btn_menu_text_new_game.png`
  - `game/art/ui/button/btn_menu_text_load.png`
  - `game/art/ui/button/btn_menu_text_quit.png`
  - `tools/main_menu_button_layers_preview.png`

验证：

- `python scripts/process_main_menu_button_layers.py` 通过。
- `python -m py_compile scripts/process_main_menu_button_layers.py` 通过。
- `ReadLints` 检查 `scripts/process_main_menu_button_layers.py` 无新增错误。
- 文字层半透明像素占比从约 `17%-36%` 降至约 `2%`，只剩边缘抗锯齿。

经验：

- **金色文字扣白底不能只看亮度**：要结合饱和度 / chroma，否则会把金色高光误扣成透明。
- **游戏 UI 文字主体应尽量不透明**：分层叠加时，文字主体 alpha 低会把底框颜色带进笔画里。

### 19.53 从完整主菜单参考图复用按钮时优先裁完整按钮（2026-05-09）

现象：

- 用户认可按钮三态同源派生逻辑，但认为 AI 单独生成的按钮母版不如 `assets/raw/scene_background/ui_main_menu_full_v5.png` 里的原按钮好看。
- v5 原图中的按钮已经包含更好的金属框、宝石、内板配色和文字风格。

原因：

- 之前的 AI 底框和文字层虽然功能正确，但美术风格与 v5 首界面不完全一致。
- v5 原图按钮自带文字和不同配色，强行拆成“无字底框 + 单独文字”会损失原图质感，且抠字/补底容易留下痕迹。

修复：

- `scripts/process_main_menu_button_layers.py` 新增 v5 完整按钮导出：
  - 从 `ui_main_menu_full_v5.png` 裁出 `新游戏`、`读取存档`、`离开` 三枚按钮。
  - 使用 `rembg` 抠掉背景，保留原按钮和原文字。
  - 每枚按钮再派生 normal / hover / pressed 三态，保证同一按钮三态 mask 一致。
- `game/scripts/ui/main_menu.gd` 新增 `V5_BUTTON_MAP`：
  - 优先使用 `btn_menu_v5_*_{normal,hover,pressed}.png`。
  - 如果 v5 完整按钮资源缺失，再回落到旧的共享底框 + 文字层方案。

验证：

- `python scripts/process_main_menu_button_layers.py` 通过，生成 9 张 v5 按钮状态图。
- `python -m py_compile scripts/process_main_menu_button_layers.py` 通过。
- `ReadLints` 检查 `game/scripts/ui/main_menu.gd` 与 `scripts/process_main_menu_button_layers.py` 无新增错误。
- 三枚按钮各自的 normal / hover / pressed alpha mask 完全一致。
- `tools/main_menu_button_layers_preview.png` 已切换为 v5 完整按钮预览。

经验：

- **参考图按钮已经足够好时，不要强行重绘**：优先裁原图按钮并做状态派生，能最大化保持首界面一致性。
- **完整按钮适合保留原字**：当原图文字、材质、阴影与底框融合得很好时，拆字会破坏质感；工程上可以让完整按钮优先、分层按钮兜底。
- **裁图抠背景优先用专用 matting 工具**：复杂金属边框和山水背景颜色接近时，手写颜色阈值容易残留背景，`rembg` 更稳。

### 19.54 抠图后的按钮不能按各自 alpha bbox 缩放（2026-05-09）

现象：

- v5 完整按钮接入后，`新游戏` 按钮明显比 `读取存档` 和 `离开` 大。
- 三态效果正确，但三枚按钮之间的视觉尺寸不统一。

原因：

- `rembg` 对三枚按钮的透明边界不同。
- `fit_v5_button_on_canvas()` 原来复用了 `fit_on_canvas()`，会按每张图自己的 alpha bbox 裁切再缩放。
- alpha bbox 越紧，最终缩放越大，导致 `新游戏` 看起来比另外两枚大。

修复：

- v5 完整按钮改为按固定裁图尺寸统一缩放：
  - 三枚按钮都来自 `575x155` 裁图。
  - 缩放比例统一由原始裁图尺寸和 `512x128` 输出画布计算。
  - 不再按每张图的 alpha bbox 单独决定缩放比例。
- 重新生成 `btn_menu_v5_*_{normal,hover,pressed}.png` 与 `tools/main_menu_button_layers_preview.png`。

验证：

- `python scripts/process_main_menu_button_layers.py` 通过。
- `python -m py_compile scripts/process_main_menu_button_layers.py` 通过。
- `ReadLints` 检查 `scripts/process_main_menu_button_layers.py` 无新增错误。
- 三枚按钮 normal 输出横向 bbox 已统一到约 `x=64-440`。
- 每枚按钮的 normal / hover / pressed mask 仍保持完全一致。

经验：

- **同组 UI 资源要用同一几何基准缩放**：抠图 alpha bbox 只能用于清透明边，不能用于决定同组按钮的最终尺寸。
- **先统一尺寸，再做三态派生**：否则即使每个按钮自己的三态稳定，不同按钮之间仍会视觉不齐。

### 19.55 UI 资产生产流程要沉淀成项目 Skill（2026-05-09）

现象：

- 主菜单按钮从参考图裁切、抠图、三态派生、Godot 接入，连续踩了多个可复发问题。
- 后续背包、装备、商店等 UI 还会大量复用类似流程，靠对话记忆容易遗漏。

原因：

- UI 资产生产不是单张图片问题，而是“参考图 → 透明 PNG → 三态 → Godot 主题覆盖 → 预览 → 验证”的完整管线。
- 如果没有固定 checklist，后续 AI 容易重复：
  - 独立生成三态导致轮廓跳动。
  - 按每张 alpha bbox 缩放导致同组控件大小不一。
  - `UI_THEME.style_button()` 或 `Button.flat` 覆盖贴图样式。
  - 修复后忘记写经验记录。

修复：

- 新增项目级 Cursor Skill：`.cursor/skills/producing-godot-ui-assets/SKILL.md`。
- Skill 覆盖：
  - 参考图裁切 / 分层或完整按钮复用。
  - 同组 UI 的统一 canvas、统一裁图几何和统一缩放规则。
  - alpha 清理、金色文字保色、三态同源派生。
  - Godot `StyleBoxTexture` 接入与 `flat=false` 规则。
  - `UI_THEME.style_button()` 覆盖风险。
  - 预览、mask 检查、脚本编译、lint、场景验证和经验记录。

验证：

- Skill 文件 132 行，低于 500 行。
- `ReadLints` 检查 `.cursor/skills/producing-godot-ui-assets/SKILL.md` 无新增错误。
- 用 subagent 做无 Skill 基线测试，确认自然流程会遗漏部分关键约束。
- 用 subagent 读取新 Skill 后应用到“背包面板按钮三态生产”场景，最终复测通过。

经验：

- **复杂资产管线要写成 Skill，不只写经验日志**：经验日志适合追溯坑，Skill 适合让后续 Agent 直接执行正确流程。
- **Skill 不能过度绑定一次案例**：可以保留主菜单作为例子，但脚本名、按钮名、mask 检查必须提示按目标 UI 替换。
- **写 Skill 也要验证**：用一个非主菜单场景复测，能及时发现模板硬编码问题。











