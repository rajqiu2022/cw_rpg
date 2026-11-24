"""Root-only exact two-target source successor; no engine/import/collector.

The fourteen values are declared independently from frozen PNG ancestors and
existing import evidence. A runtime diagnostic is never an expected-value input.
Nothing is written until all source/byte/typed inverses and scope checks pass.
"""
from __future__ import annotations

import argparse
import copy
import json
import re
from pathlib import Path

from stage_sources_repair_retry5 import build_file_patch, digest, encode, need, res, same

HERE = Path(__file__).resolve().parent
PREFIX = "res://build/luoyang_city_full_rollout_20261022ap_source_finalize01/"
MANIFEST = "res://data/maps/luoyang_full_city_20261022ap/market/ch4_s3_luoyang_market/manifest.json"
INDEX = "res://scripts/city/luoyang_full_city_index_20261022ap.gd"
OLD_MANIFEST = "21335fa0099ef74ca78cf85403ca7461d06c8fc6c0901ec2b028fbe9018bcb2a"
OLD_INDEX = "76bb15ca260c44a90bbe8247fcf6b7a12a44e9571a5039e818174c3b77725b9b"
ORIGINS = {
    "res://art/modules/building/build_linxi_smithy_front.png",
    "res://art/maps/luoyang_modular_v2/source/notice_pavilion_v2.png",
    "res://art/modules/prop/linxi_brazier_forge_v1.png",
    "res://art/maps/luoyang_enclosure_v11/source/courtyard_wall_gate_v3.png",
    *("res://art/maps/luoyang_enclosure_v11/ch4_s2_canal_docks/ground_v14/root_ground_v14_02/" + name + ".png" for name in ["ground_off_raw", "ground_on_raw", "floor"]),
}
SCENES4 = {"ch4_s0_luoyang_gate", "ch4_s1_luoyang_yamen", "ch4_s2_canal_docks", "ch4_s3_luoyang_market"}


