"""Exact residual READY text freeze; no engine, collectors or production writes."""
import hashlib
import json
from pathlib import Path

QA = Path(__file__).resolve().parent
ROOT = Path(__file__).resolve().parents[3]
sha = lambda data: hashlib.sha256(data).hexdigest()
DOCS = {
    "res://build/luoyang_city_finish_20261025i_source01/outputs/root_region_source_rebind26_stage03/receipt.json": "ebeb133b25c8e6d8d27f1b571b5f4ebaf7a53acb6594c4ffa78bfceacefcb513",
    "res://build/luoyang_city_finish_20261025i_source01/region_source_rebind_repair02/region_source_rebind26_deployed_ROOT_ACTUAL.json": "5fcebce700aeff7f4646a4a81983665c3c0abf888330b1b5a8720485b132c361",
    "res://build/luoyang_city_finish_20261025i_source01/region_source_rebind_repair02/pre_remaining_guard_ROOT_ACTUAL.json": "5ff901b300d331f2a3780f550a7367e2a88ff7820eaef2801a85fdf289b6b4f9",
}
docs = []
for path, digest in DOCS.items():
    data = (ROOT / "game" / path.removeprefix("res://")).read_bytes()
    assert sha(data) == digest, path
    docs.append(json.loads(data))
assert docs[1]["passed"] is True and docs[1]["target_count"] == 26
assert docs[1]["stage"]["sha256"] == next(iter(DOCS.values()))
assert docs[2]["passed"] is True and docs[2]["checked"]["save15_exactticks"] == 15

original_key = (QA / "bounded_region_remaining02_NOTREADY.gd").read_bytes()
original_fixture = (QA / "bounded_region_remaining02_NOTREADY.json").read_bytes()
assert sha(original_key) == "bde0e265df7d592c440af3794c9f17c95877b9fc9843bd793ba798a90f982da7"
assert sha(original_fixture) == "9996f9fa6fa422b38c8f2064fcd5f840673c2177633156f03a749d308fdc2897"
old = json.loads(original_fixture)
contract = ROOT / "game/build/luoyang_regions_20261027d_source01/final_bounded_source_contract02_BUILD.json"
assert sha(contract.read_bytes()) == "fbea2783d833c0c942670604fbcc40f3325157a70565ad568955fd2cb1d1e783"
new_contract = json.loads(contract.read_bytes())
old_contract = json.loads((ROOT / "game/build/luoyang_regions_20261027d_source01/final_bounded_source_contract_BUILD.json").read_bytes())
for region in ("civic", "temple"):
    assert new_contract[region] == old_contract[region]
    assert len(new_contract["expected_sources"][region]) == old["declared_expected_sources"]["counts"][region]
assert new_contract["manifest"]["sha256"] == "77c638a7d229a6dfd2437b9b9374c15af68232899690d2d7dda52e17c44327ff"

fixture = original_fixture
fixture_hunks = []
def replace_fixture(before, after, count=1):
    global fixture
    before, after = before.encode(), after.encode()
    assert fixture.count(before) == count, before
    fixture = fixture.replace(before, after)
    fixture_hunks.append((before, after, count))

replace_fixture('"status": "NOTREADY_REPAIRED_CIVIC_DECLARATIONS_AND_ROOT_GUARD_PENDING"', '"status": "ROOT26_REPAIRED_CIVIC_TEMPLE_REMAINING_READY_NOT_EXECUTED"')
replace_fixture('"ready": false', '"ready": true')
blockers = json.dumps(old["blockers"], ensure_ascii=False, indent=2).replace("\n", "\n  ")
replace_fixture('"blockers": ' + blockers, '"blockers": []')
replace_fixture('"fixed_documents": {}', '"fixed_documents": ' + json.dumps(DOCS, ensure_ascii=False, separators=(",", ":")))
replace_fixture("final_bounded_source_contract_BUILD.json", "final_bounded_source_contract02_BUILD.json", 2)
replace_fixture("f0ad1e1f2e6c60c442d2e5dbcf650fad01686fa82ca208a499c829af9a9e609e", "fbea2783d833c0c942670604fbcc40f3325157a70565ad568955fd2cb1d1e783", 2)
replace_fixture("54976bb040827b1dfc4cff9103ef9c5d84841c57eec8790c803de48b3820cae6", "77c638a7d229a6dfd2437b9b9374c15af68232899690d2d7dda52e17c44327ff")
reverse = fixture
for before, after, count in reversed(fixture_hunks):
    assert reverse.count(after) == count, after
    reverse = reverse.replace(after, before)
assert reverse == original_fixture
actual = json.loads(fixture)
assert actual["ready"] is True and actual["fixed_documents"] == DOCS
assert actual["budgets"]["whole_seconds"] == 60 and "gate" not in actual

key = original_key
key_hunks = [
    (b"bounded_region_remaining02_NOTREADY.json", b"bounded_region_remaining02_READY.json"),
    (b"PENDING_ROOT_REPAIRED_SOURCE_FIXTURE_SHA", sha(fixture).encode()),
    (b"bounded_region_remaining02_NOTREADY_output/", b"bounded_region_remaining02_READY_output/"),
]
for before, after in key_hunks:
    assert key.count(before) == 1
    key = key.replace(before, after, 1)
reverse = key
for before, after in reversed(key_hunks):
    assert reverse.count(after) == 1
    reverse = reverse.replace(after, before, 1)
assert reverse == original_key
assert b"gate_admission" not in key and b"spec.gate" not in key

proof = {
    "status": "MECHANICAL_REMAINING_READY_FREEZE_NO_ENGINE",
    "key": {"path": "bounded_region_remaining02_READY.gd", "sha256": sha(key), "bytes": len(key)},
    "fixture": {"path": "bounded_region_remaining02_READY.json", "sha256": sha(fixture), "bytes": len(fixture)},
    "key_exact_three_literal_full_byte_inverse": True,
    "fixture_full_byte_inverse": True,
    "fixture_delta_only": "status/ready/blockers/fixed_documents; independent Source contract path+SHA and manifest SHA. No anchors/routes/dialogue/source counts or expected values observed-filled.",
    "independent_Source_counts": {"civic": 769, "temple": 679},
    "Root_fixed_documents": DOCS,
    "whole_seconds": 60, "max_PNG": 2, "Gate_retest": False,
    "original_EOF_EOL_preserved": True, "engine_calls": 0, "canonical_writes": 0,
}
for name, content in [(proof["key"]["path"], key), (proof["fixture"]["path"], fixture), ("bounded_region_remaining02_READY_mechanical_inverse.json", (json.dumps(proof, ensure_ascii=False, indent=2) + "\n").encode())]:
    with (QA / name).open("xb") as stream:
        stream.write(content)
print(json.dumps(proof, ensure_ascii=False))
