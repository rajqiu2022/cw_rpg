"""Prepare only a read-only stage02 basis and retry4 full diff, never stage."""
from __future__ import annotations

import difflib
import json

from prepare_handoff10 import HERE, resource, sha, write_new


def main():
    previous = (HERE / "stage_sources_retry3.py").read_bytes()
    current = (HERE / "stage_sources_repair_retry4.py").read_bytes()
    assert sha(previous) == "584e372ec906f95128efc9e1516d1292b7f2bb9f22b9f018df937d5a8273f18e"
    assert sha(current) == "e89bfd88844ceffe127518fcbe29e570eb6db276f8ddcead2a76b3e5d7470792"
    path = "res://build/luoyang_city_full_rollout_20261022ap_source_finalize01/outputs/root_integration1_stage02/receipt.json"
    raw = resource(path).read_bytes()
    assert sha(raw) == "b3ed75f8303d8b62a8cbe56b79a857309930c7493b28b216c2a11ee2110e1d39"
    receipt = json.loads(raw)
    basis = []
    for ident, node in receipt["nodes"].items():
        if not any(r["candidate_path"] == node["path"] for r in receipt["targets"]):
            continue
        row = next(r for r in receipt["targets"] if r["candidate_path"] == node["path"])
        assert sha(resource(node["path"]).read_bytes()) == node["sha256"]
        basis.append({"id": ident, "base_input_path": node["path"], "base_input_sha256": node["sha256"], "canonical_current_target": row["target"], "canonical_current_sha256": row["candidate_sha256"], "not_a_new_deployment_target_until_semantically_changed": True})
    diff = "".join(difflib.unified_diff(previous.decode("utf-8").splitlines(keepends=True), current.decode("utf-8").splitlines(keepends=True), fromfile="stage_sources_retry3.py", tofile="stage_sources_repair_retry4.py"))
    with (HERE / "repair_retry4_vs_retry3.diff").open("xb") as stream:
        stream.write(diff.encode("utf-8"))
    basis_sha = write_new("repair_stage02_source_basis_READY.json", {
        "status": "PINNED_DEPLOYED_STAGE02_METADATA_INPUTS_NOT_REPAIR_AUTHORIZATION",
        "stage_receipt": {"path": path, "sha256": sha(raw)},
        "metadata_and_index_nodes": basis,
        "all37_deployed_target_current_hash_basis": {r["target"]: r["candidate_sha256"] for r in receipt["targets"]},
        "new_approval_old_target_sha256": "9c3f9b5a35360ca2b488424ea0a3922759bf3b70d21452c7298dff51e7aac817",
        "new_tool_sha256": sha(current), "full_diff_sha256": sha(diff.encode("utf-8")),
        "pending": ["System exact Temple/BIND SHA successor + legal binding/x typed and byte proof", "Root new closed10 execution approval and proof pins", "Source-only minimal metadata/index graph and exact new target scope approval", "Root actual new stage; then 8field/5room independent source maps"],
        "old_stage02_typed_and_candidate_bytes_pass_does_not_grant_runtime": True,
        "no_stage_engine_collector_or_canonical_write": True,
    })
    print(json.dumps({"repair_basis_sha256": basis_sha, "retry4_sha256": sha(current), "diff_sha256": sha(diff.encode("utf-8")), "basis_nodes": len(basis), "stager_executed": False}))


if __name__ == "__main__":
    main()
