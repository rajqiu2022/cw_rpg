# 技术选型决策报告

> 项目：受《风云之天下会》（智冠 1998）启发的漫画 2.5D 武侠 RPG
> 决策日期：2026-04-25
> 决策结论：**Godot 4**

---

## 一、决策结论

**采用 Godot 4（GDScript 为主，必要时 C# 补充）。**

核心理由：在"漫画 2.5D + AI 生成资产 + 独立小团队"这三个约束下，Godot 4 是当前综合最优解。Unity 太重、Web 缺 2.5D 现成轮子、RPG Maker 模板锁死风格。

---

## 二、四引擎对比表

| 维度 | Godot 4 | Unity 6 | Web (Phaser/PixiJS) | RPG Maker MZ |
|---|---|---|---|---|
| **2D / 2.5D 原生支持** | 一流（`Y-Sort`、等距 `TileMap` 自带） | 良好（需配置 `Sprite Renderer Order in Layer`） | 弱（自己实现 Y-Sort） | 仅 RPG Maker 模板 |
| **45° 视角实现成本** | 低（拖拽即用） | 中 | 高 | 0（但风格被锁死） |
| **PNG 资产导入流程** | 拖入 `res://` 即用 | Import Settings 多步 | webpack/vite 配置 | 严格命名 + 工具导入 |
| **AI 出图工作流契合度** | ⭐⭐⭐⭐⭐ | ⭐⭐⭐ | ⭐⭐⭐ | ⭐⭐（强约束） |
| **学习曲线** | 低（GDScript 语法接近 Python） | 中高（C# + 庞大 API） | 中（JS/TS + 引擎 API） | 极低（事件编辑器） |
| **跨平台导出** | Win/Mac/Linux/Android/iOS/Web 全覆盖 | 全覆盖（业界最广） | 仅浏览器 / Electron 套壳 | Win/Mac/Android/iOS/Web |
| **引擎大小** | ~100 MB 单文件 | ~10 GB+ 安装 | 0（库依赖） | ~500 MB |
| **版权 / 收费** | MIT 免费，零分成 | 个人版免费，超 20 万美元营收要付费 | 开源免费 | 单机授权 ~$80 |
| **社区 / 中文资料** | 增长快，中文资料够用 | 最丰富 | 丰富但非游戏专向 | 中文社区强（圈子小） |
| **场景编辑器** | 节点树 + 场景嵌套，易理解 | 强大但复杂 | 无（代码驱动） | 内置（强模板） |
| **存档 / 国际化 / 输入** | 内置 | 内置 | 自己实现 | 内置 |
| **风格自由度** | 高 | 高 | 高 | **低（锁死 RPG Maker 味）** |
| **AI 辅助开发友好度** | 高（GDScript 简洁） | 高（C# 大模型熟） | 极高（前端代码） | 低（事件流程） |

---

## 三、为什么是 Godot 4

### 3.1 漫画 2.5D 是它的"主场"

Godot 4 的 `Node2D` + `Y-Sort` 机制天然适配 45° 视角的角色与场景层级排序。`TileMap` 节点直接支持 isometric / half-offset 模式，新建场景拖几下就能跑出《风云之天下会》那种斜向 45° 的地图。

参考案例：
- *Brotato*（2D 俯视，Godot 制作，Steam 销量百万级）
- *Cassette Beasts*（2.5D，Godot 制作）
- *Dome Keeper*（2D，Godot 制作）

### 3.2 与 AI 出图工作流零摩擦

我们的资产流水线最终会输出标准 PNG 到 `assets/processed/`。Godot 的导入逻辑是：

> **把 PNG 复制到 `res://` 任意子目录 → 重启编辑器 → 自动识别为 Texture2D，可直接拖到 Sprite2D。**

Unity 必须经过 Import Settings（pixel per unit、filter mode、压缩格式）逐张配置；Web 需要打包工具配置静态资源；RPG Maker 必须命名为 `Actor1_1.png` 这种固定格式。**只有 Godot 是"AI 流水线友好"的。**

### 3.3 学习曲线对独立开发者友好

GDScript 语法接近 Python，`func _ready():` 就能开始写。AI 助手对 GDScript 4.x 的代码生成质量已经很高（OpenAI o4 / Claude 4.x 级别都没问题）。

### 3.4 商业风险最低

MIT 协议，无任何分成、无引擎收费。个人项目商业化无后顾之忧。Unity 2023 年的"按安装收费"事件让大量独立开发者迁出，**Godot 4 是当前独立游戏圈的政治正确选项**。

---

## 四、为什么不选其他

### Unity 6
- 优点：生态最成熟、招人最容易、跨平台最稳。
- 缺点：
  - 2D 工具链长期是"3D 引擎做 2D"的体验，Y-Sort、TileMap、动画事件都要更多配置
  - 安装体积 10GB+，启动慢，对老笔记本不友好
  - 收费政策反复，独立开发者信心被透支
- 何时回头选 Unity：项目要做 3D 大世界 / VR / 手游商业化中重度。

### Web (Phaser 3 / PixiJS)
- 优点：分享只需一个链接、调试用 Chrome DevTools、TypeScript 体验顺
- 缺点：
  - 2.5D / Y-Sort 没有现成的成熟方案
  - 浏览器音频、字体、本地存档都有兼容性坑
  - 性能上限低于原生引擎
- 何时选：要做 H5 小游戏 / 营销 demo / 网页内嵌剧情向。

### RPG Maker MZ
- 优点：剧情驱动型 RPG 上手最快，事件编辑器、对话框、菜单全开箱即用
- 缺点：
  - **致命**：所有 UI / 战斗界面 / 角色行走图都被模板锁死，无论怎么换素材都"一眼 RPG Maker 味"
  - 想做漫画质感的 45° 视角必须深度魔改 JS 插件，反而比 Godot 从零写更累
- 何时选：做纯日式 JRPG，且不在意"撞脸"问题。

---

## 五、技术栈版本与工具

| 组件 | 选择 | 备注 |
|---|---|---|
| 引擎 | **Godot 4.3+ (.NET 版可选)** | 单文件 ~100MB，从 https://godotengine.org/ 下载 |
| 主语言 | **GDScript** | 项目体量未达需要 C# 性能优化的程度 |
| 版本控制 | Git + LFS | LFS 用于大尺寸 PNG 资产 |
| AI 出图 | OpenAI GPT Image 2 (`gpt-image-2`) + Holopix 备选 | 见 `art-pipeline.md` |
| 出图脚本运行时 | Python 3.11+ | 见 `scripts/requirements.txt` |
| IDE | Cursor + Godot 内置编辑器 | Cursor 写脚本/文档，Godot 编辑器搭场景 |

---

## 六、决策可逆性

本项目的 AI 美术流水线**与引擎完全解耦**：所有资产输出为标准 PNG + JSON 元数据。如果未来发现 Godot 4 在某方面卡死项目，迁移到 Unity / Web 不需要重做美术资产，只需重写引擎层代码（场景 / 控制器 / UI）。

迁移成本主要在引擎代码（预计 1–2 周重写），**美术资产、Prompt 库、数值表全部 0 成本继承**。
