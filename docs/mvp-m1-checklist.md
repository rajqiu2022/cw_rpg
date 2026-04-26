# M1 验收清单 · 数据驱动重构

> v0.2.0-m1 完成后的手动跑测步骤。  
> 全部勾上即认为 M1 通过，可进入 M2（探索场景 + 对话系统）。

---

## 0. 启动

```
打开 Godot 4.6 编辑器
File → Open Project → 选 F:\Code\RPG_GAME\game\project.godot
```

如果是首次打开 v0.2.0 改动，Godot 会重新导入 14 个 .tres 资源。等导入条跑完再 F5。

---

## 1. 编辑器输出面板（Output Panel）静态检查

按 F5 运行游戏前，先看 **底部 Output 面板** 是否有红色 / 黄色 push_warning。

**预期**：无 `[Inventory] item not found:` 或 `[Battle] enemy not found:` 警告。  
**如有红字**：截图给我，可能是 .tres 字段名漏了 / 路径打错。

---

## 2. 主菜单

- [ ] 标题正常显示
- [ ] 版本号显示为 `v0.2.0-m1  ·  data-driven battle`
- [ ] "继续游戏" 按钮初始置灰
- [ ] 点击"开始游戏"无报错，自动跳到战斗场景

---

## 3. 战斗场景（数据驱动版）

- [ ] 敌人显示为 **"落单匪徒"**（不是 "无名匪徒"）
- [ ] 敌人头像加载正确
- [ ] 玩家显示为 **"沈不归"**（不是 "主角"）
- [ ] 战斗日志第一行：`遭遇战开始 —— 沈不归 vs 落单匪徒`
- [ ] 第二行有"装备 0/0，攻 +0 防 +0"提示
- [ ] 普通攻击按钮可用，技能按钮显示 "排云掌 (-5 MP)"
- [ ] 打 1-3 回合可击败落单匪徒（HP 60）

---

## 4. 胜利结算（**关键验证点**）

打赢后，**切到胜利场景前**注意 Godot Output 面板，应该看到类似：

```
[M1 Smoke] enemy=thug_lone gold=+18 exp=+20 slots=N weapon=(none)
    - 小还丹 × 1     # 50% 概率会出现
```

- [ ] 看到 `[M1 Smoke]` 这行 print 输出
- [ ] gold 值在 10-25 之间（与 EnemyDef 配置一致）
- [ ] exp = 20
- [ ] 50% 概率掉小还丹（多打几次可以验证）

---

## 5. 胜利场景

- [ ] 显示战利品金额和经验
- [ ] 点"返回主菜单"成功

---

## 6. 二次进入

- [ ] 主菜单"继续游戏"仍是置灰（因为没存档）
- [ ] 再点"开始游戏"再次进入战斗场景，敌人 HP 为满血（说明数据驱动每次都是新实例）

---

## 7. 一致性快查（编辑器内）

打开 FileSystem 面板浏览 `res://data/`，应当看到：

```
data/
├── characters/        (空)
├── dialogs/           (空)
├── enemies/
│   ├── bandit_mountain.tres
│   ├── boss_zhao_wuji.tres
│   └── thug_lone.tres
├── equipment/
│   ├── cloth_armor.tres
│   └── iron_sword.tres
├── items/
│   ├── chapter1_map.tres
│   ├── healing_pill_major.tres
│   ├── healing_pill_minor.tres
│   └── mana_pill.tres
├── quests/            (空)
├── scenes/            (空)
├── shops/qingfeng_merchant.tres
└── skills/
    ├── basic_attack.tres
    ├── defend.tres
    ├── heavy_swing.tres
    └── palm_strike.tres
```

双击任一 `.tres`，右侧 Inspector 应能正确显示字段（例如 `thug_lone` 的 max_hp = 60、attack = 12 等）。

如显示乱或类型不对，多半是 .tres 内字段名拼错或类型化数组语法不对，告诉我哪个文件、什么报错。

---

## 完成判定

以上 1-6 全部 ✓ → M1 通过 → 进 M2（探索场景）。
