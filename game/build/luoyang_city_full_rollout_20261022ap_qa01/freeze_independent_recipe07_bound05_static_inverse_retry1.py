"""Unique read-only static inverse and prior expectation freeze for05_bound01.

No engine, PNG decode, native diagnostic read or new expected numeric derivation.
"""
from pathlib import Path
import copy
import hashlib
import json

ROOT = Path(__file__).resolve().parents[3]
GAME = ROOT / "game"
QA = Path(__file__).resolve().parent
SYSTEM = GAME / "build/luoyang_city_full_rollout_20261022ap_system01"
OUT = QA / "wall_yamen_independent_recipe07_BOUND05_SOURCE_FROZEN_RETRY1_NOT_ACTUAL.json"


def sha(path):
    return hashlib.sha256(path.read_bytes()).hexdigest()


def fixed(path, expected):
    assert sha(path) == expected, str(path)
    return json.loads(path.read_bytes())


def local(path):
    assert path.startswith("res://") and ".." not in path
    return GAME / path[6:]


assert not OUT.exists()
parent_path = QA / "wall_yamen_independent_recipe06_TWO_SOURCE_ROWS_FIXED_NOT_ACTUAL.json"
prior = fixed(parent_path, "f8952820d003d5784fd40cb4614323056cc282b8a09e0cb489633d4e5c760899")
old_dir = SYSTEM / "finite_two_domain_publication_epoch04"
new_dir = SYSTEM / "finite_two_domain_publication_epoch05_bound01"
old_input_path, input_path = old_dir / "input_READY.json", new_dir / "input_READY.json"
old_input = fixed(old_input_path, "7b1da122d0342d2a6db4be264237422343bf3d2564060b1908225d4f0fc04dc2")
new_input = fixed(input_path, "3739600a91f13531b633d215b04b92caa1eec70d8922727663868c0393afd5f7")
handoff_path = new_dir / "handoff_READY.json"
handoff = fixed(handoff_path, "9992b199edb53776ce35b119f80d24b3e50b9c5080e6801d7f7e86b6dfab0b0b")
auth_row = handoff["Root_arithmetic_authorization"]
auth = fixed(local(auth_row["path"]), "1dc99ef19c3591093c8d89eaa9c61690be4f8c5b3feb9231ba0a7ac72ea07931")
assert auth["independent_source_recipe_sha256"] == sha(parent_path)
proof_row = handoff["source_expression_proof"]
fixed(local(proof_row["path"]), "ee85e0112a1b0053393420926c1d13498c0bc2d76bbf7daa5138bf5becefb155")
assert len(old_input["source_pins"]) == 46 and len(new_input["source_pins"]) == 53
extra = {k: v for k, v in new_input["source_pins"].items() if k not in old_input["source_pins"]}
assert len(extra) == 7
for k, v in old_input["source_pins"].items():
    assert new_input["source_pins"][k] == v
for k, v in extra.items():
    assert sha(local(k)) == v
restored = copy.deepcopy(new_input)
restored["output_prefix"] = old_input["output_prefix"]
changed_ids = {r["id"] for r in prior["source_arithmetic_two_row_revision"]["exact_four_coordinate_components_in_two_rows"]}
assert changed_ids == {"market_west_ward_frontage_solid_2", "assembled_market_tree_group_a_rect"}
expected_rows = {r["id"]: r for r in prior["Market"]["parent_geometry"]["solids"]}
old_rows = {r["id"]: r for r in old_input["market"]["raw_geometry"]["solids"]}
for row in restored["market"]["raw_geometry"]["solids"]:
    if row["id"] in changed_ids:
        assert row == expected_rows[row["id"]]
        row["points_px"] = copy.deepcopy(old_rows[row["id"]]["points_px"])
assert new_input["market"]["raw_geometry"] == prior["Market"]["parent_geometry"]
assert new_input["yamen"]["raw_geometry"] == prior["Yamen"]["parent_geometry"]
for k in extra:
    restored["source_pins"].pop(k)
assert len(old_input["source_pin_lineage"]) == 52
assert len(restored["source_pin_lineage"]) == 59
new_lineage = [r for r in restored["source_pin_lineage"] if r["path"] in extra]
assert len(new_lineage) == 7 and {r["path"] for r in new_lineage} == set(extra)
restored["source_pin_lineage"] = [r for r in restored["source_pin_lineage"] if r["path"] not in extra]
assert restored.pop("arithmetic_correction_authorization") == auth_row
assert restored == old_input
# Type-aware serialized comparison follows original stored JSON scalar values;
# it does not rely on Python's relaxed integer-vs-float equality alone.
assert json.dumps(restored, ensure_ascii=False, sort_keys=True, separators=(",", ":")) == json.dumps(old_input, ensure_ascii=False, sort_keys=True, separators=(",", ":"))
publisher_path = new_dir / "publisher_READY.gd"
old_publisher_path = old_dir / "publisher_READY.gd"
assert sha(publisher_path) == "43cddead404f6aec31be20c3f79bf1065de4984b68cb98b99e9068a1cdbfb351"
assert sha(old_publisher_path) == "396fe184a196b6034909e75bffa9e988ad3f94f097c84cbce48b98723ef7fd1e"
expected_bytes = old_publisher_path.read_bytes()
for before, after in ((b"finite_two_domain_publication_epoch04", b"finite_two_domain_publication_epoch05_bound01"), (b"7b1da122d0342d2a6db4be264237422343bf3d2564060b1908225d4f0fc04dc2", b"3739600a91f13531b633d215b04b92caa1eec70d8922727663868c0393afd5f7")):
    expected_bytes = expected_bytes.replace(before, after)
assert expected_bytes == publisher_path.read_bytes()
plan = copy.deepcopy(prior)
plan["prepared_recipe06_exact_two_source_rows"] = {"path": "res://" + parent_path.relative_to(GAME).as_posix(), "sha256": sha(parent_path)}
plan["unique_publisher_input_identity_only_not_expected_output"] = {"publisher": {"path": "res://" + publisher_path.relative_to(GAME).as_posix(), "sha256": sha(publisher_path)}, "input": {"path": "res://" + input_path.relative_to(GAME).as_posix(), "sha256": sha(input_path)}}
plan["bound05_unique_static_inverse"] = {"handoff_sha256": sha(handoff_path), "authorization": auth_row, "source_expression_proof": proof_row, "source_pin_counts": [46, 53], "source_provenance_row_counts_separate_from_unique_keys": [52, 59], "seven_extra_source_pins": extra, "publisher_whole_original_byte_inverse_except_two_paths_and_one_SHA_header": True, "input_whole_type_and_serialized_inverse_except_two_rows_new_OUT_seven_declarations_and_Rootauth": True, "prior_mask_expected_RGBA_cells_inherited_unchanged_no_redecode": True, "neither_failed04_nor_native_diagnostic_reexecuted": True, "first_QA_lineage_count_assertion_failure_retained": True}
assert plan["independent_local_mask_expectations"] == prior["independent_local_mask_expectations"]
plan["status"] = "INDEPENDENT_SOURCE_FROZEN07_BOUND05_STATIC_INVERSE_COMPLETE_NOT_ACTUAL_GEOMETRY_PASS"
OUT.write_text(json.dumps(plan, ensure_ascii=False, indent=2)+"\n", encoding="utf-8")
print(json.dumps({"path": str(OUT), "sha256": sha(OUT), "source_pin_counts": [46,53], "exact_input_inverse": True, "exact_publisher_byte_inverse": True, "PNG_decodes": 0, "engine_runs": 0, "canonical_writes": 0}))
