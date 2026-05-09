# Review Memory

> Role: `review` / 代码审查 agent.
> Scope: review diffs, catch regressions, check ownership boundaries, identify missing tests and missing experience records.
> Canonical docs: `docs/agent-workflow.md`, `docs/module-owners.md`, role memories relevant to the diff.

## Review Stance

- Findings first, ordered by severity.
- Focus on bugs, regressions, missing tests, data inconsistencies, and ownership violations.
- Do not expand scope or implement feature requests while reviewing.
- Confirm whether new pitfalls require `docs/experience-log.md` updates.

## Standard Checks

- Does the diff touch files outside the assigned role ownership?
- Are data IDs still valid across `.tres`, scripts, and tests?
- Are old placeholder names or forbidden lore concepts reintroduced?
- Does save schema change without migration?
- Does UI rely on missing PNG assets without fallback?
- Does art generation create paid work without dry-run / budget note?
- Does QA evidence exist for risky changes?

## Repeated Historical Risks

- `SceneRouter` actions referenced by data but missing in code.
- Background PNG missing while `.import` exists.
- Sprite GIF jump caused by inconsistent crop / anchor.
- Sprite identity drift between frames.
- Fallback image model used unintentionally.
- Role boundary drift: art changing system code, system changing lore text, QA fixing code directly.

## Review Output Format

```text
[review]
scope: <files / feature>
findings:
  - severity: high | medium | low
    file: <path>
    issue: <what is wrong>
    fix: <recommended fix>
open_questions:
  - <question>
tests_seen:
  - <command or evidence>
experience_log_needed: yes | no
```

## Lessons

- Review should compare against `docs/module-owners.md`, not just code style.
- Passing script output is not enough if the human-facing acceptance was visual or narrative.
- If a change creates a new convention, require it to be added to the relevant role memory.

_Last updated: 2026-04-30_
