"""Root-only single historical fade row and one index SHA; no engine/writeback."""
import argparse
import copy
import json
from pathlib import Path
from stage_sources_repair_retry5 import build_file_patch, digest, encode, need, res, same

HERE = Path(__file__).resolve().parent
P = "res://build/luoyang_city_full_rollout_20261022ap_source_finalize01/"
M = "res://data/maps/luoyang_full_city_20261022ap/market/ch4_s3_luoyang_market/manifest.json"
I = "res://scripts/city/luoyang_full_city_index_20261022ap.gd"
OM = "08e3456d654cfa19442c91540d730a10fec4db1159ed5e1a8250d95e062a38be"
OI = "84b4aa577e0d46c26f0ac072ecab1f3999f29c577deec29ae0968f0eb26ebfa8"
FADE = "res://scripts/city/luoyang_district_life_fade_20261016f.gd"
F0 = "f359a43a88470ff220fa095cbd7f73ea04637c55c2faadd0a3b5f325e4b7a244"
F1 = "bc2958cc8f9a60ac9952891c30037441a62e289d8fee2fa235e6b864abf3a1bf"
F2 = "3f2d43276f89341a450579fa07a0dd0bb2369d059ad928e7187fb35df59f1ac7"
FOUR = {"ch4_s0_luoyang_gate", "ch4_s1_luoyang_yamen", "ch4_s2_canal_docks", "ch4_s3_luoyang_market"}


