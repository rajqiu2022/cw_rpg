# RPG_GAME — 漫画 2.5D 武侠 RPG

> 受经典国产武侠 RPG **《风云之天下会》**（智冠科技 / 迷像视觉 1998）启发的现代复刻 / 致敬项目。
> 美术风格：漫画 2.5D（45° 视角，还原马荣成《风云》漫画质感）。
> 当前阶段：**美术资产生成流水线 + 技术选型**（游戏代码尚未启动）。

---

## 项目结构

```
RPG_GAME/
├── docs/
│   ├── tech-selection.md     # 引擎技术选型决策报告（推荐 Godot 4）
│   ├── art-pipeline.md       # AI 美术流水线上手手册
│   └── budget.md             # 美术成本预算与限流机制
├── prompts/
│   ├── templates/            # 11 个 YAML prompt 模板
│   └── tasks.yaml            # 待生成资产清单
├── scripts/
│   ├── gen_assets.py         # 异步批量调 GPT Image 2
│   ├── postprocess.py        # rembg 抠图 + Pillow 切片 + sprite sheet
│   ├── verify.py             # 资产规范校验
│   └── requirements.txt      # Python 依赖
├── assets/
│   ├── _style_bible/         # 风格圣经（参考锚点图，必须最先产出）
│   ├── raw/                  # GPT Image 2 直出原图
│   └── processed/            # 抠图、切片、对齐后的成品
├── .env.example              # 环境变量模板（复制为 .env 填入 API Key）
└── .gitignore
```

---

## 快速开始

### 1. 安装依赖

```powershell
cd scripts
python -m pip install -r requirements.txt
```

### 2. 配置 API Key

```powershell
Copy-Item .env.example .env
# 编辑 .env，填入 OPENAI_API_KEY
```

### 3. 阅读流水线手册

详见 [`docs/art-pipeline.md`](docs/art-pipeline.md)。完整流程：

```
1. 手动 + GPT Image 2 产出 Style Bible（assets/_style_bible/）
2. 编辑 prompts/tasks.yaml 列出要生成的资产
3. python scripts/gen_assets.py        # 跑批量生成
4. python scripts/postprocess.py       # 抠透明背景 + 切片
5. python scripts/verify.py            # 校验
```

### 4. 预算保护

`gen_assets.py` 内置 **$80 USD 硬上限**（详见 [`docs/budget.md`](docs/budget.md)），达到自动停止，不会失控。

---

## 技术栈

- **游戏引擎**：Godot 4.3+（决策依据见 [`docs/tech-selection.md`](docs/tech-selection.md)）
- **AI 出图**：OpenAI GPT Image 2（`gpt-image-2`，2026-04-21 发布）
- **后处理**：Python 3.11+ / `rembg` / `Pillow`
- **版本控制**：Git + Git LFS（处理大尺寸 PNG）

---

## 当前进度

- [x] 技术选型报告
- [x] 项目骨架
- [ ] Prompt 模板库（11 个）
- [ ] 资产任务示例
- [ ] 批量生成脚本
- [ ] 后处理脚本
- [ ] 校验脚本
- [ ] 预算文档
- [ ] 流水线手册

---

## 法律声明

本项目仅作技术学习与个人致敬用途。《风云》漫画版权归马荣成 / 天下出版有限公司所有；《风云之天下会》游戏版权归智冠科技股份有限公司所有。任何商业化前应取得相应授权或改用原创题材。
