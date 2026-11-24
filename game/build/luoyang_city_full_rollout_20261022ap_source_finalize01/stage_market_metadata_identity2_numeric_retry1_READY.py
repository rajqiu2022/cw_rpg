"""Root-only exact absent mask/parent declarations; never engine/canonical."""
from __future__ import annotations

import argparse
import copy
import json
from pathlib import Path

from stage_sources_repair_retry5 import build_file_patch, digest, encode, need, res, same

HERE = Path(__file__).resolve().parent
PREFIX = "res://build/luoyang_city_full_rollout_20261022ap_source_finalize01/"
M = "res://data/maps/luoyang_full_city_20261022ap/market/ch4_s3_luoyang_market/manifest.json"
I = "res://scripts/city/luoyang_full_city_index_20261022ap.gd"
OLD_M = "5860180aebec2eef0c8e8f7512a0a1ae4775a3bc45096e74932fb64b3bfdd0e2"
OLD_I = "03338fe64db8b59baf5d0978d275bbe46d594334d3658467308776f1e06d5418"
MASK = "d161eeabae012793be71e61f9e09e19db7a1a101b1f4e749879a42915328512e"
FOUR = {"ch4_s0_luoyang_gate", "ch4_s1_luoyang_yamen", "ch4_s2_canal_docks", "ch4_s3_luoyang_market"}


