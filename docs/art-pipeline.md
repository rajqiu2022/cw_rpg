# AI 美术资产流水线 — 上手手册

> 目标：把"自然语言描述"稳定地变成**符合《风云》漫画 2.5D 风格、可直接拖进 Godot 的游戏资产**。
> 工具栈：OpenAI **GPT Image 2** + `rembg` + `Pillow` + Python 异步脚本。

---

## 流水线全景

```
┌─────────────────────────────────────────────────────────────────────┐
│  Step 1  Style Bible（一次性）                                       │
│    手动 + GPT Image 2 high quality                                  │
│    产出 5–8 张参考锚点图 → assets/_style_bible/                       │
│                                                                     │
│  Step 2  填任务清单                                                  │
│    编辑 prompts/tasks.yaml（YAML 锚点 + 模板引用）                   │
│                                                                     │
│  Step 3  批量生成（gen_assets.py）                                   │
│    异步并发 → assets/raw/{category}/{id}.png + .meta.json            │
│                                                                     │
│  Step 4  后处理（postprocess.py）                                    │
│    rembg 抠透明 + Pillow 标准化尺寸 + sprite sheet 拼装               │
│    → assets/processed/                                              │
│                                                                     │
│  Step 5  校验（verify.py）                                           │
│    alpha / 尺寸 / 命名 / meta 完整性                                  │
│    → reports/verify_*.json                                          │
│                                                                     │
│  Step 6  导入 Godot                                                 │
│    把 assets/processed/ 复制到 Godot 项目 res://assets/              │
└─────────────────────────────────────────────────────────────────────┘
```

---

## 准备工作（首次）

### 1. 安装 Python 依赖

```powershell
cd f:\Code\RPG_GAME\scripts
python -m pip install -r requirements.txt
```

> ⚠ `rembg` 首次运行会下载 onnx 模型（~170 MB，缓存在 `~/.u2net/`）。
> 国内网络慢的话可以先 `python -c "from rembg import remove; remove(b'')"` 提前触发下载。

### 2. 配置 OpenAI API Key

```powershell
cd f:\Code\RPG_GAME
Copy-Item .env.example .env
notepad .env   # 填入 OPENAI_API_KEY
```

> 账户必须 **完成 OpenAI Verification**（开发者控制台）才能用 `gpt-image-2`。
> 国内访问可在 `.env` 把 `OPENAI_BASE_URL` 改成 `https://api.apiyi.com/v1`（或其它代理）。

### 3. 验证环境

```powershell
python scripts\gen_assets.py --dry-run --priority 1
```

应该看到任务表 + "Dry-Run: True" + 结果汇总，**不会调用 API、不花钱**。

---

## Step 1：Style Bible（最关键，决定全局质量）

> Style Bible 是"风格圣经"。所有后续资产都通过模板里的 `reference_images` 引用它，确保整个游戏视觉统一。
> **这一步质量决定后续 700+ 张资产的成败，值得投入 $10 反复打磨。**

### 必出的 6 张

| 文件名 | 用途 | 推荐 prompt 要点 |
|---|---|---|
| `01_protagonist_full.png` | 步惊云全身立绘 | 角色身份句 + 港漫厚涂 + 全身正面 |
| `02_protagonist_face_sheet.png` | 表情 8 宫格 | 同人物 + 8 种表情：平静/愤怒/痛苦/嘲讽/震惊/笑/疲惫/眯眼 |
| `03_color_palette.png` | 色板 | 角色主色（黑/银/酒红）+ UI 色（深棕/金）+ 强调色 |
| `04_ui_kit_sample.png` | UI 套件示例 | 一张图含按钮、对话框、图标边框，统一风格 |
| `05_scene_sample_isometric.png` | 45° 场景示例 | 天下会大殿俯视图，等距视角 |
| `06_combat_pose_reference.png` | 战斗姿态参考 | 主角施展排云掌的关键瞬间 |

### 操作流程

1. **先在 ChatGPT Plus 网页版交互式生成**（不走 API），反复改 prompt 到满意
2. 满意后在 ChatGPT 里另存原图（避免压缩）
3. 重命名为 `01_protagonist_full.png` 等放入 `assets/_style_bible/`
4. **不要直接用 API 生成 Style Bible**，因为需要大量交互式微调，API 模式效率低

