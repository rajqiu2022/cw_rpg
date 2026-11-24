# 高级随机编队与普通攻击兵器特效（2026-09-12）

## 结果

- 第五至八章7个高风险随机战区域与雁门关统一配置1、2、3名敌人的编队池，权重为`2 / 5 / 2`：单敌约22%，双敌约56%，三敌约22%。
- `SceneScript.encounter_allow_full_group_for_solo`只在这些高级区域开启。独行玩家在高级区域也可能遭遇完整三敌；未开启该字段的普通/前期区域继续把固定三敌压到双敌，保留上手保护。
- 普通攻击按当前武器动态选择剑、刀、棍、拳掌、暗器五套独立四帧命中特效。命名武学的原有特效、伤害公式、命中率和内力消耗均未改动。
- 敌方若没有装备记录，会从其第一门带兵器契约的招式推断普通攻击类型；完全没有兵器线索时才回退为拳掌冲击。

## 运行资源

| 类型 | 动画ID | 运行图集 | 视觉语义 |
|---|---|---|---|
| 剑 | `basic_sword` | `game/art/battle_vfx/basic_weapon_v1/vfx_basic_sword_4frame_v1.png` | 银蓝细剑痕、短促金属触点 |
| 刀 | `basic_blade` | `game/art/battle_vfx/basic_weapon_v1/vfx_basic_blade_4frame_v1.png` | 厚重暖白刀弧、重斩火星 |
| 棍 | `basic_staff` | `game/art/battle_vfx/basic_weapon_v1/vfx_basic_staff_4frame_v1.png` | 木棍钝击风痕、木屑和尘土 |
| 拳掌 | `basic_palm` | `game/art/battle_vfx/basic_weapon_v1/vfx_basic_palm_4frame_v1.png` | 近身气压、冲击环，无掌形符号 |
| 暗器 | `basic_hidden` | `game/art/battle_vfx/basic_weapon_v1/vfx_basic_hidden_4frame_v1.png` | 银针细轨迹、针尖命中火星 |

原图与生成记录位于`assets/raw/battle_vfx/basic_weapon_v1/`。全部为1254×1254 RGBA、2×2时间顺序四帧，透明背景，运行时按627×627单帧切分。

## 最终生成提示词

使用Codex内置图像生成，没有调用外部CLI或ALAPI。五张图共用约束：`2×2 chronological four-frame sprite sheet; exact equal cells; transparent RGBA; no text, watermark, character, hand, weapon body or decorative border; restrained low-magic contact effect; ordinary attack intensity clearly below named martial arts; no cross-cell leakage`。

- 剑：`thin silver-blue sword glint → short diagonal slash → compact metal contact spark → rapid fading motes`。
- 刀：`thicker warm-white dao crescent → heavy amber slash → compact metal impact spark → fast fade`。
- 棍：`tan staff motion streak → broad blunt ochre sweep → wood-chip and dust impact → settling dust`。
- 拳掌：`compact physical pressure → small impact ring → warm close-range burst → fading dust; no palm glyph, rune or projectile`。
- 暗器：`tiny silver dart/needle streak → crossed fine trails → pinpoint impact spark → sparse fading motes`。

## 验证

- Godot 4.6.2严格编辑器导入：exit 0，五张新图完成导入。
- `test_high_encounter_basic_vfx_20260912.gd`：89项检查0失败；覆盖8区1/2/3编队、权重关系、单人高级区三敌保留、普通区单人保护、五类映射、敌方棍系推断、资源存在及图集哈希不复用。
- `test_party_encounter_pacing_batch_20260909.gd`：430项0失败；后期正式编队与1/2/3人基线继续通过。测试退出保留既有ObjectDB/资源清理告警。
- `test_encounter_rebalance_mine_batch_20260909.gd`：108项0失败；前期及矿区原有随机战约束未被高级区规则污染。

## 范围

本批只更新Godot工程与源资源，未重新构建Web/微信导出包。三敌高压战提高行动经济压力，允许撤离和提前探索；真人游玩后的消耗品经济与第五至八章逐章数值仍应继续校准。
