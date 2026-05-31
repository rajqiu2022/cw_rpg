# 武功内功互补系统设计

> 最后更新：2026-05-28  
> 用途：定义外功（攻击技）与内功（Buff/被动）的互补规则，以及装备对武功的加成规则。

---

## 一、核心概念

### 外功 vs 内功

| 类型 | 定义 | Kind | 示例 |
|------|------|------|------|
| **外功** | 攻击技 / Debuff 技，消耗 MP | ATTACK / DEBUFF | 华山剑法·破云、寒霜针、隐影夺命 |
| **内功** | Buff 技 / 被动技，增强属性或提供特殊效果 | BUFF | 紫霞神功、金刚力（被动）、月华引（被动） |

### 互补规则

**同门外功 + 同门内功 = 外功获得额外效果。**

玩家学会某门派的内功心法后，该门派所有外功自动获得互补加成。加成效果在战斗伤害计算时自动叠加，不需要玩家手动"激活"。

---

## 二、五派互补表

### 古峰派 — 金刚力

| 内功 | 互补外功 | 互补效果 |
|------|---------|---------|
| `gufeng_jingang_li` 金刚力 | 开山一刀、伏虎、裂地 | **power +15**（筋骨化刃：金刚力淬炼筋骨，刀势更沉） |

**设计意图**：古峰是力量型门派，互补收益是简单粗暴的伤害加成。不需要特殊条件——因为古峰的玩家不喜欢花里胡哨。

---

### 华山派 — 紫霞神功

| 内功 | 互补外功 | 互补效果 |
|------|---------|---------|
| `huashan_zixia_shengong` 紫霞神功 | 华山一剑、破云、剑断千山 | **暴击倍率 1.5x → 1.8x**（紫霞灌剑：紫霞真气灌注剑身，暴击时剑气增三成） |

**设计意图**：华山是敏捷型/暴击型门派，互补收益是暴击伤害提升。配合紫霞凝罡（+50% 暴击率），形成"高暴击率+高暴击伤害"的爆发流派。

**注意**：`skill_bonus_crit_mult = 0.3` 是乘算加成——原有 1.5x × (1 + 0.3) 还是加算 1.5 + 0.3？采用**加算** `crit_mult = 1.5 + 0.3 = 1.8`，更直观。

---

### 凌月派 — 月华引

| 内功 | 互补外功 | 互补效果 |
|------|---------|---------|
| `lingyue_yuehua_yin` 月华引 | 凌波一指、寒霜针、寒霜万针 | **power +10** + **中毒伤害 +50%**（月华淬毒：月华引将寒毒炼化，毒发时伤害倍增） |

**设计意图**：凌月是毒控型门派，核心特色是淬毒暗器。互补后中毒每回合伤害 +50%，让凌月的持续输出能力大幅提升。

---

### 茗雾山庄 — 隐影诀

| 内功 | 互补外功 | 互补效果 |
|------|---------|---------|
| `mingwu_yinying_jue` 隐影诀 | 茗雾扫风、雾隐三式、隐影夺命 | **对 HP<50% 敌人额外 +20% 伤害**（影杀：隐影诀洞悉脉门，伤者更难抵挡） |

**设计意图**：茗雾是暗杀型门派，核心特色是"收割残血"。原版隐影夺命已有"HP<30% 必暴击"，互补后将收割阈值从 30% 提升到 50% 且额外 +20% 伤害——茗雾玩家在敌人半血后就进入收割模式。

---

### 武当派 — 玄武心经

| 内功 | 互补外功 | 互补效果 |
|------|---------|---------|
| `wudang_xuanwu_xinjing` 玄武心经 | 太极初式、四象、两仪 | **受击时反射 15% 伤害**（玄武护体：玄武心经运转时，来犯之力反噬其主） |

**设计意图**：武当是防御型/反伤型门派。原有玄武格已有"防御+30% + 反射 50%"的主动技能，互补后成为被动常驻 15% 反伤——符合"以柔克刚、后发制人"的武当哲学。

