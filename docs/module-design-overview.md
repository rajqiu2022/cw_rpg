# RPG_GAME 项目模块设计总览

> 生成日期：2026-07-03  
> 引擎：Godot 4.6.2 · 语言：GDScript  
> 项目性质：漫画 2.5D 武侠 AVG-RPG（致敬《风云之天下会》1998）

---

## 一、架构总览

```
game/
├── autoload/          # 9 个全局单例（生命期 = 游戏全程）
├── scripts/
│   ├── domain/        # 13 个 Resource 数据模型类
│   ├── battle/        # 1 个战斗控制器
│   ├── field/         # 5 个探索场景控制器
│   └── ui/            # 15 个 UI 面板脚本
├── scenes/            # 10 个 .tscn 场景 + 8 个 UI .tscn
├── data/              # 数据资产（.tres 文件）
│   ├── dialogs/       # 30+ 对话脚本
│   ├── enemies/       # 31 种敌人配置
│   ├── equipment/     # 100+ 装备
│   ├── items/         # 40+ 物品
│   ├── quests/        # 50+ 任务
│   ├── scenes/        # 7 个场景定义
│   ├── shops/         # 10 个商店
│   ├── skills/        # 30+ 技能
│   └── status_effects/ # 5 种状态异常
├── art/               # 美术资源目录结构
└── tests/             # 3 个自动化测试脚本
```

---

## 二、9 个 Autoload 全局单例

| # | 名称 | 职责 | 状态 |
|---|------|------|------|
| 1 | `EventBus` | 全局信号枢纽（battle/dialog/quest/inventory 等事件） | ✅ 稳定 |
| 2 | `GameState` | 玩家状态（金币、flags、当前章节） | ✅ 稳定 |
| 3 | `Inventory` | 背包 + 6 装备槽管理 | ✅ 稳定 |
| 4 | `SceneRouter` | 场景路由 + action 字符串解析中枢 | ✅ 稳定 |
| 5 | `QuestManager` | 任务状态机 + EventBus 订阅触发 | ✅ 稳定 |
| 6 | `DialogPlayer` | 对话流播放、副作用、结束动作 | ✅ 稳定 |
| 7 | `SaveManager` | JSON 存档（5 槽，version=4） | ✅ 稳定（M7 新增 UI） |
| 8 | `CursorManager` | 全局鼠标指针管理 | ✅ 稳定 |
| 9 | `AudioManager` | BGM 交叉淡入淡出 + SFX 池化(8) + 3 路音量 | ✅ 稳定 |

---

## 三、13 个 Domain Resource 类

| 类名 | 文件 | 说明 | 状态 |
|------|------|------|------|
| `CharacterStats` | `character_stats.gd` | 角色面板（7 项核心属性 + hp/mp/attack/defense/speed） | ✅ |
| `Skill` | `skill.gd` | 技能定义（伤害/消耗/效果/冷却） | ✅ |
| `Item` | `item.gd` | 物品基类（category/quality/stackable/heal 效果） | ✅ |
| `Equipment` | `equipment.gd` | 装备子类（6 槽 + 11 种属性加成） | ✅ |
| `EnemyDef` | `enemy_def.gd` | 敌人模板（属性/技能池/AI 参数/战利品/Boss 标志） | ✅ |
| `DialogNode` | `dialog_node.gd` | 对话节点（文本/选项/副作用/结束动作） | ✅ |
| `DialogScript` | `dialog_script.gd` | 对话脚本容器（nodes 数组 + start_id） | ✅ |
| `SceneScript` | `scene_script.gd` | 场景定义（背景/热点/NPC/碰撞/BGM） | ✅ |
| `QuestDef` | `quest_def.gd` | 任务定义（主线/支线/触发条件/奖励） | ✅ |
| `ShopDef` | `shop_def.gd` | 商店定义（商品列表/价格倍率） | ✅ |
| `BattleFormula` | `battle_formula.gd` | 伤害/暴击/逃跑公式 | ✅ |
| `EnemyAI` | `enemy_ai.gd` | 5 层决策树（保命/压制/消耗/狂暴/默认） | ✅ |
| `StatusEffectDef` | `status_effect_def.gd` | 5 种状态异常模板（kind/duration/stack_rule/skip_turn） | ✅ |

---

## 四、场景系统

### 4.1 场景类型

| 场景 | 文件 | 类型 | 说明 |
|------|------|------|------|
| 主菜单 | `main_menu.tscn` | 启动场景 | 新游戏/继续/退出，版本号 v0.4.0 |
| 探索场景（经典） | `field.tscn` | 点击式 AVG | 静态背景 + 浮动热点 + 底部 HUD |
| 探索场景（可走） | `field_walkable.tscn` | 自由行走 | 玩家控制角色行走 + 热点交互 |
| 战斗 | `battle.tscn` | 回合制 | 数据驱动 1v1 回合制 |
| 商店 | `shop.tscn` | 买卖 UI | 商品列表 + 购买/出售 |
| 章节结算 | `chapter_end.tscn` | 过渡 | 任务统计 + 存档 + 返回主菜单 |
| 胜利 | `result_victory.tscn` | 过渡 | 战斗胜利 + 战利品 |
| 失败 | `result_defeat.tscn` | 过渡 | 战斗失败 |

