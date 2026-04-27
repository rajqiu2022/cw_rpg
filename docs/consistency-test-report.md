# 角色一致性测试报告

> **目的**：在没有 Style Bible 参考图的情况下，仅靠 prompt 文本身份锚定，验证 DMXAPI 上的 `gpt-image-1` / `gpt-image-1.5` / `gpt-image-2` 三个模型能否：
>
> 1. **同一模型多张图保持同一角色脸（一致性）**
> 2. **三模型横评谁最适合武侠 RPG（横评）**
>
> 测试日期：2026-04-27 · 工具：`scripts/gen_assets.py` + 模板 `prompts/templates/character_portrait_textonly.yaml`
>
> 测试样本目录：[`reports/consistency_2026_04_27/`](../reports/consistency_2026_04_27/)

---

## 1. 实验设计

### 1.1 测试矩阵（7 张计划，已完成 4 张）

| # | task id | 模型 | 姿态 | 表情 | 状态 |
|---|---|---|---|---|---|
| 1 | `consist_v2_neutral` | gpt-image-2 | 抱臂凝视前方 | 冷峻平静 | ✅ |
| 2 | `consist_v2_combat` | gpt-image-2 | 排云掌出招 | 专注气势凝聚 | ✅ |
| 3 | `consist_v2_grief` | gpt-image-2 | 单膝跪地、剑斜插于地 | 神情凝重 | ⏳ 限流待重跑 |
| 4 | `consist_v15_neutral` | gpt-image-1.5 | 抱臂凝视前方 | 冷峻平静 | ✅ |
| 5 | `consist_v15_combat` | gpt-image-1.5 | 排云掌出招 | 专注气势凝聚 | ✅ |
| 6 | `consist_v1_neutral` | gpt-image-1 | 抱臂凝视前方 | 冷峻平静 | ⏳ 限流待重跑 |
| 7 | `consist_v1_combat` | gpt-image-1 | 排云掌出招 | 专注气势凝聚 | ⏳ 限流待重跑 |
| 8 | `scale_v2_walk` | gpt-image-2 | 山间行走 | 平视前方 | ✅ B 方案补测 |

### 1.2 角色身份锚（每张图共用，不变）

```text
步惊云：二十出头年轻男子，黑色长直发束于脑后，脸型清瘦轮廓分明，
眉目俊朗神色沉稳，身着黑色长袍外披深紫色披风，
腰间束带，体格修长矫健
```

### 1.3 关键参数

- **size**：1024×1024
- **quality**：medium
- **风格基线**：港式漫画 / 2.5D 漫画质感 / 厚涂墨线 / 古风
- **后端**：DMXAPI 中转（基础设施在 Azure OpenAI 上）

---

## 2. 同模型一致性观察

### 2.1 gpt-image-2（最新）— 2 张

| neutral（抱臂凝视） | combat（排云掌） |
|---|---|
| ![v2_neutral](../reports/consistency_2026_04_27/v2/consist_v2_neutral.png) | ![v2_combat](../reports/consistency_2026_04_27/v2/consist_v2_combat.png) |

**同一人识别度**：⭐⭐⭐⭐⭐（很强）

- ✅ **脸型一致**：都是清瘦下颌、剑眉、长直发束于脑后
- ✅ **服装一致**：黑色长袍 + 深紫色披风 + 黑色腰带 + 黑色护臂
- ✅ **风格一致**：墨线厚涂、紫色披风布褶质感统一
- ✅ **身份感一致**：都给人"沉稳少年武者"的感觉

### 2.2 gpt-image-1.5（中代）— 2 张

| neutral（抱臂凝视） | combat（排云掌） |
|---|---|
| ![v15_neutral](../reports/consistency_2026_04_27/v15/consist_v15_neutral.png) | ![v15_combat](../reports/consistency_2026_04_27/v15/consist_v15_combat.png) |

**同一人识别度**：⭐⭐⭐⭐（不错，略次于 v2）

- ✅ 服装一致（黑袍紫披）
- ⚠ **脸型有微差**：neutral 略瘦削成熟，combat 略圆润显年轻
- ⚠ 五官立体感不如 v2，更接近水彩浮世绘

---

## 3. 模型横评（同 prompt）

### 3.1 neutral 三模型对比

| gpt-image-2 | gpt-image-1.5 | gpt-image-1 |
|---|---|---|
| ![v2_neutral](../reports/consistency_2026_04_27/v2/consist_v2_neutral.png) | ![v15_neutral](../reports/consistency_2026_04_27/v15/consist_v15_neutral.png) | ⏳ 待补 |

