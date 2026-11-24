# 正式美术资源生产台账 v1

> 目标：替换所有兜底图、测试音频、临时 UI、候选角色图和占位特效。  
> 模型：GPT Image 2。原图、prompt、模型、成本和采用状态必须可追溯。

## 1. “正式资源”门槛

## 1.1 2026-07-15 接入审计

- 当前可直接引用的正式 PNG 路径已完成存在性检查；未发现代码或数据引用了不存在的 `res://art/` 文件。
- 第二至第四章仍缺独立正式背景、关键 NPC 立绘、证据物件和战斗特效，当前场景暂复用已通过的竹尾/密林背景。这些复用资源不标记为新章节正式资产。
- 本次会话没有可调用的内置图像生成工具入口，因此没有用程序绘图或占位图冒充 GPT Image 2 正式资源；待生成工具可用后按 A4-A6 批次补图并保留 meta.json。

### 本次采用（GPT Image 2 / ALAPI）

| 任务 | 原图与元数据 | 游戏接入路径 | 结果 |
|---|---|---|---|
| `ch3_bg_wulin_assembly_v1` | `assets/raw/scene_background/ch3/` | `game/art/backgrounds/bg_ch3_wulin_assembly.png` | adopted |
| `ch3_bg_trial_ground_v1` | `assets/raw/scene_background/ch3/` | `game/art/backgrounds/bg_ch3_trial_ground.png` | adopted |
| `ch4_bg_luoyang_yamen_v1` | `assets/raw/scene_background/ch4/` | `game/art/backgrounds/bg_ch4_luoyang_yamen.png` | adopted |
| `ch4_bg_ancient_temple_v1` | `assets/raw/scene_background/ch4/` | `game/art/backgrounds/bg_ch4_ancient_temple.png` | adopted |

### 1.2 2026-07-20 系统 UI 与战斗特效批次

- 使用“概念图 -> 技术拆解 -> 独立可运行资产”的流程，避免将模型生成的整页界面当作不可交互的假 UI。
- 新系统底图均无文字；Godot 继续负责中文、数值、动态列表和按钮事件。
- 七个战斗特效均为严格 2x2 四帧图集，先保留洋红底原图，再抠图为带 alpha 的运行时 PNG。

| 任务组 | 原图与元数据 | 游戏接入路径 | 结果 |
|---|---|---|---|
| `ui_*_panel_formal_v1` x5 | `assets/raw/ui/system/` | `game/art/ui/system/` | adopted |
| `vfx_*_4frame_v1` x7 | `assets/raw/battle_vfx/common/` | `game/art/battle_vfx/` | adopted |
| `ui_quest_panel_formal_v1` | `assets/raw/ui/quest/` | `game/art/ui/quest/ui_quest_panel_formal_v1.png` | adopted |
| `ui_skill_panel_formal_v1` | `assets/raw/ui/skill/` | `game/art/ui/skill/ui_skill_panel_formal_v1.png` | adopted |

系统 UI 采用范围：商店、存档、胜利、失败、章节结算。现有对话框、战斗 HUD、背包、装备、任务和武学保留已有的正式框体与实时控件；新增无字对话/战斗指令底图已归档供后续版式迭代，未覆盖现有可读性更好的控件层。

> `ch3_portrait_lingshuang_v1` 首张输出性别不符合角色设定，保留 raw 供审计但标记 rejected，不接入游戏；重试任务已补强女性身份约束。

一张图只有同时满足以下条件才可标为 `adopted`：

- 使用项目 Style Bible 或已通过角色锚点生成。
- 无水印、乱码、繁体字、蜘蛛/蛛网、现代物件和明显结构错误。
- 尺寸、透明通道、裁切、安全边距符合用途规范。
- 在 Godot 中完成实际界面/场景截图验收，而不是只看原图。
- 有对应 `meta.json`，记录 task id、最终 prompt、模型与生成时间。
- 移动端压缩后仍清晰，且不会造成不可接受的包体或显存占用。

## 2. 全量批次

| 批次 | 内容 | 预计资产单元 | 优先级 |
|---|---|---:|---|
| A0 | Style Bible 锚点复核：主角、女主、五派、UI、战斗色板 | 10 | P0 |
| A1 | 微信启动、主菜单、HUD、通用弹窗、背包/装备/任务/武学/存档 | 45 | P0 |
| A2 | 通用物品、装备、技能、任务类型、状态图标 | 90 | P0 |
| A3 | 第一章场景/NPC/头像/敌人/特效正式化 | 55 | P0 |
| A4 | 第二章 4 场景、关键人物、敌人、证据、战斗特效 | 48 | P1 |
| A5 | 第三章大会 + 五派场景/角色/技能/敌人/特效 | 82 | P1 |
| A6 | 第四章洛阳 4 场景、人物、敌人、线索、特效 | 58 | P1 |
| A7 | 压缩、图集、微信分包、低端机降级版本 | 派生物 | P1 |

预计约 388 个原始资产单元。按钮三态、动画帧和压缩版本属于派生物，不按独立创意资产重复计费。

## 3. 生成与接入规则

- UI 底框与无字部件由 GPT Image 2 生成，中文文字由本地字体叠加，避免图中文字错误。
- NPC 头像先锁定半身立绘，再从同一参考生成表情变体。
- 精灵图按“角色锚点 -> 单方向关键帧 -> 循环 QA -> 镜像/派生”生产，不一次盲跑全方向。
- 战斗特效生成高对比纯色底序列，抠图后做 alpha 边缘和循环检查。
- 场景背景输出无 UI、无角色版本；NPC、出口指示和可交互物单独分层。
- 每个批次先出 1 个代表资产，通过 art-review 后再批量。

## 4. 微信资源规格

| 类型 | 工作母版 | 游戏内建议 |
|---|---|---|
| 场景背景 | 1920x1080 PNG | WebP/PNG，按设备档位 1920 或 1280 宽 |
| 角色头像 | 1024 方图或半身图 | 512-768 高，透明 WebP/PNG |
| 场景精灵 | 1024 母版 | 单帧 256-384 方格，图集加载 |
| UI 面板 | 2x 设计尺寸 | 九宫格切片或 WebP，文字独立渲染 |
| 图标 | 512 母版 | 128/256 图集 |
| 战斗特效 | 1024 母版序列 | 256-512 图集，限制同时驻留数量 |

## 5. 现有资产处理

当前 `game/art` 约有 681 张 PNG，但包含备份、候选版本、重复状态图和未验收产物。迁移时按以下状态处理：

- `adopted`：满足正式资源门槛，直接进入压缩/分包。
- `candidate`：视觉可用但缺元数据或实机验收，补齐后决定。
- `rejected`：占位、测试、重复备份、风格漂移，不进入发布包。

首轮审计优先清理 `characters_backup_*`、测试音频、旧 `ui/cold_wuxia` 候选稿和未引用 PNG，禁止把整个 `game/art` 无差别导出到微信包。

## 6. 每批验收输出

- 任务 ID 与最终 prompt 列表。
- 原图、处理后文件、采用文件三层路径。
- 角色/动画对照图或 GIF。
- Godot 实机截图：桌面 1920x1080、移动横屏安全区。
- 生成成本、采用率、被拒原因。
