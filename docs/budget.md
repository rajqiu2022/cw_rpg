# 美术资产成本预算

> 默认 backend：OpenAI **GPT Image 2** (`gpt-image-2`, 2026-04-21 发布)
> 中国大陆推荐：**DMXAPI 中转**（详见 [dmxapi-setup.md](./dmxapi-setup.md)）
> 数据来源：OpenAI 官方定价（April 2026）+ DMXAPI 公开价目 + buildfastwithai 实测
> 上次更新：2026-04-26

---

## 零、Backend 选择速查表

| Backend | 单价 | 币种 | 中国直连 | 模型覆盖 | 推荐场景 |
|---|---|---|---|---|---|
| OpenAI 官方 | $0.053 / 张 (medium 1024) | USD | ❌ 需 VPN | OpenAI 全套 | 海外开发者 / 极致质量 |
| **DMXAPI 中转** | **¥1 / 张** (gpt-image-1) | **CNY** | ✅ | OpenAI + Flux + 即梦 + Imagen | **🇨🇳 中国推荐** |
| API易 (apiyi) | ~$0.04 / 张 | USD/CNY | ✅ | OpenAI + Flux | Flux 全网最低价 |

> **¥1 ≈ $0.14**（按 7:1 估算）。DMXAPI 中转价相当于 OpenAI 原价 ×1.3，但**省去 VPN + 海外卡 + 封号风险**。

---

## 一、OpenAI 官方单价表（USD）

### 按尺寸 × 质量（OpenAI 官方计算器）

| 尺寸 | low | medium | high |
|---|---|---|---|
| 1024 × 1024 | $0.006 | $0.053 | $0.211 |
| 1024 × 1536（竖） | $0.005 | $0.041 | $0.165 |
| 1536 × 1024（横） | $0.005 | $0.041 | $0.165 |
| 2K（实验） | token 计费 | token 计费 | token 计费 |
| 4K（fal.ai 实测） | $0.01 | — | $0.41 |

### 按 token（带 reference 图编辑必走此项）

- 文本输入：$5 / 1M tokens
- 图像输入（参考图）：$8 / 1M tokens（`gpt-image-2` 永远高保真，单价较 1.5 高）
- 图像输出：$30 / 1M tokens

> ⚠ **edits 端点（带参考图）成本通常是同 size/quality 的 generations 端点的 1.5–3 倍**，因为强制高保真处理参考图。
> `gen_assets.py` 用 `cost_from_usage()` 从响应 usage 字段实时换算，比 size×quality 估算更准。

---

## 二、第一版完整美术集合预算（$80 USD ≈ 580 元）

| 类别 | 张数 | 平均尺寸 / 质量 | 平均单价 | 小计 | 用途说明 |
|---|---|---|---|---|---|
| Style Bible（含反复迭代） | ~50 | 1024×1024 / high | $0.211 | $10 | 风格圣经，所有后续资产引用，必须高质量 |
| 主角立绘（步惊云） | 8 | 1024×1536 / high | $0.165 | $1.3 | 不同表情/姿态 |
| 同伴立绘（聂风/秦霜/无名/楚楚） | 4×8 = 32 | 1024×1536 / high | $0.165 | $5.3 | 同上 |
| 反派立绘（雄霸/断浪/剑圣等） | 6×4 = 24 | 1024×1536 / high | $0.165 | $4.0 | 关键剧情角色 |
| 角色 sprite（主+5 同伴） | 6×40 = 240 | 1024×1024 / medium | $0.053 | $12.7 | 4 方向 × 待机/走/攻/受/死 = 40 帧/角色 |
| 反派 sprite | 50 | 1024×1024 / medium | $0.053 | $2.7 | 仅出场战斗的关键反派 |
| UI 按钮三态 | 30 | 1024×1024 / medium | $0.053 | $1.6 | 10 个按钮 × 3 态 |
| UI 对话框 / 菜单框 | 8 | 1536×1024 / high | $0.165 | $1.3 | 9-slice 友好 |
| 武功招式图标 | 80 | 1024×1024 / medium | $0.053 | $4.2 | 主角+同伴的武功树 |
| 道具图标 | 200 | 1024×1024 / medium | $0.053 | $10.6 | 武器/丹药/材料/任务物品 |
| 场景背景 | 50 | 1536×1024 / high | $0.165 | $8.3 | 主线 30 + 支线 20 |
| Tileset 瓦片集 | 12 | 1024×1024 / high | $0.211 | $2.5 | 不同地形主题 |
| **小计** | **~790** | — | — | **$64.5** | |
| 重试 / 失败缓冲 | — | — | — | $15.5 | 24% 缓冲（保守） |
| **预算硬上限** | — | — | — | **$80.0** | `BUDGET_LIMIT_USD` 默认值 |

