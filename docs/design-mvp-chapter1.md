# MVP 第一章 整体设计稿

> v0.2.0 目标：完成端到端的"开场到第一章结束"完整体验。  
> 5-8 分钟可通关，包含所有核心系统的最小可用版本。  
> **本文档需用户拍板确认后才开始实现。**

---

## 0. 现状自检

| 现状 | 是否够撑 MVP |
|---|---|
| 主菜单 / 战斗 / 胜利存档闭环 | ✅ 框架在，可复用 |
| Lovart 6 张高质量参考图 | ✅ 够当占位 |
| DMXAPI / OpenAI 出图管线 | ✅ 在，按需补图 |
| **缺**：探索场景 / 对话系统 / 背包 / 任务 / 多敌人 / 多技能 / 商店 / 章节剧本 | ⛔ 全要补 |

---

## 1. 产品一句话定位

> **漫画 2.5D 武侠 AVG-RPG**：玩家通过点击式场景探索 + 回合制战斗推进江湖故事，每章 5-15 分钟，单机离线，AI 生成美术。

—— 关键决策：**不做 2D 顶视角自由走**，做 AVG 式静态场景 + 互动热点。原因见 §3。

---

## 2. 玩家三层循环

```
┌─ 5 秒：单回合战斗 ─────────────────────────────┐
│   选技能 → 看动画 → 看伤害数字 → 看对方反击    │
└────────────────────────────────────────────────┘
            ↑                    ↓
┌─ 1 分钟：场景内 ───────────────────────────────┐
│   静态场景 + 4-8 个互动热点（NPC/出口/宝箱）   │
│   点击触发：对话 / 战斗 / 拾取 / 商店 / 离开    │
└────────────────────────────────────────────────┘
            ↑                    ↓
┌─ 5-15 分钟：章节内 ────────────────────────────┐
│   推主线 → 打 boss → 升级 → 解锁下章           │
└────────────────────────────────────────────────┘
```

---

## 3. 关键决策：为什么不做 2D 顶视角自由走

| 维度 | 顶视角自由走（《风云》原作）| AVG 式点击场景（推荐）|
|---|---|---|
| 主角立绘 | 需要四向 8 帧 sprite，~32 张/角色 | 1 张静态半身像就够 |
| GPT Image 2 适配 | ❌ 出不出（已实测"精灵"被你判不行）| ✅ 强项 |
| 场景资产 | 需要瓦片地图 + 边界碰撞 | 1 张全景图就够 |
| Lovart 高质量图利用 | ❌ 用不上 | ✅ 直接当背景 |
| 单章开发时间 | 8-12 小时 | 3-5 小时 |
| 玩家观感 | 老派 RPG 怀旧 | 漫画 + 视觉小说混血 |

**结论**：AVG 式更适合"AI 美术 + 单人开发"现实，且充分发挥 GPT Image 2 强项。

可类比游戏：
- 操作风格：橙光文字游戏 / 《疑案追声》
- 视觉风格：《极乐迪斯科》对话 + 《圣女战旗》立绘
- 战斗风格：《最后一战》《八方旅人》回合制

---

## 4. 第一章故事 MVP（占位剧本）

> 角色名/门派名/反派名标 ★ 都是占位，可后续完全替换。剧情骨架是普通武侠"师门血案 → 下山立志"模板，**必须先有占位才能跑通系统**。

### 4.1 世界观（2 段）

> 大乾朝末年，江湖动荡，三大门派分立中原。
> 武当掌玄机、少林守佛理、唐门藏暗影。三派之外，散修野心勃勃，黑教★\*暗中蛊惑武林。
> 你是武当弟子★ **沈不归★**，性烈如火，五年前因师门寄居山下的村庄遭屠，独自下山修行，发誓追凶。

\* 黑教 = 占位反派组织名

### 4.2 第一章主线骨架（5-8 分钟流程）

