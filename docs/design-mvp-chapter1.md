# MVP 第一章 整体设计稿

> v0.2.0 目标：完成端到端的"开场到第一章结束"完整体验。
> 6-10 分钟可通关，包含所有核心系统的最小可用版本。
> **本文档与 `docs/world-bible.md` v0.3 对齐（2026-04-27）。原占位剧情（沈不归 / 清风镇 / 赵无忌 / 黑教）已替换为新世界观下的"林西村下山"。**

---

## 修订记录

| 版本 | 日期 | 内容 |
|---|---|---|
| v0.1 | 2026-04 | 占位剧情（武当弟子沈不归追黑教进清风镇打赵无忌）；MVP 系统骨架 |
| **v0.2** | **2026-04-27** | **剧情切到 v0.3 世界观**：冷孤云从林西村下山、刑樊天送行、村外教学战、竹尾村密林救悦无姮、章末战 vs 蒙面杀手首领（茗雾派伪装烈云盟） |

---

## 0. 现状自检（2026-04-27）

| 现状 | 是否够撑 MVP |
|---|---|
| 主菜单 / 战斗 / 胜利存档闭环 | ✅ M1 已完成 |
| Field 场景 + 互动热点 + 对话系统 | ✅ M2 已完成 |
| Quest 系统 + 主线任务 1 | ✅ M3 已完成 |
| 多场景跳转 + NPC 对话 + 商店 | ✅ M4 已完成 |
| **本文档定稿后**：把 `game/data/` 下 .tres 占位剧情切到新世界观 | ⛔ 待做（步骤 E）|
| **本文档定稿后**：跑 stage 2 美术资产（场景 / 立绘）| ⛔ 待做（步骤 D）|
| 背包 / 装备 UI + 物品使用 | ⛔ M5 待做 |
| 章末 Boss + 状态异常 + 章节结算 | ⛔ M6 待做 |
| 5 槽存档 + 加载 / 继续游戏 | ⛔ M7 待做 |

> **当前位置**：M1-M4 程序框架已实装但跑的还是 v0.1 占位剧情；本次重写后需把 game/data/ 切到 v0.2 新剧情，再跑 M5-M7。

---

## 1. 产品一句话定位

> **漫画 2.5D 武侠 AVG-RPG**：玩家通过点击式场景探索 + 回合制战斗推进江湖故事，每章 6-15 分钟，单机离线，AI 生成美术。

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
┌─ 6-10 分钟：章节内 ────────────────────────────┐
│   推主线 → 打 boss → 升级 → 解锁下章           │
└────────────────────────────────────────────────┘
```

---

## 3. 关键决策：为什么不做 2D 顶视角自由走

| 维度 | 顶视角自由走 | AVG 式点击场景（推荐）|
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

## 4. 第一章故事（v0.3 世界观对齐）

### 4.1 章节定位

> **MVP 第一章覆盖 `world-bible.md §6 章一 + 章二前半`**，作为 MVP 起点：
> - 章一（林西村下山）—— 完整呈现
> - 章二（竹尾村）—— 仅做密林救悦无姮 + 章末战这个**高潮段**，留下"凌月山选派"为第二章入口

为什么合并：单做"林西村下山"缺章末高潮（boss 战），玩家观感不完整；合并到"竹尾密林救女主"为 MVP 收束最自然。

### 4.2 世界观铺垫（开场旁白 2 段）

> 大乾朝中期，江湖已二十年未起大风波。
> 武当掌剑、华山争雄、少林守佛、古峰雄霸、凌月幽冥、茗雾隐世——七派分立中原，互不渗透。
> 直到一日，**各大派的大弟子相继离奇身亡**——武林一时震动，传言是百年来被各派排挤的**烈云盟**所为。
>
> 你是林西村一名平民少年，**冷孤云**，二十岁，自小由武师 **刑樊天** 抚养长大。
> 这天清晨，村里得了消息——你决定下山。

### 4.3 第一章主线骨架（6-10 分钟流程）

```
[黑屏旁白]
"林西二十年的山雾，掩不住今天来的这道消息。"
"师傅说我武功只够保命。可我不愿一辈子困在这村子里。"

  ↓ 自动加载

[场景 1：林西村·主街]    背景：bg_linxi_main.png（待出图）
  互动点（4 NPC + 1 出口）：
    ├─ 刑樊天（村东武师院 → 主线推进对话："师傅，我要下山"）
    ├─ 沈半盏（村中央酒馆 → 商店：买小还丹/林西酒/粗布麻衣）
    ├─ 杜青衫（村南铁匠铺 → 剧情对话："送你一柄铁剑，路上保命"，得【铁剑】）
    ├─ 走货郎（村西闲聊 → 揭世界观："听说各派大弟子接连身亡，传是烈云盟…")
    └─ [出口] 村外山道 → 场景 2

  主线接受："下山闯荡江湖，先去竹尾村打听消息"

  ↓

