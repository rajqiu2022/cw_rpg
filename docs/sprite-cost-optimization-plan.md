# Sprite 低成本优化路线（v0.1）

> Owner: `art`.
> Goal: 主角 sprite 还没最终解决前，先减少盲目 API 消耗。每次付费出图前，必须先完成本文件的零成本检查。
> Related: `docs/agents/art-memory.md`, `docs/sprite-prompt-playbook.md`, `docs/experience-log.md` §15.

---

## 1. 当前判断

最近几轮证明了两件事：

- **方向是对的**：单张大立绘式 sprite 不适合游戏；sheet / strip + GIF + QA 才是正确路线。
- **问题还没完全解决**：8 帧右走仍有体块偏大、动作不够游戏 sprite、闭环和脚线稳定性需要继续优化。

因此下一步不要继续“凭感觉重跑”。每次 API 调用前必须先回答：

1. 当前失败是 prompt 问题、参考图问题、裁切/锚点问题，还是源图动作问题？
2. 这个问题能不能用现有 raw + 本地脚本验证？
3. 如果必须出图，是否只重跑 **1 个最小 strip/sheet**？

---

## 2. 零 API 阶段（必须先做）

### 2.1 建立现有资产 QA 表

对每张候选 strip/sheet 先跑 `scripts/qa/check_sprite_strip.py`，不要肉眼直接决定重跑。

```powershell
# 8 帧纯动画 strip
python scripts/qa/check_sprite_strip.py `
  --source assets/raw/sprite/v3/sprite_lengguyun_walk_right_8f_strip.png `
  --expected 8 --baseline-tolerance 12 --height-tolerance 24 `
  --report logs/qa/sprite_walk_right_8f_strip.json

# 9 格 loop-check strip（第 9 格仅校验，不导入游戏）
python scripts/qa/check_sprite_strip.py `
  --source assets/raw/sprite/v3/sprite_lengguyun_walk_right_8f_loop_strip.png `
  --expected 9 --baseline-tolerance 12 --height-tolerance 24 `
  --report logs/qa/sprite_walk_right_8f_loop_strip.json
```

已知结果：

| 资产 | 检出格 | 基线极差 | 高度极差 | 结论 |
|------|--------|----------|----------|------|
| `sprite_lengguyun_walk_right_8f_strip.png` | 8/8 | 13 px | 13 px | FAIL（超 12px 容差 1px） |
| `sprite_lengguyun_walk_right_8f_loop_strip.png` | 9/9 | 7 px | 7 px | PASS |

### 2.2 统一预览，不看自动裁白边 GIF

所有 GIF 都用固定画布 + bottom-center anchor。不要直接把不同尺寸裁白边 PNG 串起来。

```powershell
python scripts/build_sprite_preview.py `
  --source assets/raw/sprite/v3/sprite_lengguyun_walk_right_8f_loop_strip.png `
  --cols 9 --segment-columns `
  --sprite-height 96 --canvas-width 160 --canvas-height 160 `
  --duration-ms 90 `
  --output-gif assets/previews/sprite/sprite_lengguyun_walk_right_9f_check.gif `
  --output-sheet assets/processed/sprite/sprite_lengguyun_walk_right_9f_check.png
```

### 2.3 先归因，再出图

| 现象 | 优先判断 | 不该马上做的事 |
|------|----------|----------------|
| GIF 跳 | 是否裁切/锚点不统一 | 直接重跑 prompt |
| 第 8 帧回第 1 帧跳 | 源动作不闭环 | 重跑普通 8 帧，不加 loop check |
| 角色忽大忽小 | 源图格内比例不稳 / 后处理 resize 不稳 | 批量重跑四方向 |
| 衣服/酒壶/头发漂移 | 参考图缺失或 prompt 硬锁不够 | 无参考纯文跑多帧 |
| 头巾/额带出现 | identity hard lock 失败 | 继续沿用该图做后续参考 |

---

## 3. Dry-run 阶段（仍不付费）

每个付费任务前先 dry-run，且涉及参考图的模板必须 `require_reference_images: true`。

```powershell
python scripts/gen_assets.py `
  --task sprite_lengguyun_walk_right_8f_loop_strip `
  --dry-run --force
```

检查项：

- `reference_images` 文件真实存在。
- prompt 里没有旧 IP / 旧主角 / 头巾 / 45° 等距地砖描述。
- 任务格数和 QA 命令一致：8 帧用 `--expected 8`，9 格 loop-check 用 `--expected 9`。
- 如果用 `--fallback-model gpt-image-2`，确认不会自动切到 `gpt-image-1.5`。
- dry-run meta 应写入 `logs/dry_run/<task_id>.meta.json`，不要覆盖 `assets/raw/**/*.meta.json` 的真实出图成本记录。

---

## 4. 最小付费实验

只有通过 §2 和 §3 后，才允许付费出图。规则：

- 一次只跑 **1 个 task**，不要连跑 4 向或 9 张。
- 必须加 `--fallback-model gpt-image-2`，除非 producer 明确批准 fallback。
- 每次出图后立刻跑 QA 表和 GIF，不先继续下一张。
- 单张失败时先写原因，不要立刻第二次重跑。

推荐顺序：

1. 先把右走 9 格 loop strip 做到稳定。
2. 再复制同一策略到左 / 上 / 下。
3. 四向都通过 QA 后，才交给 `system` 接入 Godot。

---

## 5. 下一轮 prompt 优化方向

不要先追求“更华丽”。先让它更像游戏 sprite：

- 小人高度继续压低，目标 72-96px，而不是 110-140px。
- 每格留足白边，不让剑、衣摆、头发跨入邻格。
- 每格身体中心固定，脚底基线固定。
- 8 帧必须含 passing / up 过程态，不要 8 张都是大跨步。
- 9 格 loop-check：第 9 格复制第 1 格；游戏导入只用前 8 格。
- 参考图只用于“传统 RPG sprite sheet 的比例和节奏”，不能照抄蓝衣、标签、深色背景。

---

## 6. Stop Rules

遇到以下情况，停止出图，先回到文档或脚本：

- 同一 prompt 连续 2 次出现头巾 / 额带 / 旧服装。
- QA 基线极差连续两次 > 12px。
- 第 9 格无法接近第 1 格。
- 参考图路径依赖本机绝对路径且文件不存在。
- 本轮已花费超过 producer 批准预算。

---

_Last updated: 2026-04-30_
