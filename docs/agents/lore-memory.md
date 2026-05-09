# Lore Memory

> Role: `lore` / 剧情与世界观 agent.
> Scope: world bible, character voice, naming rules, dialog text, quest prose, story consistency.
> Canonical docs: `docs/world-bible.md`, `docs/design-mvp-chapter1.md`, `docs/acceptance-checklists/lore.md`.

## Canonical Setting

- Current protagonist: 冷孤云.
- Current chapter frame: 林西村下山 → 村外教学战 → 竹尾村 / 密林推进 → 章末 Boss.
- Current major factions: 茗雾山庄 / 烈云盟.
- The old placeholder world must not leak into new text.

## Forbidden / Replace Rules

| Old / Forbidden | Replacement / Rule |
|-----------------|--------------------|
| 沈不归 | 冷孤云 |
| 清风镇 | Use current v0.3 location names from `world-bible.md` / `design-mvp-chapter1.md` |
| 黑教 | 茗雾山庄 or the correct v0.3 faction context |
| 赵无忌 | Use current chapter boss identity from v0.3 design |
| 蜘蛛 / 蛛网意象 | Forbidden unless user explicitly changes world bible |
| 繁体中文 | Use simplified Chinese |

## Dialog Style Rules

- Keep field dialog concise enough for the bottom dialog box.
- NPC lines should reveal role, pressure, and local stakes quickly.
- Player choices should sound like player intent, not author commentary.
- If a dialog node has mechanical side effects, keep the text aligned with the actual effect.

## Data Files Owned

- `game/data/dialogs/*.tres`: `speaker`, `text`, `choices`, narrative flow wording.
- `game/data/quests/*.tres`: title, description, objective prose.
- Shared ownership:
  - quest trigger / reward structure: `system` / `battle`
  - item or equipment stats: `system` / `battle`

## Acceptance Must Include

- No old placeholder names.
- No forbidden imagery.
- `on_end` and side-effect IDs still resolve.
- Quest reward wording matches actual reward fields.
- Changed story state is reflected in `docs/current-progress.md` when it affects sprint status.

## Lessons

- Do not rewrite script resources as pure prose. `.tres` files carry both narrative text and mechanical hooks.
- For batch replacements, inspect a few surrounding lines before changing to avoid replacing historical notes or comments incorrectly.
- When lore touches trigger strings or rewards, hand off to `system` or `battle` for validation instead of guessing.

_Last updated: 2026-04-30_
