# 模块归属表（v0.1）

> 用途：明确每个目录 / 文件的「写权 agent」与「只读 agent」，避免多 agent 互相覆盖。
> 与 `docs/agent-workflow.md` 第 2 节配套使用；变更模块归属必须双文件同步。

---

## 1. 顶层目录归属

| 路径 | 写权 agent | 只读 agent |
|------|------------|------------|
| `docs/world-bible.md` | lore | producer / art / system / battle |
| `docs/design-mvp-chapter1.md` | producer + lore（双签） | 全员 |
| `docs/current-progress.md` | producer | 全员（追加自己模块进展时由 producer 整合） |
| `docs/experience-log.md` | 全员追加，producer 整理结构 | 全员 |
| `docs/agent-workflow.md` | producer | 全员 |
| `docs/ai-rules.md` | producer | 全员 |
| `docs/ui-style-guide.md` | producer + art + system（双签） | 全员 |
| `docs/change-template.md` | producer | 全员 |
| `docs/module-owners.md` | producer | 全员 |
| `docs/agents/README.md` | producer | 全员 |

| `docs/agents/producer-memory.md` | producer | 全员 |
| `docs/agents/lore-memory.md` | lore | producer / review |
| `docs/agents/system-memory.md` | system | producer / review |
| `docs/agents/battle-memory.md` | battle | producer / review |
| `docs/agents/art-memory.md` | art | producer / review |
| `docs/agents/qa-memory.md` | qa | producer / review |
| `docs/agents/review-memory.md` | review | producer |
| `docs/agents/memory-template.md` | producer | 全员 |
| `docs/acceptance-checklists/` | producer + 对应模块 agent | qa |
| `docs/sprite-prompt-playbook.md` | art | 全员 |
| `docs/sprite-cost-optimization-plan.md` | art | producer / qa / system |
| `docs/style-bible-prompts.md` | art | 全员 |
| `docs/mvp-m*-checklist.md` | qa + producer | 全员 |
| `docs/budget.md` | producer | 全员 |
| `docs/dmxapi-setup.md` / `docs/tech-selection.md` / `docs/godot-demo-howto.md` | producer | 全员 |
| `docs/art-pipeline.md` / `docs/art-validation-*.md` / `docs/consistency-test-report.md` | art | 全员 |

---

## 2. Godot 工程 `game/`

| 路径 | 写权 agent | 备注 |
|------|------------|------|
| `game/project.godot` | system | 改 autoload / 输入映射 / 屏幕分辨率 |
| `game/scripts/autoload/event_bus.gd` | system | 信号定义；新增信号必须广播给 lore/qa 评审是否影响订阅 |
| `game/scripts/autoload/game_state.gd` | system | 主角 / 全局 flag |
| `game/scripts/autoload/inventory.gd` | system | 物品 / 装备槽 |
| `game/scripts/autoload/save_manager.gd` | system | schema 升版必须同步迁移 + experience-log |
| `game/scripts/autoload/scene_router.gd` | system | `resolve_action` 是关键路径，改前请 review |
| `game/scripts/autoload/dialog_player.gd` | system | 对话节点的副作用解析 |
| `game/scripts/autoload/quest_manager.gd` | system | 状态机；任务 trigger 字符串语法 |
| `game/scripts/battle/battle_controller.gd` | battle | 调数值不动 UI |
| `game/scripts/domain/*.gd`（CharacterStats / Skill / Item / Equipment / EnemyDef / DialogNode / DialogScript / SceneScript / QuestDef / ShopDef） | system | 字段定义；新增字段需通知 battle/lore |
| `game/scripts/field/*.gd` | system | Field 控制 / 走路 / 互动 |
| `game/scripts/ui/*.gd` | system | UI 行为；文案文字仍归 lore 改 |
| `game/scenes/*.tscn`、`game/scenes/ui/*.tscn` | system | 场景拼装 |
| `game/data/dialogs/*.tres` | lore | speaker / text / choices；副作用字段（give_item 等）由 lore 维护，不动结构 |
| `game/data/quests/*.tres` | lore + system（双签） | 标题/描述 lore，trigger/reward 字符串结构 system |
| `game/data/scenes/*.tres` | lore（hotspot 文案）+ system（路由 action） | 改 background_path 必须美术先入库 |
| `game/data/items/*.tres` | lore（名字/描述）+ system（数值字段） | 字段错位时由 system 修 |
| `game/data/equipment/*.tres` | battle（数值）+ lore（名字描述） | |
| `game/data/skills/*.tres` | battle | |
| `game/data/enemies/*.tres` | battle（数值/AI）+ lore（名字台词） | |
| `game/data/shops/*.tres` | system（结构）+ lore（文案） | |
| `game/tests/*.gd` | qa | 实现 agent 不直接改测试通过，发现失败要复现 |
| `game/art/**/*.png` | art | system 只读，PNG 缺失时 system 必须用 FallbackBg |

---

## 3. 美术管线 `prompts/`、`scripts/`、`assets/`

| 路径 | 写权 agent | 备注 |
|------|------------|------|
| `prompts/templates/*.yaml` | art | 新增模板必须写到 `docs/sprite-prompt-playbook.md` |
| `prompts/tasks.yaml` | art | 任务 id 命名规范见 playbook；改之前 dry-run |
| `scripts/gen_assets.py` | art（命令行使用）+ system（代码维护） | 命令行参数变更要更新 playbook |
| `scripts/build_sprite_preview.py` | art | 拆帧 / GIF 预览 |
| `scripts/postprocess.py` | art | rembg / 后处理 |
| `scripts/ping_dmx.py` / `scripts/check_dmxapi.py` | art + qa | 余额 / 通道健康 |
| `scripts/smoke_test.py` / `scripts/verify.py` | qa | 不烧钱的回归 |
| `assets/raw/**` | art | 出图原始产物，不要手工编辑 |
| `assets/processed/**` | art | 后处理结果 |
| `assets/previews/**` | art | GIF / 对照图 |
| `assets/_style_bible/**` | art + producer（归档决定） | |
| `assets/art_validation_v2/**` | art | 已通过验证的 v2 资产存档 |

---

## 4. 项目根

| 路径 | 写权 agent | 备注 |
|------|------------|------|
| `AGENTS.md` | producer | 任意 agent 修改前必须经 producer 同意 |
| `.env` / `.env.example` | producer | 不进 git；密钥变更需通知 art / qa |
| `prompts\` 等 Windows 反斜杠路径出现的重复目录 | producer | 这是 git 在大小写 / 斜杠混用造成的，请整合，不要随意新增 |

---

## 5. 跨模块改动的处理

凡是同时落地在两个写权 agent 下的改动（例如「新增一种状态异常」需要 battle 改数值 + system 改 SaveManager schema + lore 写描述），必须：

1. producer 拆出 3 个串行子任务并标明顺序。
2. 每个子任务结束都做最小验证（编辑器能开 / 测试能跑 / 数据能加载），再交下一棒。
3. 全部完成后 review agent 跨文件审一次。

---

_最后更新：2026-04-30（新增 `docs/agents/` 角色独立记忆归属）_
