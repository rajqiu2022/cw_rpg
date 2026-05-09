# 试运行：主角 8 帧右走 sprite 闭环（多 Agent 协作 v0.1）

> 用途：把当前正在迭代的「冷孤云 8 帧右走 strip + 9 格 loop check」走一遍 `docs/agent-workflow.md` 定义的全流程，作为多 Agent 协作的第一个闭环样例。
> 目标：跑完 producer → art → qa → review → producer 一圈，留下可复用的 handoff、命令与判定结论。
> 状态：✅ 已完成（2026-05-01 复跑 QA 与固定锚点预览）。

---

## 1. producer：拆分与验收标准

### 1.1 用户原始诉求

> 「8 帧比 4 帧顺，但最后一帧到第 1 帧仍跳帧明显。」

### 1.2 拆分

| # | 子任务 | 写权 agent | 输入 | 输出 | 顺序 |
|---|--------|------------|------|------|------|
| T1 | 写 9 格 loop strip 模板 + 任务 | art | 现有 8 帧模板、用户参考图 | `prompts/templates/sprite_protagonist_walk_right_8f_loop_strip.yaml`、`prompts/tasks.yaml` 新任务 | 串行 1 |
| T2 | 出图（仅 gpt-image-2，禁 fallback） | art | T1 模板 | `assets/raw/sprite/v3/sprite_lengguyun_walk_right_8f_loop_strip.png` | 串行 2 |
| T3 | 用 build_sprite_preview 切 9 格 / 8 帧两版预览 | art | T2 原图 | `assets/previews/sprite/sprite_lengguyun_walk_right_8f_loopcheck.gif` 等 | 串行 3 |
| T4 | qa 校验：分割 / 基线 / 高度 / 闭环差异 | qa | T2 原图、T3 预览 | `logs/qa/*.json`、本文件 §3 实测表 | 串行 4 |
| T5 | review：跨模块审查 + 决定是否入库 Godot | review | T1~T4 全部产出 | 决策 + experience-log 追加项 | 串行 5 |

> 三句话验收标准（vs `docs/acceptance-checklists/art.md`）：
>
> - **分割稳定**：用 `scripts/qa/check_sprite_strip.py` 自动分出 9 个角色块。
> - **基线 / 高度极差**：分别 ≤ 12px / 24px。
> - **首尾闭环**：第 9 格姿态与第 1 格相似，且固定锚点 GIF 目视无明显跳帧（loop check 帧本身用于此验收）。

---

## 2. art：实现交接

```
[handoff]
from: producer
to: art
goal: 让 8 帧右走能闭环且帧间动作均匀
context_files:
  - prompts/templates/sprite_protagonist_walk_right_8f_loop_strip.yaml
  - prompts/tasks.yaml
  - assets/raw/sprite/v3/sprite_lengguyun_walk_right_8f_loop_strip.png
  - scripts/build_sprite_preview.py
  - docs/experience-log.md (§15.13~§15.14)
expected_output:
  - 一张通过 loop check 的 9 格 strip
  - 一份 8 帧 GIF 预览
acceptance:
  - 9 格基线偏差 ≤ 12px
  - 8 帧 GIF 接缝肉眼无明显跳跃
  - 衣袍颜色为冷灰，非帧间漂移
  - 不出现头巾 / 额带 / 红头绳
constraints:
  - 仅使用 gpt-image-2，禁 fallback 到 1.5
  - 单次预算 <= ¥1
```

art 已落地：

- 模板：`prompts/templates/sprite_protagonist_walk_right_8f_loop_strip.yaml`
- 任务：`sprite_lengguyun_walk_right_8f_loop_strip`（`sprite/v3`）
- 实际花费：约 ¥0.2226（详见 `assets/raw/sprite/v3/sprite_lengguyun_walk_right_8f_loop_strip.meta.json`）
- 切片预览（保留比例 / 底部锚定）：`assets/previews/sprite/sprite_lengguyun_walk_right_9f_with_loopcheck.gif`、`sprite_lengguyun_walk_right_8f_loopcheck.gif`

---

## 3. qa：实测结论

### 3.1 命令

```powershell
# 8 帧版（旧）
python scripts/qa/check_sprite_strip.py `
  --source assets/raw/sprite/v3/sprite_lengguyun_walk_right_8f_strip.png `
  --expected 8 --baseline-tolerance 12 --height-tolerance 24 `
  --report logs/qa/sprite_walk_right_8f_strip.json