### 4.2 场景数据（7 个 .tres）

| ID | 场景 | 类型 |
|----|------|------|
| `linxi_tutorial` | 林西村教程 | walkable |
| `ch1_s0_linxi_main_walkable` | 林西村主街 | walkable |
| `ch1_s1_road` | 官道 | classic |
| `ch1_s2_qingfeng` / `ch1_s2_qingfeng_walkable` | 竹尾村 | 双版本 |
| `ch1_s3_west_ruin` / `ch1_s3_zhuwei_forest` | 城西废宅/竹尾森林 | classic/walkable |

### 4.3 场景路由规则

- **SceneRouter** 根据 SceneScript 类型自动选择：classic → `field.tscn`，walkable → `field_walkable.tscn`
- action 字符串解析：`dialog:`/`battle:`/`scene:`/`give_item:`/`give_gold:`/`set_flag:`/`accept_quest:`/`complete_quest:`/`open_inventory`/`open_quest_log`/`play_bgm:`/`play_sfx:`/`stop_bgm`

---

## 五、UI 面板系统（15 个脚本 + 8 个场景）

### 5.1 Field HUD

| 面板 | 热键 | 文件 | 状态 |
|------|------|------|------|
| 角色信息 | — | `field_primary_hud.gd` | ✅ |
| 背包 | I / 按钮 | `inventory_panel.gd` + `inventory_panel.tscn` | ✅ 6×6 格子 + 5 Tab + 品质色 |
| 装备 | E / 按钮 | `equipment_panel.gd` + `equipment_panel.tscn` | ✅ 6 槽 + 属性显示 + tooltip |
| 技能 | K / 按钮 | `skill_panel.gd` + `skill_panel.tscn` | ✅ 7 流派筛选 |
| 任务 | J / 按钮 | `quest_panel.gd` + `quest_panel.tscn` | ✅ 面板 + 右下追踪 |
| 存档 | F5 / 系统按钮 | `save_slot_panel.gd` + `save_slot_panel.tscn` | ✅ **M7 新增** 5 槽 SAVE/LOAD 模式 |

### 5.2 对话/商店

| 面板 | 文件 | 状态 |
|------|------|------|
| 对话框 | `dialog_box.gd` + `dialog_box.tscn` | ✅ 底部立绘 + 名字 + 富文本 + 选项 |
| 商店 | `shop_ui.gd` + `shop.tscn` | ✅ 买卖、背包物品出售 |

### 5.3 主菜单/过渡

| 面板 | 文件 | 状态 |
|------|------|------|
| 主菜单 | `main_menu.gd` + `main_menu.tscn` | ✅ v5 按钮、空背景兜底、版本号 |
| 章节结算 | `chapter_end.gd` + `chapter_end.tscn` | ✅ 任务统计 + 存档入口 |
| 胜利 / 失败 | `result_victory.gd` / `result_defeat.gd` | ✅ |

### 5.4 主题/工具

| 文件 | 职责 |
|------|------|
| `wuxia_theme.gd` | 武侠 UI 配色常量（金/玉/钢） |
| `ui_texture_skin.gd` | 贴图皮肤工具 |
| `ui_display_art.gd` | 美术图展示组件 |
| `inventory_btn.gd` | 仓库调度台按钮组件 |

---

## 六、状态异常系统（M6）

| 类型 | kind | 效果 | skip_turn |
|------|------|------|-----------|
| 中毒 | POISON | max_hp 比例 DOT（默认 5%） | ❌ |
| 虚弱 | WEAK | 防御减半 + 伤害 -30% | ❌ |
| 爆发 | BURST | 暴击率 +50%（Buff） | ❌ |
| 眩晕 | STUN | 跳过回合 | ✅ |
| 冰冻 | FREEZE | 跳过回合 + 受击 +20% 伤害 | ✅ |

- 叠加规则：REPLACE（新覆盖旧）/ EXTEND（累加回合）
- 解除：duration 到期 / 解毒丹/破虚散等道具

---

## 七、存档系统（M7）

| 特性 | 说明 |
|------|------|
| 槽位数 | 5（slot 0-4） |
| 格式 | JSON，path=`user://save_{n}.json` |
| 版本 | v4（inventory + quests + audio_volumes + 7 项核心属性） |
| 已支持功能 | 保存/加载/元数据读取/时间戳/覆盖确认 |
| UI | SaveSlotPanel（SAVE 模式：场景内 F5/系统按钮 · LOAD 模式：主菜单继续） |

### 存档数据结构