def run(spec):
    first = {}

    def read(path, expected):
        raw = res(path).read_bytes()
        need(digest(raw) == expected, "PIN_CHANGED:" + path)
        first[path] = expected
        return raw

    def pin(name):
        row = spec["pinned_inputs"][name]
        return read(row["path"], row["sha256"])

    need(spec["status"] == "ROOT_LOCKED_MARKET_SINGLE_FADE_HISTORY_TWO_TARGETS", "ROOT_LOCKED_INPUT")
    scope = json.loads(pin("root_scope"))
    need(scope["approved_by_root"] is True and scope["target_count"] == 2 and {r["target"]: r["old_sha256"] for r in scope["targets"]} == {M: OM, I: OI}, "ROOT_SCOPE9_EXACT_TWO")
    before_m, before_i = read(M, OM), read(I, OI)
    parent_receipt = json.loads(pin("parent_stage"))
    parent_targets = {r["target"]: r for r in parent_receipt["targets"]}
    need(read(parent_targets[M]["candidate_path"], OM) == before_m and read(parent_targets[I]["candidate_path"], OI) == before_i, "EXACT_C316_CURRENT_BYTES")
    old = json.loads(before_m)
    need("source_migration" not in old, "SINGLE_ABSENT_ROOT_FIELD_ONLY")
    ao = json.loads(pin("frozen_ao"))
    row = ao["source_migration"]["source_delta"][FADE]
    need(row["historical_sha256"] == [F0, F1] and row["current_before_sha256"] == F1 and row["new_sha256"] == F2 and row["candidate_path"] == "res://build/luoyang_market_two_shops_20261021ao_system01/District_fade_READY.gd", "EXACT_F359_BC2958_3F2D_FROZEN_AO_ROW")
    read(row["candidate_path"], F2)
    read(FADE, F2)
    owners = json.loads(pin("parent_owners"))
    market = next(r for r in owners["scenes"] if r["id"] == "ch4_s3_luoyang_market")
    need(len(market["source_sha256"]) == 1595, "FIXED_MARKET1595")
    binding = json.loads(pin("district_binding"))["source_sha256"]
    need(len(binding) == 93, "FIXED_DISTRICT93")
    differences = {k: {"prior": v, "city_fixed": market["source_sha256"].get(k)} for k, v in binding.items() if market["source_sha256"].get(k) != v}
    need(differences == {FADE: {"prior": F0, "city_fixed": F2}}, "ONLY_FADE_DIFFERENCE_OTHER92_EXACT")
    migration = {"source_delta": {FADE: row}}
    need(before_m.endswith(b"\n}\n"), "PARENT_TERMINAL_JSON_BYTES")
    member = '  "source_migration": ' + json.dumps(migration, ensure_ascii=False, indent=2).replace("\n", "\n  ")
    after_m = before_m[:-3] + b",\n" + member.encode("utf-8") + b"\n}\n"
    value = json.loads(after_m)
    restored = copy.deepcopy(value)
    need(same(restored.pop("source_migration"), migration) and same(restored, old), "SINGLE_ROOT_FIELD_WHOLE_TYPED_INVERSE")
    suffix = b",\n" + member.encode("utf-8") + b"\n}\n"
    need(after_m.endswith(suffix) and after_m[:-len(suffix)] + b"\n}\n" == before_m, "SINGLE_ROOT_MEMBER_WHOLE_BYTE_INVERSE")
    need(before_i.count(OM.encode()) == 1, "INDEX_ONE_OLD_SHA_LITERAL")
    after_i = before_i.replace(OM.encode(), digest(after_m).encode())
    need(after_i.replace(digest(after_m).encode(), OM.encode()) == before_i, "INDEX_ONE_LITERAL_WHOLE_BYTE_INVERSE")
    successor = copy.deepcopy(owners)
    for path, old_sha, new_sha in [(M, OM, digest(after_m)), (I, OI, digest(after_i))]:
        need(successor["core_source_sha256"][path] == old_sha, "CORE_EXACT_OLD_HEADER")
        successor["core_source_sha256"][path] = new_sha
    for r in successor["scenes"] + successor["rooms"]:
        for field in ["source_sha256", "receipt_source_sha256"]:
            if r["id"] in FOUR:
                need(r[field][I] == OI, "FOUR_EXISTING_INDEX_VALUES")
                r[field][I] = digest(after_i)
            if r["id"] == "ch4_s3_luoyang_market":
                need(r[field][M] == OM, "MARKET_EXISTING_MANIFEST_VALUE")
                r[field][M] = digest(after_m)
    successor["status"] = "SOURCE_ONLY_DERIVED_FADE_HISTORY_QA_MAPS_PENDING_EXTERNAL_ACTUAL_STAGE_RECEIPT"
    out = spec["output_root"]
    need(out.startswith(P + "outputs/") and out.endswith("/") and not res(out).exists(), "NEW_BUILD_ONLY_OUTPUT")
    outputs = {out + "market_source_successor.json": after_m, out + "ap_city_index_true.gd": after_i, out + "independent_qa_source_maps_pending_receipt.json": encode(successor)}
    patch, proofs, targets = "*** Begin Patch\n", {}, []
    for target, prior, old_bytes, filename, data in [(M, OM, before_m, "market_source_successor.json", after_m), (I, OI, before_i, "ap_city_index_true.gd", after_i)]:
        piece, proof = build_file_patch(res(target).as_posix(), old_bytes, data)
        patch += piece
        proofs[target] = proof
        targets.append({"target": target, "old_sha256": prior, "candidate_path": out + filename, "candidate_sha256": digest(data), "candidate_bytes": len(data)})
    patch += "*** End Patch\n"
    outputs[out + "canonical_deployment.apply_patch"] = patch.encode("utf-8")
    final = {path: digest(res(path).read_bytes()) for path in first}
    need(final == first, "SOURCE_FIRST_FINAL_DRIFT")
    receipt = {"status": "AP_MARKET_SINGLE_FADE_HISTORY_TWO_TARGETS_STAGED_NOT_DEPLOYED", "input": spec["_locked_input"], "targets": targets, "exact_frozen_ao_fade_row": row, "district_binding93_only_mismatch": differences, "other92_binding_sources_exact": True, "one_root_member_typed_and_byte_inverse": True, "index_one_literal_whole_byte_inverse": True, "source_keys_all_unchanged": True, "source_first": first, "source_final": final, "patch_path": out + "canonical_deployment.apply_patch", "patch_sha256": digest(outputs[out + "canonical_deployment.apply_patch"]), "patch_reconstruction": proofs, "target_partition": {"patch_count": 2, "copy_count": 0, "total": 2, "union_exact_targets": True}, "independent_owner_recipe_path": out + "independent_qa_source_maps_pending_receipt.json", "independent_owner_recipe_sha256": digest(outputs[out + "independent_qa_source_maps_pending_receipt.json"]), "no_engine_import_collector_geometry_or_canonical_write": True}
    outputs[out + "receipt.json"] = encode(receipt)
    need(not res(out).exists(), "NO_EARLY_OUTPUT_WRITE")
    for path, data in outputs.items():
        target = res(path)
        target.parent.mkdir(parents=True, exist_ok=True)
        with target.open("xb") as stream:
            stream.write(data)
    return {"targets": 2, "receipt_sha256": digest(outputs[out + "receipt.json"]), "output_root": out}


if __name__ == "__main__":
    parser = argparse.ArgumentParser()
    parser.add_argument("input")
    parser.add_argument("--input-sha256", required=True)
    args = parser.parse_args()
    data = Path(args.input).read_bytes()
    need(digest(data) == args.input_sha256, "ROOT_EXTERNAL_INPUT_PIN")
    spec = json.loads(data)
    spec["_locked_input"] = {"path": "res://" + Path(args.input).resolve().relative_to(HERE.parents[1]).as_posix(), "sha256": args.input_sha256}
    print(json.dumps(run(spec)))
