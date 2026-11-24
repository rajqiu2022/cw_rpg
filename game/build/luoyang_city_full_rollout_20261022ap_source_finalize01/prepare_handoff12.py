"""Assemble Root-requested LOCKED build-only input; never run the stager."""
from __future__ import annotations

import json

from prepare_handoff10 import HERE, GAME, resource, sha, write_new


def main():
    before = (HERE / "source_finalization_input_handoff11_PENDING.json").read_bytes()
    assert sha(before) == "92efb0167f4bf6f470a8b200c1268316abb855a9fa015137663f2b8d233fbe03"
    plan = json.loads(before)
    rows = [
        ("garden_shore_root_finite_art", "res://build/luoyang_city_full_rollout_20261022ap_root01/integration1/garden_shore_finite_visual_admission.json", "1a82bcee82519ede6cfeeb66bf066aedbb1bfe234bfe3df9c34a2d29f816b930"),
        ("garden_shore_actual_overview", "res://build/luoyang_city_full_rollout_20261022ap_qa01/garden_shore_visual_overview/88688_2418/result.json", "227bf77152edd3fc431cb120e66783b3394f6619604b1985e35d3a1c215949fa"),
        ("garden_shore_actual_image", "res://build/luoyang_city_full_rollout_20261022ap_qa01/garden_shore_visual_overview/88688_2418/garden_native_overview_fit0625.png", "bcbb1884fdfd711cfe0a10dc705d79d32e46bc81b3ecda5bd3437112f9167e43"),
    ]
    for ident, path, expected in rows:
        assert sha(resource(path).read_bytes()) == expected
        assert ident not in {r["id"] for r in plan["pinned_inputs"]}
        plan["pinned_inputs"].append({"id": ident, "path": path, "sha256": expected})
    admitted = json.loads(resource(rows[0][1]).read_bytes())
    assert admitted["approved_by_root"] is True and admitted["root_actually_viewed_image"] is True
    assert admitted["helper_sha256"] == "3efaeff0d0fd6c24e3056e034f25350961730ba98826918baeeffa6962c6257b"
    plan["status"] = "ROOT_LOCKED_AP_SOURCE_FINALIZATION_INPUT"
    plan["blockers"] = []
    plan["output_root"] = "res://build/luoyang_city_full_rollout_20261022ap_source_finalize01/outputs/root_integration1_stage01/"
    assert not resource(plan["output_root"]).exists()
    plan["predecessor_input"] = {"path": "res://" + (HERE / "source_finalization_input_handoff11_PENDING.json").relative_to(GAME).as_posix(), "sha256": sha(before), "preserved": True}
    plan["known_actual_garden_v4"]["native_art_review_pending"] = False
    plan["known_actual_garden_v4"]["review_status"] = "ROOT_FINITE_SHORE_CONSTRUCTOR_RENDER_PASS_NOT_WHOLE_GARDEN_OR_CITY_ART"
    plan["known_actual_garden_v4"]["root_finite_art_input"] = "garden_shore_root_finite_art"
    plan["known_actual_garden_v4"]["shore_overview_input"] = "garden_shore_actual_overview"
    plan["known_manifest_seeds"]["quarter_shore_helper_source_only_successor"]["actual_single_image_pending"] = False
    plan["root_lock_scope"] = {
        "parent_message": "Root requested NEW h12, root_integration1_stage01 epoch, final input for external SHA approval then Root-only retry2 execution; subagent must not stage.",
        "build_only": True, "canonical_deployment_authorized": False,
        "future_deployment_requires_exact_candidate_sha_plan_and_guard_authorization": True,
        "independent_qa_runtime_not_yet_run": True,
    }
    inputs = {r["id"]: r for r in plan["pinned_inputs"]}
    scope = json.loads(resource(inputs["root_target_scope_gate"]["path"]).read_bytes())
    assert scope["approved_by_root"] is True and scope["target_count"] == 37
    assert {r["target"] for r in scope["targets"]} == set(plan["root_target_allowlist"])
    assert {r["id"] for r in plan["required_gates"]} == {
        "market_native_publication", "garden_background_permission", "artisan_native_publication", "garden_native_publication", "root_target_preauthorization",
    }
    result = write_new("source_finalization_input_handoff12_ROOT_LOCKED.json", plan)
    receipt = write_new("handoff12_root_build_gate_preparation.json", {
        "status": "ROOT_REQUESTED_LOCKED_INPUT_PREPARED_NOT_STAGE_OR_DEPLOYMENT",
        "input_sha256": result, "previous_sha256": sha(before),
        "scope_sha256": inputs["root_target_scope_gate"]["sha256"],
        "target_count": 37, "five_required_gates": True,
        "last_finite_art_three_inputs_exact": [r[2] for r in rows],
        "stager_executed": False, "canonical_written": False,
        "no_geometry_or_old_collection_replay": True,
    })
    print(json.dumps({"locked_input_sha256": result, "preparation_receipt_sha256": receipt, "targets": 37, "stager_executed": False}))


if __name__ == "__main__":
    main()
