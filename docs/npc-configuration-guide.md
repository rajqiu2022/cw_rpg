# NPC、对话与敌人配置指南

这份指南给剧情、关卡和美术资源新增提供统一入口。完整自动盘点结果见
`docs/npc-roster-and-asset-audit-v1.md`，不要手改那份生成报告。

## 四层配置

| 目标 | 配置位置 | 负责内容 |
| --- | --- | --- |
| 场景内出现的位置 | `game/data/scenes/<scene>.tres` 的 `npcs` | NPC ID、名字、坐标、精灵图、对话 ID、缩放、出现/隐藏条件 |
| 跨场景身份默认值 | `game/data/npcs/npc_catalog.tres` | 同一 NPC 的默认精灵图、默认对话、行为类型、角色类型 |
| 对话和任务副作用 | `game/data/dialogs/<dialog_id>.tres` | 台词、选项、接取/完成任务、给道具、触发战斗或切场景 |
| 敌人与战斗动作 | `game/data/enemies/<enemy_id>.tres` | 战斗本体、攻击/受击/倒地帧、数值、掉落、技能和音效接口 |

## 查询方法

```powershell
# 生成全部 NPC、对话关联、资源缺口和敌人动作缺口
python scripts/audit_npc_resources.py --write-report

# 查某个 NPC 在哪些场景出现，以及使用哪段对话
rg -n '"npc_id": "<npc_id>"' game/data/scenes

# 查某段对话被谁使用
rg -n '"dialog_id": "<dialog_id>"' game/data/scenes

# 查某个敌人在哪些剧情中被触发
rg -n 'battle:<enemy_id>' game/data/scenes game/data/dialogs
```

## 对话行为约定

- 所有巡逻 NPC 必须通过 `NPCNode.begin_conversation(player_global_position)` 进入交谈状态：停止巡逻、切换到待机条并面向主角。
- 对话结束统一由场景控制器调用 `NPCNode.end_conversation()`，恢复巡逻。不要在某一段对白里单独暂停计时器，否则切场景或异常结束时容易留下冻结状态。
- 场景配置的 `portrait_path`、人物目录的 `portrait_path` 和该 NPC 本人对白节点中的 `portrait_path` 必须表达同一年龄、性别、衣着和身份。重要角色使用独立头像；通用头像只允许普通男女老少路人复用。
- 接入或修改 NPC 后运行 `python scripts/audit_npc_resources.py --write-report`。报告中的 `dialog-portrait-mismatch` 必须清零；`identity-reuse` 和 `generic portrait review` 需逐项人工判断，不得把不同身份的角色仅因服装相近而复用。

## 场景 NPC 最小模板

```gdscript
{
  "npc_id": "zhuwei_gate_guard",
  "npc_name": "村口守卫",
  "pos": Vector2(0.90, 0.60),
  "sprite_path": "res://art/characters/npc_zhuwei_gate_guard_idle_down_25d_4f_v2_runtime.png",
  "dialog_id": "ch1_s2_guard",
  "scale": 0.95,
  "movement_mode": "idle"
}
```

`npc_id` 是稳定标识，不能为了改文案改掉；同一人物的剧情前后状态可共享
同一精灵图，但不同身份不得复用同一角色图。

## 资源验收标准

- 站立/坐姿 NPC：独立 `640x160` 四帧透明条带，每帧 `160x160`；必须完整露出脚部。
- Field 全身精灵的头顶、双脚和随身物件必须完整入画，脚底下方至少保留 6px 透明安全区。人工审图通过后在场景配置写入 `"sprite_quality": "full_body_reviewed"`；同一场景的不同身份 NPC 不得复用同一条精灵资源。
- 巡逻 NPC：在待机条带外，额外提供独立行走条带。
- 敌人：独立战斗本体、至少 3 张攻击帧、1 张受击帧；Boss 还应有倒地帧。
- 场景精灵图不得使用 `battle_*.png` 静态战斗图；敌人也不得借用其他敌人的攻击帧。
- 每次接入后运行 Godot headless 解析和 `scripts/audit_npc_resources.py --write-report`。

## 当前生产顺序

1. 第一章任务 NPC：废宅守卫、被缚村民、村口守卫、武馆教头、客栈角色。
2. 第一章战斗敌人：江湖散兵、竹尾山贼、武馆弟子、野兽、赵无忌。
3. 第二、三章的守村人、猎户、林中剑客、大会执事、考校官及其对应敌人。
4. 后续章节敌人按首次出现的主线战斗顺序补齐，不用“通用刺客图”充数。

## 2026-08-07 林西村样板场景

- `linxi_village_center`：6 名独立 NPC，作为普通单屏村落的最低生活密度参考。
- `linxi_village_scrollmap`：11 名独立 NPC，作为原生滚动地图的配置样板；场景背景为 `3388x1614`，不得在运行时放大。
- 两个场景中的活动 NPC 都必须使用独立 `npc_id`、独立 `sprite_path` 和明确 `dialog_id`。巡逻角色还需配置可循环的行走条带，不能让待机图平移。
- 新增 NPC 时应同时补全身份与所处区域的合理性。例如武器架旁使用乡勇教头而不是木匠，药圃附近使用药师、采药人或学徒，避免图像身份和对白身份不一致。
