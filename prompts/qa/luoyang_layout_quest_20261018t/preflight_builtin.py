"""Offline builtin imagegen preflight only: no SDK, network, subprocess or generation."""
import hashlib, json
from pathlib import Path
import yaml
ROOT = Path(__file__).resolve().parents[3]
TASK_ID = "luoyang_layout_quest_20261018t_npc_temple_gate_monk_idle_down_1f_v1"
ASSET_ID = "npc_temple_gate_monk_idle_down_1f_v1"
raw_tasks = (ROOT / "prompts/tasks.yaml").read_bytes()
data = yaml.safe_load(raw_tasks)
tasks = data["tasks"]
rows = [row for row in tasks if row["id"] == TASK_ID]
checks = {}
checks["one_new_task"] = len(rows) == 1
row = rows[0]
template_path = ROOT / ("prompts/templates/" + row["template"] + ".yaml")
template = yaml.safe_load(template_path.read_text(encoding="utf-8"))
spec_path = ROOT / row["spec_path"]
spec = json.loads(spec_path.read_text(encoding="utf-8"))
prompt_path = ROOT / row["prompt_path"]
prompt = prompt_path.read_text(encoding="utf-8")
checks["task_ids_unique"] = len([x["id"] for x in tasks]) == len(set(x["id"] for x in tasks))
checks["historical_tasks_prefix_exact"] = hashlib.sha256(raw_tasks[:182977]).hexdigest() == "090276d9cad1c119653abcd2560dc173f4707ebe87db17b2ebcc578ae2688796"
checks["raw_output_absent"] = not (ROOT / spec["output_path"]).exists()
checks["metadata_absent"] = not (ROOT / row["generated_metadata_path"]).exists()
checks["builtin_only"] = row["execution_backend"] == template["execution_backend"] == spec["execution_backend"] == "builtin_image_gen"
checks["unknown_model_not_fabricated"] = row["model"] is None and template["model"] is None and spec["model"] is None
checks["single_attempt_unexecuted"] = row["attempt_budget"] == spec["attempt_budget"] == 1 and row["attempts_used"] == spec["attempts_used"] == 0
checks["no_fallback_retry_or_cli_batch"] = row["retries_allowed"] is False and row["cli_fallback_allowed"] is False and template["builtin_tool_only"] is True
checks["skipped_by_legacy_generator"] = row["skip"] is True
checks["prompt_template_exact"] = template["prompt_template"].strip() == prompt.strip()
checks["single_square_frame"] = spec["intended_size_px"] == [1024,1024] and spec["frames"] == spec["rows"] == spec["columns"] == 1
checks["transparent_background"] = spec["transparent_background"] is True and template["transparent_background"] is True
checks["actual_geometry_not_fabricated"] = spec["source_geometry"]["source_ground_anchor_px"] is None and spec["source_geometry"]["source_visible_bounds"] is None
checks["correct_identity_constraints"] = all(x in prompt for x in ["bald","middle-aged","monk","No weapon","not a sprite sheet"])
checks["raw_model_metadata_not_claimed"] = spec["provider"] is None and spec["generation_owner"] == "producer_ROOT_unique_builtin_call"
checks["no_reference_input_required"] = template["reference_images"] == spec["reference_images"] == []
files = [template_path,spec_path,prompt_path,ROOT/"prompts/tasks.yaml",Path(__file__),ROOT/"game/scripts/field/npc_node.gd",ROOT/"game/scripts/field/field_walkable_controller.gd"]
report = {"kind":"OFFLINE_BUILTIN_PREFLIGHT_NOT_GEN_ASSETS_CLI_DRY_RUN","passed":all(checks.values()),"checks":checks,"generation_calls":0,"network_calls":0,"sdk_calls":0,"engine_calls":0,"task_id":TASK_ID,"task_status":row["status"],"legacy_cli_note":"gen_assets.py process_task ignores execution_backend and chooses API default_model; do not run/enable this task via CLI or claim builtin provider support from its dry-run.","files":[{"path":str(p.relative_to(ROOT)).replace(chr(92),"/"),"sha256":hashlib.sha256(p.read_bytes()).hexdigest(),"bytes":p.stat().st_size} for p in files]}
print(json.dumps(report, ensure_ascii=True, indent=2))
raise SystemExit(0 if report["passed"] else 1)