def run(spec):
    first = {}

    def read(path, expected):
        raw = res(path).read_bytes()
        need(digest(raw) == expected, "PIN_CHANGED:" + path)
        need(path not in first or first[path] == expected, "CONFLICTING_PIN:" + path)
        first[path] = expected
        return raw

    def pin(ident):
        row = spec["pinned_inputs"][ident]
        return read(row["path"], row["sha256"])

    need(spec["status"] == "ROOT_LOCKED_MARKET14_TWO_TARGET_SOURCE_ONLY", "ROOT_LOCK_REQUIRED")
    need(spec["target_old_sha256"] == {MANIFEST: OLD_MANIFEST, INDEX: OLD_INDEX}, "EXACT_TWO_CURRENT_TARGETS")
    gate = json.loads(pin("root_scope"))
    need(gate.get("approved_by_root") is True and gate["target_count"] == 2, "ROOT_EXACT_TWO_SCOPE_REQUIRED")
    gate_rows = {r["target"]: r["old_sha256"] for r in gate["targets"]}
    need(gate_rows == spec["target_old_sha256"], "ROOT_SCOPE_EXACT_OLD_VALUES")
    admission = json.loads(pin("root_closure_admission"))
    need(admission.get("approved_by_root") is True and admission.get("diagnostic_is_expected_source") is False and admission["canonical_target_count"] == 2 and admission["new_media_or_imports"] == 0, "ROOT_FINITE14_ADMISSION_NO_DIAGNOSTIC_EXPECTED")
    need(admission["scope_path"] == spec["pinned_inputs"]["root_scope"]["path"] and admission["scope_sha256"] == spec["pinned_inputs"]["root_scope"]["sha256"], "ROOT_ADMISSION_SCOPE_IDENTITY")
    parent = json.loads(pin("parent_stage03"))
    need(parent["source_first"] == parent["source_final"] and parent["target_partition"]["total"] == 20, "PARENT_ACTUAL_STAGE03")
    parent_targets = {r["target"]: r for r in parent["targets"]}
    old_manifest_bytes = read(parent_targets[MANIFEST]["candidate_path"], OLD_MANIFEST)
    old_index_bytes = read(parent_targets[INDEX]["candidate_path"], OLD_INDEX)
    read(MANIFEST, OLD_MANIFEST)
    read(INDEX, OLD_INDEX)
    old_manifest = json.loads(old_manifest_bytes)
    quarter = parent["nodes"]["quarter_final"]
    read(quarter["path"], quarter["sha256"])
    ancestors = quarter["value"]["source_sha256"]
    evidence = json.loads(pin("independent_media_evidence"))
    need(evidence == spec["independent_media_evidence_value"], "EXACT_FROZEN_MEDIA_EVIDENCE_VALUE")
    need(evidence["status"] == "HISTORICAL_DECLARED_PIN_AND_EXACT_EXISTING_REMAP_PROOF_ONLY", "HISTORICAL_MEDIA_EVIDENCE_REQUIRED")
    declared_rows = [{"png_path": r["source_png"], "png_sha256": r["already_fixed_png_sha256"], "sidecar_path": r["existing_import_path"], "sidecar_sha256": r["existing_import_sha256"], "compiled_path": r["declared_compiled_path"], "compiled_sha256": r["existing_compiled_sha256"]} for r in evidence["seven_rows"]]
    rows = spec["media_rows"]
    need(same(rows, declared_rows), "SEVEN_ROWS_MUST_BE_FIXED_HISTORICAL_EVIDENCE_PROJECTION")
    need(len(rows) == 7 and {r["png_path"] for r in rows} == ORIGINS, "ONLY_SEVEN_FROZEN_PNG_ANCESTORS")
    all_old = {}
    for field in ["legacy_source_sha256", "runtime_authority_sha256", "artifacts"]:
        need(not (set(all_old) & set(old_manifest[field])), "PARENT_SOURCE_CLASSES_DISJOINT")
        all_old.update(old_manifest[field])
    additions = {}
    historical_checks = 0
    for row in rows:
        png, sidecar, compiled = row["png_path"], row["sidecar_path"], row["compiled_path"]
        need(ancestors[png] == row["png_sha256"] == all_old[png], "PNG_FIXED_QUARTER_AND_MARKET_ANCESTOR_PIN")
        read(png, row["png_sha256"])
        need(sidecar == png + ".import" and compiled.startswith("res://.godot/imported/") and compiled.endswith(".ctex"), "EXACT_EXISTING_IMPORT_DOMAINS")
        raw = read(sidecar, row["sidecar_sha256"]).decode("utf-8")
        sections = re.split(r"^\[([^\]\r\n]+)\]\r?$", raw, flags=re.M)
        parsed = {sections[i]: sections[i + 1] for i in range(1, len(sections), 2)}
        need("remap" in parsed and "deps" in parsed, "IMPORT_SECTIONS")
        remaps = re.findall(r'^path(?:\.[A-Za-z0-9_]+)?="(res://[^"\r\n]+)"\r?$', parsed["remap"], re.M)
        need(remaps == [compiled], "ONE_EXACT_DECLARED_REMAP")
        need(re.findall(r'^source_file="(res://[^"\r\n]+)"\r?$', parsed["deps"], re.M) == [png], "SIDECAR_SOURCE_FILE_EXACT_ANCESTOR")
        need(re.findall(r'^dest_files=\["(res://[^"\r\n]+)"\]\r?$', parsed["deps"], re.M) == [compiled], "SIDECAR_DEST_FILES_EXACT_REMAP")
        read(compiled, row["compiled_sha256"])
        historical = next(r for r in evidence["seven_rows"] if r["source_png"] == png)["historical_declarations"]
        for leaf, expected in [(png, row["png_sha256"]), (sidecar, row["sidecar_sha256"]), (compiled, row["compiled_sha256"])]:
            need(historical.get(leaf), "EVERY_MEDIA_LEAF_NEEDS_PREEXISTING_DECLARATION")
            for declaration in historical[leaf]:
                record_path = declaration["record_path"]
                need("market_raw_source_diagnostic" not in record_path and "market_import_key_expansion" not in record_path, "NO_CURRENT_DIAGNOSTIC_EXPECTED_VALUE_SOURCE")
                record = json.loads(read(record_path, declaration["record_sha256"]))
                pointer = declaration["pointer"]
                need(pointer.startswith("/"), "DECLARED_JSON_POINTER")
                for key in pointer[1:].split("/"):
                    record = record[key.replace("~1", "/").replace("~0", "~")]
                need(record == declaration["declared_sha256"] == expected, "EXACT_HISTORICAL_MEDIA_DECLARATION")
                historical_checks += 1
        for path, expected in [(sidecar, row["sidecar_sha256"]), (compiled, row["compiled_sha256"])]:
            need(path not in all_old and path not in additions, "FOURTEEN_NEW_KEYS_ONLY_NO_REPLACEMENT")
            additions[path] = expected
    need(len(additions) == 14 and additions == spec["source_additions"], "DECLARED14_EXACT_INDEPENDENT_REMAP_UNION")
    need(additions == evidence["fourteen_existing_leaf_pins"], "EXACT_FOURTEEN_HISTORICAL_DECLARED_PINS")
    new_manifest = copy.deepcopy(old_manifest)
    new_manifest["legacy_source_sha256"].update(additions)
    restored = copy.deepcopy(new_manifest)
    for path in additions:
        del restored["legacy_source_sha256"][path]
    need(same(restored, old_manifest), "WHOLE_TYPED_PARENT_INVERSE_ONLY_LEGACY14")
    manifest_bytes = encode(new_manifest)
    manifest_sha = digest(manifest_bytes)
    need(old_index_bytes.count(OLD_MANIFEST.encode()) == 1, "INDEX_ONE_OLD_MANIFEST_LITERAL")
    index_bytes = old_index_bytes.replace(OLD_MANIFEST.encode(), manifest_sha.encode())
    need(index_bytes.count(manifest_sha.encode()) == 1 and index_bytes.replace(manifest_sha.encode(), OLD_MANIFEST.encode()) == old_index_bytes, "INDEX_ONE_LITERAL_WHOLE_BYTE_INVERSE")
    index_sha = digest(index_bytes)
    owners = json.loads(pin("independent_stage03_owner_maps"))
    need(owners["status"] == "ROOT_ACTUAL_STAGE_INDEPENDENT_QA_SOURCE_MAPS" and len(owners["scenes"]) == 8 and len(owners["rooms"]) == 5, "FIXED_INDEPENDENT_8_PLUS5_PARENT")
    next_owners = copy.deepcopy(owners)
    for path, old, new in [(MANIFEST, OLD_MANIFEST, manifest_sha), (INDEX, OLD_INDEX, index_sha)]:
        need(next_owners["core_source_sha256"][path] == old, "CORE_EXACT_OLD_HEADER")
        next_owners["core_source_sha256"][path] = new
    changes = []
    for r in next_owners["scenes"] + next_owners["rooms"]:
        prior = next(x for x in owners["scenes"] + owners["rooms"] if x["id"] == r["id"])
        for field in ["source_sha256", "receipt_source_sha256"]:
            table = r[field]
            if r["id"] in SCENES4:
                need(table[INDEX] == OLD_INDEX, "FOUR_CITIES_EXISTING_INDEX_HEADER")
                table[INDEX] = index_sha
            if r["id"] == "ch4_s3_luoyang_market":
                need(table[MANIFEST] == OLD_MANIFEST and not (set(table) & set(additions)), "MARKET_OLD_MANIFEST14_ABSENT")
                table[MANIFEST] = manifest_sha
                table.update(additions)
            newkeys = set(table) - set(prior[field])
            changed = {k for k in table.keys() & prior[field].keys() if table[k] != prior[field][k]}
            need(not (set(prior[field]) - set(table)), "NO_EXPECTED_SOURCE_REMOVAL")
            need(newkeys == (set(additions) if r["id"] == "ch4_s3_luoyang_market" else set()), "ONLY_MARKET14_EXPECTED_NEW_KEYS")
            need(changed == ({INDEX, MANIFEST} if r["id"] == "ch4_s3_luoyang_market" else {INDEX} if r["id"] in SCENES4 else set()), "ONLY_FOUR_INDEX_AND_MARKET_MANIFEST_EXPECTED_SUCCESSIONS")
            changes.append({"id": r["id"], "field": field, "count": len(table), "added": sorted(newkeys), "changed": sorted(changed)})
    out = spec["output_root"]
    need(out.startswith(PREFIX + "outputs/") and out.endswith("/") and not res(out).exists(), "NEW_BUILD_ONLY_OUTPUT_ROOT")
    outputs = {out + "market_source_successor.json": manifest_bytes, out + "ap_city_index_true.gd": index_bytes}
    targets = []
    patch = "*** Begin Patch\n"
    patch_proofs = {}
    for target, old, name, raw in [(MANIFEST, OLD_MANIFEST, "market_source_successor.json", manifest_bytes), (INDEX, OLD_INDEX, "ap_city_index_true.gd", index_bytes)]:
        previous = old_manifest_bytes if target == MANIFEST else old_index_bytes
        piece, proof = build_file_patch(res(target).as_posix(), previous, raw)
        patch += piece
        patch_proofs[target] = proof
        targets.append({"target": target, "old_sha256": old, "candidate_path": out + name, "candidate_sha256": digest(raw), "candidate_bytes": len(raw)})
    patch += "*** End Patch\n"
    outputs[out + "canonical_deployment.apply_patch"] = patch.encode("utf-8")
    next_owners["status"] = "SOURCE_ONLY_DERIVED_MARKET14_QA_MAPS_PENDING_EXTERNAL_ACTUAL_STAGE_RECEIPT"
    next_owners["source_only_successor"] = {"parent_owner_maps": spec["pinned_inputs"]["independent_stage03_owner_maps"], "independent_media_evidence": spec["pinned_inputs"]["independent_media_evidence"], "no_actual_collector_values_read": True}
    outputs[out + "independent_qa_source_maps_pending_receipt.json"] = encode(next_owners)
    final = {path: digest(res(path).read_bytes()) for path in first}
    need(final == first, "SOURCE_FIRST_FINAL_DRIFT")
    receipt = {"status": "AP_MARKET14_EXACT_TWO_SOURCE_METADATA_STAGED_NOT_DEPLOYED", "input": spec["_locked_input"], "targets": targets, "source_additions": additions, "media_rows": rows, "historical_declarations_checked": historical_checks, "whole_typed_manifest_inverse": True, "index_one_literal_whole_byte_inverse": True, "all_native_geometry_other_manifest_fields_unchanged": True, "source_first": first, "source_final": final, "patch_path": out + "canonical_deployment.apply_patch", "patch_sha256": digest(outputs[out + "canonical_deployment.apply_patch"]), "patch_reconstruction": patch_proofs, "target_partition": {"patch_count": 2, "copy_count": 0, "total": 2, "union_exact_targets": True}, "independent_owner_recipe_path": out + "independent_qa_source_maps_pending_receipt.json", "independent_owner_recipe_sha256": digest(outputs[out + "independent_qa_source_maps_pending_receipt.json"]), "expected_table_changes": changes, "no_engine_import_collector_geometry_or_canonical_write": True}
    outputs[out + "receipt.json"] = encode(receipt)
    need(not res(out).exists(), "NO_EARLY_OUTPUT_WRITE")
    for path, raw in outputs.items():
        destination = res(path)
        destination.parent.mkdir(parents=True, exist_ok=True)
        with destination.open("xb") as stream:
            stream.write(raw)
    return {"targets": 2, "source_additions": 14, "receipt_sha256": digest(outputs[out + "receipt.json"]), "output_root": out}


if __name__ == "__main__":
    parser = argparse.ArgumentParser()
    parser.add_argument("input")
    parser.add_argument("--input-sha256", required=True)
    args = parser.parse_args()
    raw = Path(args.input).read_bytes()
    need(digest(raw) == args.input_sha256, "EXTERNAL_ROOT_INPUT_PIN")
    spec = json.loads(raw)
    spec["_locked_input"] = {"path": "res://" + Path(args.input).resolve().relative_to(HERE.parents[1]).as_posix(), "sha256": args.input_sha256}
    print(json.dumps(run(spec)))