```
[黑屏旁白]
"五年了。线索断在清风镇★。我循着血迹，回到了这里。"

  ↓ 自动加载

[场景 1：清风镇外·官道]    背景：bg_battle_default.png（先复用）
  互动点 ：
    ├─ 路边石碑（旁白：到清风镇还有十里）
    ├─ 路边尸体（教学战触发：vs 落单匪徒，必胜）
    └─ [出口] 进城

  战斗后：尸体身上找到【粗布麻衣】+【小还丹×1】+【清风镇地图】
  → 主线任务接受："前往清风镇打听黑教下落"

  ↓

[场景 2：清风镇·主街]    背景：bg_main_menu.png（Lovart 主界面图）
  互动点（NPC 4 个 + 2 个出口）：
    ├─ 客栈老板（主线推进 → "城西废宅近来不太平"）
    ├─ 神秘商人（→ 商店界面，可买卖）
    ├─ 哭泣女子（支线接受："夫君被掳走，请相救" → +50 两奖励）
    ├─ 守城兵丁（闲聊，揭示世界观）
    ├─ [出口] 离镇（章节中段后才解锁）
    └─ [出口] 前往城西 → 场景 3

  ↓

[场景 3：清风镇·城西废宅]   背景：bg_equipment.png（Lovart 装备界面图）
  互动点：
    ├─ 被绑男子（如果接了支线 → 救出，得线索"赵无忌★"）
    ├─ 旧木箱（拾取：【铁剑】武器，攻击+5）
    └─ 大门 → 章末战触发

  章末战：vs 赵无忌★（精英怪，HP 200 / Atk 22 / 有 1 个特殊技能）

  ↓

[胜利剧情]
赵无忌临死交代："黑教在...玄机谷..."（剧透下一章）

[章节结算面板]
  - 完成主线
  - 解锁第二章（暂不开放）
  - 总耗时统计
  - [回主菜单]
```

### 4.3 涉及内容统计

- 角色：1 主角 + 4 个有名 NPC + 3 个敌人
- 场景背景：3 张（已有 3 张占位可用）
- 立绘：主角 1 + 反派 1 + NPC 0（用文字头像即可）
- 战斗：3 场（教学/小怪/章末 boss）
- 物品：4 件（小还丹×N、粗布麻衣、铁剑、地图）
- 技能：3 个（普攻、排云掌、防御）
- 任务：1 主线 + 1 支线
- 对话：约 25 段，每段 30-80 字
- 总流程时间：5-8 分钟

---

## 5. 系统模块图（要做的全部代码）

```
RPG_GAME/game/
├── scripts/
│   ├── autoload/                   全局单例
│   │   ├── game_state.gd       ✅ 已有
│   │   ├── scene_router.gd     ✅ 已有，扩
│   │   ├── save_manager.gd     ✅ 已有，扩 5 槽
│   │   ├── event_bus.gd        🆕 全局信号枢纽
│   │   ├── dialog_player.gd    🆕 对话队列驱动
│   │   ├── inventory.gd        🆕 玩家背包
│   │   └── quest_manager.gd    🆕 任务状态机
│   │
│   ├── domain/                     纯数据 Resource
│   │   ├── character_stats.gd  ✅ 已有
│   │   ├── skill.gd            ✅ 已有
│   │   ├── item.gd             🆕 物品定义
│   │   ├── equipment.gd        🆕 装备
│   │   ├── enemy_def.gd        🆕 敌人模板
│   │   ├── quest_def.gd        🆕 任务定义
│   │   ├── dialog_node.gd      🆕 对话节点
│   │   ├── shop_def.gd         🆕 商店清单
│   │   └── scene_script.gd     🆕 场景脚本（互动点列表）
│   │
│   ├── battle/                     战斗系统
│   │   ├── battle_controller.gd ✅ 已有，重构为数据驱动
│   │   ├── battle_formula.gd   🆕 伤害/命中/暴击公式
│   │   ├── status_effect.gd    🆕 状态异常（中毒/眩晕）
│   │   └── enemy_ai.gd         🆕 敌人决策树
│   │
│   ├── field/                      探索场景 🆕
│   │   ├── field_controller.gd 🆕 场景管理器
│   │   ├── interact_hotspot.gd 🆕 互动热点节点
│   │   └── scene_loader.gd     🆕 从 .tres 加载场景
│   │
│   └── ui/                         UI 层
│       ├── main_menu.gd        ✅ 已有
│       ├── result_victory.gd   ✅ 已有
│       ├── result_defeat.gd    ✅ 已有
│       ├── dialog_box.gd       🆕 对话气泡
│       ├── inventory_ui.gd     🆕 背包栏
│       ├── quest_log_ui.gd     🆕 任务记录
│       ├── status_panel_ui.gd  🆕 角色面板
│       ├── shop_ui.gd          🆕 商店
│       └── chapter_end_ui.gd   🆕 章节结算
│
├── scenes/
│   ├── main_menu.tscn          ✅
│   ├── battle.tscn             ✅
│   ├── result_victory.tscn     ✅
│   ├── result_defeat.tscn      ✅
│   ├── field.tscn              🆕 探索场景模板
│   └── chapter_end.tscn        🆕 章节结算
│
└── data/                            🆕 全部内容数据
    ├── characters/protagonist.tres
    ├── enemies/
    │   ├── thug_lone.tres
    │   ├── bandit_mountain.tres
    │   └── boss_zhao_wuji.tres
    ├── skills/
    │   ├── basic_attack.tres
    │   ├── palm_strike.tres
    │   └── defend.tres
    ├── items/
    │   ├── healing_pill_minor.tres
    │   ├── cloth_armor.tres
    │   └── chapter1_map.tres
    ├── equipment/iron_sword.tres
    ├── quests/
    │   ├── main_ch1_to_qingfeng.tres
    │   └── side_ch1_save_husband.tres
    ├── dialogs/                  对话以场景为单位
    │   ├── ch1_road_intro.tres
    │   ├── ch1_inn_keeper.tres
    │   └── ch1_boss_dying.tres
    ├── shops/qingfeng_merchant.tres
    └── scenes/
        ├── ch1_s1_road.tres        场景 1 互动点配置
        ├── ch1_s2_qingfeng.tres
        └── ch1_s3_west_yard.tres
```