> 替代方案：用 GPT Image 2 网页版试出满意 prompt，再写入一个**专门的 `tasks_style_bible.yaml`** 用 API 复跑（保证可重复）。

---

## Step 2：填任务清单

编辑 `prompts/tasks.yaml`：

### YAML 锚点共享角色定义（避免重复）

```yaml
character_anchors:
  bujingyun: &bujingyun
    character_name: "步惊云"
    character_appearance: |
      二十出头黑发男子，长直发束于脑后，...

tasks:
  - id: portrait_bujingyun_neutral
    template: character_portrait
    category: character
    priority: 1
    vars:
      <<: *bujingyun       # 复用锚点
      pose: "抱臂凝视前方"
      expression: "冷峻"
```

### 字段说明

| 字段 | 含义 | 是否必填 |
|---|---|---|
| `id` | 唯一标识，决定输出文件名 | ✓ |
| `template` | `prompts/templates/<name>.yaml` 不带后缀 | ✓ |
| `category` | 子目录分类（如 `sprite/bujingyun`） | ✓ |
| `vars` | 注入模板 variables 的具体值 | ✓ |
| `priority` | 1=必跑、2=次要 | ✗（默认 99） |
| `skip` | true 临时跳过 | ✗ |

### 模板列表（11 个）

```
character_portrait        立绘
sprite_idle               待机
sprite_walk               行走
sprite_attack             战斗招式
sprite_hurt_death         受击 / 倒地
ui_button                 按钮三态
ui_dialog_box             对话框
ui_icon_skill             武功图标
ui_icon_item              道具图标
scene_background_45deg    场景背景
tileset_45deg             45° 瓦片集
```

---

## Step 3：批量生成

### 常用命令

```powershell
# 1. 干跑：渲染 prompt 不调 API（推荐先做一次）
python scripts\gen_assets.py --dry-run

# 2. 仅跑高优先级
python scripts\gen_assets.py --priority 1

# 3. 跑指定单个任务
python scripts\gen_assets.py --task portrait_bujingyun_neutral

# 4. 临时调低预算（只准花 $5）
python scripts\gen_assets.py --budget 5

# 5. 强制重跑（覆盖已存在）
python scripts\gen_assets.py --task ... --force

# 6. 跑全部
python scripts\gen_assets.py
```

### 输出

```
assets/raw/
├── character/
│   ├── portrait_bujingyun_neutral.png        # 直出原图
│   └── portrait_bujingyun_neutral.meta.json  # prompt + cost + usage + timestamp
└── sprite/bujingyun/
    └── ...
```

### 实时监控

终端会显示进度条 + 累计花费。达到 `BUDGET_LIMIT_USD` 自动停止并打印汇总表。

失败任务写入 `logs/failed.log`（JSONL 格式），可单独 `--task xxx` 重跑。

---

## Step 4：后处理

### 常用命令

```powershell
# 全部后处理（rembg 抠图 + 标准化尺寸）
python scripts\postprocess.py

# 仅处理某类别
python scripts\postprocess.py --category sprite/bujingyun

# 处理后顺便拼 sprite sheet
python scripts\postprocess.py --pack-sheets

# 跳过抠图（已经透明的素材）
python scripts\postprocess.py --no-rembg
```

### 输出

```
assets/processed/
├── character/
│   └── portrait_bujingyun_neutral.png        # 透明背景，原始尺寸保持
├── sprite/bujingyun/
│   └── sprite_bujingyun_idle_south.png       # 256×256 标准网格
├── ui/icon/skill/
│   └── icon_skill_paiyunzhang.png            # 128×128
└── _sheets/
    └── bujingyun_sheet.png                   # 横向拼装 sprite sheet
```

### 类别 → 目标尺寸映射（写在 `postprocess.py` 顶部 `TARGET_SIZES`）

```python
sprite          → 256×256       # 全部 sprite 标准网格
ui/icon/skill   → 128×128
ui/icon/item    → 128×128
ui/button       → 512×170       # 3:1
ui/dialog       → 保持原图
scene           → 保持原图
tileset         → 保持原图（不抠图，单独切瓦片）
character       → 保持原图（立绘大图）
```