[场景 2：林西村·村外山道]    背景：bg_linxi_road.png（待出图）
  互动点：
    ├─ 路边石碑（旁白："林西村到竹尾村，五十里。")
    ├─ 路边江湖散兵（教学战触发：vs 江湖散兵，必胜）
    └─ [出口] 进竹尾村 → 场景 3

  战斗后掉落：【粗布麻衣】+【小还丹×1】+【竹尾村地图】
  支线触发（隐藏奖励）：找到地图 → 标注"竹尾村密林近来不太平"

  ↓

[场景 3：竹尾村·村外密林]    背景：bg_zhuwei_forest.png（待出图）
  互动点：
    ├─ 被围攻的红衣女子（接受支线："援手救人" → 触发章末战入场动画）
    │   └─ 即悦无姮（凌月派大师姐），被 3 名"自称烈云盟"的蒙面杀手围攻
    ├─ 旧木箱（拾取：【小还丹×2】）
    └─ 林深处石坛 → 章末战触发

  章末战：vs **蒙面杀手首领**（精英，HP 200 / Atk 22 / 技能"毒针"概率中毒）

  ↓

[胜利剧情]
首领临死前：
  "…茗雾…茗雾会找到你的…"
  （旁白：你不知"茗雾"是什么，但记下了这个名字。）

悦无姮（解开面纱，长舒一口气）：
  "多谢搭救。我是凌月派 悦无姮。"
  "若你不嫌，请同往凌月山一行——师姐尚有要事。"

[章节结算面板]
  - 完成主线"下山闯荡"
  - 完成支线"援手救人"
  - 解锁第二章·入派抉择（暂不开放）
  - 总耗时统计
  - [回主菜单]
