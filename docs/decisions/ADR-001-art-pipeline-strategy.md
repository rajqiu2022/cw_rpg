# ADR-001 美术资产流水线策略：去 DMXAPI 单点依赖

- **状态**：已采纳（accepted）
- **日期**：2026-04-27
- **决策者**：项目维护者 + AI 协作者
- **背景文档**：[`docs/consistency-test-report.md`](../consistency-test-report.md) 第 7 章 · [`docs/experience-log.md`](../experience-log.md) 第 1.5.1 节

---

## 1. 上下文

2026-04-27 当日实测 DMXAPI 出现 **4 类不可回避的不稳定问题**：

1. **IP 风控**（并发 ≥ 4 → TLS 握手失败 30+ 分钟）
2. **Azure moderation 拦截**（中文武侠 prompt 误判）
3. **上游渠道熔断 503**（"所有令牌分组 default 下对于模型 gpt-image-2 均无可用渠道"，5–30+ 分钟无 SLA）
4. **响应空数据**（HTTP 200 但 `data[]` 为空，渠道熔断前过渡态）

**实际影响**：B 方案规模化测试 6 张任务，仅 1 张成功，其余 5 张全部因 503 失败。开发期跑批被强行打断。

**核心矛盾**：DMXAPI 价格便宜（实测 ¥0.13/张），但**稳定性达不到开发期实时迭代要求**。

---

## 2. 决策

**采纳"去 DMXAPI 单点依赖"策略**：DMXAPI 不再作为开发期主力出图通道，仅在批量阶段作为容错备选。

### 2.1 美术资产分层供给

| 层级 | 阶段 | 主力工具 | 备选 | 备注 |
|---|---|---|---|---|
| **L1 开发期实时** | M4–M7 程序框架开发 | 现有 5 张 v2 高质量图当 placeholder | ChatGPT Plus 网页手动出图 | 不依赖任何 API |
| **L2 单角色批量** | 一次需要 6+ 张同角色图 | ChatGPT Plus 网页（手贴 prompt） | DMXAPI（跑批前 `ping_dmx.py` 探活） | 网页版稳定性 >> API |
| **L3 工业批量** | 一次需要 30+ 张资产（M7+） | OpenAI 官方 gpt-image-2 GA 直连（≈2026-05） | DMXAPI 容错备份 | 等 GA 后用虚拟卡接入 |
| **L4 极致一致性** | 主角专属 sprite 大量出 | 用现有 v2 图训练 LoRA（Replicate/RunPod ≈ ¥30） | — | 永久免费 + 100% 同人 |

### 2.2 工程层面落地

- **`GEN_CONCURRENCY` 默认值改 1**（已知 ≥ 4 触发 DMXAPI IP 风控）
- **跑批前必须先 `python scripts/ping_dmx.py`** 探活，渠道死的不要硬跑
- **`.env.example` 加警告头**：DMXAPI 仅适合冷批量，不适合开发期实时迭代
- **`docs/art-pipeline.md` 顶部加 SOP 入口**：默认指引开发者走 ChatGPT Plus 手动路线

### 2.3 当前阶段执行优先级

1. **立即推进 M4 战斗系统纵深**（与美术解耦）
2. **现有 5 张 v2 图作为所有角色立绘 placeholder**：`v2_neutral` / `v2_combat` / `v2_walk` / `v15_neutral` / `v15_combat`
3. **暂停所有"靠 DMXAPI 大批量出图"的尝试**，直到 OpenAI GA 或换路线

---

## 3. 不采纳的方案

| 方案 | 拒绝理由 |
|---|---|
| 死磕 DMXAPI（重试 + 容错路由） | 上游渠道熔断不受我们控制，重试只是浪费 token + dev 时间 |
| 现在就转 OpenAI 官方直连 | 不支持银联，需要海外信用卡 + VPN，且账号封禁风险高；GA 还要等约 1 周，性价比低 |
| 立刻部署本地 SD/ComfyUI | 学习曲线 1–2 周，对当前阶段（程序优先）是错误投入 |
| 多供应商 fallback（DMXAPI + 豆包 + Lovart） | 工程量半天，但只解决 L3 层问题；L1/L2 用网页版根本不需要 fallback |

---

## 4. 风险与缓解

| 风险 | 概率 | 缓解 |
|---|---|---|
| ChatGPT Plus 国内访问需翻墙，手动出图节奏慢 | 高 | 接受。开发期出图频次低（每周 ~5 张），人工节奏可控 |
| OpenAI 官方 GA 时间推迟 | 中 | 退路：切到豆包 Seedream 3.0（¥0.08/张，国内直连，支持微信支付） |
| 等待期间美术 placeholder 不够撑场面 | 低 | 5 张 v2 图覆盖主角各种姿态，配角可临时复用 |
| 长期主角风格漂 | 低 | 后期投 ¥30 训 LoRA 一劳永逸 |

