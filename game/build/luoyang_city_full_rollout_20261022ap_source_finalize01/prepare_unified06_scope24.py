"""Exact24 current deployment ancestry from EF969, no stage/canonical write."""
import json
from prepare_handoff10 import HERE, resource, sha, write_new

S = "res://build/luoyang_city_full_rollout_20261022ap_source_finalize01/"
stagepath = S + "outputs/root_unified_visual_resident_stage01/receipt.json"
raw = resource(stagepath).read_bytes()
assert sha(raw) == "ef969c47a3433fd160d2e70f48de30b0d14d0eb88b8ce916c3ba38c2e405f429"
stage = json.loads(raw)
drop = {"res://scripts/city/luoyang_resident_field_20261016.gd", "res://scripts/field/field_walkable_controller.gd", "res://scripts/ui/field_primary_hud.gd", "res://scripts/city/luoyang_environment_layer_20261022ap.gd", "res://data/maps/luoyang_full_city_20261022ap/environment.json"}
assert len(stage["targets"]) == 29 and drop <= {r["target"] for r in stage["targets"]}
depraw = resource(S + "unified06_dependencies03/handoff_READY.json").read_bytes()
assert sha(depraw) == "b2e73b62b7b0347c3ce9acc25a792a7e7adc8e026d92574a60e4fc22a8cad9d0"
dep = json.loads(depraw)
candidates = {r["target"]: r["candidate"] for r in dep["additional_canonical_targets"]}
candidates[dep["execution_parent"]["path"]] = dep["execution_proposal"]
router = "res://scripts/autoload/scene_router.gd"
candidates[router] = {"path": "res://build/luoyang_city_full_rollout_20261022ap_system01/exact_market_artisan_resident_candidate06/Router_exact_market_artisan_resident_READY.gd", "sha256": "60cf6de154dbf07546e0a59e941af392a442b71178af59eb7cdca5da1eeab0eb"}
targets = []
for row in stage["targets"]:
    if row["target"] in drop:
        continue
    target = {"target": row["target"], "old_sha256": row["candidate_sha256"], "old_snapshot": row["candidate_path"], "basis_actual_receipt": {"path": stagepath, "sha256": sha(raw)}}
    assert sha(resource(row["target"]).read_bytes()) == sha(resource(row["candidate_path"]).read_bytes()) == row["candidate_sha256"]
    if row["target"] in candidates:
        target["candidate"] = candidates[row["target"]]
    targets.append(target)
assert len(targets) == 24
result = {"status": "REQUEST_ROOT_NEW_EXACT24_SCOPE_FROM_DEPLOYED_EF969_NOT_STAGE_OR_DEPLOY_PERMISSION", "target_count": 24, "targets": targets, "unchanged_five_targets_excluded": sorted(drop), "execution_parent_sha256": dep["execution_parent"]["sha256"], "pending_execution_proposal": dep["execution_proposal"], "no_engine_collector_native_replay_or_canonical_write": True}
value = write_new("unified06_exact24_scope_request_READY.json", result)
print({"scope_request_sha256": value, "targets": 24})
