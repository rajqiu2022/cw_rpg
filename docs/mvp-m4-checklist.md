# MVP M4 验收清单 · 多场景跳转 + NPC 对话 + 商店

> 目标：在 M3 任务系统基础上，**完整跑通"场景 1 → 场景 2 → 场景 3 → 章末战 → 主菜单"流程**，
> 含 4 个 NPC 对话、商店买卖、1 条支线任务（救丈夫）、章末 placeholder boss 战。
>
> 范围：M4 全部。M4 ✅ 后开 M5（背包/装备 UI + 物品使用）。

---

## 0. 启动前

- [ ] Godot 编辑器底部 autoload 看到 7 个全在：
      `EventBus` / `GameState` / `Inventory` / `SceneRouter` / `QuestManager` / `DialogPlayer` / `SaveManager`
- [ ] 资源浏览器里以下新建资源双击不报错：
      - `res://data/scenes/ch1_s2_qingfeng.tres`
      - `res://data/scenes/ch1_s3_west_ruin.tres`
      - `res://data/quests/q_ch1_side_01_rescue_husband.tres`
      - `res://data/dialogs/ch1_s2_*.tres`（共 4 个）
      - `res://data/dialogs/ch1_s3_*.tres`（共 3 个）
      - `res://scenes/shop.tscn`
- [ ] **删除旧存档**（避免 M3 旧 schema 干扰）：
      Windows 路径：`%APPDATA%\Godot\app_userdata\<项目名>\save_0.json`

## 1. 主菜单

- [ ] 版本字符串显示 `v0.2.0-m4 · multi-scene + npc + shop`
- [ ] 「开始新游戏」可用，「继续游戏」初始 disabled

## 2. 场景 1 出官道 → 进场景 2 自动完成 q2

- [ ] 「开始新游戏」→ 进官道 → 进场对话 → 接 q1
- [ ] 点路边尸体 → 战斗 → 击败 thug_lone → q1 自动完成
- [ ] 点「继续前行 →」→ 战后对话 3 节 → 接 q2 → 对话末尾**自动跳转场景 2**
- [ ] 进入场景 2 瞬间控制台输出：
      `[Quest] ✓ completed: q_ch1_main_02_qingfeng 「打探清风镇」 (gold +0, exp +0)`

## 3. 场景 2 · 清风镇主街（4 NPC + 2 出口）

- [ ] 场景标题：`清风镇 · 主街`
- [ ] 进场旁白播放（沈不归独白）
- [ ] 看到 4 个 NPC 互动按钮：客栈老板 / 神秘商人 / 哭泣女子 / 守城兵丁
- [ ] 看到 2 个出口按钮：
      - 「[出口] 离镇 ←」（**初始隐藏**，要打通章末才解锁）
      - 「[出口] 前往城西 →」（**初始隐藏**，需先与客栈老板对话）

### 3.1 客栈老板（主线推进）

- [ ] 点 → 对话 2-3 节 → 揭示"城西废宅最近不太平"
- [ ] 对话结束后 set_flag `rumour_west_ruin = true`
- [ ] 「[出口] 前往城西 →」按钮**立即出现**（hotspot 自动刷新）

### 3.2 神秘商人（→ 商店 UI）

- [ ] 点 → 短对话 1 节 → on_end `shop:qingfeng_merchant`
- [ ] 自动跳转到商店界面（详见第 5 章）
- [ ] 关闭商店后自动回到场景 2

### 3.3 哭泣女子（接 q3 支线）

- [ ] 点 → 对话呈现选项：「我帮你」/「莫管闲事」
- [ ] 选「我帮你」→ accept_quest `q_ch1_side_01_rescue_husband`
- [ ] 任务面板显示蓝圈 `○ 营救丈夫`
- [ ] 选「莫管闲事」→ 任务**不**接受，对话直接结束
- [ ] 重复点哭泣女子，**已接受过的不会再触发选择**（QuestManager 层防重复）

### 3.4 守城兵丁（闲聊）

- [ ] 点 → 短对话 2-3 节 → 揭示世界观（黑教 / 师门往事）
- [ ] 无副作用，反复点都能看

## 4. 场景 3 · 城西废宅（3 互动点）

- [ ] 场景 2 点「[出口] 前往城西 →」→ 进场景 3
- [ ] 场景标题：`清风镇 · 城西废宅`
- [ ] 进场旁白：旧宅阴森氛围

### 4.1 旧木箱（拾取铁剑）

- [ ] 点旧木箱 → 短对话 1 节 → give_item `iron_sword:1`
- [ ] 控制台 `[Inventory] item_picked_up: iron_sword`
- [ ] 木箱按钮**永久消失**（hide_flag `looted_west_ruin_box`）

### 4.2 被绑男子（救丈夫支线分支）

