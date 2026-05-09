# QA Memory

> Role: `qa` / 测试与验收 agent.
> Scope: automated tests, manual checklists, repro records, verification commands, acceptance evidence.
> Canonical docs: `docs/acceptance-checklists/qa.md`, `docs/mvp-m*-checklist.md`.

## QA Responsibilities

- Verify work against acceptance, not against intention.
- Reproduce bugs with steps, expected result, actual result, and logs.
- Do not modify implementation code while acting as QA.
- If acceptance is untestable, return to `producer` for clarification.

## Current Automated Assets

- `game/tests/test_inventory_m5.gd`: inventory use, equipment slots, serialization roundtrip.
- `scripts/smoke_test.py`: low-cost pipeline smoke test.
- `scripts/verify.py`: project verification when applicable.
- `scripts/qa/check_sprite_strip.py`: sprite strip segmentation / baseline / height QA.

## Common Commands

```powershell
# Sprite strip QA
python scripts/qa/check_sprite_strip.py `
  --source assets/raw/sprite/v3/sprite_lengguyun_walk_right_8f_loop_strip.png `
  --expected 9 --baseline-tolerance 12 --height-tolerance 24 `
  --report logs/qa/sprite_walk_right_8f_loop_strip.json
```

Godot test command depends on local `GODOT_BIN`; see `docs/experience-log.md` §14.1.

## Manual Regression Focus

- Main menu: new game / continue game.
- Field: fallback background appears if PNG missing.
- Dialog: choices, side effects, and on_end actions resolve.
- Quest: accept / complete / save / reload persistence.
- Inventory and equipment: slots, use item, save v3 roundtrip.
- Shop: `shop:` actions and `SceneRouter.go_shop()` path.

## Reporting Format

```text
[qa-result]
target: <feature or file>
commands:
  - <command>
result: PASS | FAIL | BLOCKED
evidence:
  - <logs / screenshots / report paths>
notes:
  - <important observation>
```

## Lessons

- A GIF can look wrong because preview frames are cropped inconsistently, not because the source animation is wrong. Verify with fixed-anchor previews.
- `.import` files do not prove PNGs exist.
- QA should preserve failing evidence instead of immediately fixing the implementation.

_Last updated: 2026-04-30_