---

## Step 5：校验

```powershell
python scripts\verify.py
python scripts\verify.py --strict   # warn 也视为 fail
```

检查项：

- **alpha 通道**：processed/ 下 PNG 必须有透明像素（rembg 没出错）
- **尺寸**：符合该类别期望
- **命名**：仅 `a-z0-9_`
- **meta**：raw/ 下每张 PNG 必须有同名 `.meta.json` 且字段齐全

报告：`reports/verify_<timestamp>.json`

---

## Step 6：导入 Godot

1. 在 Godot 4 项目根目录建 `assets/` 文件夹
2. 把 `f:\Code\RPG_GAME\assets\processed\` 内容**直接复制**进去
3. Godot 重启编辑器，自动识别为 `Texture2D`
4. 拖到 `Sprite2D` 节点的 `Texture` 槽即可

> sprite sheet：用 `AtlasTexture` 切片，Region 按 256×256 网格设置。
> tileset：在 Godot `TileSet` 资源里导入 `tileset_45deg.png`，用等距 / 半偏移模式切片。

---

## 故障排查

| 症状 | 可能原因 | 解决 |
|---|---|---|
| `OPENAI_API_KEY 未配置` | `.env` 没填 / 仍是占位值 | 编辑 `.env`，确认值不是 `sk-...` |
| `403 / 401` | 账户未通过 Verification | OpenAI Console → Verification 完成认证 |
| `429 RateLimit` | 触发 IPM 限流 | 降 `GEN_CONCURRENCY` 到 2，或等待累计消费升 Tier |
| 角色脸偏移 / 不像同一人 | reference_images 不存在 / 参考图本身不一致 | 检查 `assets/_style_bible/` 文件存在；首先打磨好 Style Bible |
| 中文文字乱码 | 模板 prompt 没明确"中文必须正确" | 模板已含此约束，必要时在 `vars` 里补充 `negative` |
| 生成的图带白底没透明 | 这是正常的，需跑 postprocess | `gpt-image-2` 不支持透明，必须 rembg 兜底 |
| rembg 报错 onnx 模型下载失败 | 国内网络访问 GitHub Release 失败 | 手动下载 [u2net.onnx](https://github.com/danielgatis/rembg/releases) 放到 `~/.u2net/` |
| sprite sheet 报 `size_mismatch` | 该角色的 sprite 尺寸不一 | 全部跑 `postprocess.py` 标准化尺寸后再 `--pack-sheets` |
| 跑到一半超预算停了 | 触发 `BudgetExceeded` | `--budget` 临时加额，或编辑 `.env` 持久调高 |
| `template_error: KeyError` | 模板 variables 没填全 | 检查 `tasks.yaml` 该任务的 `vars` 是否覆盖了模板里所有 `{{var}}` |
| 出图 ~120 秒一张太慢 | GPT Image 2 thinking 模式本身慢 | 降 `quality: low/medium`、并发开足 4、`--priority 1` 分批 |

---

## 经验记录（持续更新）

> 用户规则要求：每次出现问题修复后做经验记录，避免反复出错。

### 2026-04-25 项目搭建期

1. **CreatePlan 工具失败教训**：使用工具的参数标签必须用完整命名空间前缀（XML 格式约定），写错会报 `Must provide either a 'plan' or both 'old_str' and 'new_str'`。修复：所有 parameter 都按规范前缀格式写。
2. **PowerShell 不识别 `dir /a`**：Win 下应用 `Get-ChildItem -Force` 或仅 `dir`（无参数）。
3. **`gpt-image-2` 砍掉了透明背景支持**：1.5 还有，2.0 反而没了。所有 sprite 必须本地 rembg 后处理，已在流水线兜底。
4. **edits 端点（带参考图）成本明显高于 generations**：因为永远高保真处理参考图。在 `gen_assets.py` 的 `cost_from_usage()` 里实时换算，比 size×quality 估算更准。
5. **OpenAI Tier 1 仅 5 IPM**：`GEN_CONCURRENCY=4` 是上限。累计消费 $50 自动升 Tier 2 到 20 IPM。
6. **rembg 首次运行下载模型 170MB**：国内网络慢，提前 warmup 一次或手动放模型到 `~/.u2net/`。