- [ ] **若未接 q3**：点被绑男子 → 短对话 1 节（"先生救命...看似不认识"）→ 无副作用
- [ ] **若已接 q3**：点被绑男子 → 对话 2 节 → 救援结束
      - set_flag `rescued_husband = true`
      - **q3 自动完成**（trigger = `flag_set:rescued_husband`），控制台输出 completed
      - 任务面板蓝圈消失
      - 给奖励 `+50 gold`（q3.reward_gold）

### 4.3 大门（章末战入口）

- [ ] 点大门 → 对话 2 节（赵无忌登场独白）→ on_end `battle:boss_zhao_wuji`
- [ ] **进入章末战**：boss_zhao_wuji（HP 200 / Atk 22）
- [ ] 战斗胜利 → 进 result_victory（M4 暂时简单收尾，章节结算 UI 留 M6）
- [ ] 「返回主菜单」回到 main_menu

## 5. 商店 UI（核心新增模块）

### 5.1 进入

- [ ] 神秘商人对话末尾自动进 shop.tscn
- [ ] 顶部显示：`清风商铺 — 客官，远道而来，看看小店有什么需要？`
- [ ] 顶部右侧显示：`金 X` 实时跟随 GameState.gold
- [ ] 底部 4 个按钮：`买入 / 卖出 / 关闭` 三个 tab，外加 `关闭`

### 5.2 买入页

- [ ] 列表显示 5 件商品：小还丹（30）/ 大还丹（90）/ 凝气丹（45）/ 粗布麻衣（30）/ 铁剑（80）
- [ ] 每行右侧「买入」按钮，金不够时禁用
- [ ] 点「买入」→ 扣金 + 加入背包 + 控制台输出 `[Shop] bought: <item_id>`
- [ ] 顶部金额实时刷新

### 5.3 卖出页

- [ ] 列表显示当前背包**所有非 KEY_ITEM** 的物品
- [ ] 显示卖价 = `sell_price`（item.sell_price，已是回收价的实际数值）
- [ ] 点「卖出」→ 扣物品 + 加金 + 控制台输出 `[Shop] sold: <item_id>`
- [ ] 装备物品（铁剑/麻衣）也能卖（卖完控制台 OK，不报错）

### 5.4 关闭

- [ ] 点「关闭」→ 回到 ch1_s2_qingfeng（用 SceneRouter.go_field 自动恢复 _current_field_id）

### 5.5 边界

- [ ] 没钱时「买入」灰掉
- [ ] 背包空时「卖出」页显示 `背包空空如也`
- [ ] 商店重复进出，金额/库存正确

## 6. 任务系统（M3 → M4 衔接）

- [ ] q2「打探清风镇」进入场景 2 那一刻自动完成
- [ ] q3「营救丈夫」选「我帮你」后进入面板
- [ ] q3 救出丈夫后自动完成 + 发奖（+50 gold）
- [ ] 进入场景 3 不会触发任何新任务（场景 3 没绑 trigger）

## 7. 存档持久化（关键：JSON 看到 quests + flags）

- [ ] 场景 2 与商店老板交易后，回 main_menu 触发存档
- [ ] 用文件管理器打开 `save_0.json`：
      ```json
      "current_field": "ch1_s2_qingfeng",
      "quests": { "q_ch1_main_01_thug": 2, "q_ch1_main_02_qingfeng": 2 },
      "flags": { "defeated_thug_lone": true, "rumour_west_ruin": true, ... }
      ```
- [ ] 退出 → 重启 → 「继续游戏」恢复到场景 2，老板已聊过、出口已解锁、金额正确

## 8. 异常路径

- [ ] 删 `data/dialogs/ch1_s2_inn_keeper.tres` 跑 → 控制台 warning，但场景 2 仍可加载
- [ ] 商店没有 `qingfeng_merchant.tres` → 控制台 warning，回到 field
- [ ] q3 选「莫管闲事」后再点哭泣女子 → 选项再次出现（这是允许的，玩家有反悔机会）
- [ ] q3 已接受/已完成后再点哭泣女子 → 不再出现选项，只播放固定致谢/默认对话

## 9. 调试器 Remote 检查（场景 2 完整跑完后）

- [ ] `/root/QuestManager.states`：q1=2, q2=2（接了支线则 q3 也存在）
- [ ] `/root/GameState.flags`：`defeated_thug_lone, rumour_west_ruin, looted_west_ruin_box, rescued_husband`（按选择）
- [ ] `/root/Inventory.slots`：含 `chapter1_map / cloth_armor / iron_sword`（如果救人就还有更多）
- [ ] `/root/SceneRouter._current_field_id` = `ch1_s2_qingfeng`（在 shop 之后回到这）

---

## 全部 ✅ 后

更新 `AGENTS.md` 改 m4，提交 git，开 M5（背包/装备 UI + 物品使用）。