---

## 三、与替代方案的成本对比

| 方案 | 同等量级成本 | 优劣 |
|---|---|---|
| **GPT Image 2 (本方案)** | **~$80** | 一致性最强、UI/文字最稳、不支持透明 |
| Midjourney v7 | ~$30/月 × 2 月 + 时间 | 风格美但一致性差，无 API（违 ToS） |
| Stable Diffusion (本地) | 0 美元（电费除外） | 自由度最高，需 GPU + LoRA 训练，时间成本高 |
| Holopix AI（国内）| ¥199/月 ≈ $28 | 像素 / 多视角强项，但漫画质感弱于 GPT |
| 即梦 AI | 免费积分 / 按量 | 国风强项，API 较新 |
| 外包给独立画师 | $5–30/张 | 质量稳定但慢（数月）+ 修改成本高 |

> 结论：对"小团队漫画 2.5D 武侠 RPG"这个 niche，GPT Image 2 在质量、一致性、API 可靠性、价格四维度综合最优。

---

## 四、限流与并发策略

### OpenAI 账户层级限制（gpt-image-2）

| Tier | TPM | IPM | 适用项目阶段 |
|---|---|---|---|
| Free | ❌ 不支持 | ❌ | 不可用 |
| Tier 1 | 100,000 | **5** | 当前默认 |
| Tier 2 | 250,000 | 20 | 累计消费 $50 后自动升级 |
| Tier 3 | 800,000 | 50 | $100 |
| Tier 4 | 3,000,000 | 150 | $250 |
| Tier 5 | 8,000,000 | 250 | $1000 |

> **IPM = Images Per Minute**。Tier 1 仅 5/分钟。
> `gen_assets.py` 的 `GEN_CONCURRENCY=4` 默认值就是为 Tier 1 留余量（GPT Image 2 出图约 2 分钟/张，4 并发实际 ≈ 2 IPM）。
> 累计消费超过阈值后，可手动升 `GEN_CONCURRENCY` 提速。

### 速度估算

| 任务量 | Tier 1（4 并发） | Tier 2（10 并发） |
|---|---|---|
| 50 张 | ~25 分钟 | ~10 分钟 |
| 200 张 | ~1.5 小时 | ~40 分钟 |
| 800 张（全集） | ~6.5 小时 | ~2.5 小时 |

> 建议：先跑 priority=1 的代表性任务（约 11 张，~10 分钟）验证质量，再批量推全部。

---

## 五、预算保护机制

`gen_assets.py` 内置三层保护：

1. **预算预检**：每次发请求前检查 `budget.remaining >= 估算成本`，不足则跳过该任务（`status=budget_skip`）
2. **实时累计**：每张成功后用 `cost_from_usage()` 累加实际花费，存于 `Budget.spent`
3. **硬上限触发**：`Budget.add()` 如果累计超过 `BUDGET_LIMIT_USD`，抛 `BudgetExceeded` 异常，整批任务终止并打印汇总

### 调整预算上限