# 9 格 loop check 版（新）
python scripts/qa/check_sprite_strip.py `
  --source assets/raw/sprite/v3/sprite_lengguyun_walk_right_8f_loop_strip.png `
  --expected 9 --baseline-tolerance 12 --height-tolerance 24 `
  --report logs/qa/sprite_walk_right_8f_loop_strip.json
```

### 3.2 结果（2026-04-30）

| 资产 | 检出格 / 期望 | 基线极差 | 高度极差 | 状态 |
|------|---------------|----------|----------|------|
| `sprite_lengguyun_walk_right_8f_strip.png`（旧） | 8 / 8 | 13 px | 13 px | **FAIL**（基线超 12 tol 1 px） |
| `sprite_lengguyun_walk_right_8f_loop_strip.png`（新，9 格 + loop check） | 9 / 9 | 7 px | 7 px | **PASS** |

2026-05-01 复跑结论一致：

- 旧 8 帧 strip：8/8，基线极差 13 px，仍为 **FAIL**，只保留历史对照。
- 9 格 loop-check strip：9/9，基线极差 7 px，高度极差 7 px，仍为 **PASS**。
- 固定锚点预览已重新输出：`assets/previews/sprite/sprite_lengguyun_walk_right_9f_check.gif`、`assets/processed/sprite/sprite_lengguyun_walk_right_9f_check.png`。

### 3.3 解读

- 9 格 loop check 版 **同时改善了基线对齐**（13 → 7 px），说明 loop 校验帧不仅修闭环，也间接迫使模型把人物画得更稳。
- 旧 8 帧版基线偏差 13 px，超过推荐阈值；不建议直接接入 Godot 作为最终素材。
- 「头巾 / 额带 / 红头绳 / 蜘蛛意象」目视检查无违规；衣袍颜色冷灰一致，无帧间漂移。

### 3.4 输出

- `logs/qa/sprite_walk_right_8f_strip.json`
- `logs/qa/sprite_walk_right_8f_loop_strip.json`

---

## 4. review：跨模块审查

| 关注点 | 结论 |
|--------|------|
| 是否影响 Godot 系统模块 | 暂未接图；system agent 不需立即改动 |
| 是否影响存档 schema | 无 |
| 是否破坏既有动画约定 | 无；新文件，旧 4 帧资产保留 |
| 是否新增踩坑 | 是 → 已在 `docs/experience-log.md` §15.13~§15.14 沉淀 |
| 是否需要追加 playbook | 已完成：`docs/sprite-prompt-playbook.md` 增加 9 格 loop check 与零成本 QA 段落 |
| 命名 / 禁忌 | 通过 |
| 模型与预算 | 仅 gpt-image-2，单张 ≈ ¥0.22，符合阶段上限 |

review 决策：

- 采用 9 格 loop strip 版作为后续主角右走的「最小可入库」候选；
- 旧 8 帧纯动画 strip 明确降级为历史对照，不进入 Godot；
- 左走优先评估 `Sprite2D.flip_h` 镜像，避免无必要出图；上 / 下如需新增，按同一 9 格 loop-check 策略单方向最小付费实验。

---

## 5. producer：汇总与下一步

- **本次试运行结论**：流程跑通，`acceptance-checklists/art.md` + `qa.md` 在「8 帧 vs 9 格 loop check」上能稳定输出可量化判定。
- **沉淀**：
  - 增加了 `scripts/qa/check_sprite_strip.py`（QA 角色专属轻量工具）。
  - 经验记录 `docs/experience-log.md` §16 已更新。
  - `AGENTS.md`、`current-progress.md` 已加多 Agent 协作速查节。
- **下一步（不并行）**：
  1. producer 决定是否接受左走使用 `flip_h` 镜像；
  2. 若接受，art 只为上 / 下各做单方向 9 格 loop-check 最小实验；
  3. qa 每个方向复用 `check_sprite_strip.py` + 固定锚点 GIF；
  4. system 只在方向素材全部 PASS 后接入 `Sprite2D` / `AnimatedSprite2D`；
  5. review 一次性对方向资产 + 接图代码做最终审。

---

_最后更新：2026-05-01_
