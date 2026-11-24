"""NEW Root-authorized exact JSON-copy staging input and complete EOL audit."""
from __future__ import annotations

import difflib
import json

from prepare_handoff10 import HERE, GAME, resource, sha, write_new


def eol(data):
    return {"bytes": len(data), "sha256": sha(data), "crlf": data.count(b"\r\n"), "cr": data.count(b"\r"), "lf": data.count(b"\n"), "final_lf": data.endswith(b"\n"), "bom": data.startswith(b"\xef\xbb\xbf")}


def main():
    oldtool = (HERE / "stage_sources_retry2.py").read_bytes()
    tool = (HERE / "stage_sources_retry3.py").read_bytes()
    assert sha(oldtool) == "dc6b626e29bcf6f40916568050ca1b2b713abf2fe0ee9ac84fcae1fccbf25c80"
    before = (HERE / "source_finalization_input_handoff12_ROOT_LOCKED.json").read_bytes()
    assert sha(before) == "f17a29c850e42a5c86d7ad744cc66780eeed9bd3865a9abd1ded2ae7d06eea5f"
    plan = json.loads(before)
    plan["predecessor_input"] = {"path": "res://" + (HERE / "source_finalization_input_handoff12_ROOT_LOCKED.json").relative_to(GAME).as_posix(), "sha256": sha(before), "preserved": True, "actual_failed_buffered_before_output": True}
    plan["output_root"] = "res://build/luoyang_city_full_rollout_20261022ap_source_finalize01/outputs/root_integration1_stage02/"
    assert not resource(plan["output_root"]).exists()
    failed_path = "res://build/luoyang_city_full_rollout_20261022ap_root01/integration1/source_stage01_failure.json"
    failure_sha = "f8caabd2995dbb57abab23e53b809007c93d556492133187f6d385b0f00eb5b9"
    assert sha(resource(failed_path).read_bytes()) == failure_sha
    plan["pinned_inputs"].append({"id": "root_actual_stage01_failure_preserved", "path": failed_path, "sha256": failure_sha})
    plan["required_generator"] = {"path": "res://" + (HERE / "stage_sources_retry3.py").relative_to(GAME).as_posix(), "sha256": sha(tool), "root_must_read_before_execution": True, "reason": "Only fixed ABSENT9C3F approval JSON mechanical-copy plan; all source, typed, authority and patch guards remain. Partition patch36 + copy1 exact37."}
    plan["root_authorized_byte_copy_successor"] = {
        "authorization": "Root explicitly approved retry3 sole ABSENT execution_successor9C3F JSON original-byte mechanical copy; remaining36 via original apply_patch. No candidate/authority/native/history/SHA change and no normalization. Do not stage as subagent.",
        "target": "res://data/maps/luoyang_full_city_20261022ap/execution_successor.json",
        "candidate_sha256": "9c3f9b5a35360ca2b488424ea0a3922759bf3b70d21452c7298dff51e7aac817",
        "old_sha256": "ABSENT", "patch_count": 36, "copy_count": 1, "union_exact_target_count": 37,
        "canonical_deployment_authorized": False,
    }
    inputs = {r["id"]: r for r in plan["pinned_inputs"]}
    authority = json.loads(resource(inputs["execution_approval"]["path"]).read_bytes())
    audit = []
    for row in plan["pass_through_targets"]:
        if row.get("candidate_from_authority") is True:
            owned = authority["owned"][row["target"]]
            pairs = {(e["new_snapshot"], e["new_sha256"]) for e in owned["edges"] if e["new_sha256"] == owned["current_sha256"]}
            assert len(pairs) == 1
            path, expected = next(iter(pairs))
        else:
            path, expected = row["candidate_path"], row["candidate_sha256"]
        data = resource(path).read_bytes()
        assert sha(data) == expected
        audit.append({"target": row["target"], "candidate_input": path, "domain": "literal_pass_through", **eol(data)})
    for row in plan["nodes"]:
        if "target" not in row:
            continue
        if row["kind"] == "index":
            data = resource(inputs[row["base_input"]]["path"]).read_bytes()
            assert b"\r" not in data and data.endswith(b"\n") and not data.startswith(b"\xef\xbb\xbf")
            audit.append({"target": row["target"], "domain": "index_replacements_preserve_checked_LF_seed", "seed": inputs[row["base_input"]]["path"], "generated_candidate_lf_final_lf_no_bom": True, "seed_eol": eol(data)})
        elif row.get("literal_candidate_input"):
            data = resource(inputs[row["literal_candidate_input"]]["path"]).read_bytes()
            assert b"\r" not in data and data.endswith(b"\n") and not data.startswith(b"\xef\xbb\xbf")
            audit.append({"target": row["target"], "domain": "fully_guarded_original_literal_bytes", **eol(data)})
        else:
            assert row["kind"] == "metadata"
            audit.append({"target": row["target"], "domain": "deterministic_encode_json_plus_final_LF", "generated_candidate_lf_final_lf_no_bom": True, "not_generated_or_staged_by_this_audit": True})
    assert len(audit) == len({r["target"] for r in audit}) == 37
    assert {r["target"] for r in audit} == set(plan["root_target_allowlist"])
    bad = [r for r in audit if r.get("cr", 0) or r.get("final_lf", True) is False or r.get("bom", False)]
    assert len(bad) == 1 and bad[0]["target"] == plan["root_authorized_byte_copy_successor"]["target"]
    diff = "".join(difflib.unified_diff(oldtool.decode("utf-8").splitlines(keepends=True), tool.decode("utf-8").splitlines(keepends=True), fromfile="stage_sources_retry2.py", tofile="stage_sources_retry3.py"))
    with (HERE / "retry3_vs_retry2.diff").open("xb") as stream:
        stream.write(diff.encode("utf-8"))
    audit_sha = write_new("handoff12_all37_EOLOFF_readonly_audit.json", {"status": "ALL37_CANDIDATE_EOL_DOMAINS_READ_ONLY_NOT_STAGER", "rows": audit, "sole_unpatchable_literal_target": bad[0], "no_candidate_or_canonical_modified": True, "no_engine_or_stager_executed": True})
    input_sha = write_new("source_finalization_input_handoff13_ROOT_LOCKED.json", plan)
    receipt_sha = write_new("handoff13_retry3_preparation.json", {"status": "ROOT_AUTHORIZED_SINGLE_JSON_COPY_TOOL_AND_LOCKED_INPUT_PREPARED_NOT_STAGED", "tool_sha256": sha(tool), "input_sha256": input_sha, "audit_sha256": audit_sha, "diff_sha256": sha(diff.encode("utf-8")), "h12_failure_sha256": failure_sha, "target_count": 37, "partition": "patch36 disjoint copy1 union exact37", "candidate_or_canonical_written": False, "stager_executed": False})
    print(json.dumps({"retry3_sha256": sha(tool), "h13_sha256": input_sha, "all37_audit_sha256": audit_sha, "diff_sha256": sha(diff.encode("utf-8")), "receipt_sha256": receipt_sha, "stager_executed": False}))


if __name__ == "__main__":
    main()
