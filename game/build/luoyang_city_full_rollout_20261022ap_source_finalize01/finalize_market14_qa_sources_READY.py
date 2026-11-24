"""Independent post-actual-stage source-domain review; never run a collector."""
from __future__ import annotations

import argparse
import copy
import json

from prepare_handoff10 import resource, sha, same, write_new

PREFIX = "res://build/luoyang_city_full_rollout_20261022ap_source_finalize01/"
INPUT = PREFIX + "market_import_closure2_ROOT_LOCKED.json"
INPUT_SHA = "eb671d19134a625ea1f7bdd47e684588a614ca42c1760664f6ffe4997747d2c9"
STAGE = PREFIX + "outputs/root_integration4_market14_stage01/receipt.json"
M = "res://data/maps/luoyang_full_city_20261022ap/market/ch4_s3_luoyang_market/manifest.json"
I = "res://scripts/city/luoyang_full_city_index_20261022ap.gd"
OLD_M = "21335fa0099ef74ca78cf85403ca7461d06c8fc6c0901ec2b028fbe9018bcb2a"
OLD_I = "76bb15ca260c44a90bbe8247fcf6b7a12a44e9571a5039e818174c3b77725b9b"
FOUR = {"ch4_s0_luoyang_gate", "ch4_s1_luoyang_yamen", "ch4_s2_canal_docks", "ch4_s3_luoyang_market"}


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--actual-stage-receipt-sha256", required=True)
    args = parser.parse_args()
    first = {}

    def read(path, expected):
        raw = resource(path).read_bytes()
        assert sha(raw) == expected, ("PIN_CHANGED", path)
        first[path] = expected
        return raw

    plan = json.loads(read(INPUT, INPUT_SHA))
    receipt = json.loads(read(STAGE, args.actual_stage_receipt_sha256))
    assert receipt["status"] == "AP_MARKET14_EXACT_TWO_SOURCE_METADATA_STAGED_NOT_DEPLOYED"
    assert receipt["target_partition"] == {"patch_count": 2, "copy_count": 0, "total": 2, "union_exact_targets": True}
    assert receipt["source_first"] == receipt["source_final"]
    assert receipt["input"] == {"path": INPUT, "sha256": INPUT_SHA}
    targets = {r["target"]: r for r in receipt["targets"]}
    assert set(targets) == {M, I}
    pins = plan["pinned_inputs"]
    owners = json.loads(read(**{"path": pins["independent_stage03_owner_maps"]["path"], "expected": pins["independent_stage03_owner_maps"]["sha256"]}))
    history = json.loads(read(pins["independent_media_evidence"]["path"], pins["independent_media_evidence"]["sha256"]))
    extra = {}
    for row in history["seven_rows"]:
        for key, hashkey in [("existing_import_path", "existing_import_sha256"), ("declared_compiled_path", "existing_compiled_sha256")]:
            path, expected = row[key], row[hashkey]
            assert path not in extra
            declarations = row["historical_declarations"][path]
            assert declarations
            for declaration in declarations:
                source = json.loads(read(declaration["record_path"], declaration["record_sha256"]))
                for token in declaration["pointer"][1:].split("/"):
                    source = source[token.replace("~1", "/").replace("~0", "~")]
                assert source == expected == declaration["declared_sha256"]
            read(path, expected)
            extra[path] = expected
    assert len(extra) == 14 and extra == history["fourteen_existing_leaf_pins"] == plan["source_additions"] == receipt["source_additions"]
    parent = json.loads(read(pins["parent_stage03"]["path"], pins["parent_stage03"]["sha256"]))
    old = {r["target"]: r for r in parent["targets"]}
    m0 = json.loads(read(old[M]["candidate_path"], OLD_M))
    m1_bytes = read(targets[M]["candidate_path"], targets[M]["candidate_sha256"])
    m1 = json.loads(m1_bytes)
    restored = copy.deepcopy(m1)
    for key, value in extra.items():
        assert all(key not in m0[field] for field in ["legacy_source_sha256", "runtime_authority_sha256", "artifacts"])
        assert restored["legacy_source_sha256"].pop(key) == value
    assert same(restored, m0)
    i0 = read(old[I]["candidate_path"], OLD_I)
    i1 = read(targets[I]["candidate_path"], targets[I]["candidate_sha256"])
    assert i0.count(OLD_M.encode()) == 1 and i1 == i0.replace(OLD_M.encode(), targets[M]["candidate_sha256"].encode())
    assert i1.replace(targets[M]["candidate_sha256"].encode(), OLD_M.encode()) == i0
    final = copy.deepcopy(owners)
    for path in [M, I]:
        assert final["core_source_sha256"][path] == targets[path]["old_sha256"]
        final["core_source_sha256"][path] = targets[path]["candidate_sha256"]
    changes = []
    for r in final["scenes"] + final["rooms"]:
        previous = next(x for x in owners["scenes"] + owners["rooms"] if x["id"] == r["id"])
        for field in ["source_sha256", "receipt_source_sha256"]:
            table = r[field]
            if r["id"] in FOUR:
                assert table[I] == OLD_I
                table[I] = targets[I]["candidate_sha256"]
            if r["id"] == "ch4_s3_luoyang_market":
                assert table[M] == OLD_M and not (set(table) & set(extra))
                table[M] = targets[M]["candidate_sha256"]
                table.update(extra)
            restored_table = copy.deepcopy(table)
            if r["id"] in FOUR:
                restored_table[I] = OLD_I
            if r["id"] == "ch4_s3_luoyang_market":
                restored_table[M] = OLD_M
                for key in extra:
                    del restored_table[key]
            assert same(restored_table, previous[field]), ("UNEXPECTED_OWNER_SOURCE_CHANGE", r["id"], field)
            changes.append({"id": r["id"], "field": field, "count": len(table)})
    candidate = json.loads(read(receipt["independent_owner_recipe_path"], receipt["independent_owner_recipe_sha256"]))
    assert same(candidate["core_source_sha256"], final["core_source_sha256"])
    assert same(candidate["scenes"], final["scenes"]) and same(candidate["rooms"], final["rooms"])
    final["actual_stage_receipt"] = {"path": STAGE, "sha256": args.actual_stage_receipt_sha256}
    final["source_only_successor"] = candidate["source_only_successor"]
    final["source_only_successor"]["independent_whole_parent_inverse"] = True
    assert all(sha(resource(p).read_bytes()) == expected for p, expected in first.items())
    maps_sha = write_new("market14_actual_stage_independent_qa_owner_source_maps_READY.json", final)
    report_sha = write_new("market14_actual_stage_independent_source_review_READY.json", {"status": "INDEPENDENT_EXACT2_14_HISTORICAL_LEAVES_TYPED_AND_BYTE_INVERSES_PASS", "actual_stage_receipt_sha256": args.actual_stage_receipt_sha256, "owner_maps_sha256": maps_sha, "targets": targets, "historical_media_leaves": 14, "only_market14_additions_and_index_four_header_successions": True, "other_four_exteriors_and_five_rooms_source_tables_unchanged": True, "counts": changes, "source_first_final_same": True, "no_engine_stager_collector_or_canonical_write": True})
    print(json.dumps({"owner_maps_sha256": maps_sha, "review_sha256": report_sha, "scene_rows": 8, "room_rows": 5}))


if __name__ == "__main__":
    main()