```

### 4.4 涉及内容统计

| 类别 | 数量 | 内容 |
|---|---|---|
| 角色 | 1 主角 + 4 有名 NPC | 冷孤云 / 刑樊天 / 沈半盏 / 杜青衫 / 走货郎 / 悦无姮 |
| 场景背景 | 3 张 | 林西村主街 / 林西村山道 / 竹尾村密林（**全部待出图，stage 2 必产**） |
| 立绘 | 6 张 | 主角 / 刑樊天 / 沈半盏 / 杜青衫 / 悦无姮 / 蒙面杀手首领（**全部待出图，stage 2 必产**） |
| 战斗 | 2 场 | 教学（江湖散兵）/ 章末（蒙面杀手首领）|
| 物品 | 5 件 | 小还丹×N、林西酒、粗布麻衣、铁剑、竹尾村地图 |
| 技能 | 3 个 | 普攻 / 林西基础剑法·一式 / 防御 |
| 任务 | 1 主线 + 1 支线 | 主："下山闯荡" / 支："援手救人" |
| 对话 | 约 30 段 | 每段 30-80 字 |
| 总流程 | 6-10 分钟 | |

### 4.5 主线任务定义

| 字段 | 主线 ch1_main | 支线 ch1_side |
|---|---|---|
| ID | `ch1_xia_shan` | `ch1_jiu_yuewuxing` |
| 标题 | 下山闯荡 | 援手救人 |
| 描述（接受时）| 师傅说武功只够保命，但江湖动荡，你决定下山一探究竟。先去竹尾村打听消息。| 密林深处一名红衣女子被围攻，求你出手相救。|
| 触发 | 自动接受（主菜单进入即接受）| 与悦无姮对话选"我帮你"|
| 完成条件 | `enemy_defeated:masked_killer_leader` | 同上（章末战胜利同时完成）|
| 奖励 | 经验 50 + 金 50 | 经验 30 + 金 30 + 悦无姮好感 +5 |

### 4.6 商店清单（沈半盏酒馆）

| 物品 | 买价 | 卖价 | 备注 |
|---|---|---|---|
| 小还丹 | 30 | 12 | +30 HP |
| 林西酒（剧情）| - | - | 杜青衫送 / 不可买，永久 +5 HP，战中喝 +20 MP |
| 粗布麻衣 | 80 | 30 | 装备槽 ARMOR / +3 防 |
| 解毒丹 | 50 | 20 | 解中毒状态 |

---

## 5. 系统模块图（要做的全部代码）

```
RPG_GAME/game/
├── scripts/
│   ├── autoload/                   全局单例
│   │   ├── game_state.gd       ✅ M1
│   │   ├── scene_router.gd     ✅ M1
│   │   ├── save_manager.gd     ✅ M1（5 槽待 M7 扩）
│   │   ├── event_bus.gd        ✅ M1
│   │   ├── dialog_player.gd    ✅ M2
│   │   ├── inventory.gd        ✅ M1
│   │   └── quest_manager.gd    ✅ M3
│   │
│   ├── domain/                     纯数据 Resource
│   │   ├── character_stats.gd  ✅ M1
│   │   ├── skill.gd            ✅ M1
│   │   ├── item.gd             ✅ M1
│   │   ├── equipment.gd        ✅ M1
│   │   ├── enemy_def.gd        ✅ M1
│   │   ├── quest_def.gd        ✅ M3
│   │   ├── dialog_node.gd      ✅ M2
│   │   ├── shop_def.gd         ✅ M4
│   │   └── scene_script.gd     ✅ M2
│   │
│   ├── battle/                     战斗系统
│   │   ├── battle_controller.gd ✅ M1
│   │   ├── battle_formula.gd   🆕 M6（伤害/命中/暴击公式）
│   │   ├── status_effect.gd    🆕 M6（中毒/眩晕/防御/虚弱）
│   │   └── enemy_ai.gd         🆕 M6（敌人决策树）
│   │
│   ├── field/                      探索场景
│   │   ├── field_controller.gd ✅ M2
│   │   ├── interact_hotspot.gd ✅ M2
│   │   └── scene_loader.gd     ✅ M2
│   │
│   └── ui/                         UI 层
│       ├── main_menu.gd        ✅ M1
│       ├── result_victory.gd   ✅ M1
│       ├── result_defeat.gd    ✅ M1
│       ├── dialog_box.gd       ✅ M2
│       ├── shop_ui.gd          ✅ M4
│       ├── inventory_ui.gd     🆕 M5
│       ├── quest_log_ui.gd     🆕 M5
│       ├── status_panel_ui.gd  🆕 M5
│       └── chapter_end_ui.gd   🆕 M6
│
├── scenes/
│   ├── main_menu.tscn          ✅
│   ├── battle.tscn             ✅
│   ├── result_victory.tscn     ✅
│   ├── result_defeat.tscn     ✅
│   ├── field.tscn              ✅ M2
│   ├── shop.tscn               ✅ M4
│   └── chapter_end.tscn        🆕 M6
│
└── data/                            v0.2 切到新世界观（步骤 E 待做）
    ├── characters/
    │   └── protagonist_lengguyun.tres            🆕 切名：冷孤云
    ├── enemies/
    │   ├── jianghu_drifter.tres                  🆕 江湖散兵（教学）
    │   ├── masked_killer_minion.tres             🆕 蒙面杀手小怪
    │   └── masked_killer_leader.tres             🆕 蒙面首领（章末，原赵无忌）
    ├── skills/
    │   ├── basic_attack.tres                     ✅
    │   ├── linxi_basic_sword_one.tres            🆕（原 palm_strike）
    │   └── defend.tres                           ✅
    ├── items/
    │   ├── healing_pill_minor.tres               ✅
    │   ├── cloth_armor.tres                      ✅
    │   ├── chapter1_zhuwei_map.tres              🆕（原 chapter1_map → 改名）
    │   ├── linxi_jiu.tres                        🆕 林西酒（剧情）
    │   └── antidote_pill.tres                    🆕 解毒丹
    ├── equipment/
    │   └── iron_sword.tres                       ✅（武器名不变）
    ├── quests/
    │   ├── ch1_xia_shan.tres                     🆕 主线（原 main_ch1_to_qingfeng）
    │   └── ch1_jiu_yuewuxing.tres                🆕 支线（原 side_ch1_save_husband）
    ├── dialogs/                  v0.2 全部重写
    │   ├── ch1_intro_narration.tres              🆕 开场旁白
    │   ├── ch1_s1_xing_fantian.tres              🆕 刑樊天送行
    │   ├── ch1_s1_shen_banzhan.tres              🆕 沈半盏酒馆
    │   ├── ch1_s1_du_qingshan.tres               🆕 杜青衫送铁剑
    │   ├── ch1_s1_walking_vendor.tres            🆕 走货郎闲聊
    │   ├── ch1_s2_road_drifter.tres              🆕 教学战触发
    │   ├── ch1_s3_yuewuxing_meet.tres            🆕 救悦无姮
    │   ├── ch1_s3_killer_dying.tres              🆕 章末战胜
    │   └── ch1_s3_yuewuxing_after.tres           🆕 章末告别
    ├── shops/
    │   └── linxi_shenbanzhan.tres                🆕（原 qingfeng_merchant）
    └── scenes/
        ├── ch1_s1_linxi_main.tres                🆕 林西村主街（原 ch1_s1_road）
        ├── ch1_s2_linxi_road.tres                🆕 林西村外山道（原 ch1_s2_qingfeng）
        └── ch1_s3_zhuwei_forest.tres             🆕 竹尾村密林（原 ch1_s3_west_yard）
