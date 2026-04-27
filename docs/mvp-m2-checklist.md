# MVP M2 验收清单 · 探索场景 + 对话 + 战斗闭环

> 目标：在 Godot 4.6 编辑器里跑通"主菜单 → 官道 → 看碑/查尸 → 战斗 → 胜利 → 回官道 → 继续前行"完整闭环。
>
> 范围：M2 全部子任务（M2.0 ~ M2.4）。
>
> 按勾选顺序逐项手动验证，全部 ✅ 后即可开始 M3。

---

## 0. 启动前

- [ ] Godot 编辑器中打开 `game/project.godot`，确认下方 5 个 autoload 全在：
      `EventBus`、`GameState`、`Inventory`、`SceneRouter`、`DialogPlayer`、`SaveManager`
- [ ] 编辑器底部「输出」/「调试器」栏不存在 **红字** 错误（黄字 warning 可暂忽略）
- [ ] 资源浏览器看 `res://data/scenes/ch1_s1_road.tres`、`res://data/dialogs/ch1_road_intro.tres` 等文件，**双击不报错**

## 1. 主菜单

- [ ] 主菜单标题为「沈不归 · 第一章」，副标题/版本含 `v0.2.0-m2`
- [ ] 「开始新游戏」按钮可用；「继续游戏」根据有无存档自动 enable/disable
- [ ] 点击「开始新游戏」 → 切到「**清风镇外 · 官道**」场景（不是直接进战斗）

## 2. 进场对话（ch1_road_intro）

- [ ] 自动弹出对话框，第一句旁白：`五年了。 线索断在清风镇。`
- [ ] 第二句切换到「沈不归」立绘 + 名字
- [ ] 最后一句旁白提示「点击发光按钮可以探查」
- [ ] 对话结束后 **自动消失**，HUD 显示「金 0」 和 场景标题

## 3. 互动热点显示

进场后场景上应出现 **2** 个按钮（"继续前行"暂时被 require_flag 锁住）：

- [ ] `查看石碑`（左侧偏下）
- [ ] `路边尸体`（中下）
- [ ] **不应该** 出现 `继续前行 →` 按钮

## 4. 石碑对话（ch1_stone_inscription）

- [ ] 点 `查看石碑` → 第一句描述「清风镇 十里 / 莫问黑教」
- [ ] 第二句沈不归独白
- [ ] 对话结束 → 回到场景，按钮们仍是原来的 2 个
- [ ] 调试器输出无新红字

## 5. 尸体调查 + 战斗 + 胜利回流（M2 核心闭环）

- [ ] 点 `路边尸体` → 看到尸体描述
- [ ] 第二句变成「沈不归 · 警觉」
- [ ] 对话结束 → **自动切到战斗场景**（敌人："独行黑教徒"）
- [ ] 用「普通攻击」或「掌击」杀掉敌人 → 胜利场景，奖励金币 + 经验
- [ ] 胜利场景按 `继续` → **自动回到「清风镇外 · 官道」场景**（不是主菜单）
- [ ] 背景 + 场景标题正常显示，HUD 金币是初始值 + 战斗掉落值

## 6. 战后场景状态变化（hide_flag / require_flag）

回到官道后：

- [ ] `路边尸体` 按钮 **已消失**（`hide_flag = defeated_thug_lone` 起作用）
- [ ] `查看石碑` 按钮仍在（不受影响）
- [ ] **新出现** `继续前行 →` 按钮（`require_flag = defeated_thug_lone` 起作用）

## 7. 战后剧情对话（ch1_road_after_thug）

- [ ] 点 `继续前行 →` → 弹出第一句旁白「在尸体身上你寻得一张地图…」
- [ ] HUD 金币 **+8**（give_gold）
- [ ] 第二句沈不归独白
- [ ] 第三句旁白「M2 演示版到此结束」
- [ ] 对话结束 → 留在官道（M4 后这里会跳清风镇）

## 8. Inventory 状态（按 F8 调试器或在 Godot 编辑器 Remote 检查）

战斗胜利 + 战后对话结束后：

- [ ] `Inventory.has_item("chapter1_map")` == true（来自 ch1_road_after_thug）
- [ ] `Inventory.has_item("cloth_armor")` == true（来自 ch1_road_after_thug）
- [ ] `GameState.flags["saw_stone_warning"]` == true（如点过石碑）
- [ ] `GameState.flags["defeated_thug_lone"]` == true
- [ ] `GameState.flags["looted_thug_corpse"]` == true
- [ ] `GameState.flags["ready_to_qingfeng"]` == true

> 在 Godot **运行中** → 顶部 `Debugger` → `Remote` 选中根节点 → 找到 autoload 的属性面板查看。
> 也可以在 `field_controller.gd` 临时加一行 `print(GameState.flags)` 验证。

## 9. 异常路径

- [ ] 在对话进行中点其他热点按钮 → 不响应（DialogPlayer.is_playing() 拦截）
- [ ] 如果通过 hack 让 `defeated_thug_lone` 为 true 后再启动游戏 → 进场就能看到「继续前行」按钮，看不到尸体

---

## 全部 ✅ 后

更新 `AGENTS.md` 把状态改成 v0.2.0-m2，提交 git，推 GitHub，开始 M3（Quest 系统）。
