from __future__ import annotations

import hashlib
import json
from pathlib import Path


ROOT = Path(__file__).resolve().parents[2]
HERE = Path(__file__).resolve().parent
MANIFEST = HERE / "followup_generation_manifest.json"
TASKS = ROOT / "prompts/tasks.yaml"
OUT = HERE / "preflight_followups.actual.json"


def sha256(path: Path) -> str:
    return hashlib.sha256(path.read_bytes()).hexdigest().upper()


def block(text: str, task_id: str) -> str:
    marker = f"  - id: {task_id}"
    start = text.find(marker)
    if start < 0:
        return ""
    end = text.find("\n  - id: ", start + len(marker))
    return text[start:] if end < 0 else text[start:end]


checks: list[dict[str, object]] = []


def check(name: str, passed: bool, detail: object) -> None:
    checks.append({"name": name, "passed": bool(passed), "detail": detail})


manifest = json.loads(MANIFEST.read_text(encoding="utf-8"))
tasks_text = TASKS.read_text(encoding="utf-8")
check("budget_exact",
      manifest["initial_generation_budget_total"] == 4
      and manifest["initial_generation_calls_already_used"] == 2
      and manifest["remaining_initial_generation_calls"] == 2
      and manifest["targeted_edit_budget"] == 1
      and manifest["followup_calls_used"] == 0,
      {key: manifest[key] for key in (
          "initial_generation_budget_total", "initial_generation_calls_already_used",
          "remaining_initial_generation_calls", "targeted_edit_budget", "followup_calls_used")})
check("no_retry_or_fallback",
      manifest["automatic_retry"] is False and manifest["cli_network_or_paid_fallback"] is False,
      {"automatic_retry": manifest["automatic_retry"], "cli_network_or_paid_fallback": manifest["cli_network_or_paid_fallback"]})
check("three_followup_tasks", len(manifest["tasks"]) == 3, len(manifest["tasks"]))

decision = ROOT / manifest["historical_no_call"]["decision"]
decision_data = json.loads(decision.read_text(encoding="utf-8"))
check("old_timber_proposal_permanent_no_call",
      sha256(decision) == manifest["historical_no_call"]["decision_sha256"]
      and decision_data["status"] == "HISTORICAL_PROPOSAL_PERMANENT_NOTCALL_NOT_GENERATED"
      and decision_data["calls_used"] == 0
      and decision_data["failure_credit"] is False,
      decision_data["status"])

rows: list[dict[str, object]] = []
for row in manifest["tasks"]:
    task_id = row["id"]
    prompt = ROOT / row["prompt"]
    spec_path = ROOT / row["spec"]
    spec = json.loads(spec_path.read_text(encoding="utf-8"))
    task_block = block(tasks_text, task_id)
    mode = "edit" if row["kind"].startswith("single_targeted_edit") else "generate"
    expected = [
        f"execution_mode: {mode}",
        "execution_backend: builtin_image_gen",
        "model: null", "provider: null", "cost: null",
        "transparent_background: true",
        "status: PREFLIGHT_SOURCE_READY_NOT_GENERATED",
        "attempts_used: 0", "attempt_budget: 1",
        "retries_allowed: false", "cli_fallback_allowed: false", "skip: true",
        f"prompt_path: {row['prompt']}", f"spec_path: {row['spec']}",
    ]
    missing = [line for line in expected if line not in task_block]
    check(f"{task_id}:unique_registry", tasks_text.count(f"id: {task_id}") == 1,
          tasks_text.count(f"id: {task_id}"))
    check(f"{task_id}:registry_contract", bool(task_block) and not missing, missing)
    check(f"{task_id}:prompt_sha", sha256(prompt) == row["prompt_sha256"], sha256(prompt))
    check(f"{task_id}:spec_sha", sha256(spec_path) == row["spec_sha256"], sha256(spec_path))
    check(f"{task_id}:spec_contract",
          spec["status"] == "PREFLIGHT_SOURCE_READY_NOT_GENERATED"
          and spec["execution_backend"] == "builtin_image_gen"
          and spec["execution_mode"] == mode
          and spec["model"] is None and spec["provider"] is None and spec["cost"] is None
          and spec["attempt_budget"] == 1 and spec["attempts_used"] == 0
          and spec["automatic_retry"] is False and spec["cli_network_or_paid_fallback"] is False,
          {key: spec.get(key) for key in (
              "status", "execution_backend", "execution_mode", "model", "provider", "cost",
              "attempt_budget", "attempts_used", "automatic_retry", "cli_network_or_paid_fallback")})
    output = ROOT / spec["proposed_output_path"]
    check(f"{task_id}:output_absent", not output.exists(), output.exists())
    rows.append({
        "id": task_id,
        "kind": row["kind"],
        "prompt_sha256": sha256(prompt),
        "spec_sha256": sha256(spec_path),
        "output": spec["proposed_output_path"],
        "output_exists": output.exists(),
    })