---

## 6. 系统 MVP 边界

每个系统给"最小但完整"的范围。**这是我们承诺要做的，多一分都不写**。

| 系统 | MVP 范围 | **明确不做** |
|---|---|---|
| 角色 | 1 主角 + 5 属性（HP/MP/攻/防/速）+ 升级 | 多职业、转职、天赋树、内功 |
| 战斗 | 1v1 回合制 + 3 技能槽 + 4 状态（中毒/眩晕/防御/虚弱）| 队伍战、AOE、Combo、QTE、连击 |
| 背包 | 单页 30 格 + 堆叠 + 使用/丢弃 + 装备 | 多页、整理、自动卖、仓库 |
| 装备 | 武器槽 + 衣甲槽（共 2 槽）即穿即生效 | 护腕/护具、强化、附魔、套装 |
| 任务 | 接受/进行中/完成三态 + 主线 1 + 支线 1 | 分支结局、声望、限时、悬赏 |
| 对话 | 单线 + 2 选 1 分支（最多 1 处）| 立绘表情切换、配音、动态变量 |
| 商店 | 固定库存 5 件 + 固定价格 + 买卖 | 库存随机、砍价、声望折扣 |
| 探索 | 静态背景 + 4-8 个互动热点点击 | 自由移动、视野遮挡、跳跃 |
| 存档 | 5 槽 + 全状态保存（仅 JSON）| 自动存档、云存档、版本迁移 |
| UI | 简体中文 + 键鼠 | 手柄、英文、缩放、动效 |

---

## 7. 数据模型（关键 Resource 字段）

### Item（物品）
```
@export var item_id: StringName
@export var display_name: String
@export var description: String
@export var icon_path: String
@export var stackable: bool = true
@export var max_stack: int = 99
@export var usable_in_battle: bool = true
@export var sell_price: int = 0
@export var buy_price: int = 0
@export var heal_hp: int = 0          # 简化：所有"消耗品"用统一字段
@export var heal_mp: int = 0
```

### Equipment（装备）继承自 Item，加：
```
enum Slot { WEAPON, ARMOR }
@export var slot: Slot
@export var atk_bonus: int = 0
@export var def_bonus: int = 0
```

### Quest（任务定义）
```
enum Status { NOT_STARTED, IN_PROGRESS, COMPLETED, FAILED }
@export var quest_id: StringName
@export var title: String
@export var description_states: Dictionary  # status → 当前显示文本
@export var reward_gold: int = 0
@export var reward_exp: int = 0
@export var reward_items: Array[Item] = []
@export var triggers: Array[String] = []    # event_bus 信号匹配
```

