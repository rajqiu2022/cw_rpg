# Producer Memory

> Role: `producer` / 主控 / 制作人 agent.
> Scope: priority, sprint state, task decomposition, acceptance, cross-role decisions, integration risks.
> Read after: `AGENTS.md`, `docs/current-progress.md`, `docs/agent-workflow.md`, `docs/module-owners.md`.

## Operating Rules

- Be the only role that decides scope, priority, merge order, and whether a task is ready for user acceptance.
- Split complex work into 2-4 subtasks before implementation.
- Parallelize exploration only; implementation is serial when files or modules overlap.
- Every handoff must include `memory_files`, `context_files`, `expected_output`, `acceptance`, and `constraints`.
- If acceptance is vague, stop and write concrete acceptance before assigning work.

## Current Project State

- M1-M5 are implemented in the workspace.
- M6 (chapter boss, status effects, chapter ending UI) is the next major engineering milestone.
- M7 (multi-slot save UI) is parked.
- Content debt remains: some in-game `.tres` dialog text and speaker values may still carry old placeholder names.
- Art debt remains: v2 scene images should be synchronized into `game/art/backgrounds/`; protagonist sprite work is still experimental.

## Active Collaboration Model

- v0.1 multi-agent workflow is documented in `docs/agent-workflow.md`.
- Role ownership is documented in `docs/module-owners.md`.
- Independent role memories live under `docs/agents/`.
- Use real subagents for broad read-only exploration or review when the task is complex; use single-role execution for small tasks.
- Local Web coordination lives in `tools/agent_hub/`: it scans repo state, manages tasks, generates handoff text, and tracks QA/cost artifacts. It does not call LLMs or deploy independent agents; execution remains in Cursor.

## Decision Log

| Date | Decision | Reason |
|------|----------|--------|
| 2026-04-30 | Use lightweight role memories before building automation | Prevent memory pollution without prematurely creating a complex agent platform |
| 2026-04-30 | Keep `producer` as final integrator | Avoid multiple agents making conflicting project-level decisions |
| 2026-04-30 | Role memory is not a replacement for `experience-log.md` | Role memories keep working context; `experience-log.md` preserves durable pitfalls |
| 2026-05-01 | Agent Hub v1 is human-in-the-loop | Avoid separate model configuration; Web generates handoff, Cursor agent executes |
| 2026-05-01 | Agent Hub UI uses Chinese display filters | Keep internal enum/protocol stability while showing Chinese labels to users |
| 2026-05-01 | Agent Hub story page is read-only | Keep `world-bible` and design docs as canonical sources before adding Web editing |
| 2026-05-01 | Walk left direction is always derived from walk right by mirror, not by separate API call | Right-walk PASS baseline guarantees identity / pose; left-mirror inherits both at zero API cost |
| 2026-05-01 | Per direction: dry-run -> single paid generation -> immediate QA -> only then next direction | Prevents 2-4x identity drift cost when batching all four directions blind |

## Producer Checklist

- [ ] Read global memory files.
- [ ] Identify target role(s).
- [ ] Check `docs/module-owners.md` for write ownership.
- [ ] Write handoff with `memory_files`.
- [ ] Require role-specific acceptance checklist.
- [ ] Decide whether QA and review are required.
- [ ] Update `docs/current-progress.md` when sprint state changes.

## Open Risks

- The repo currently has many uncommitted files; producer must avoid broad refactors until user decides commit / cleanup strategy.
- Some paths appear duplicated with Windows backslashes; producer should prevent new duplicated path variants.
- Sprite generation can consume budget quickly; producer must approve batch generation beyond small experiments.

_Last updated: 2026-05-05_