rope = manifest["tasks"][0]
measurement = ROOT / rope["anchor_measurement"]
measurement_data = json.loads(measurement.read_text(encoding="utf-8"))
selected = measurement_data["selected_pair"]
check("rope_anchor_measurement",
      sha256(measurement) == rope["anchor_measurement_sha256"]
      and measurement_data["passed"] is True
      and abs(selected["horizontal_span_px"] - 359.86) < 0.001
      and abs(selected["vertical_delta_px"]) < 0.2
      and selected["right_source_alpha"] >= 16,
      selected)

wet_reference = ROOT / manifest["tasks"][2]["reference_image"]
check("wet_edit_exact_reference",
      sha256(wet_reference) == manifest["tasks"][2]["reference_image_sha256"], sha256(wet_reference))

rope_prompt = (ROOT / manifest["tasks"][0]["prompt"]).read_text(encoding="utf-8").lower()
market_prompt = (ROOT / manifest["tasks"][1]["prompt"]).read_text(encoding="utf-8").lower()
edit_prompt = (ROOT / manifest["tasks"][2]["prompt"]).read_text(encoding="utf-8").lower()
check("rope_is_rope_only",
      all(token in rope_prompt for token in (
          "left knot", "runs tautly to the right", "no wooden, stone or metal post", "no bollard", "no detached loop")),
      "single load-bearing knot/hawser, no support object")
check("market_single_connected_ground_patch",
      all(token in market_prompt for token in (
          "one connected transparent ground-overlay patch", "north-south", "east-west",
          "two modest irregular", "no whole city", "wheel ruts", "wet shore")),
      "single connected cross-street/stall-wear patch only")
check("wet_edit_only_extracts_halo",
      all(token in edit_prompt for token in (
          "remove the broad soft grey aura", "preserve the exact vertical stone course", "do not redraw",
          "genuinely transparent")),
      "targeted halo extraction only")

passed = all(bool(row["passed"]) for row in checks)
report = {
    "schema": "luoyang_shore_market_followup_generation_preflight_v1",
    "passed": passed,
    "manifest": str(MANIFEST.relative_to(ROOT)).replace("\\", "/"),
    "manifest_sha256": sha256(MANIFEST),
    "tasks_yaml_sha256": sha256(TASKS),
    "calls_made_by_preflight": {"generation": 0, "edit": 0, "network": 0, "engine": 0, "sdk": 0},
    "tasks": rows,
    "checks": checks,
    "credit_boundary": "Offline source/registry preflight only; no followup call or runtime credit.",
}
OUT.write_text(json.dumps(report, ensure_ascii=False, indent=2) + "\n", encoding="utf-8", newline="\n")
print(json.dumps({"passed": passed, "checks": len(checks), "failed": [row["name"] for row in checks if not row["passed"]]}, ensure_ascii=False))
raise SystemExit(0 if passed else 1)
