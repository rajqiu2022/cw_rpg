"""NEW input selects only exact-schema tool04 and a fresh output epoch."""
import json
from prepare_handoff10 import HERE, sha, write_new
raw = (HERE / "unified06_input03_ROOT_LOCKED.json").read_bytes()
assert sha(raw) == "0b4f5447f870133b23f18376c06bb0778893adc1f16dd6475a9431031ed8bfd1"
plan = json.loads(raw)
plan["required_generator"] = {"path": "res://build/luoyang_city_full_rollout_20261022ap_source_finalize01/stage_unified06_04_READY.py", "sha256": "8de0b1dc9c5f24511947221760c9efb1e48a59fff152c426800b790ec7c26b28", "root_must_read_before_execution": True}
plan["output_root"] = "res://build/luoyang_city_full_rollout_20261022ap_source_finalize01/outputs/root_unified06_numeric_stage02/"
plan["authorization_schema_successor"] = {"previous_unexecuted_input": {"path": "res://build/luoyang_city_full_rollout_20261022ap_source_finalize01/unified06_input03_ROOT_LOCKED.json", "sha256": sha(raw)}, "only_fixed_FF10_and_ACA3_exact_existing_schema_checks": True, "no_source_recipe_target_or_candidate_changes": True}
value = write_new("unified06_input04_ROOT_LOCKED.json", plan)
print({"input_sha256": value, "targets": len(plan["root_target_allowlist"]), "stager_executed": False})