---

## 三、装备武功加成

### Equipment 新增字段

| 字段 | 类型 | 说明 |
|------|------|------|
| `skill_bonus_school` | String | 增强哪个门派（"gufeng"/"huashan"/"lingyue"/"mingwu"/"wudang"/"all"），空字符串表示不增强 |
| `skill_bonus_power` | int | power 加值（如 +15） |
| `skill_bonus_crit_mult` | float | 暴击倍率加成（如 0.2 表示 +0.2x） |

### 门派招牌武器加成

| 装备 | item_id | school | power | crit_mult | 备注 |
|------|---------|--------|-------|-----------|------|
| 太极真剑 | `wudang_taiji_sword` | wudang | +15 | — | 武当镇派 |
| 松纹古剑 | `wudang_pine_sword` | wudang | +8 | — | 武当入派 |
| 华山快剑 | `huashan_sword` | huashan | +10 | — | 华山入派 |
| 紫霞剑 | `huashan_zixia_sword` | huashan | +15 | +0.2 | 华山至宝 |
| 古峰重刀 | `gufeng_blade` | gufeng | +15 | — | 古峰入派 |
| 金刚重刀 | `gufeng_diamond_blade` | gufeng | +20 | — | 古峰至宝 |
| 银月飞针 | `silver_moon_needle` | lingyue | +10 | — | 凌月暗器 |
| 寒霜镖 | `frost_dart` | lingyue | +15 | — | 凌月至宝 |
| 茗雾短匕 | `mingwu_dagger` | mingwu | +10 | — | 茗雾入派 |
| 隐锋 | `hidden_edge` | mingwu | +15 | — | 茗雾至宝 |
| 渊冥古剑 | `yuanming_sword` | all | +10 | — | 渊冥子神兵 |
| 七星龙泉剑 | `seven_star_sword` | all | +8 | — | 最强通用 |

### 加成规则

1. **同门派叠加**：武器 `skill_bonus_power` + 内功互补 `complement_bonus_power` 可以叠加
   - 如华山派装紫霞剑（+15）+ 紫霞神功互补 = 华山剑法总 power 加成 +15+专有暴击效果
2. **"all" 门派**：对所有门派技能生效，但不与同门派加成叠加（取最大值）
   - 如装渊冥古剑（all +10）打华山剑法 + 华山快剑（huashan +10），取 max(10, 10) = 10
3. **饰品也可加成**：理论上 `skill_bonus_school` 不限槽位（当前仅武器使用，预留扩展）

---

## 四、战斗层实现概要

### 互补检测流程

```
player_uses_skill(skill)
  → check: player.skills 包含 skill.complemented_by?
    → YES: 激活互补效果
      - gufeng: power_mult += complement_bonus_power/100
      - huashan: crit_multiplier = 1.5 + 0.3 (crit 时生效)
      - lingyue: power_mult += 0.10; freeze_chance *= 2
      - mingwu: if enemy.hp_ratio < 0.5: dealt *= 1.2
      - wudang: 在敌方攻击 RESOLVE 阶段 reflect = dealt * 0.15
```

### 装备加成流程

```
player_uses_skill(skill)
  → bonus = Inventory.get_equipped_skill_bonus(skill.school)
  → power_mult += bonus.power / 100
  → crit_mult += bonus.crit_mult
```

### Inventory 新增方法

```gdscript
func get_equipped_skill_bonus(school: String) -> Dictionary:
    ## 返回 {power: int, crit_mult: float}
    ## 遍历 6 个装备槽，聚合 skill_bonus_school 匹配的加成
```

---

## 五、UI 展示建议（后续迭代）

1. **技能列表**：学会内功后，互补外功的显示名旁显示 ✦ 标记和互补效果描述
2. **装备详情**：显示"增强 [门派名] 武功 +X"
3. **战斗 HUD**：使用互补技能时，技能名旁短暂显示互补特效文字（如 "紫霞灌剑！"）