### DialogNode（对话节点）
```
@export var speaker: String         # "客栈老板"
@export var text: String            # 一段台词
@export var choices: Array[Dictionary] = []   # [{text, jump_to_id, set_flag}]
@export var on_end_action: String = ""   # "open_shop:qingfeng" / "start_battle:thug" / "next:next_node_id"
```

### SceneScript（场景脚本）
```
@export var scene_id: StringName
@export var background_path: String
@export var bgm_path: String = ""
@export var on_enter_dialog: DialogNode    # 进入时旁白
@export var hotspots: Array[Dictionary] = []
# hotspot = {pos: Vector2, label: "客栈老板", action: "dialog:ch1_inn_keeper"}
```

---

## 8. EventBus 信号规约

任何"游戏事件"都走 EventBus，QuestManager 监听，不要让任务系统反向耦合到战斗/场景。

```gdscript
signal enemy_defeated(enemy_id: StringName)
signal item_picked_up(item_id: StringName, count: int)
signal scene_entered(scene_id: StringName)
signal npc_talked_to(npc_id: StringName)
signal flag_set(flag_name: StringName, value)
```

任务通过 `triggers: ["enemy_defeated:boss_zhao_wuji"]` 配置完成条件。

---

## 9. 实现路线（垂直切片，按 milestone 推进）

每个 milestone 都"端到端能跑"，不是孤立做某个系统。

| M | 时长 | 内容 | 验收标准 |
|---|---|---|---|
| **M1** | 1.5h | 数据驱动重构 + EventBus + Inventory autoload | 战斗系统从 .tres 读敌人和技能；战利品自动入背包 |
| **M2** | 2h | Field 场景 + 互动热点 + 对话系统 | 主菜单→场景 1→点尸体→触发战斗→胜利后回到场景 1 |
| **M3** | 1.5h | Quest 系统 + 主线任务 1 | 任务自动接受/推进/完成；UI 显示当前任务 |
| **M4** | 1.5h | 多场景跳转 + NPC 对话 + 商店 | 场景 1→2→3 完整流转；商店买卖物品 |
| **M5** | 1h | 背包/装备 UI + 物品使用 | 背包栏可打开；穿铁剑攻击+5；战中用回血药 |
| **M6** | 1.5h | 章末 Boss + 状态异常 + 章节结算 | 打赢赵无忌后看到结算画面回主菜单 |
| **M7** | 1h | 5 槽存档 + 加载/继续游戏 | 任意时刻能存档读档恢复完整状态 |

**合计：10 小时编码**，分 3-4 天完成。

---

## 10. 占位故事可替换性保证

所有故事内容都在 `data/dialogs/*.tres` 和 `data/quests/*.tres` 里，**不写在代码**。

后续你想完全换故事：
1. 改 `data/dialogs/` 下的对话文本
2. 改 `data/quests/` 下的任务描述
3. 改 `data/characters/protagonist.tres` 的名字字段
4. 替换 `assets/_style_bible/` 下的参考图，重出立绘
5. 不需要动一行代码

这是"内容与代码分离"的核心目标。

---

## 11. 不在 v0.2.0 范围内的（明确不做）

> 防止范围漂移，列在这里就是承诺不做。

- ❌ 战斗动画（Tween 简单缩放即可，不做粒子/技能特效）
- ❌ 多人队伍战
- ❌ 第二章及以后内容
- ❌ 专业美术资产（继续用占位图 + 手写中文标题）
- ❌ 音效 / BGM
- ❌ Steam 上架 / 打包发布
- ❌ 多语言
- ❌ Linux / macOS 版本

**v0.2.0 完成后**才会评估这些。

---

## 12. 待用户拍板的关键决策（5 个问题）

填完这 5 个我就动手：

1. **场景操作模式** = AVG 式点击热点 ✓（推荐）/ 顶视角自由走（更难做）
2. **占位故事接受？** = 武当弟子沈不归追黑教 ✓ / 我自己写一份 / 先用占位，能跑就行
3. **战斗模式** = 1v1 简单回合制 ✓（可后续扩队伍）/ 直接做队伍战
4. **章末 boss 战难度** = 比常规怪难 1.5 倍 ✓ / 加新机制 / 多阶段战斗
5. **优先扩美术还是优先扩玩法** = 玩法先 ✓（M1-M7 完成后再补图）/ 边做边出图（出图打断节奏）

确认后，我把 §9 的 M1-M7 拆成 todo，开始 M1。
