# 剧情 / 世界观验收清单（lore）

> 适用对象：剧情 agent 提交对话、任务文案、章节剧情、命名前的最后自检。
> 配套：`docs/world-bible.md` v0.3+、`docs/design-mvp-chapter1.md`、`docs/agent-workflow.md`。

## 必过项

- [ ] 角色名 / 地名 / 门派名与 `world-bible.md` v0.3+ 一致；不出现旧 IP（沈不归 / 清风镇 / 赵无忌 / 黑教 / 武当弟子）。
- [ ] 不出现 `world-bible.md §禁忌` 里禁止的意象（蜘蛛 / 蛛网等）。
- [ ] 简体中文，无繁体字残留；引号、省略号、破折号符合中文排版习惯。
- [ ] 每条对话 `text` 长度适合底部对话框（建议中文 ≤ 60 字 / 行）。
- [ ] `choices` 不超过 4 个；选项措辞为玩家口吻而不是旁白。
- [ ] 所有副作用字段（`give_item` / `give_gold` / `set_flag` / `accept_quest` / `complete_quest`）拼写与 `Inventory` / `QuestManager` 中现有 ID 一致。
- [ ] `on_end` 中 `next:` / `battle:` / `scene:` / `end` 的目标 ID 真实存在。
- [ ] 任务文案中的奖励描述与 `q_*.tres` 中的 `reward_*` 字段口径一致（金额 / 物品名 / 经验值）。
- [ ] 新增 NPC / 任务有写入 `docs/current-progress.md` 的「正在做」或「下一步」。

## 提交时附带

- 改动文件清单
- 主要文案变更前后对照（≤ 5 处）
- 是否影响 `QuestManager` 触发器 / 旧存档（如否，请明说）
