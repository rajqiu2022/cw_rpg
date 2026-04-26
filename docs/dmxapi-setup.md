# DMXAPI 中转接入指南

> 中国大陆开发者首选方案。国内直连、支付宝充值、一个 key 通 GPT/Flux/即梦/Imagen 全套，无需 VPN，无封号风险。

---

## 1. 为什么选 DMXAPI

| 痛点 | OpenAI 直连 | DMXAPI 中转 |
|---|---|---|
| 中国大陆访问 | ❌ 需 VPN | ✅ 直连 |
| 支付方式 | ❌ 海外信用卡 | ✅ 支付宝/微信 |
| 封号风险 | 🔴 高（IP/卡 BIN 检测） | 🟢 零（厂商关系） |
| 价格 | OpenAI 原价 | **集采 7 折** |
| 模型覆盖 | 仅 OpenAI | OpenAI + Flux + 即梦 + Imagen |
| API 协议 | OpenAI SDK | **OpenAI SDK 完全兼容**（只改 1 行 base_url） |

---

## 2. 注册与充值（5 分钟）

1. 打开 [https://www.dmxapi.cn](https://www.dmxapi.cn) （**注意是 .cn 不是 .com**，国内人民币计价）
2. 微信扫码注册
3. 个人中心 → 充值 → 支付宝/微信 → 充 ¥30-100（小额起步）
4. 个人中心 → 令牌管理 → 创建新令牌 → 复制 `sk-xxx` 字符串

> ⚠️ **令牌即密码**。永远不要把它贴到聊天 / 代码 / 截图 / GitHub。一旦泄露立刻删除并重建。

---

## 3. 配置 .env（30 秒）

在项目根目录创建 `.env` 文件（已被 `.gitignore` 忽略）：

```dotenv
OPENAI_API_KEY=你刚拷贝的sk-xxx
OPENAI_BASE_URL=https://www.dmxapi.cn/v1
OPENAI_IMAGE_MODEL=gpt-image-1
BUDGET_LIMIT_CNY=50.0
```

> `gen_assets.py` 通过检测 `OPENAI_BASE_URL` 中是否含 `dmxapi` 自动切换到中转模式：
> - 价格表切到 CNY 单价
> - 预算单位切到 ¥
> - 跳过 OpenAI 特有的 token-usage 计费换算

---

## 4. 跑首张图（验证连通）

```powershell
cd f:\Code\RPG_GAME

# 第一步：dry-run 验证 prompt 渲染（不烧钱）
python scripts\gen_assets.py --dry-run --task portrait_bujingyun_neutral

# 第二步：真出 1 张图（约 ¥1）
python scripts\gen_assets.py --task portrait_bujingyun_neutral --budget 5

# 出图后查看
explorer assets\raw\character
```

输出应类似：

```
后端：DMXAPI 中转 | 模型：gpt-image-1 | 预算上限：¥5.00 | 并发：4 | Dry-Run：False

         结果汇总
┌────────────────┬──────────┐
│ 状态           │     数量 │
├────────────────┼──────────┤
│ 成功           │        1 │
│ 总花费         │ ¥1.0000  │
│ 剩余预算       │ ¥4.0000  │
└────────────────┴──────────┘
```

---

## 5. DMXAPI 模型清单速查

来源：[DMXAPI 模型定价页](https://rmb.dmxapi.cn/) / [画图模型文档](http://imagemodels.dmxapi.com/)

| 模型 ID | 厂商 | 价格 (¥/张) | 适合 |
|---|---|---|---|
| `gpt-image-1` | OpenAI | ¥1+ | UI、含中文、要求精准的角色立绘 |
| `flux-kontext-pro` | Black Forest Labs | ¥0.2 | 道具/技能图标批量、性价比之王 |
| `flux-kontext-max` | Black Forest Labs | ¥0.4 | 高质量场景背景 |
| `seedream-3.0` | 字节豆包/即梦 | ¥0.08 | 中国题材兜底，**有 10 万张免费额度** |
| `imagen4` | Google | 估约 ¥0.5 | 备用，未实测 |

> **缺失**：DMXAPI **没有 Midjourney**（全行业都没官方 API）。如果未来要用 MJ 解决角色一致性，需另接 PiAPI.ai / useapi.net 等逆向 API。

---

## 6. 在 tasks.yaml 里按任务指定模型（混合策略）

让 700+ 张资产自动分流给最合适的模型：

```yaml
tasks:
  # UI / 含中文 → gpt-image-1（贵但精准）
  - id: ui_button_normal_start
    template: ui_button
    model: gpt-image-1          # ← 显式指定
    vars:
      label: "开始游戏"

  # 简单图标 → flux-kontext-pro（便宜 5 倍）
  - id: icon_item_silver
    template: ui_icon_item
    model: flux-kontext-pro
    vars:
      item_name: "银两"

  # 角色立绘 → gpt-image-1（一致性优先）
  - id: portrait_bujingyun_neutral
    template: character_portrait
    model: gpt-image-1
    vars: ...

  # 兜底测试 / 简单道具 → seedream-3.0（免费/超便宜）
  - id: scene_grass_tile
    template: tileset
    model: seedream-3.0
```

`gen_assets.py` 会优先用 task 内的 `model` 字段，没指定则回落到 `OPENAI_IMAGE_MODEL` 环境变量。

---

## 7. 成本对照（700 张资产实测推算）

| 分配方案 | 总价 (¥) | 总价 (USD) | 备注 |
|---|---|---|---|
| 全 `gpt-image-1` | ¥700 | ~$100 | 最贵 |
| **混合（推荐）** | **¥210** | **~$30** | UI 用 gpt，icon 用 flux，兜底用 seedream |
| 全 `flux-kontext-pro` | ¥140 | ~$20 | 便宜但中文 UI 不如 gpt |
| 全 `seedream-3.0` | ¥56 | ~$8 | 免费额度内基本不要钱 |

---

## 8. 常见问题

### Q1：DMXAPI 的 `gpt-image-1` 是不是 OpenAI 最新的 GPT Image 2？

不一定。DMXAPI 沿用了 OpenAI 的旧模型 ID `gpt-image-1`。OpenAI 在 2026-04 发布的 GPT Image 2 大概率仍走同 ID 端点（OpenAI 习惯做"ID 不变、底层升级"，参考 GPT-4 → GPT-4o）。**实测验证方式**：跑一张图看效果，与 ChatGPT 网页版 GPT Image 2 对比。

### Q2：余额查询？

```python
# 直接登录 https://www.dmxapi.cn 个人中心查
# 或调 API：GET https://www.dmxapi.cn/api/user/self （需要 user-token，不是 sk-）
```

### Q3：充值发票？

DMXAPI 后台支持自助开票（增值税普票），充值即可开。

### Q4：如果 DMXAPI 哪天倒闭怎么办？

切换成本 = **改 1 行 `OPENAI_BASE_URL`**。可以无缝切到：
- API易：`https://api.apiyi.com/v1`
- 302.AI：`https://api.302.ai/v1`
- OpenRouter：`https://openrouter.ai/api/v1`
- OpenAI 官方：`https://api.openai.com/v1`

---

## 9. 经验记录

> 用户规则：每次出现问题修复后做经验记录。

- **DMXAPI 不返回可信 token usage**：必须在 `cost_from_usage` 里做 backend 判断，DMXAPI 模式下直接 fallback 到 per-image 价格表
- **币种切换**：如果 `BUDGET_LIMIT_USD` 设了 80，但用户切到 DMXAPI，会被当 ¥80 用——`gen_assets.py` 已处理，DMXAPI 模式优先读 `BUDGET_LIMIT_CNY`
- **.com vs .cn 域名**：`https://www.dmxapi.cn` 和 `https://www.dmxapi.com` 是**两个独立账户系统**（人民币 vs 美元计价），令牌不通用，注册时选好不要混
- **API key 防泄露**：聊天工具、Cursor、IDE 历史都是泄露源。最稳的做法：`.env` 文件 + `.gitignore` + 永远不复制粘贴
- **🔥 OpenAI SDK connect timeout 默认 5s 太短**：DMXAPI 中转的 TLS 握手 + 图像生成首字节响应需要 30-90s。**必须显式传 `httpx.Timeout(300, connect=30)`**，否则所有请求会在 16s 左右连续失败重试。`gen_assets.py` 已通过 `HTTP_CONNECT_TIMEOUT` / `HTTP_TOTAL_TIMEOUT` 环境变量可配置，默认 30/300s
- **🔥 DMXAPI 模型 ID 与文档不完全一致**（实测时间 2026-04-26）：
  - ✅ `gpt-image-1`、`gpt-image-2`、`gpt-image-1.5`、`dall-e-3`、`imagen4` —— 文档与实际一致
  - ❌ `seedream-3.0` —— **不存在**，真名 `doubao-seedream-3-0-t2i-250415`（也有 4-0/4-5/5-0）
  - ❌ `flux-kontext-pro` —— 已被替换为 `flux-2-pro` / `flux-2-flex`
  - 🆕 `gemini-3-pro-image-preview` —— 新增，未在文档高亮
  - 🆕 `qwen-image-2.0-pro` —— 国产通义万相，便宜
  - **排查方式**：`python scripts/check_dmxapi.py --no-image` 列出全部 771 个模型，搜关键词
- **诊断脚本 `check_dmxapi.py`**：连通性 / 余额 / 出图分别测试，¥0.08-1 成本，避免在 700 张正式批量前才发现配置问题

### 当前已验证可用模型（2026-04-26 实测）

| 模型 ID | 单价 | 实测耗时 | 备注 |
|---|---|---|---|
| `gpt-image-1` | ¥1.0 | 32-65s | ✅ 成功，质量好 |
| `gpt-image-2` | 估 ¥1.5 | 待测 | DMXAPI 已上架 OpenAI 最新 |
| `dall-e-3` | 估 ¥0.6 | 待测 | 老款，便宜 |
| `flux-2-pro` | 估 ¥0.4 | 待测 | 替代 flux-kontext-pro |
| `doubao-seedream-3-0-t2i-250415` | ¥0.08 | 待测 | 字节即梦 3.0 |
| `qwen-image-2.0-pro` | 估 ¥0.3 | 待测 | 国产兜底 |
