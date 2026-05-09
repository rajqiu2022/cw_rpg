# System Memory

> Role: `system` / Godot 系统 agent.
> Scope: Godot architecture, autoloads, field routing, save schema, inventory/equipment/shop/UI systems.
> Canonical docs: `docs/design-mvp-chapter1.md`, `docs/module-owners.md`, `docs/acceptance-checklists/system.md`.

## Architecture Snapshot

- Engine: Godot 4 + GDScript.
- Core runtime chain: main menu → `SceneRouter` → Field scene → dialog / battle / shop / inventory / quest UI.
- Current system design doc: `docs/system-technical-design-v0.1.md` (2026-05-04).
- Latest handoff doc: `docs/system-handoff-2026-05-04.md`.
- Autoloads currently include:
  - `EventBus`
  - `GameState`
  - `Inventory`
  - `SceneRouter`
  - `SaveManager`
  - `DialogPlayer`
  - `QuestManager`
- Save schema is currently v3 and includes `inventory`.
- `SceneScript` now supports walkable `collision_rects` and `trigger_zones`; `field_walkable_controller.gd` generates static obstacles and trigger areas from those arrays.

## Critical Invariants

- `EventBus` is the signal hub. New cross-system events should go through it.
- `SceneRouter.resolve_action()` is the action string gateway. Keep action syntax centralized.
- `SceneRouter.go_field_smart(scene_id, spawn?)` is now the standard entry for field transitions. It reads `SceneScript.is_walkable` and chooses classic `field.tscn` vs `field_walkable.tscn`; use it for saves, battle victory/flee returns, shop returns, dialog `scene:` actions, and exits.
- UI-opening action strings must go through `EventBus.ui_requested(panel_id)`; `SceneRouter` must not hold Field UI node references.
- `QuestManager.accept()` and `QuestManager.complete()` are the only external quest state APIs.
- Do not emit quest signals directly from random systems.
- `SaveManager` schema upgrades must include migration notes and `experience-log.md` entries.
- Missing `game/art/**/*.png` must not break scenes; preserve `FallbackBg` and HintBar behavior.

## Known Past Pitfalls

- `SceneRouter` once missed `go_shop()` while data referenced `shop:` actions; always verify router API and data actions together.
- Classic Field and walkable Field still have low-level entry helpers, but feature code should not call them directly. If battle/shop/save/exit paths bypass `go_field_smart()`, a scene can reopen in the wrong container and lose its interaction model.
- PNG `.import` files are not enough. If real PNGs are missing, runtime textures are empty.
- UI fallback exists because early runs looked blank when art was not actually in repo.
- Inventory / equipment changes must update save serialization and UI together.

## Data / File Ownership

- Owns scripts under `game/scripts/autoload/`, `game/scripts/field/`, `game/scripts/ui/`, `game/scripts/domain/`.
- Owns scene wiring under `game/scenes/`.
- Shares data ownership with:
  - `lore` for text in `.tres`
  - `battle` for combat numbers
  - `art` for actual image files and paths

## Preferred Verification

- Open Godot project without parser errors.
- Run relevant `game/tests/*.gd` when `GODOT_BIN` is configured.
- For save changes: new game → save → quit → continue → verify current field, inventory, quest state.
- For router changes: test every changed action string once.

## Lessons

- Treat `.tres` data as part of the system contract. Script changes and data changes must be validated together.
- Do not fix failing tests by weakening tests unless QA agrees the original acceptance was wrong.
- If a system task needs new art assets, block on an `art` handoff instead of inventing placeholder final paths.
- For 45° turn-based battle, keep battle logic data-driven and put 45° layout/animation in a `BattleView` layer; do not mix visual stance with damage formulas or quest events.
- Router changes should include a search for direct `SceneRouter.go_field(` / `go_field_walkable(` calls; exits are easy to miss because they live in `field_walkable_controller.gd`.
- Trigger zones that emit `set_flag` can cause Field rebuilds; preserve the player's current normalized position when rebuilding walkable scenes.

_Last updated: 2026-05-04_
