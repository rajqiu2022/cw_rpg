"""Add only Root fresh23 scope gate; no staging or canonical writes."""
import json
from prepare_handoff10 import HERE, resource, sha, same, write_new

raw = (HERE / "unified06_input03_PENDING.json").read_bytes()
assert sha(raw) == "e09bcb1cfb818493ff9df6d681adb85fdb9b5c61a103dc106c7573a62585da41"
plan = json.loads(raw)
scopepath = "res://build/luoyang_city_full_rollout_20261022ap_root01/integration11/scope_READY.json"
scopebytes = resource(scopepath).read_bytes()
assert sha(scopebytes) == "36cd81898631e298c31045115f41d620145e491a7d2350559165b728ab114931"
scope = json.loads(scopebytes)
assert scope["approved_by_root"] is True and scope["target_count"] == 23
pin = {"id": "root_unified06_scope23", "path": scopepath, "sha256": sha(scopebytes)}
assert pin["id"] not in {r["id"] for r in plan["pinned_inputs"]}
plan["pinned_inputs"].append(pin)
plan["required_gates"].append({"id": "root_target_preauthorization", "input": pin["id"], "pointer": ["approved_by_root"], "equals": True})
assert len(plan["required_gates"]) == 5
plan["status"] = "ROOT_LOCKED_AP_SOURCE_FINALIZATION_INPUT"
plan["blockers"] = []
plan["root_lock_scope"] = {"path": scopepath, "sha256": sha(scopebytes), "exact_target_count": 23, "canonical_deployment_still_requires_fresh_plan_authorization": True}
value = write_new("unified06_input03_ROOT_LOCKED.json", plan)
print({"input_sha256": value, "targets": 23, "stager_executed": False})
