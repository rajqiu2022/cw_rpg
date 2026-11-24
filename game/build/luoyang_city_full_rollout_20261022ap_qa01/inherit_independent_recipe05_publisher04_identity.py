"""NEW exact publisher-identity successor; never recompute expected masks."""
from pathlib import Path
import copy
import hashlib
import json

ROOT = Path(__file__).resolve().parents[3]
GAME = ROOT / "game"
QA = Path(__file__).resolve().parent
SYSTEM = GAME / "build/luoyang_city_full_rollout_20261022ap_system01"
OUT = QA / "wall_yamen_independent_recipe05_SOURCE_FROZEN_NOT_ACTUAL.json"


def sha(path):
    return hashlib.sha256(path.read_bytes()).hexdigest()


def fixed(path, value):
    assert sha(path) == value, str(path)
    return json.loads(path.read_bytes())


assert not OUT.exists()
parent_path = QA / "wall_yamen_independent_recipe04_SOURCE_FROZEN_NOT_ACTUAL.json"
parent = fixed(parent_path, "f04cacc3620b867370fa3c1a03d6e48e8352081c05de7cfed461593a9642c444")
old_dir = SYSTEM / "finite_two_domain_publication_epoch03"
new_dir = SYSTEM / "finite_two_domain_publication_epoch04"
old_input = fixed(old_dir / "input_READY.json", "044d933bba30484de5b82c083a7e3ed487a33a977945c04e990912b0430904db")
new_input = fixed(new_dir / "input_READY.json", "7b1da122d0342d2a6db4be264237422343bf3d2564060b1908225d4f0fc04dc2")
restored_input = copy.deepcopy(new_input)
assert restored_input["output_prefix"] == old_input["output_prefix"].replace("epoch03", "epoch04")
restored_input["output_prefix"] = old_input["output_prefix"]
assert restored_input == old_input
old_script = old_dir / "publisher_READY.gd"
new_script = new_dir / "publisher_READY.gd"
assert sha(old_script) == "55b9c28203079a8943612df6a8076b45e7d0f5e335515dcdb49da30510591615"
assert sha(new_script) == "396fe184a196b6034909e75bffa9e988ad3f94f097c84cbce48b98723ef7fd1e"
expected = old_script.read_text(encoding="utf-8").replace("finite_two_domain_publication_epoch03", "finite_two_domain_publication_epoch04").replace("044d933bba30484de5b82c083a7e3ed487a33a977945c04e990912b0430904db", "7b1da122d0342d2a6db4be264237422343bf3d2564060b1908225d4f0fc04dc2")
addition = '''func exact_polygon_multiset(actual: Array[PackedVector2Array],expected: Array[PackedVector2Array]) -> bool:
	# Independent source oracle order need not equal original object ordinal.
	# Every complete typed polygon must match exactly, once; no epsilon/reorder
	# inside a polygon, no count loss, no current-data expected reconstruction.
	if actual.size()!=expected.size(): return false
	var used: Array[bool]=[]
	for index: int in expected.size(): used.append(false)
	for poly: PackedVector2Array in actual:
		var match_index: int=-1
		for index: int in expected.size():
			if not used[index] and api.equal(poly,expected[index]): match_index=index;break
		if match_index<0: return false
		used[match_index]=true
	return true
'''
assert expected.count("func parent_native(") == 1
expected = expected.replace("func parent_native(", addition + "func parent_native(", 1)
assert expected.count("api.equal(data.solids,expected_native)") == 1
expected = expected.replace("api.equal(data.solids,expected_native)", "exact_polygon_multiset(data.solids,expected_native)", 1)
assert expected == new_script.read_text(encoding="utf-8")
plan = copy.deepcopy(parent)
plan["prepared_recipe04_frozen_source_pixel_expectation"] = {"path": "res://" + parent_path.relative_to(GAME).as_posix(), "sha256": sha(parent_path)}
plan["unique_publisher_input_identity_only_not_expected_output"] = {"publisher": {"path": "res://" + new_script.relative_to(GAME).as_posix(), "sha256": sha(new_script)}, "input": {"path": "res://" + (new_dir / "input_READY.json").relative_to(GAME).as_posix(), "sha256": sha(new_dir / "input_READY.json")}}
plan["source_identity_successor_static_proof"] = {"input_change_only_new_output_prefix": True, "publisher_exact_normalized_text_inverse": True, "normalization_boundary": "read_text newline normalization for inspection only; all four original actual byte SHAs fixed above; no original file changed", "only_behavioral_delta": "Independent polygon list order uses one-to-one exact exhausted multiset. Packet.solids still exact sequence-equal record native solids. No perpolygon vertex reorder/value/type epsilon/count weakening.", "independent_mask_expectations_unchanged": True, "all_author_footprints_routes_actor_conditions_unchanged": True}
assert plan["independent_local_mask_expectations"] == parent["independent_local_mask_expectations"]
plan["status"] = "INDEPENDENT_SOURCE_FROZEN05_PUBLISHER04_EXACT_IDENTITY_SUCCESSOR_NOT_ACTUAL_PASS"
OUT.write_text(json.dumps(plan, ensure_ascii=False, indent=2)+"\n", encoding="utf-8")
print(json.dumps({"path": str(OUT), "sha256": sha(OUT), "mask_expected_unchanged": True, "PNG_decodes_this_successor": 0, "engine_runs": 0, "canonical_writes": 0, "accepted": False}))
