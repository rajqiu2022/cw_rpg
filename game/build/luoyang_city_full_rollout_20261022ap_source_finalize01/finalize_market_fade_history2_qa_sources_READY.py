"""Independent source-only review after Root's single fade-row actual stage."""
import argparse
import copy
import json
from prepare_handoff10 import resource, sha, same, write_new

P = "res://build/luoyang_city_full_rollout_20261022ap_source_finalize01/"
M = "res://data/maps/luoyang_full_city_20261022ap/market/ch4_s3_luoyang_market/manifest.json"
I = "res://scripts/city/luoyang_full_city_index_20261022ap.gd"
OM = "08e3456d654cfa19442c91540d730a10fec4db1159ed5e1a8250d95e062a38be"
OI = "84b4aa577e0d46c26f0ac072ecab1f3999f29c577deec29ae0968f0eb26ebfa8"
FADE = "res://scripts/city/luoyang_district_life_fade_20261016f.gd"
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

    ipath = P + "market_fade_history2_ROOT_LOCKED.json"
    isha = "ff69b15af63829f64f0a6442ac4ab6e61bfd34eb3b66343db5144d2515edc42f"
    plan = json.loads(read(ipath, isha))
    stagepath = P + "outputs/root_integration9_market_fade_stage01/receipt.json"
    stage = json.loads(read(stagepath, args.actual_stage_receipt_sha256))
    assert stage["status"] == "AP_MARKET_SINGLE_FADE_HISTORY_TWO_TARGETS_STAGED_NOT_DEPLOYED"
    assert stage["input"] == {"path": ipath, "sha256": isha}
    assert stage["source_first"] == stage["source_final"]
    assert stage["target_partition"] == {"patch_count": 2, "copy_count": 0, "total": 2, "union_exact_targets": True}
    targets = {r["target"]: r for r in stage["targets"]}
    assert set(targets) == {M, I} and targets[M]["old_sha256"] == OM and targets[I]["old_sha256"] == OI
    pins = plan["pinned_inputs"]

    def pin(name):
        row = pins[name]
        return read(row["path"], row["sha256"])

    parent = json.loads(pin("parent_stage"))
    old_targets = {r["target"]: r for r in parent["targets"]}
    old_bytes = read(old_targets[M]["candidate_path"], OM)
    old = json.loads(old_bytes)
    next_bytes = read(targets[M]["candidate_path"], targets[M]["candidate_sha256"])
    nxt = json.loads(next_bytes)
    row = json.loads(pin("frozen_ao"))["source_migration"]["source_delta"][FADE]
    assert "source_migration" not in old
    restored = copy.deepcopy(nxt)
    assert same(restored.pop("source_migration"), {"source_delta": {FADE: row}}) and same(restored, old)
    marker = b',\n  "source_migration": '
    assert next_bytes.count(marker) == 1 and next_bytes[:next_bytes.index(marker)] + b"\n}\n" == old_bytes
    i0 = read(old_targets[I]["candidate_path"], OI)
    i1 = read(targets[I]["candidate_path"], targets[I]["candidate_sha256"])
    assert i0.count(OM.encode()) == 1 and i1 == i0.replace(OM.encode(), targets[M]["candidate_sha256"].encode())
    previous = json.loads(pin("parent_owners"))
    result = copy.deepcopy(previous)
    for path in [M, I]:
        assert result["core_source_sha256"][path] == targets[path]["old_sha256"]
        result["core_source_sha256"][path] = targets[path]["candidate_sha256"]
    counts = {}
    for r in result["scenes"] + result["rooms"]:
        old_row = next(x for x in previous["scenes"] + previous["rooms"] if x["id"] == r["id"])
        counts[r["id"]] = {}
        for field in ["source_sha256", "receipt_source_sha256"]:
            table = r[field]
            changed = set()
            if r["id"] in FOUR:
                assert table[I] == OI
                table[I] = targets[I]["candidate_sha256"]
                changed.add(I)
            if r["id"] == "ch4_s3_luoyang_market":
                assert table[M] == OM and len(table) == 1595
                table[M] = targets[M]["candidate_sha256"]
                changed.add(M)
            assert table.keys() == old_row[field].keys()
            assert {k for k in table if table[k] != old_row[field][k]} == changed
            counts[r["id"]][field] = len(table)
    pending = json.loads(read(stage["independent_owner_recipe_path"], stage["independent_owner_recipe_sha256"]))
    assert same(result["core_source_sha256"], pending["core_source_sha256"])
    assert same(result["scenes"], pending["scenes"]) and same(result["rooms"], pending["rooms"])
    result["actual_stage_receipt"] = {"path": stagepath, "sha256": args.actual_stage_receipt_sha256}
    result["fade_history_successor"] = {"only_frozen_ao_fade_row": True, "frozen_ao": pins["frozen_ao"], "all_source_keysets_unchanged": True, "no_current_collector_values_read": True}
    assert all(sha(resource(path).read_bytes()) == expected for path, expected in first.items())
    maps_sha = write_new("market_fade_history2_actual_independent_qa_owner_source_maps_READY.json", result)
    review_sha = write_new("market_fade_history2_actual_independent_source_review_READY.json", {"status": "INDEPENDENT_SINGLE_FROZEN_FADE_ROW_WHOLE_TYPED_BYTE_INVERSE_PASS", "actual_stage_receipt_sha256": args.actual_stage_receipt_sha256, "owner_maps_sha256": maps_sha, "targets": targets, "all_source_keysets_unchanged": True, "counts": counts, "no_engine_stager_collector_or_canonical_write": True})
    print(json.dumps({"owner_maps_sha256": maps_sha, "review_sha256": review_sha, "scene_rows": 8, "room_rows": 5}))


if __name__ == "__main__":
    main()
