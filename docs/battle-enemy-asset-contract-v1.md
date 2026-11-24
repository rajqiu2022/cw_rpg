# 敌人战斗资源规范 V1

## 目标

每个可战斗敌人都必须以自身的身份、武器和朝向出现。战斗视图不得把甲敌人的攻击帧套到乙敌人身上，也不得把角色立绘当作战斗单位使用。

## 一个敌人 ID 的最小资源合同

`game/data/enemies/<enemy_id>.tres` 必须维护以下字段：

| 字段 | 要求 |
| --- | --- |
| `battle_actor_path` | 透明背景、全身待机战斗精灵；脚底完整；单人单 ID。 |
| `battle_actor_scale` | 以 1.0 作为标准成人高度；普通人只允许在 `0.78-0.92` 内微调。 |
| `battle_actor_flip_h` | 敌人位于右侧时应面向左；源图若面向右必须设为 `true`。 |
| `attack_frame_paths` | 同一角色、同一服装、同一武器的 3 帧攻击序列；按预备、接触、收势排序。 |
| `hit_frame_paths` | 同一角色的受击帧；可先使用短暂受击姿态，但不得使用其他 ID。 |
| `defeat_frame_paths` | 同一角色的倒地或退场帧。 |
| 音效路径 | `ready / attack / hit / defeat` 均保留独立接口；资源缺失时允许静默，但不允许改用错误角色音效。 |

## 帧与画布标准

- 运行时画布：`768 x 768` PNG，透明背景，角色完整落在安全区内。
- 攻击源姿态：默认面向右；右侧敌人运行时由 `BattleActor` 镜像到左。
- 三帧节奏：`0.11s / 帧`，第 2 帧必须是有效接触帧；角色先移动到目标近旁，再播放第 1 帧。
- 待机、攻击、受击的衣饰、发型、武器、比例和光源必须一致。
- 禁止：对话立绘、带场景背景的图、黑底未抠图、静态 PNG 平移冒充攻击、跨 ID 复用攻击帧。

## 当前接入审计

| 敌人 ID | 待机 | 专属攻击 | 朝向 | 状态 |
| --- | --- | --- | --- | --- |
| `thug_lone` | `battle_thug_lone_v2` | `thug_lone_dao_attack_f01..03` | 已镜像到左 | 已接入 |
| `bandit_mountain` | 刀客待机 | `bandit_mountain_dao_attack_f01..03` | 已镜像到左 | 已接入 |
| `masked_killer_ambush` | `battle_masked_killer_boss_v2` | `masked_killer_boss_attack_f01..03_v2` | 源图面向左 | 已接入 |
| `masked_killer_leader` | `battle_masked_killer_leader_v1` | `masked_killer_leader_attack_f01..03` | 待复审源图方向 | 待统一校验 |
| `linxi_dojo_disciple` / `linxi_dojo_senior` | 杖法待机 | 缺少同一弟子动作帧 | - | 禁止新增战斗复用 |
| `linxi_wild_beast` | 野狼待机 | 缺少野狼咬击帧 | - | 待补 |
| `zhuwei_bandit` / `wudang_disciple` / 后续敌人 | 已有或缺待机不一 | 多数缺专属动作帧 | - | 待按 ID 量产 |

## 接入门槛

1. 先对比待机图与三帧攻击图，确认身份一致，再更新 `.tres`。
2. 右侧敌人必须在实机中截一次待机和攻击截图，确认都面向玩家。
3. 攻击接触点必须在目标前方，禁止在原地播放或穿越目标。
4. 资源未验收时保持短距离身体攻击兜底，并在数据审计中列为“待补”；不得指向其他敌人的帧。
