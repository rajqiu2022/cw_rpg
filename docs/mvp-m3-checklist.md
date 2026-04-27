# MVP M3 验收清单 · Quest 系统 + 主线任务 1

> 目标：在 M2 完整闭环基础上，**任务自动接受/推进/完成 + UI 显示当前任务 + 任务奖励发放 + 存档持久化**。
>
> 范围：M3 全部。M3 ✅ 后开 M4（多场景 + NPC + 商店）。

---

## 0. 启动前

- [ ] Godot 编辑器底部 autoload 看到 7 个全在：
      `EventBus` / `GameState` / `Inventory` / `SceneRouter` / **`QuestManager`** / `DialogPlayer` / `SaveManager`
- [ ] 资源浏览器看 `res://data/quests/q_ch1_main_01_thug.tres` 和 `q_ch1_main_02_qingfeng.tres` 双击不报错
- [ ] **删除旧存档**（避免 M2 旧 schema 干扰）：
      Windows 路径：`%APPDATA%\Godot\app_userdata\<项目名>\save_0.json`

## 1. 主菜单

- [ ] 版本字符串显示 `v0.2.0-m3 · quest system`
- [ ] 「开始新游戏」可用，「继续游戏」初始 disabled

## 2. 进场对话 → 自动接 q1

- [ ] 「开始新游戏」→ 进官道，进场对话依次播放 3 节
- [ ] 第 3 节（旁白「点击发光按钮可以探查」）结束时，控制台输出：
      `[Quest] ▶ accepted: q_ch1_main_01_thug 「风波再起」`
- [ ] 对话结束 → 右下角 **任务面板** 显示：
      ```
      ▶ 当前任务
      ● 风波再起
        击退埋伏在路边的黑教徒。
      ```

## 3. 任务面板 UI

- [ ] 右下角任务面板半透明黑底，标题 `▶ 当前任务`，金色字
- [ ] 主线任务用 **橙点 ●** 标识（侧线任务用蓝圆圈，本期没有）
- [ ] HUD 右侧有「任务 (J)」按钮 → 点击 / 按 J 键 切换面板可见性
- [ ] 没有任务时面板显示 `暂无任务`（M3 玩家不应见到此状态，除非按 J 隐藏）

## 4. 战斗胜利 → 自动完成 q1（核心闭环）

- [ ] 点 `路边尸体` → 看 2 节对话 → 自动进战斗
- [ ] 击败 thug_lone → 战斗 `_end_battle(true)` 里 emit `enemy_defeated:thug_lone`
- [ ] **QuestManager 立即匹配 q1 的 trigger** → 控制台输出：
      `[Quest] ✓ completed: q_ch1_main_01_thug 「风波再起」 (gold +12, exp +10)`
- [ ] 胜利场景奖励：战斗本身 gold/exp + **任务奖励 +12 金 +10 exp**
- [ ] 「继续」回官道 → 任务面板显示 `暂无任务`（q1 已 completed，q2 未接）

## 5. 战后剧情 → 自动接 q2

- [ ] 点「继续前行 →」→ 战后对话依次播放 3 节
- [ ] 第 2 节（沈不归独白「先入城打听消息」）结束时控制台输出：
      `[Quest] ▶ accepted: q_ch1_main_02_qingfeng 「打探清风镇」`
- [ ] 对话结束 → 任务面板显示：
      ```
      ▶ 当前任务
      ● 打探清风镇
        进入清风镇，向当地人打听黑教的消息。
      ```

> q2 的完成条件是 `scene_entered:ch1_s2_qingfeng`，M4 做完场景 2 后会自动完成；M3 阶段它会一直留在面板上。

## 6. 存档持久化（核心：JSON 里能看到 quests 字段）

- [ ] 战斗胜利后在胜利页点 **存档** 按钮
- [ ] 用文件管理器打开 `%APPDATA%\Godot\app_userdata\<项目名>\save_0.json`
- [ ] JSON 里能看到（关键字段，version=2）：
      ```json
      "version": 2,
      "current_field": "ch1_s1_road",
      "quests": {
        "q_ch1_main_01_thug": 2
      }
      ```
      （状态枚举：0=NOT_STARTED, 1=IN_PROGRESS, 2=COMPLETED, 3=FAILED）
- [ ] 退出游戏 → 重启 → 主菜单点「继续游戏」
- [ ] 自动回到 `ch1_s1_road`，**之前打过的尸体按钮仍然不可见**，q1 已完成

## 7. 异常路径

- [ ] 同一任务**不会**被重复接受（控制台不会出现两次 `▶ accepted`）
- [ ] 任务进行中再次触发 trigger 不会重复完成
- [ ] 删 `q_ch1_main_01_thug.tres` 跑游戏 → 控制台 `[QuestManager] quest .tres not found: ...`，但游戏不崩

## 8. 调试器 Remote 检查

战斗胜利后在 Godot 顶部 `Debugger → Remote` 选中根节点：

- [ ] `/root/QuestManager.states` = `{q_ch1_main_01_thug: 2}`
- [ ] `/root/GameState.flags["defeated_thug_lone"]` = true
- [ ] `/root/Inventory.slots` 不空（M2 战利品）

---

## 全部 ✅ 后

更新 `AGENTS.md` 改 m3，提交 git，开 M4（多场景 + NPC + 商店）。