```bash
# 临时（命令行参数优先级最高）
python scripts/gen_assets.py --budget 30

# 持久（编辑 .env）
BUDGET_LIMIT_USD=120
```

---

## 六、降本技巧

1. **dry-run 校验 prompt**：`--dry-run` 不调 API，只渲染 prompt 落到 `.meta.json`，省试错费
2. **优先级分批**：标 `priority: 1` 的任务先跑（10 余张验证质量），再放 `priority: 2`
3. **复用已生成资产**：脚本默认跳过已存在的输出（`out_png.exists()`），改 prompt 后只需删除目标 PNG 重跑
4. **medium 优先于 high**：sprite 类（最终降到 256×256）用 medium 完全够用，high 仅用于立绘 / 大场景
5. **Style Bible 反复打磨**：前期 $10 投入换取后续 $70 成功率，性价比最高
6. **混合 backend**（DMXAPI 用户）：UI/含中文 → `gpt-image-1`（¥1）、icon → `flux-kontext-pro`（¥0.2）、tile → `seedream-3.0`（¥0.08），整体省 70%

---

## 七、DMXAPI 价目表（CNY）

来源：[DMXAPI 模型定价](https://rmb.dmxapi.cn/) — 集采 7 折后 per-image 计费，**与 size/quality 无关**。

| 模型 ID | ¥/张 | USD 等值 | OpenAI 同质量价对比 | 适合 |
|---|---|---|---|---|
| `gpt-image-1` | ¥1.0 | ~$0.14 | $0.053-0.211 | UI、中文文字、关键立绘 |
| `flux-kontext-pro` | ¥0.2 | ~$0.03 | — | 道具/技能图标批量 |
| `flux-kontext-max` | ¥0.4 | ~$0.06 | — | 高质量场景背景 |
| `seedream-3.0` | ¥0.08 | ~$0.011 | — | 中国题材兜底（含 10 万张免费额度） |
| `imagen4` | ~¥0.5 | ~$0.07 | — | 备用，未实测 |

### 700 张资产混合策略实测

| 分配方案 | UI(50) | 角色(80) | sprite(240) | icon(150) | scene(80) | tile(100) | **总价** |
|---|---|---|---|---|---|---|---|
| 全 `gpt-image-1` | ¥50 | ¥80 | ¥240 | ¥150 | ¥80 | ¥100 | **¥700** |
| **混合（推荐）** | ¥50 (gpt) | ¥80 (gpt) | ¥48 (flux 0.2) | ¥30 (flux) | ¥32 (flux 0.4) | ¥8 (seed) | **¥248** |
| 全 `seedream-3.0` | ¥4 | ¥6.4 | ¥19.2 | ¥12 | ¥6.4 | ¥8 | **¥56** |

> **混合方案性价比最高**：UI 中文/角色一致性用最强模型，简单 sprite/icon/tile 用便宜模型，省 65% 不损质量。
> 在 `tasks.yaml` 里给每个任务加 `model:` 字段即可分流，详见 [dmxapi-setup.md §6](./dmxapi-setup.md)。

---

## 八、如何切换 backend

只改 `.env` 一个文件，代码零改动：

```dotenv
# 切换到 DMXAPI（中国推荐）
OPENAI_API_KEY=sk-你的DMXAPI令牌
OPENAI_BASE_URL=https://www.dmxapi.cn/v1
OPENAI_IMAGE_MODEL=gpt-image-1
BUDGET_LIMIT_CNY=50.0

# 切换到 OpenAI 官方
OPENAI_API_KEY=sk-proj-xxx
OPENAI_BASE_URL=https://api.openai.com/v1
OPENAI_IMAGE_MODEL=gpt-image-2
BUDGET_LIMIT_USD=80.0
```

`gen_assets.py` 通过检测 `OPENAI_BASE_URL` 自动切换价格表与币种，无需手动指定 `--backend`。
