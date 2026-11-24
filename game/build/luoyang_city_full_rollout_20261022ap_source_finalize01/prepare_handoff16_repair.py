"""Preserve actual retry4 rejection, lock only Root-authorized retry5 successor."""
from __future__ import annotations

import difflib
import json

from prepare_handoff10 import HERE, GAME, resource, sha, write_new


def main():
    previous = (HERE / "source_finalization_input_handoff15_repair_ROOT_LOCKED.json").read_bytes()
    assert sha(previous) == "db62b67b432709cc181406f98524897935f7f0f4fc332f9ea8a88bb188ae2ff6"
    plan = json.loads(previous)
    failed_path = "res://build/luoyang_city_full_rollout_20261022ap_root01/integration3/source_repair_stage01_failure.json"
    failed = resource(failed_path).read_bytes()
    failure = json.loads(failed)
    assert failure["natural_os_exit"] == 1 and failure["error"] == "EXISTING_DATA_MUST_USE_TYPED_METADATA_NODE_NOT_OPAQUE_COPY"
    oldtool = (HERE / "stage_sources_repair_retry4.py").read_bytes()
    tool = (HERE / "stage_sources_repair_retry5.py").read_bytes()
    assert sha(oldtool) == "e89bfd88844ceffe127518fcbe29e570eb6db276f8ddcead2a76b3e5d7470792"
    assert sha(tool) == "23f21249602117ae9a3e638c94d5b1a17725d3bc1e9464912115a7ba3da776b4"
    plan["pinned_inputs"].append({"id": "actual_repair_stage01_failure_preserved", "path": failed_path, "sha256": sha(failed)})
    plan["output_root"] = "res://build/luoyang_city_full_rollout_20261022ap_source_finalize01/outputs/root_integration3_repair_stage02/"
    assert not resource(plan["output_root"]).exists()
    plan["predecessor_input"] = {"path": "res://" + (HERE / "source_finalization_input_handoff15_repair_ROOT_LOCKED.json").relative_to(GAME).as_posix(), "sha256": sha(previous), "actual_failed_before_buffered_output_write": True}
    plan["required_generator"] = {"path": "res://" + (HERE / "stage_sources_repair_retry5.py").relative_to(GAME).as_posix(), "sha256": sha(tool), "root_must_read_before_execution": True, "reason": "Single existing approval JSON9C->80A may pass original GD-only branch only with exactE903 Root pin; nineowned identical, TempleBF65->D9CD only current, old29proof pins retained exact37, all original source/typed/media/partition guards remain."}
    diff = "".join(difflib.unified_diff(oldtool.decode("utf-8").splitlines(keepends=True), tool.decode("utf-8").splitlines(keepends=True), fromfile="stage_sources_repair_retry4.py", tofile="stage_sources_repair_retry5.py"))
    with (HERE / "repair_retry5_vs_retry4.diff").open("xb") as stream:
        stream.write(diff.encode("utf-8"))
    result = write_new("source_finalization_input_handoff16_repair_ROOT_LOCKED.json", plan)
    receipt = write_new("handoff16_repair_preparation.json", {"status": "ROOT_REQUESTED_EXACT20_RETRY5_INPUT_PREPARED_NOT_STAGED", "input_sha256": result, "tool_sha256": sha(tool), "diff_sha256": sha(diff.encode("utf-8")), "old_h15_actual_failure_sha256": sha(failed), "unchanged_target_count": 20, "unchanged_scope_sha256": "7328d3aff83bcd611166672eaa79b9c3eb9f2a91070f3522b6752dcb0b1f707e", "stager_executed": False, "canonical_written": False})
    print(json.dumps({"h16_sha256": result, "retry5_sha256": sha(tool), "diff_sha256": sha(diff.encode("utf-8")), "receipt_sha256": receipt, "stager_executed": False}))


if __name__ == "__main__":
    main()
