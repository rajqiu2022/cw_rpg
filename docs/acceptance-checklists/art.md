# 美术管线验收清单（art）

> 适用对象：prompt 模板 / 出图任务 / 后处理脚本 / sprite sheet 入库。
> 配套：`docs/sprite-prompt-playbook.md`、`docs/style-bible-prompts.md`。

## 出图前

- [ ] 任务 id 写进 `prompts/tasks.yaml`，没有临时改 `prompts/templates/` 后立刻跑。
- [ ] dry-run 一遍确认没有缺 `reference_images`、缺变量。
- [ ] 明确指定模型：默认 `gpt-image-2`；如需禁 fallback，使用 `--fallback-model gpt-image-2`。
- [ ] 单次预算估算 ≤ 当前阶段上限（参考 `docs/budget.md`）。

## 出图后

- [ ] `assets/raw/` 中的图与 `meta.json` 一一对应。
- [ ] 角色一致性：肤色 / 衣袍颜色 / 道具位置在同一序列中无明显漂移。
- [ ] sprite sheet：脚底基线对齐、身体水平居中（用 `scripts/build_sprite_preview.py --segment-columns` 校验）。
- [ ] 走路 / 攻击循环：第 N 帧能自然接回第 1 帧，没有跳帧。
- [ ] 没有出现违禁元素：头巾 / 额带 / 红头绳 / 蜘蛛 / 蛛网 / 文字水印 / 繁体字。
- [ ] 入库前生成 GIF 预览存到 `assets/previews/sprite/`，方便其他 agent 复看。

## 提交时附带

- 任务 id、模型、张数、预算实际花费
- 至少 1 张 GIF 或对照图
- 是否需要 system agent 接图（如是，给出 Godot 路径建议）
- 新踩坑 → `docs/experience-log.md` 中追加章节号
