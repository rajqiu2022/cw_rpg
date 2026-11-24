# 战斗持械手与动作朝向修复 · 2026-09-10

## 修改

- 冷孤云剑、刀源图备战左手、攻击右手，确认为原图错误。本批使用 Codex 内置 ImageGen 各重做一张 4×5 母图，全程固定解剖学右手持械，左手空闲；没有使用整图镜像假装修复持械手。
- 新运行路径为 `game/art/sprites/battle/weapon_variants_v4/lengguyun/sword|dao`。其余棍、掌、暗器保留 v3。每类五状态各4帧、512×384 RGBA、ready 身高300px、底部12px，生成原图、去色版、SHA256和元数据保存于 `assets/raw/sprite/battle/weapon_direction_20260910/`。
- `BattleSpriteFacing` 将朝向归属到每张源图。高阶武馆弟子/乡勇教头共用的 `dojo_senior` 四张hit源图为朝右，其他状态朝左；`dojo_disciple` hit第1帧朝右，第2～4帧朝左。运行时逐帧纠正，避免切换状态后倒向反转。
- `BattleActor` 的ready、move、attack、hit、defeat统一走逐帧朝向；受击朝向与位移依据实际攻击来源，移除“屏幕左半/右半”判断。穿插后攻击者位于身后时会对应改变反应方向；持续伤害没有来源时从正常面向反向轻退。单体、群体和反伤路径均传入来源。
- 修正旧单挑视图把所有敌人源图都声明为朝左的配置；敌人使用朝右源图时与编队表现一致。

## 检查范围

从现役 EnemyDef、Companion 与五类主角加载根提取21个动作源目录，生成奇数帧和偶数帧接触表并目检。部分目录只提供ready，其余状态来自另一个版本，空格并不表示运行时缺帧。检查包含攻向、准备/移动/出手的一致性与受击受力方向；本批只重绘存在明确换手问题的主角剑、刀。

源图接触表与新资源五状态GIF位于 `assets/previews/sprite/battle_direction_20260910/`。`battle_ready.png`、`battle_hit.png`为Godot实际BattleActor组件渲染证据，非整场战斗录像。

## 验证

- Godot 4.6.2 导入和脚本解析通过。
- `validate_battle_direction_20260910.gd` 通过：两角色同在屏幕左半仍向正确方向退；背后来源反转；受击结束回到原位和正常方向；教头混向纠正；40张新武器资源规格。
- `validate_player_weapon_sprite_variants_v2.gd`通过，已更新检查新剑/刀根。
- `validate_battle_sprite_sets.gd`通过（退出时存在该旧脚本资源泄漏警告）。
- 旧 `validate_party_battle_feedback_20260814.gd` 因不存在的 `ALLY_SLOTS/ENEMY_SLOTS` 无法解析，未算通过。
- 旧 `validate_battle_damage_paths.tscn` 10项中2项不符，四路径数值为37/37/37/38，另有状态期望不符；本批没有修改伤害/状态结算，不将该测试计作通过。

后续新增动作图应声明真实源图朝向，并把例外精确到帧；不能再次用敌我阵营推断源图朝向，也不能以单张正面静态图证明整套动作持械一致。
