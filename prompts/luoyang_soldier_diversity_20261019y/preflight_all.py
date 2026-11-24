"""Offline registry/spec/prompt preflight for y soldiers. No SDK, network, engine or generation."""
import hashlib
import json
from pathlib import Path

import yaml

ROOT = Path(__file__).resolve().parents[2]
BASE = ROOT / "prompts/luoyang_soldier_diversity_20261019y"
IDS = [
    "young_gate_sentry_idle_down_1f_v1",
    "mature_patrol_walk_right_8f_atlas_v1",
    "old_veteran_idle_down_1f_v1",
    "archer_walk_right_8f_atlas_v1",
    "squad_leader_idle_down_1f_v1",
    "commander_idle_down_1f_v1",
]
PREFIX = "luoyang_soldier_diversity_20261019y_"
tasks_path = ROOT / "prompts/tasks.yaml"
tasks = yaml.safe_load(tasks_path.read_text(encoding="utf-8"))["tasks"]
expected_task_ids = [PREFIX + item for item in IDS]
rows = {row.get("id"): row for row in tasks if row.get("id") in expected_task_ids}
checks = {}
checks["six_unique_registered_tasks"] = set(rows) == set(expected_task_ids) and len(rows) == 6
checks["original_six_order_preserved"] = [row.get("id") for row in tasks if row.get("id") in expected_task_ids] == expected_task_ids
files = [tasks_path, BASE / "manifest.json", Path(__file__), ROOT / "game/scripts/field/npc_node.gd"]
specs = []
prompts = []
for item in IDS:
    task_id = PREFIX + item
    row = rows.get(task_id, {})
    spec_path = BASE / f"npc_luoyang_{item}.spec.json"
    prompt_path = BASE / f"npc_luoyang_{item}.txt"
    spec = json.loads(spec_path.read_text(encoding="utf-8"))
    prompt = prompt_path.read_text(encoding="utf-8")
    specs.append(spec)
    prompts.append(prompt)
    files.extend([prompt_path, spec_path])
    checks[f"{item}_task_paths"] = row.get("prompt_path") == str(prompt_path.relative_to(ROOT)).replace("\\", "/") and row.get("spec_path") == str(spec_path.relative_to(ROOT)).replace("\\", "/")
    checks[f"{item}_builtin_unknown_model"] = row.get("execution_backend") == spec["execution_backend"] == "builtin_image_gen" and row.get("model") is None and row.get("provider") is None and spec["model"] is None and spec["provider"] is None and spec["cost"] is None
    output_exists = (ROOT / spec["output_path"]).exists()
    metadata_exists = (ROOT / spec["metadata_path"]).exists()
    attempts_used = row.get("attempts_used")
    checks[f"{item}_one_attempt_no_fallback"] = row.get("attempt_budget") == spec["attempt_budget"] == 1 and attempts_used == spec["attempts_used"] and attempts_used in {0, 1} and row.get("retries_allowed") is False and row.get("cli_fallback_allowed") is False and row.get("skip") is True
    checks[f"{item}_output_state_consistent"] = spec["transparent_background"] is True and spec["runtime_authorization"] == "NONE_SOURCE_ART_ONLY" and output_exists == metadata_exists == (attempts_used == 1)
    checks[f"{item}_prohibited_elements_excluded"] = all(token in prompt for token in ["No headband", "red head string", "spider", "web", "text", "watermark"])
walk_specs = [spec for spec in specs if spec["identity"] in {"mature_patrol", "archer"}]
static_specs = [spec for spec in specs if spec["identity"] not in {"mature_patrol", "archer"}]
checks["four_static_one_frame"] = len(static_specs) == 4 and all(spec["source_layout"]["kind"] == "single_fullbody_static" and spec["source_layout"]["frames"] == 1 for spec in static_specs)
checks["two_walk_exact_4x2_eight"] = len(walk_specs) == 2 and all(spec["source_layout"]["kind"] == "equal_cell_atlas" and spec["source_layout"]["columns"] == 4 and spec["source_layout"]["rows"] == 2 and spec["source_layout"]["frames"] == 8 for spec in walk_specs)
checks["walk_idle_extraction_is_conditional"] = all("if_ART_and_Root_visual_acceptance_passes" in spec["runtime_target_after_actual_measurement"]["idle_extraction"] for spec in walk_specs)
manifest = json.loads((BASE / "manifest.json").read_text(encoding="utf-8"))
checks["manifest_six_calls_one_each"] = manifest["generation"]["maximum_calls"] == 6 and manifest["generation"]["calls_used"] == sum(row.get("attempts_used", 0) for row in rows.values()) and manifest["generation"]["calls_per_identity"] == 1 and manifest["generation"]["retries_allowed"] is False
checks["runtime_target_160_140_8"] = manifest["current_runtime_standard"]["cell_px"] == [160, 160] and manifest["current_runtime_standard"]["target_visible_height_px"] == 140 and manifest["current_runtime_standard"]["target_bottom_transparent_margin_px"] == 8
report = {
    "kind": "OFFLINE_BUILTIN_BATCH_PREFLIGHT_NOT_GEN_ASSETS_CLI_DRY_RUN",
    "passed": all(checks.values()),
    "checks": checks,
    "generation_calls": 0,
    "network_calls": 0,
    "sdk_calls": 0,
    "engine_calls": 0,
    "task_ids": [PREFIX + item for item in IDS],
    "files": [{"path": str(path.relative_to(ROOT)).replace("\\", "/"), "sha256": hashlib.sha256(path.read_bytes()).hexdigest(), "bytes": path.stat().st_size} for path in files],
    "note": "Root runs six separate builtin calls at most. This preflight gives no generation, layout, runtime, import, Field or formal credit.",
}
print(json.dumps(report, ensure_ascii=False, indent=2))
raise SystemExit(0 if report["passed"] else 1)
