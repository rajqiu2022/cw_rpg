from __future__ import annotations

import hashlib
import json
from pathlib import Path


ROOT = Path(__file__).resolve().parents[2]
HERE = Path(__file__).resolve().parent
TASK_ID = "luoyang_shore_market_20261020ae_flat_damp_stain_vertical_v4"
PROMPT = HERE / "decal_docks_flat_damp_stain_vertical_v4.txt"
SPEC = HERE / "decal_docks_flat_damp_stain_vertical_v4.spec.json"
TASKS = ROOT / "prompts/tasks.yaml"
OUTPUT = ROOT / "assets/raw/luoyang_shore_market_20261020ae/decal_docks_flat_damp_stain_vertical_v4.png"
REPORT = HERE / "preflight_flat_damp_stain_v4.actual.json"


def sha256(path: Path) -> str:
    return hashlib.sha256(path.read_bytes()).hexdigest().upper()


def task_block(text: str) -> str:
    marker = f"  - id: {TASK_ID}"
    start = text.find(marker)
    if start < 0:
        return ""
    end = text.find("\n  - id: ", start + len(marker))
    return text[start:] if end < 0 else text[start:end]


checks: list[dict[str, object]] = []


def check(name: str, passed: bool, detail: object) -> None:
    checks.append({"name": name, "passed": bool(passed), "detail": detail})


spec = json.loads(SPEC.read_text(encoding="utf-8"))
prompt = PROMPT.read_text(encoding="utf-8")
prompt_lower = prompt.lower()
tasks_text = TASKS.read_text(encoding="utf-8")
block = task_block(tasks_text)

check("unique_registry", tasks_text.count(f"id: {TASK_ID}") == 1,
      tasks_text.count(f"id: {TASK_ID}"))
required_registry = [
    "execution_backend: builtin_image_gen",
    "execution_mode: generate",
    "model: null", "provider: null", "cost: null",
    "transparent_background: true",
    "status: PREFLIGHT_SOURCE_READY_NOT_GENERATED",
    "attempts_used: 0", "attempt_budget: 1",
    "retries_allowed: false", "cli_fallback_allowed: false", "skip: true",
    f"prompt_path: {PROMPT.relative_to(ROOT).as_posix()}",
    f"spec_path: {SPEC.relative_to(ROOT).as_posix()}",
]
missing_registry = [line for line in required_registry if line not in block]
check("registry_contract", bool(block) and not missing_registry, missing_registry)
check("spec_contract",
      spec["status"] == "PREFLIGHT_SOURCE_READY_NOT_GENERATED"
      and spec["execution_backend"] == "builtin_image_gen"
      and spec["execution_mode"] == "generate"
      and spec["model"] is None and spec["provider"] is None and spec["cost"] is None
      and spec["transparent_background"] is True
      and spec["attempt_budget"] == 1 and spec["attempts_used"] == 0
      and spec["automatic_retry"] is False
      and spec["cli_network_or_paid_fallback"] is False
      and spec["runtime_credit"] is False,
      {key: spec.get(key) for key in (
          "status", "execution_backend", "execution_mode", "model", "provider", "cost",
          "transparent_background", "attempt_budget", "attempts_used", "automatic_retry",
          "cli_network_or_paid_fallback", "runtime_credit")})
check("output_absent", not OUTPUT.exists(), OUTPUT.exists())
required_prompt_phrases = [
    "flat orthographic 2.5d ground-overlay view",
    "one connected vertical damp-stain film",
    "no stones, paving blocks, brick joints, rock texture, curb, wall",
    "no perceived height",
    "large clean transparent margins on all four sides",
    "do not draw a new floor",
    "do not imitate the rejected stone-strip images",
]
missing_prompt = [phrase for phrase in required_prompt_phrases if phrase not in prompt_lower]
check("flat_wet_only_prompt", not missing_prompt, missing_prompt)
check("bounded_world_target",
      spec["target_world_envelope_px"]["width_range"] == [80, 100]
      and spec["target_world_envelope_px"]["height_approx"] == 400,
      spec["target_world_envelope_px"])
check("single_call_stop_condition",
      "only newly authorized wet-only generation" in spec["stop_condition"]
      and "no automatic retry" in spec["stop_condition"],
      spec["stop_condition"])

passed = all(bool(row["passed"]) for row in checks)
report = {
    "schema": "luoyang_shore_market_flat_damp_stain_v4_preflight_v1",
    "passed": passed,
    "task_id": TASK_ID,
    "prompt": PROMPT.relative_to(ROOT).as_posix(),
    "prompt_sha256": sha256(PROMPT),
    "spec": SPEC.relative_to(ROOT).as_posix(),
    "spec_sha256": sha256(SPEC),
    "tasks_yaml_sha256": sha256(TASKS),
    "proposed_output": OUTPUT.relative_to(ROOT).as_posix(),
    "proposed_output_exists": OUTPUT.exists(),
    "calls_made_by_preflight": {"generation": 0, "edit": 0, "network": 0, "engine": 0, "sdk": 0},
    "checks": checks,
    "credit_boundary": "Offline registry/source preflight only. Root may make exactly one builtin generation call; no generated-art or runtime credit exists yet."
  }
REPORT.write_text(json.dumps(report, ensure_ascii=False, indent=2) + "\n", encoding="utf-8", newline="\n")
print(json.dumps({"passed": passed, "checks": len(checks), "failed": [row["name"] for row in checks if not row["passed"]]}, ensure_ascii=False))
raise SystemExit(0 if passed else 1)

