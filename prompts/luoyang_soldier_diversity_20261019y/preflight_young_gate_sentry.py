"""Offline preflight for the first y soldier builtin call. No SDK, network, engine or generation."""
import hashlib
import json
from pathlib import Path

import yaml

ROOT = Path(__file__).resolve().parents[2]
TASK_ID = "luoyang_soldier_diversity_20261019y_young_gate_sentry_idle_down_1f_v1"
SPEC = ROOT / "prompts/luoyang_soldier_diversity_20261019y/npc_luoyang_young_gate_sentry_idle_down_1f_v1.spec.json"
PROMPT = ROOT / "prompts/luoyang_soldier_diversity_20261019y/npc_luoyang_young_gate_sentry_idle_down_1f_v1.txt"

tasks = yaml.safe_load((ROOT / "prompts/tasks.yaml").read_text(encoding="utf-8"))["tasks"]
rows = [row for row in tasks if row.get("id") == TASK_ID]
spec = json.loads(SPEC.read_text(encoding="utf-8"))
prompt = PROMPT.read_text(encoding="utf-8")
row = rows[0] if len(rows) == 1 else {}
checks = {
    "one_registered_task": len(rows) == 1,
    "builtin_only": row.get("execution_backend") == spec["execution_backend"] == "builtin_image_gen",
    "unknown_model_honest": row.get("model") is None and row.get("provider") is None and spec["model"] is None and spec["provider"] is None,
    "one_attempt_no_retry": row.get("attempt_budget") == spec["attempt_budget"] == 1 and row.get("attempts_used") == spec["attempts_used"] == 0 and row.get("retries_allowed") is False,
    "legacy_cli_disabled": row.get("skip") is True and row.get("cli_fallback_allowed") is False and spec["cli_fallback_allowed"] is False,
    "paths_exact": row.get("prompt_path") == str(PROMPT.relative_to(ROOT)).replace("\\", "/") and row.get("spec_path") == str(SPEC.relative_to(ROOT)).replace("\\", "/"),
    "transparent_single_frame": spec["transparent_background"] is True and spec["source_layout"] == {"kind": "single_fullbody_static", "rows": 1, "columns": 1, "frames": 1, "facing": "down_front", "actual_size_px": None, "actual_alpha_bounds": None},
    "runtime_not_preapproved": spec["runtime_authorization"] == "NONE_SOURCE_ART_ONLY" and spec["runtime_target_after_actual_measurement"]["processing_status"].startswith("PENDING_"),
    "required_prompt_content": all(token in prompt for token in ["18–22", "long spear", "transparent", "not a sprite sheet", "No headband", "not a recolour"]),
    "raw_absent_before_call": not (ROOT / spec["output_path"]).exists(),
    "metadata_absent_before_call": not (ROOT / spec["metadata_path"]).exists(),
}
files = [ROOT / "prompts/tasks.yaml", PROMPT, SPEC, Path(__file__), ROOT / "game/scripts/field/npc_node.gd"]
report = {
    "kind": "OFFLINE_BUILTIN_PREFLIGHT_NOT_GEN_ASSETS_CLI_DRY_RUN",
    "passed": all(checks.values()),
    "checks": checks,
    "generation_calls": 0,
    "network_calls": 0,
    "sdk_calls": 0,
    "engine_calls": 0,
    "task_id": TASK_ID,
    "files": [
        {
            "path": str(path.relative_to(ROOT)).replace("\\", "/"),
            "sha256": hashlib.sha256(path.read_bytes()).hexdigest(),
            "bytes": path.stat().st_size,
        }
        for path in files
    ],
    "note": "Root must use builtin image generation directly. Model/provider/cost remain null unless the builtin tool discloses them.",
}
print(json.dumps(report, ensure_ascii=False, indent=2))
raise SystemExit(0 if report["passed"] else 1)
