"""Offline preflight for the two measured y weapon-envelope edits. No generation/network/engine."""
import hashlib
import json
from pathlib import Path

import yaml

ROOT = Path(__file__).resolve().parents[2]
BASE = ROOT / "prompts/luoyang_soldier_diversity_20261019y"
NAMES = [
    "young_gate_sentry_idle_down_1f_v2_weapon_envelope_edit",
    "old_veteran_idle_down_1f_v2_weapon_envelope_edit",
]
PREFIX = "luoyang_soldier_diversity_20261019y_"
tasks_path = ROOT / "prompts/tasks.yaml"
tasks = yaml.safe_load(tasks_path.read_text(encoding="utf-8"))["tasks"]
checks = {"edit_tasks_are_last_two": [row.get("id") for row in tasks[-2:]] == [PREFIX + name for name in NAMES]}
files = [tasks_path, Path(__file__)]
for name in NAMES:
    task_id = PREFIX + name
    rows = [row for row in tasks if row.get("id") == task_id]
    row = rows[0] if len(rows) == 1 else {}
    prompt_path = BASE / f"npc_luoyang_{name}.txt"
    spec_path = BASE / f"npc_luoyang_{name}.spec.json"
    spec = json.loads(spec_path.read_text(encoding="utf-8"))
    prompt = prompt_path.read_text(encoding="utf-8")
    reference = ROOT / spec["reference_image_path"]
    files.extend([prompt_path, spec_path, reference])
    checks[f"{name}_single_registration"] = len(rows) == 1
    checks[f"{name}_builtin_edit_only"] = row.get("execution_backend") == spec["execution_backend"] == "builtin_image_gen" and row.get("execution_mode") == spec["execution_mode"] == "edit"
    checks[f"{name}_unknown_provider"] = row.get("model") is None and row.get("provider") is None and spec["model"] is None and spec["provider"] is None and spec["cost"] is None
    checks[f"{name}_single_attempt_no_fallback"] = row.get("attempt_budget") == spec["attempt_budget"] == 1 and row.get("attempts_used") == spec["attempts_used"] == 0 and row.get("retries_allowed") is False and row.get("cli_fallback_allowed") is False and row.get("skip") is True
    checks[f"{name}_reference_exact"] = row.get("reference_image_path") == spec["reference_image_path"] and hashlib.sha256(reference.read_bytes()).hexdigest() == spec["reference_image_sha256"]
    checks[f"{name}_new_output_absent"] = not (ROOT / spec["output_path"]).exists() and not (ROOT / spec["metadata_path"]).exists()
    checks[f"{name}_preserve_and_padding_prompt"] = all(token in prompt for token in ["Preserve the exact same", "transparent padding", "not a redesign", "Do not crop"])
report = {
    "kind": "OFFLINE_BUILTIN_TARGETED_EDIT_PREFLIGHT",
    "passed": all(checks.values()),
    "checks": checks,
    "generation_calls": 0,
    "network_calls": 0,
    "sdk_calls": 0,
    "engine_calls": 0,
    "authorized_future_calls": 2,
    "files": [{"path": str(path.relative_to(ROOT)).replace("\\", "/"), "sha256": hashlib.sha256(path.read_bytes()).hexdigest(), "bytes": path.stat().st_size} for path in files],
    "note": "These are bounded reference edits with new output names. The six v1 raw files remain untouched; no retries after these two calls.",
}
print(json.dumps(report, ensure_ascii=False, indent=2))
raise SystemExit(0 if report["passed"] else 1)