def run(spec):
    first = {}

    def read(path, expected):
        raw = res(path).read_bytes()
        need(digest(raw) == expected, "PIN_CHANGED:" + path)
        first[path] = expected
        return raw

    def pin(name):
        p = spec["pinned_inputs"][name]
        return read(p["path"], p["sha256"])

    need(spec["status"] == "ROOT_LOCKED_MARKET_MASK_PARENT_EXACT_TWO_METADATA", "ROOT_LOCKED_EXACT_TWO")
    gate = json.loads(pin("root_scope"))
    need(gate.get("approved_by_root") is True and gate["target_count"] == 2, "ROOT_SCOPE8_REQUIRED")
    need({r["target"]: r["old_sha256"] for r in gate["targets"]} == {M: OLD_M, I: OLD_I}, "ROOT_EXACT_TWO_OLD_PINS")
    old_m_bytes, old_i_bytes = read(M, OLD_M), read(I, OLD_I)
    old_m = json.loads(old_m_bytes)
    need("mask_sha256" not in old_m and "parent_publication" not in old_m, "ONLY_TWO_ABSENT_FIELDS")
    parent_actual = json.loads(pin("parent_stage14"))
    prior_targets = {r["target"]: r for r in parent_actual["targets"]}
    need(read(prior_targets[M]["candidate_path"], OLD_M) == old_m_bytes and read(prior_targets[I]["candidate_path"], OLD_I) == old_i_bytes, "ACTUAL_PARENT_FC3F_BYTES")
    publication = json.loads(pin("market_publication17536"))
    need(publication["passed"] is True and publication["published"] is True and publication["walk_candidate"]["rgba_sha256"] == MASK, "FROZEN17536_DECLARED_RGBA_IDENTITY")
    publisher = pin("market_publisher17536").decode("utf-8")
    publisher_path = spec["pinned_inputs"]["market_publisher17536"]["path"]
    need(publication["source_first"][publisher_path] == publication["source_final"][publisher_path] == spec["pinned_inputs"]["market_publisher17536"]["sha256"], "PUBLISHER_FROZEN_ACTUAL_SOURCE_FIRST_FINAL")
    need("packet.mask_sha=B.bytes_sha(packet.walk_bytes)" in publisher and '"rgba_sha256":packet.mask_sha' in publisher, "PUBLISHER_RGBA_NOT_PNG_BYTES")
    for path, expected in publication["artifacts"].items():
        need(old_m["artifacts"][path] == expected, "UNCHANGED17536_NATIVE_ARTIFACT_DECLARATION")
        read(path, expected)
    old_ao = json.loads(pin("frozen_ao_manifest"))
    live_ao = json.loads(pin("declared_ao_parent"))
    parent = old_ao["parent_publication"]
    need(same(parent, live_ao["parent_publication"]), "AO_PARENT_SUBTREE_FROZEN_AND_CURRENT_TYPED_IDENTICAL")
    r3_raw = read(parent["path"], parent["sha256"])
    # Root-authorized fixed historical representation mismatch only: C2C's
    # embedded body uses JSON floats while exact2366 uses JSON integer34/24.
    # Nothing on disk or in the candidate is changed, and same stays strict.
    historical_r3_view = json.loads(r3_raw)
    embedded_body = parent["complete_immutable_manifest"]["body_px"]
    actual_body = historical_r3_view["body_px"]
    need(type(embedded_body) is list and len(embedded_body) == 2 and type(actual_body) is list and len(actual_body) == 2, "FIXED_HISTORICAL_BODY_PAIR")
    need(type(embedded_body[0]) is float and embedded_body[0] == 34.0 and type(embedded_body[1]) is float and embedded_body[1] == 24.0, "EXACT_C2C_FLOAT34_24")
    need(type(actual_body[0]) is int and actual_body[0] == 34 and type(actual_body[1]) is int and actual_body[1] == 24, "EXACT2366_INT34_24_NOT_BOOL")
    historical_r3_view["body_px"] = embedded_body.copy()
    need(same(historical_r3_view, parent["complete_immutable_manifest"]), "WHOLE_R3_STRICT_TYPED_AFTER_ONLY_TWO_EXPLICIT_HISTORICAL_NUMBER_REPRESENTATIONS")
    for path, expected in parent["complete_immutable_manifest"]["artifacts"].items():
        read(path, expected)
    proof = json.loads(pin("system_proof"))
    need(proof["parent"]["sha256"] == OLD_M and proof["candidate"] == spec["pinned_inputs"]["system_candidate"], "SYSTEM_PROOF_CURRENT_CANDIDATE_IDENTITY")
    candidate_m = pin("system_candidate")
    candidate_value = json.loads(candidate_m)
    expected_value = copy.deepcopy(old_m)
    expected_value["mask_sha256"] = MASK
    expected_value["parent_publication"] = parent
    need(same(candidate_value, expected_value), "EXACT_TWO_FIELDS_TYPED_ONLY")
    inverse = copy.deepcopy(candidate_value)
    del inverse["mask_sha256"], inverse["parent_publication"]
    need(same(inverse, old_m), "WHOLE_TYPED_PARENT_INVERSE")
    # Remove the two complete formatted root members without reserializing the
    # other parent bytes. This independently verifies System's byte-inverse.
    text = candidate_m.decode("utf-8")
    mask_line = '  "mask_sha256": "' + MASK + '",\n'
    need(text.count(mask_line) == 1, "ROOT_MASK_SINGLE_INSERTED_LINE")
    text = text.replace(mask_line, "", 1)
    marker = ',\n  "parent_publication": '
    need(text.count(marker) == 1 and text.endswith("\n}\n"), "ONE_TERMINAL_PARENT_MEMBER")
    cut = text.index(marker)
    need((text[:cut] + "\n}\n").encode("utf-8") == old_m_bytes, "WHOLE_ORIGINAL_PARENT_BYTE_INVERSE")
    next_m_sha = digest(candidate_m)
    need(old_i_bytes.count(OLD_M.encode()) == 1, "INDEX_ONE_OLD_LITERAL")
    candidate_i = old_i_bytes.replace(OLD_M.encode(), next_m_sha.encode())
    need(candidate_i.replace(next_m_sha.encode(), OLD_M.encode()) == old_i_bytes, "INDEX_WHOLE_BYTE_INVERSE")
    next_i_sha = digest(candidate_i)
    owner = json.loads(pin("parent_owners14"))
    updated_owner = copy.deepcopy(owner)
    for path, before, after in [(M, OLD_M, next_m_sha), (I, OLD_I, next_i_sha)]:
        need(updated_owner["core_source_sha256"][path] == before, "CORE_OLD_PIN")
        updated_owner["core_source_sha256"][path] = after
    for row in updated_owner["scenes"] + updated_owner["rooms"]:
        for field in ["source_sha256", "receipt_source_sha256"]:
            table = row[field]
            if row["id"] in FOUR:
                need(table[I] == OLD_I, "FOUR_EXISTING_INDEX_PINS")
                table[I] = next_i_sha
            if row["id"] == "ch4_s3_luoyang_market":
                need(table[M] == OLD_M and len(table) == 1595, "MARKET_FIXED1595_ONLY_MANIFEST_PIN")
                table[M] = next_m_sha
    updated_owner["status"] = "SOURCE_ONLY_DERIVED_MASK_PARENT_QA_MAPS_PENDING_EXTERNAL_ACTUAL_STAGE_RECEIPT"
    out = spec["output_root"]
    need(out.startswith(PREFIX + "outputs/") and out.endswith("/") and not res(out).exists(), "NEW_BUILD_OUTPUT_ONLY")
    outputs = {out + "market_source_successor.json": candidate_m, out + "ap_city_index_true.gd": candidate_i, out + "independent_qa_source_maps_pending_receipt.json": encode(updated_owner)}
    patch, patch_proofs, targets = "*** Begin Patch\n", {}, []
    for target, before, before_bytes, filename, candidate in [(M, OLD_M, old_m_bytes, "market_source_successor.json", candidate_m), (I, OLD_I, old_i_bytes, "ap_city_index_true.gd", candidate_i)]:
        piece, patch_proof = build_file_patch(res(target).as_posix(), before_bytes, candidate)
        patch += piece
        patch_proofs[target] = patch_proof
        targets.append({"target": target, "old_sha256": before, "candidate_path": out + filename, "candidate_sha256": digest(candidate), "candidate_bytes": len(candidate)})
    patch += "*** End Patch\n"
    outputs[out + "canonical_deployment.apply_patch"] = patch.encode("utf-8")
    final = {path: digest(res(path).read_bytes()) for path in first}
    need(first == final, "SOURCE_FIRST_FINAL_DRIFT")
    receipt = {"status": "AP_MARKET_MASK_PARENT_EXACT_TWO_STAGED_NOT_DEPLOYED", "input": spec["_locked_input"], "targets": targets, "delta_only": ["mask_sha256 ABSENT -> frozen17536 D161 RGBA", "parent_publication ABSENT -> exact frozenAO parent subtree"], "whole_typed_and_byte_parent_inverse": True, "index_one_literal_whole_byte_inverse": True, "all1595_source_keys_values_unchanged_except_generated_headers": True, "source_first": first, "source_final": final, "patch_path": out + "canonical_deployment.apply_patch", "patch_sha256": digest(outputs[out + "canonical_deployment.apply_patch"]), "patch_reconstruction": patch_proofs, "target_partition": {"patch_count": 2, "copy_count": 0, "total": 2, "union_exact_targets": True}, "independent_owner_recipe_path": out + "independent_qa_source_maps_pending_receipt.json", "independent_owner_recipe_sha256": digest(outputs[out + "independent_qa_source_maps_pending_receipt.json"]), "no_engine_import_collector_geometry_or_canonical_write": True}
    outputs[out + "receipt.json"] = encode(receipt)
    need(not res(out).exists(), "NO_EARLY_WRITE")
    for path, raw in outputs.items():
        destination = res(path)
        destination.parent.mkdir(parents=True, exist_ok=True)
        with destination.open("xb") as stream:
            stream.write(raw)
    return {"targets": 2, "receipt_sha256": digest(outputs[out + "receipt.json"]), "output_root": out}


if __name__ == "__main__":
    parser = argparse.ArgumentParser()
    parser.add_argument("input")
    parser.add_argument("--input-sha256", required=True)
    args = parser.parse_args()
    raw = Path(args.input).read_bytes()
    need(digest(raw) == args.input_sha256, "ROOT_EXTERNAL_INPUT_PIN")
    spec = json.loads(raw)
    spec["_locked_input"] = {"path": "res://" + Path(args.input).resolve().relative_to(HERE.parents[1]).as_posix(), "sha256": args.input_sha256}
    print(json.dumps(run(spec)))