---

## 5. 复审节点

- **2026-05-10**：检查 OpenAI 官方 gpt-image-2 是否 GA，重新评估 L3 主力是否切回 OpenAI 直连
- **M7 完成时**：检查美术资产实际消耗量，决定是否启动 L4（LoRA 训练）

---

## 附：今日决策证据链

- `assets/raw/consistency_test/scale/scale_v2_walk.png` — 第 5 张同角色高质量图，证明纯 prompt 锚定可规模化
- `logs/failed.log` — 5 个 task 503 熔断证据
- `scripts/ping_dmx.py` — 渠道存活探测脚本（决策 2.2 工具落地）

---

## 6. 2026-04-27 修订 #2：L1 / L2 工具边界明确

### 6.1 起因

[`docs/art-validation-plan-v2.md`](../art-validation-plan-v2.md) 初版顶部写了：

> 决策（ADR-001 升级版）：美术验证全部走 ChatGPT Plus 网页，**不再依赖 DMXAPI 任何一行 API 调用**。

被用户合理质疑：**"不能都是手动出图啊"**——如果 L2 批量阶段（700+ 资产）也手动，根本不现实。

### 6.2 修正

之前 ADR §2.1 已经分了 L1–L4 四层，但实施文档（`art-validation-plan-v2.md`）把"L1 用网页"误读成了"整个项目永远不再用 DMXAPI"。措辞过激。**本次修订在 ADR 里明确划定 L1 / L2 工具边界**，避免再被错误外推。

### 6.3 明确的工具边界

| 阶段 | 资产数量 | 主力工具 | 备注 |
|---|---|---|---|
| **L1 风格验证** | 5-20 张 | ChatGPT Plus 网页**手动** | 决策导向，30-40 分钟拿结论。手动是为了避开 DMXAPI 不稳定带来的反复挫败感，**不是 DMXAPI 不能用** |
| **L2 批量生产** | 100-1000+ 张 | DMXAPI `gpt-image-2` **API 自动化**（含容错） | 手动方案废弃。必须有跑批工程能力 |
| **L3 极致一致性** | 主角专属 sprite 大量出 | LoRA 本地推理 | 不变（同 §2.1） |

### 6.4 L2 阶段必须做的容错工程清单

L1 通过后启动 L2 之前，[`scripts/gen_assets.py`](../../scripts/gen_assets.py) 必须重构以下能力：

| 能力 | 实现方式 | 解决的失败模式 |
|---|---|---|
| 跑批前探活 | 调用 [`scripts/ping_dmx.py`](../../scripts/ping_dmx.py)，失败直接终止 | 503 渠道熔断（不浪费 token） |
| 默认低并发 | `--concurrency 1`（最多 2） | IP 风控（30+ 分钟封禁） |
| 失败分类重试 | 见下表 | 4 类失败差异化处理 |
| 自动降级 | 主路失败 → fallback `gpt-image-1.5` → fallback OpenAI 直连 | 单一渠道熔断时不阻塞跑批 |
| 失败任务持久化 | 写 `logs/failed.log`，下次跑批可只重试失败 | 避免重跑成功任务 |

4 类失败的差异化处理：

| 失败模式 | 检测特征 | 处理策略 |
|---|---|---|
| IP 风控 | `APIConnectionError` + `schannel: SEC_E_INVALID_TOKEN` | 跑批暂停 30 分钟后整体重试，**不要单任务 retry**（会火上浇油） |
| Azure moderation | `BadRequestError 400 moderation_blocked` | **不重试**，写 failed.log 等人工改 prompt |
| 上游 503 渠道熔断 | `InternalServerError 503: 所有令牌分组 default 下对于模型 X 均无可用渠道` | 退避 5 分钟探活；3 次失败后整体降级到 `gpt-image-1.5` |
| 200 空响应 | `RuntimeError: API 未返回图像数据` | 视为可重试，3 次内 retry |

### 6.5 OpenAI 直连备路（L3 阶段切换）

约 2026-05 OpenAI `gpt-image-2` 公开 GA 后：

- L3 主力切到 OpenAI 直连（虚拟卡 / IP 注意）
- DMXAPI 转为 fallback（成本优势仍在，但稳定性永远赶不上原厂）
- gpt-image-1.5 不再作为降级（OpenAI 直连本身就稳）

### 6.6 当前阶段的可执行落点

- **现在做**：L1 风格验证（5 张 NPC 立绘手动出图，30-40 分钟）
- **不做**：[`scripts/gen_assets.py`](../../scripts/gen_assets.py) 容错重构，等 L1 通过再做（避免提前优化）
- **不做**：M5+ 玩法实现，等美术验证有定论再决定整个项目方向
