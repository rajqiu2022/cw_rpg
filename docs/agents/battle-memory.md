# Battle Memory

> Role: `battle` / 战斗与数值 agent.
> Scope: battle controller behavior, enemy and skill data, equipment values, combat feel, status effects.
> Canonical docs: `docs/design-mvp-chapter1.md`, `docs/acceptance-checklists/battle.md`.

## Current Combat Shape

- MVP combat is 1v1 turn-based.
- Current battle flow is data-driven from `.tres` resources.
- Enemy defeat should feed `EventBus` so `QuestManager` can progress objectives.
- Equipment bonuses stack into player stats.
- Loot comes from `EnemyDef.drop_*`.

## Owned Files

- `game/scripts/battle/battle_controller.gd`
- `game/data/skills/*.tres`
- `game/data/enemies/*.tres`
- combat-facing value fields in `game/data/equipment/*.tres`

## Shared Boundaries

- Equipment names and descriptions: `lore`.
- Equipment slot schema and UI: `system`.
- Combat tests and repro: `qa`.
- Visual effects or sprite prompts: `art`.

## Tuning Rules

- Any value change must include:
  - adjustment reason
  - expected player experience
  - measured comparison against previous version when possible
- First chapter regular fights should stay short enough for MVP pacing.
- Boss fights may be longer, but must communicate risk and recovery clearly.
- Avoid hidden mechanics that the current UI cannot explain.

## Status Effects Preparation

M6 likely introduces status effects. Do not add partial status mechanics without these fields being designed:

- status id
- display name
- duration rule
- stack rule
- per-turn effect
- remove condition
- UI text / icon placeholder
- save persistence rule

## Known Risks

- Battle changes can silently break quest progression if `enemy_defeated:<id>` changes.
- Reward tuning can break economy if shop prices are not considered.
- Adding a new equipment slot belongs to `system`, not `battle`.

_Last updated: 2026-04-30_