```

> 步骤 E 实质工作 = 把 v0.1 占位 .tres 文件按上述路径重命名 + 内容重写，**不需要动一行 GDScript**。

---

## 6. 系统 MVP 边界

每个系统给"最小但完整"的范围。**这是我们承诺要做的，多一分都不写**。

| 系统 | MVP 范围 | **明确不做** |
|---|---|---|
| 角色 | 1 主角 + 5 直接属性（HP/MP/攻/防/速）+ 升级 | 三主属（力/敏/内）派生（v1.0 后）、多职业、转职、天赋树、内功 |
| 战斗 | 1v1 回合制 + 3 技能槽 + 4 状态（中毒/眩晕/防御/虚弱）| 队伍战、AOE、Combo、QTE、连击 |
| 背包 | 单页 30 格 + 堆叠 + 使用/丢弃 + 装备 | 多页、整理、自动卖、仓库 |
| 装备 | 武器槽 + 衣甲槽（共 2 槽）即穿即生效 | 6 槽完整版（头/甲/手/武/鞋/饰）、强化、附魔、套装 |
| 任务 | 接受/进行中/完成三态 + 主线 1 + 支线 1 | 分支结局、声望、限时、悬赏 |
| 对话 | 单线 + 2 选 1 分支（最多 1 处）| 立绘表情切换、配音、动态变量 |
| 商店 | 固定库存 5 件 + 固定价格 + 买卖 | 库存随机、砍价、声望折扣 |
| 探索 | 静态背景 + 4-8 个互动热点点击 | 自由移动、视野遮挡、跳跃 |
| 存档 | 5 槽 + 全状态保存（仅 JSON）| 自动存档、云存档、版本迁移 |
| UI | 简体中文 + 键鼠 | 手柄、英文、缩放、动效 |

> **MVP 与 world-bible 的对齐**：world-bible §5.1 定义了三主属体系（力/敏/内），但 MVP 阶段用的是简化的 5 直接属性。**v1.0 阶段**（M5-M7 完成后）再升级到三主属，并保留向后兼容。

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
@export var speaker: String         # "刑樊天"
@export var text: String            # 一段台词
@export var choices: Array[Dictionary] = []   # [{text, jump_to_id, set_flag}]
@export var on_end_action: String = ""   # "open_shop:linxi_shenbanzhan" / "start_battle:masked_killer_leader" / "next:next_node_id"
```