```json
{
  "version": 4,
  "slot": 0,
  "timestamp": 1234567890,
  "chapter": 1,
  "gold": 100,
  "flags": {"flag_key": true},
  "player": { "level": 2, "hp": 85, "mp": 20, "strength": 8, ... },
  "inventory": { "slots": [...], "equipped": {...} },
  "quests": { "q_ch1_main_01_thug": "COMPLETED", ... },
  "current_field": "ch1_s1_road",
  "audio_volumes": {"master": 0.8, "bgm": 0.7, "sfx": 1.0, "ui": 0.9}
}
```

---

## 八、数据资产规模

| 类别 | 文件数 | 分布 |
|------|--------|------|
| 对话 | 30+ | 7 个场景的对话链（含教程/主线/支线） |
| 敌人 | 31 | 普通怪 16 + Boss 7 + 精英/特殊 8 |
| 技能 | 30+ | 7 流派 + 通用（普攻/毒针/重击） |
| 装备 | 100+ | 7 流派专属 + 通用（含 all 门派武学加成） |
| 物品 | 40+ | 消耗品/材料/剧情物品/品质分级 |
| 任务 | 50+ | 主线 15 + 支线 35+（覆盖 8 章） |
| 场景 | 7 | 第一章 4 场景（含双版本） |
| 商店 | 10 | 各场景商人 |
| 状态异常 | 5 | 中毒/虚弱/爆发/眩晕/冰冻 |

---

## 九、里程碑进度（Roadmap）

| M | 内容 | 时长 | 状态 |
|---|------|------|------|
| M1 | 数据驱动战斗 + EventBus + Inventory | 1.5h | ✅ **完成** |
| M2 | 探索场景 Field + 对话系统 + 战斗闭环 | 2h | ✅ **完成** |
| M3 | Quest 系统 + 主线任务 2 个 + 存档 v2 | 1.5h | ✅ **完成** |
| M4 | 多场景跳转 + NPC 对话 + 商店 | 1.5h | ✅ **完成** |
| M5 | 背包/装备 UI + 物品使用 + 6 装备槽 | 1h | ✅ **完成（验收通过 2026-07-02）** |
| M6 | 章末 Boss + 状态异常 + 音频系统 + 34 支线 | 1.5h | ✅ **完成** |
| M7 | 多槽存档 UI + 加载/继续游戏 | 1h | ✅ **完成（2026-07-03）** |

### 已完成功能闭环

```
主菜单 → Field（多场景含 shop）→ 对话/任务/战斗 
→ I 背包 · E 装备 · J 任务 · K 技能
→ F5 存档（5 槽）· 系统按钮
→ 主菜单「继续游戏」选槽加载
```

---

## 十、美术资产管线

| 组件 | 说明 | 状态 |
|------|------|------|
| ALAPI 出图 | 唯一后端 `v3.alapi.cn`（token 头） | 当前不可用返回 400 |
| `scripts/gen_assets.py` | 异步批量调图 + 预算限流 | ✅ |
| 调度台 | Web UI 管理产出（分类/采用/拒绝） | ✅ |
| 资产目录 | `raw/` → `library/` → `adopted/` → `game/art/` | ✅ |
| Tiled 场景 | `maps/tiled/` + `scripts/import_tiled_scene.py` | ✅ 工具链就绪 |
| 模块化 atlas | ground/building/veg/prop 4 类场景元素 | 待 ALAPI 恢复后出图 |

---

## 十一、测试状态

| 测试文件 | 覆盖 | 运行方式 | 状态 |
|---------|------|---------|------|
| `tests/test_inventory_m5.gd` | 消耗品使用/装备槽/序列化 | 通过 `test_inventory_m5_runner.tscn` 运行 | ✅ CLI 可运行 |
| `tests/test_scene_router_field_smart.gd` | 场景路由 | SceneTree 扩展 | ⚠️ 同上 |
| `tests/test_player_walk_animation.gd` | 行走动画 | SceneTree 扩展 | ⚠️ 同上 |
| `test/capture_ui.gd` | UI 截图对比 | headless | ⚠️ 需 GUT 框架 |

**已知问题**：所有测试脚本都继承 SceneTree 并在 `--script` 模式运行，该模式下 Godot 不加载 autoload，导致测试无法访问 GameState/Inventory 等全局单例。后续接入 GUT 框架修复。

---

## 十二、已知技术债

| 问题 | 优先级 | 说明 |
|------|--------|------|
| ALAPI 不可用 | P1 | 返回 400，需联系供应商或换后端 |
| 测试框架不工作 | P2 | 需 GUT 框架替代原 SceneTree 测试方式 |
| 对话 .tres speaker 字段 | P2 | 部分仍为旧占位"沈不归"（已批量替换但可能遗漏） |
| 美术资源缺失 | P2 | 场景背景 PNG 不存在时显示 FallbackBg |
| 战斗中使用物品 | P3 | 已在装备面板支持，战斗中未接入 |
| 第二章+内容 | P3 | 数据资产已预置 2-8 章任务/敌人/装备，场景未开发 |
| Tiled 管线待跑 | P3 | 66 个模块 PNG 需复制到 `game/art/modules/` |
