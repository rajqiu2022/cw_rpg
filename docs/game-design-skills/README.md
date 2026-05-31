# 游戏设计技能参考

> 来源：[Game Design Skill for Claude Code](https://gist.github.com/OrangeViolin/53ad898cdbc8734d8bb5c6a6ddf5cec4)
> 基于《游戏设计的100个原理》（100 Principles of Game Design）
> 下载日期：2026-05-08

## 技能列表

### 第一批（v0.1 · 2026-05-08）— 基于《游戏设计的100个原理》

| 文件 | 内容 | 对应项目阶段 |
|------|------|-------------|
| [dynamic-difficulty-adjustment.md](dynamic-difficulty-adjustment.md) | 动态难度调整（巴斯特原则） | M6 章末 Boss |
| [character-optimization-design.md](character-optimization-design.md) | 角色优化与缓解设计 | 属性系统（筋骨/机敏/内劲/悟性） |
| [flow-state-design-framework.md](flow-state-design-framework.md) | 心流状态设计框架 | 5-8 分钟 MVP 节奏 |
| [experience-pacing-structure.md](experience-pacing-structure.md) | 体验节奏与结构 | 第一章叙事节奏 |
| [environmental-storytelling-technique.md](environmental-storytelling-technique.md) | 环境叙事技术 | 竹尾村/茗雾山庄场景 |
| [doubling-halving-balance.md](doubling-halving-balance.md) | 加倍减半平衡方法 | 战斗数值快速平衡 |
| [reinforcement-feedback-systems.md](reinforcement-feedback-systems.md) | 强化与反馈系统 | 战斗奖励/任务反馈循环 |

### 第二批（v0.2 · 2026-05-24）— 基于 Gazaway、Totten、Annander 专著

| 文件 | 内容 | 来源 | 对应项目阶段 |
|------|------|------|-------------|
| [rpg-spreadsheet-balance-workflow.md](rpg-spreadsheet-balance-workflow.md) | RPG 数值建模工作流（标准人+六步法） | Gazaway §5-14 | M6 战斗公式 / 全章数值规划 |
| [quest-design-framework.md](quest-design-framework.md) | 任务系统设计框架（拓扑+五步法+心向累积） | Totten §4 + 行业实践 | 第二章起全局任务网络 |
| [2d-level-spatial-design.md](2d-level-spatial-design.md) | 2D 探索型关卡空间结构设计（建筑学方法） | Totten §1-5 | 场景布局审核 / 新场景设计 |
| [rpg-combat-formula-handbook.md](rpg-combat-formula-handbook.md) | RPG 战斗公式设计手册（三族公式+验证清单） | Gazaway §9-14 + 行业实践 | M6 战斗公式层 |
| [growth-curve-level-planning.md](growth-curve-level-planning.md) | 成长曲线与等级规划（五步法+品质分层） | Gazaway §13-17 + 行业实践 | 全章数值规划 / 装备系统设计 |

## 使用方式

1. **开发前**：根据当前 milestone 阅读对应技能文件
2. **开发中**：参照"对本项目的应用"章节指导实现
3. **测试时**：用加倍减半法快速调参，用心流框架评估体验

## 优先级映射

```
M6（章末 Boss + 战斗公式）:
  → rpg-combat-formula-handbook.md（公式选定 + 边界验证）
  → rpg-spreadsheet-balance-workflow.md（Excel 模拟 + 标准人校验）
  → doubling-halving-balance.md（Boss 数值极端测试）
  → dynamic-difficulty-adjustment.md（Boss 难度自适应）
  → reinforcement-feedback-systems.md（Boss 奖励设计）

M7（存档系统 + 任务网络）:
  → quest-design-framework.md（全章任务拓扑规划）
  → experience-pacing-structure.md（存档点位置）
  → flow-state-design-framework.md（存档不打断心流）

第二章起（新场景 + 新任务 + 装备扩展）:
  → 2d-level-spatial-design.md（场景布局设计）
  → quest-design-framework.md（任务网络设计）
  → growth-curve-level-planning.md（装备品质分层 + 投放节奏）

全程通用:
  → environmental-storytelling-technique.md（场景叙事参考）
  → flow-state-design-framework.md（整体节奏把控）
  → character-optimization-design.md（属性设计哲学）
```
