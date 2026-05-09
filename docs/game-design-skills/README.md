# 游戏设计技能参考

> 来源：[Game Design Skill for Claude Code](https://gist.github.com/OrangeViolin/53ad898cdbc8734d8bb5c6a6ddf5cec4)
> 基于《游戏设计的100个原理》（100 Principles of Game Design）
> 下载日期：2026-05-08

## 技能列表

| 文件 | 内容 | 对应项目阶段 |
|------|------|-------------|
| [dynamic-difficulty-adjustment.md](dynamic-difficulty-adjustment.md) | 动态难度调整（巴斯特原则） | M6 章末 Boss |
| [character-optimization-design.md](character-optimization-design.md) | 角色优化与缓解设计 | 属性系统（筋骨/机敏/内劲/悟性） |
| [flow-state-design-framework.md](flow-state-design-framework.md) | 心流状态设计框架 | 5-8 分钟 MVP 节奏 |
| [experience-pacing-structure.md](experience-pacing-structure.md) | 体验节奏与结构 | 第一章叙事节奏 |
| [environmental-storytelling-technique.md](environmental-storytelling-technique.md) | 环境叙事技术 | 竹尾村/茗雾山庄场景 |
| [doubling-halving-balance.md](doubling-halving-balance.md) | 加倍减半平衡方法 | 战斗数值快速平衡 |
| [reinforcement-feedback-systems.md](reinforcement-feedback-systems.md) | 强化与反馈系统 | 战斗奖励/任务反馈循环 |

## 使用方式

1. **开发前**：根据当前 milestone 阅读对应技能文件
2. **开发中**：参照"对本项目的应用"章节指导实现
3. **测试时**：用加倍减半法快速调参，用心流框架评估体验

## 优先级映射

```
M6（章末 Boss）:
  → dynamic-difficulty-adjustment.md（Boss 难度自适应）
  → doubling-halving-balance.md（Boss 数值平衡）
  → character-optimization-design.md（属性系统影响战斗）
  → reinforcement-feedback-systems.md（Boss 奖励设计）

M7（存档系统）:
  → experience-pacing-structure.md（存档点位置）
  → flow-state-design-framework.md（存档不打断心流）

全程通用:
  → environmental-storytelling-technique.md（场景设计参考）
  → flow-state-design-framework.md（整体节奏把控）
```
