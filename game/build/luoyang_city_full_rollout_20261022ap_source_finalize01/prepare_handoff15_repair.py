"""Root-requested exact20 repair lock only; does not run retry4 or deploy."""
from __future__ import annotations

import json

from prepare_handoff10 import HERE, GAME, resource, sha, write_new


def main():
    before = (HERE / "source_finalization_input_handoff14_repair_PENDING.json").read_bytes()
    assert sha(before) == "f42e65ce2abeb6564d393e2fc569f45fb4d2322822eb8cd52b00df8b4e9be54f"
    plan = json.loads(before)
    scopepath = "res://build/luoyang_city_full_rollout_20261022ap_root01/integration3/root_repair20_scope_READY.json"
    scopebytes = resource(scopepath).read_bytes()
    assert sha(scopebytes) == "7328d3aff83bcd611166672eaa79b9c3eb9f2a91070f3522b6752dcb0b1f707e"
    scope = json.loads(scopebytes)
    assert scope["approved_by_root"] is True and scope["target_count"] == 20
    assert {r["target"] for r in scope["targets"]} == set(plan["root_target_allowlist"])
    plan["pinned_inputs"].append({"id": "root_repair20_scope_gate", "path": scopepath, "sha256": sha(scopebytes)})
    plan["required_gates"].append({"id": "root_target_preauthorization", "input": "root_repair20_scope_gate", "pointer": ["approved_by_root"], "equals": True})
    plan["status"] = "ROOT_LOCKED_AP_SOURCE_FINALIZATION_INPUT"
    plan["blockers"] = []
    plan["predecessor_input"] = {"path": "res://" + (HERE / "source_finalization_input_handoff14_repair_PENDING.json").relative_to(GAME).as_posix(), "sha256": sha(before), "preserved": True}
    plan["repair_epoch_contract"]["root_exact20_scope_input"] = "root_repair20_scope_gate"
    plan["repair_epoch_contract"]["root_exact20_build_scope_only_not_final_canonical_deploy"] = True
    assert len(plan["required_gates"]) == 5
    assert not resource(plan["output_root"]).exists()
    result = write_new("source_finalization_input_handoff15_repair_ROOT_LOCKED.json", plan)
    receipt = write_new("handoff15_repair_preparation.json", {"status": "ROOT_EXACT20_REPAIR_INPUT_LOCK_PREPARED_NOT_STAGED", "input_sha256": result, "scope_sha256": sha(scopebytes), "target_count": 20, "generator_sha256": plan["required_generator"]["sha256"], "output_epoch": plan["output_root"], "no_stager_engine_collector_or_canonical_write": True})
    print(json.dumps({"locked_repair_input_sha256": result, "preparation_receipt_sha256": receipt, "targets": 20, "stager_executed": False}))


if __name__ == "__main__":
    main()