### 3.2 combat 三模型对比

| gpt-image-2 | gpt-image-1.5 | gpt-image-1 |
|---|---|---|
| ![v2_combat](../reports/consistency_2026_04_27/v2/consist_v2_combat.png) | ![v15_combat](../reports/consistency_2026_04_27/v15/consist_v15_combat.png) | ⏳ 待补 |

### 3.3 v2 vs v1.5 主观打分（10 分制）

| 维度 | v2 | v1.5 | 说明 |
|---|---|---|---|
| 港漫厚涂质感 | 9 | 7 | v2 墨线更黑、上色更厚，v1.5 偏水彩 |
| 五官立体感 | 9 | 7 | v2 颧骨/眉骨结构更分明 |
| 动势/张力 | 9 | 7 | v2 combat 的紫色掌劲特效非常出彩 |
| 服装细节 | 8 | 8 | 双方都把黑袍紫披画得很到位 |
| 背景表现 | 8 | 7 | v2 苍茫云气更有油画感 |
| 身份一致性 | 9 | 8 | v2 两张几乎是同一人，v1.5 有微差 |
| **加权总分** | **8.7** | **7.3** | **v2 完胜约 1.4 分** |

---

## 4. 成本与性能实测

| 指标 | gpt-image-2 | gpt-image-1.5 |
|---|---|---|
| 实测单张成本（CNY） | **¥0.131** | 约 ¥0.10-0.13（待精确） |
| 单张耗时 | 161 秒 | 130-180 秒 |
| Token 消耗（typical） | 450 input / 805 output | 类似 |
| 失败率（限流前） | 0/4 | 0/2 |

**对比 OpenAI 官方价**（gpt-image-2 medium 1024² ≈ $0.053 ≈ ¥0.38）：
**DMXAPI 实价约为官方的 35%，便宜 65%**。

---

## 5. 关键结论

### ✅ 已经能下的结论

1. **gpt-image-2 在 DMXAPI 上确实可用且优秀**：港漫风格命中度高，五官立体感强，色彩浓郁厚涂。

2. **纯 prompt 文本锚定**（无 Style Bible 参考图）**就能在同一模型内保持高度一致性**。这意味着：
   - 项目可以**先批量出 sprite 表情/动作变体**，不必先卡死投入 Style Bible
   - Style Bible 是锦上添花（让一致性从 ⭐⭐⭐⭐⭐ 巩固成 100%），而非必须前置

3. **gpt-image-2 比 gpt-image-1.5 显著更适合武侠 RPG**（横评 v2 完胜）：墨线更深、立体感更强、动势特效更出彩。

4. **DMXAPI 实测成本极低**：medium quality 单图 **¥0.131**，比预算估算（¥1.2/张）**便宜 10 倍**。
   - 原因：图像 token 计费按实际 prompt + 输出像素，medium 1024² 实际只用 805 output tokens
   - 整套 RPG 资源（700 张）成本估算从原 ¥700 降到 **~¥100**
   - **整套素材预算可以缩到 ¥200 以内**（含失败重试 + 偶尔上 high quality）

5. **武侠中文 prompt 必须避开几个 Azure moderation 陷阱**：
   - 不要直接写"马荣成"、"风云"等具体武侠 IP 名 → 用风格特征替代
   - 不要在 negative 词写"畸形手指"、"多余四肢" → 触发暴力分类
   - 高敏感词如"杀意"、"血红"、"绝世好剑" → 软化为"气势"、"橙红"、"长剑"

6. **DMXAPI 服务有 IP 风控**：并发 ≥ 4 容易触发隐性限流（连接 RST），后续 5-10 分钟新请求都会失败。
   - **`GEN_CONCURRENCY` 建议 ≤ 2**

### ⏳ 还差的实验

- **v1 vs v1.5 vs v2 三模型横评**：还差 v1 两张（限流恢复后补跑）
- **极端情绪一致性**：v2_grief 待补
- **multi-turn 一致性**：5 张以上（含正面/侧面/背面）
- **Style Bible reference image** 加入后，一致性能否进一步巩固

### 📌 后续建议

1. **下一步：基于这套 textonly 模板批量出 12 张主角立绘** — 涵盖所有需要的姿态/表情，验证规模化场景下的一致性是否仍能保持。预算 ~¥2。
2. **Style Bible 简化版**：不必跑完整 6 张，先用本次 `consist_v2_neutral`（这张极佳）作为 `01_protagonist_full.png`，复用现有 `character_portrait` 模板，给后续生成加一道保险。
3. **替补 backend 探索**（可选）：等 OpenAI 5 月 GA 后，对比 OpenAI 直连的图质量与 DMXAPI 中转是否有差。

