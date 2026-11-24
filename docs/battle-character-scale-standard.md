# 战斗角色资源标准 v1

战斗角色不再按肉眼猜大小，统一以主角 `battle_lengguyun_ready_v2.png` 为基准。

## 基准

- 单帧画布：`512 x 512` PNG，透明背景。
- 主角运行缩放：`0.48`。
- 站立脚底必须落在画布底部安全区内，头顶、武器、衣摆不得裁切。
- 普通敌人默认使用主角同一运行缩放；`EnemyDef.battle_actor_scale` 默认 `1.0`。
- Boss 只允许通过 `battle_actor_scale` 放大，建议 `1.05 - 1.15`，禁止直接改场景节点比例。
- 动作帧必须来自同一角色、同一服装和同一朝向：待机、攻击、受击、倒地至少各一帧。
- 敌方战斗姿态默认面向左，玩家姿态默认面向右；实际接触目标后才播放攻击帧。

## 命名与配置

资源放在 `game/art/sprites/battle/`，按角色独立命名，例如：

```text
zhuwei_bandit_dao_idle_v1.png
zhuwei_bandit_dao_windup_v1.png
zhuwei_bandit_dao_attack_v1.png
zhuwei_bandit_dao_recover_v1.png
zhuwei_bandit_dao_hit_v1.png
zhuwei_bandit_dao_defeat_v1.png
```

敌人 `.tres` 中的 `battle_actor_path` 只指向本角色待机帧，`attack_frame_paths`、`hit_frame_paths`、`defeat_frame_paths` 只能引用同一角色前缀的资源。缺帧时允许使用短暂的运行时后撤补间，但不允许复用其他 NPC 的动作图。

## 头像

非关键村民和路人不单独消耗关键立绘，使用 `game/art/characters/portraits/generic/` 下的通用头像；任务、Boss、主要剧情人物继续在场景数据中显式填写 `portrait_path`。