### SceneScript（场景脚本）
```
@export var scene_id: StringName
@export var background_path: String
@export var bgm_path: String = ""
@export var on_enter_dialog: DialogNode    # 进入时旁白
@export var hotspots: Array[Dictionary] = []
# hotspot = {pos: Vector2, label: "刑樊天", action: "dialog:ch1_s1_xing_fantian"}
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

任务通过 `triggers: ["enemy_defeated:masked_killer_leader"]` 配置完成条件。

---

## 9. 实现路线（垂直切片，按 milestone 推进）

| M | 时长 | 内容 | 验收标准 | 状态 |
|---|---|---|---|---|
| **M1** | 1.5h | 数据驱动重构 + EventBus + Inventory autoload | 战斗系统从 .tres 读敌人和技能；战利品自动入背包 | ✅ 完成 |
| **M2** | 2h | Field 场景 + 互动热点 + 对话系统 | 主菜单→场景 1→点尸体→触发战斗→胜利后回到场景 1 | ✅ 完成 |
| **M3** | 1.5h | Quest 系统 + 主线任务 1 | 任务自动接受/推进/完成；UI 显示当前任务 | ✅ 完成 |
| **M4** | 1.5h | 多场景跳转 + NPC 对话 + 商店 | 场景 1→2→3 完整流转；商店买卖物品 | ✅ 完成 |
| **E** | 1.5-2h | **v0.2 占位故事切到新世界观**（改 game/data/ 下 .tres）| 跑通 v0.2 第一章流程：林西村→山道→竹尾密林→章末战 | ⛔ 待做 |
| **D** | 1-2h | **stage 2 美术批量生产**（场景 3 张 + 立绘 6 张）| `assets/scenes/` 和 `assets/portraits/` 各就位 | ⛔ 待做 |
| **M5** | 1h | 背包/装备 UI + 物品使用 | 背包栏可打开；穿铁剑攻击+5；战中用回血药 | ⛔ 待做 |
| **M6** | 1.5h | 章末 Boss + 状态异常 + 章节结算 | 打赢蒙面首领后看到结算画面回主菜单 | ⛔ 待做 |
| **M7** | 1h | 5 槽存档 + 加载/继续游戏 | 任意时刻能存档读档恢复完整状态 | ⛔ 待做 |

**剩余编码**：约 6-7 小时（E + D + M5 + M6 + M7），分 2-3 天完成。

---

## 10. 占位故事可替换性保证

所有故事内容都在 `data/dialogs/*.tres` 和 `data/quests/*.tres` 里，**不写在代码**。

### 当前状态（v0.2）

| 内容层 | v0.1 占位 | v0.2 切到新世界观（待 E 步骤完成）|
|---|---|---|
| 主角 | 沈不归 | **冷孤云** |
| 起点 | 清风镇 | **林西村** |
| 反派 | 黑教 / 赵无忌 | **茗雾派伪装烈云盟 / 蒙面杀手首领** |
| 女主 | （无）| **悦无姮**（章末初登场）|
| 师傅 | （无）| **刑樊天** |

### 后续替换流程（再之后想换故事）

1. 改 `data/dialogs/` 下的对话文本
2. 改 `data/quests/` 下的任务描述
3. 改 `data/characters/protagonist_*.tres` 的名字字段
4. 替换 `assets/_style_bible/` 下的参考图，重出立绘
5. 不需要动一行代码

这是"内容与代码分离"的核心目标。

---

## 11. 不在 v0.2.0 范围内的（明确不做）

> 防止范围漂移，列在这里就是承诺不做。

- ❌ 战斗动画（Tween 简单缩放即可，不做粒子/技能特效）
- ❌ 多人队伍战
- ❌ 第二章及以后内容（凌月山选派 → 章 2，不做）
- ❌ 三女主多结局（章 8，不做）
- ❌ 武功精进系统（world-bible §5.2，v1.0 后做）
- ❌ 6 槽装备完整版（v1.0 后做，MVP 仅武器/衣甲 2 槽）
- ❌ 三主属（力/敏/内）派生公式（v1.0 后做，MVP 用 5 直接属性）
- ❌ 音效 / BGM
- ❌ Steam 上架 / 打包发布
- ❌ 多语言
- ❌ Linux / macOS 版本

**v0.2.0 完成后**才会评估这些。

---

## 12. 跟 world-bible 的关系

| 维度 | world-bible.md v0.3 | design-mvp-chapter1.md v0.2（本文档）|
|---|---|---|
| 范围 | 完整 8 章故事 + 全玩法系统 | 仅章 1 + 章 2 前半 + 简化系统 |
| 玩法系统 | 三主属 + 6 槽装备 + 武功精进 + 风云式战斗 | 5 直接属性 + 2 槽装备 + 3 技能 + 简化战斗 |
| 角色覆盖 | 6 主角 + 7 派 NPC + 烈云盟全员 + 茗雾全员 | 1 主角 + 4 NPC（刑樊天 / 沈半盏 / 杜青衫 / 走货郎）+ 1 女主 + 1 章末战首领 |
| 章节大纲 | 8 章详细 + 4 路结局 | 1 章合并版 |
| 待用户拍板 | 17 项决策（§9） | 已对齐 v0.3，无新增 |

**优先级**：world-bible 是"叙事 + 系统设计的权威源"；本文档是"为了把 MVP 做出来的简化裁剪"。两份冲突时以 world-bible 为准。

> 当前 world-bible §9 还有 17 项待拍板决策；这些**不影响 MVP 第一章实装**（MVP 不涉及那些决策），所以可以**同步推进 E/D/M5-M7**，待用户后续拍板再回写 world-bible。

---

## 13. 下一步

1. **E**：把 `game/data/` 下 v0.1 占位 .tres 切到 v0.2 新内容（按 §5 列表逐项重命名 + 重写）
2. **D**：跑 stage 2 美术批量生产（3 场景 + 6 立绘）
3. **M5-M7**：补完背包 UI / 章末战 / 存档

E 与 D 之间无强依赖（可并行），但 D 需要先把 `prompts/tasks.yaml` 切到新角色（步骤 C，进行中）。
