"""Independent source-only post-actual review of exact two metadata fields."""
import argparse
import copy
import json
from prepare_handoff10 import resource, sha, same, write_new

P = "res://build/luoyang_city_full_rollout_20261022ap_source_finalize01/"
M = "res://data/maps/luoyang_full_city_20261022ap/market/ch4_s3_luoyang_market/manifest.json"
I = "res://scripts/city/luoyang_full_city_index_20261022ap.gd"
OM = "5860180aebec2eef0c8e8f7512a0a1ae4775a3bc45096e74932fb64b3bfdd0e2"
OI = "03338fe64db8b59baf5d0978d275bbe46d594334d3658467308776f1e06d5418"
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

    ipath = P + "market_metadata_identity2_ROOT_LOCKED.json"
    isha = "62264f1e1f8af021d56bcf1e49348f4f7ec2ddbd8f574dd264fca6ac0a0bfd06"
    plan = json.loads(read(ipath, isha))
    stagepath = P + "outputs/root_integration8_market_identity_stage01/receipt.json"
    receipt = json.loads(read(stagepath, args.actual_stage_receipt_sha256))
    assert receipt["status"] == "AP_MARKET_MASK_PARENT_EXACT_TWO_STAGED_NOT_DEPLOYED"
    assert receipt["input"] == {"path": ipath, "sha256": isha}
    assert receipt["source_first"] == receipt["source_final"]
    assert receipt["target_partition"] == {"patch_count": 2, "copy_count": 0, "total": 2, "union_exact_targets": True}
    targets = {r["target"]: r for r in receipt["targets"]}
    assert set(targets) == {M, I} and targets[M]["old_sha256"] == OM and targets[I]["old_sha256"] == OI
    pins = plan["pinned_inputs"]

    def pin(name):
        row = pins[name]
        return read(row["path"], row["sha256"])

    previous = json.loads(pin("parent_stage14"))
    previous_targets = {r["target"]: r for r in previous["targets"]}
    m0_bytes = read(previous_targets[M]["candidate_path"], OM)
    m0 = json.loads(m0_bytes)
    m1_bytes = read(targets[M]["candidate_path"], targets[M]["candidate_sha256"])
    m1 = json.loads(m1_bytes)
    source_publication = json.loads(pin("market_publication17536"))
    mask = source_publication["walk_candidate"]["rgba_sha256"]
    assert mask == "d161eeabae012793be71e61f9e09e19db7a1a101b1f4e749879a42915328512e"
    original_ao = json.loads(pin("frozen_ao_manifest"))
    assert same(m1["parent_publication"], original_ao["parent_publication"])
    assert m1["mask_sha256"] == mask and not {"mask_sha256", "parent_publication"} & m0.keys()
    restored = copy.deepcopy(m1)
    del restored["mask_sha256"], restored["parent_publication"]
    assert same(restored, m0)
    text = m1_bytes.decode("utf-8")
    mask_line = '  "mask_sha256": "' + mask + '",\n'
    assert text.count(mask_line) == 1
    text = text.replace(mask_line, "", 1)
    marker = ',\n  "parent_publication": '
    assert text.count(marker) == 1 and (text[:text.index(marker)] + "\n}\n").encode("utf-8") == m0_bytes
    i0 = read(previous_targets[I]["candidate_path"], OI)
    i1 = read(targets[I]["candidate_path"], targets[I]["candidate_sha256"])
    assert i0.count(OM.encode()) == 1 and i1 == i0.replace(OM.encode(), targets[M]["candidate_sha256"].encode())
    owners = json.loads(pin("parent_owners14"))
    successor = copy.deepcopy(owners)
    for path in [M, I]:
        assert successor["core_source_sha256"][path] == targets[path]["old_sha256"]
        successor["core_source_sha256"][path] = targets[path]["candidate_sha256"]
    counts = {}
    for row in successor["scenes"] + successor["rooms"]:
        old_row = next(r for r in owners["scenes"] + owners["rooms"] if r["id"] == row["id"])
        counts[row["id"]] = {}
        for field in ["source_sha256", "receipt_source_sha256"]:
            table = row[field]
            expected_changed = set()
            if row["id"] in FOUR:
                assert table[I] == OI
                table[I] = targets[I]["candidate_sha256"]
                expected_changed.add(I)
            if row["id"] == "ch4_s3_luoyang_market":
                assert table[M] == OM and len(table) == 1595
                table[M] = targets[M]["candidate_sha256"]
                expected_changed.add(M)
            assert table.keys() == old_row[field].keys()
            assert {key for key in table if table[key] != old_row[field][key]} == expected_changed
            counts[row["id"]][field] = len(table)
    staged = json.loads(read(receipt["independent_owner_recipe_path"], receipt["independent_owner_recipe_sha256"]))
    assert same(successor["core_source_sha256"], staged["core_source_sha256"])
    assert same(successor["scenes"], staged["scenes"]) and same(successor["rooms"], staged["rooms"])
    successor["actual_stage_receipt"] = {"path": stagepath, "sha256": args.actual_stage_receipt_sha256}
    successor["declared_metadata_successor"] = {"whole_typed_and_byte_inverse": True, "fixed_source_keysets_all_unchanged": True, "no_current_collector_values_read": True, "mask_source_publication": pins["market_publication17536"], "parent_publication_source": pins["frozen_ao_manifest"]}
    assert all(sha(resource(path).read_bytes()) == expected for path, expected in first.items())
    maps_sha = write_new("market_identity2_actual_independent_qa_owner_source_maps_READY.json", successor)
    review_sha = write_new("market_identity2_actual_independent_source_review_READY.json", {"status": "INDEPENDENT_TWO_DECLARED_FIELDS_AND_INDEX_SOURCE_ONLY_SUCCESSOR_PASS", "actual_stage_receipt_sha256": args.actual_stage_receipt_sha256, "owner_maps_sha256": maps_sha, "targets": targets, "all_source_keysets_unchanged": True, "whole_typed_and_byte_inverse": True, "counts": counts, "no_engine_stager_collector_or_canonical_write": True})
    print(json.dumps({"owner_maps_sha256": maps_sha, "review_sha256": review_sha, "scene_rows": 8, "room_rows": 5}))


if __name__ == "__main__":
    main()