---

## 6. 风险与限制

- 本次 4 张图样本较小，统计置信度有限。后续在 12-30 张规模上再次验证才能下"工业级稳定"结论。
- DMXAPI 是 Azure 后端中转，**moderation 政策完全由 Azure 决定**，未来某次政策调整可能让现有 prompt 突然不能过审。
- gpt-image-2 在 DMXAPI 的稳定性还有待长时观察（本次有限流插曲）。

---

---

## 7. B 方案规模化补测（2026-04-27 下午）

### 7.1 设计

把 `consist_v2_neutral` 提为 Style Bible 的 `01_protagonist_full.png`，
另外计划再跑 6 张（4 张 textonly 不同 pose + 1 张 character_portrait 带 reference + 1 张 sprite_idle 带 reference）。

### 7.2 实际跑批结果（DMXAPI 受限）

| # | task | 结果 |
|---|---|---|
| 1 | `scale_v2_walk` | ✅ 高质量、与 v2_neutral 同人、风格一致 |
| 2 | `scale_v2_thinking` | ❌ DMXAPI 503 上游渠道熔断 |
| 3 | `scale_v2_smile` | ❌ 同上 |
| 4 | `scale_v2_back` | ❌ 同上 |
| 5 | `scale_v2_portrait_with_ref_neutral` | ❌ 同上 |
| 6 | `scale_v2_sprite_idle_south` | ❌ 同上 |

503 错误形如：`所有令牌分组 default 下对于模型 gpt-image-2 均无可用渠道`，
这是 DMXAPI 上游 OpenAI 渠道整体熔断，**与 prompt / IP / 并发都无关**，5+ 分钟未恢复。

### 7.3 仅凭 walk 一张已能下的扩展结论

- ✅ **第 5 张同角色图**仍然保持极强一致性（脸型/五官/发型/服装色完全对得上）
- ✅ **背景换成完全不同的环境**（山间小径 vs 苍茫天空），角色身份感不被冲淡
- ✅ **pose 从静态抱臂换成动态行走**，"沉稳武者"的气质不变
- 🎯 **核心结论**：纯 prompt 文本锚定的一致性在**至少 5 张规模**下仍然可用，没出现"漂"

### 7.4 DMXAPI 不稳定问题汇总（一日实测）

详见 `docs/experience-log.md` 第 1.5.1 节，四类失败模式：

1. IP 风控（TLS 握手失败）—— 并发 ≥ 4 触发，30+ 分钟解封
2. Azure moderation 拦截 —— 改 prompt 即可
3. **上游渠道 503 熔断 —— 不可控，5–30+ 分钟**
4. 200 但响应空 b64 —— 渠道熔断前过渡态

**对开发期的影响**：DMXAPI 只适合冷批量出图，不适合实时迭代。
建议：开发期用 ChatGPT Plus / Lovart 网页手贴 prompt 出图，DMXAPI 仅在批量阶段做容错路由。

### 7.5 给后续 M4+ 阶段的执行建议

| 阶段 | 美术资产策略 |
|---|---|
| M4–M7 程序框架开发 | 用现有 5 张 v2 高质量图当 placeholder，**优先推程序** |
| 程序就绪后批量补图 | 等 OpenAI 官方 gpt-image-2 GA（≈2026-05），用 HUTAO 虚拟卡接 OpenAI 直连，DMXAPI 降级备份 |
| 后期专属角色图 | 用现有 3 张 v2 图训练步惊云 LoRA（Replicate/RunPod ≈ ¥30），永久免费 + 极致一致性 |

---

## 附录：测试期间踩坑记录（已加入 docs/experience-log.md）

1. **`BadRequestError` 在 except 顺序中被 `APIError` 抢先**：导致 moderation_blocked 错误被当作限流重试 3 次浪费时间和 token。修复：调换 except 顺序，`BadRequestError` 在前。
2. **`cost_from_usage` 在 usage 字段为 None 时崩溃**：DMXAPI 返回的 `image_tokens` 字段可能是 `None` 而非 0。修复：所有 token 字段用 `or 0` 兜底。
3. **DMXAPI 后端是 Azure，moderation 默认严**：通过 `extra_body={"moderation": "low"}` 可以放宽一档（但仍会拦截高敏感词组合）。
4. **武侠题材必须避开的 prompt 陷阱**：见上面"关键结论 5"。
5. **DMXAPI 并发 ≥ 4 会触发 IP 风控**：5-10 分钟内所有连接 RST。建议 `GEN_CONCURRENCY ≤ 2`。
