# Agent Memory Index

> Purpose: give each role a separate long-term memory so ongoing development does not mix story, systems, battle tuning, art pipeline, QA, and review lessons into one shared context.
> Owner: `producer`.
> Rule: each role reads its own memory before touching its module, then writes back only role-specific lessons.

## Files

| Role | Memory File | Main Scope |
|------|-------------|------------|
| `producer` | `docs/agents/producer-memory.md` | Priority, sprint state, cross-role decisions, integration risks |
| `lore` | `docs/agents/lore-memory.md` | World bible, character voice, naming rules, story debt |
| `system` | `docs/agents/system-memory.md` | Godot architecture, autoloads, save schema, routing, UI systems |
| `battle` | `docs/agents/battle-memory.md` | Skills, enemies, equipment values, combat feel, status effects |
| `art` | `docs/agents/art-memory.md` | Prompt rules, sprite specs, generation models, post-processing |
| `qa` | `docs/agents/qa-memory.md` | Test commands, manual checklists, repro patterns, acceptance evidence |
| `review` | `docs/agents/review-memory.md` | Regression risks, review heuristics, repeated mistakes |
| `art-review` | `docs/agents/art-review-memory.md` | UI 审美审核、信息层次、留白、风格统一、清晰度检查 |

## Read Protocol

For every non-trivial task:

1. `producer` reads global memory:
   - `AGENTS.md`
   - `docs/current-progress.md`
   - `docs/agent-workflow.md`
   - `docs/module-owners.md`
   - `docs/agents/producer-memory.md`
2. `producer` selects the target role(s).
3. Each target role reads:
   - its own `docs/agents/<role>-memory.md`
   - the relevant source files for that module
   - the matching `docs/acceptance-checklists/<role>.md` when one exists
4. After work finishes:
   - role-specific lessons go back into the role memory
   - cross-role lessons go into `producer-memory.md`
   - durable pitfalls still go into `docs/experience-log.md`
   - sprint state goes into `docs/current-progress.md`

## Write Protocol

- Do not dump every detail into memory. Store decisions, constraints, recurring mistakes, commands, and module-specific rules.
- Do not duplicate entire design docs. Link to canonical docs and record only the working summary.
- If a lesson belongs to two roles, write the owner role's memory first, then add a short cross-reference in the other role.
- If a role breaks ownership boundaries, record it in `review-memory.md` and `producer-memory.md`.

## Handoff Addition

Every handoff should now include `memory_files`:

```text
[handoff]
from: producer
to: art
goal: <goal>
memory_files:
  - docs/agents/art-memory.md
context_files:
  - <task files>
acceptance:
  - <verifiable condition>
constraints:
  - <scope limit>
```

_Last updated: 2026-04-30_
