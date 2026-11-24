"""Mechanical QA-only freeze; no Godot, source collection, or canonical writes."""
import hashlib
import json
from pathlib import Path

ROOT = Path(__file__).resolve().parents[3]
QA = Path(__file__).resolve().parent
PINS = {
    "res://build/luoyang_city_finish_20261025i_source01/outputs/root_region_integration_exact32_stage02/receipt.json": "e569f5d85b4679175ff70a1f314d4eff3d8c4b8426471595b07539607a5376c5",
    "res://build/luoyang_city_finish_20261025i_source01/region_integration_20261027d01/region_integration32_deployed_ROOT_ACTUAL.json": "d9a8a9b7ac8752f31e8d3a59d7d4d8bddbcbaa261711bef05c6c608f54e7967f",
    "res://build/luoyang_city_finish_20261025i_source01/region_integration_20261027d01/pre_actual_guard_ROOT_ACTUAL.json": "4b4f678946c55cf8188f0e328b54056533033619bf27fcc0863cb353c18e10ee",
}

def sha(data):
    return hashlib.sha256(data).hexdigest()

def replace_once(data, before, after):
    assert data.count(before) == 1, before
    return data.replace(before, after, 1)

documents = []
for path, digest in PINS.items():
    raw = (ROOT / "game" / path.removeprefix("res://")).read_bytes()
    assert sha(raw) == digest, path
    documents.append(json.loads(raw))
assert documents[1]["passed"] is True and documents[1]["target_count"] == 32
assert documents[1]["stage"]["sha256"] == next(iter(PINS.values()))
assert documents[2]["passed"] is True
assert documents[2]["checked"]["save15_exactticks"] == 15

old_fixture = (QA / "bounded_region_actual01_NOTREADY.json").read_bytes()
old_key = (QA / "bounded_region_actual01_NOTREADY.gd").read_bytes()
assert sha(old_fixture) == "7e08ac8000bfedc134510560bb6db55cb2295716c0b005ecb59f1097cafc49c2"
assert sha(old_key) == "d71ccf6eaec43c2134bcfa21317d7a6fc58d76d4f6b781ebceecc6cf78bbcd54"
source = json.loads(old_fixture)
assert source["ready"] is False and source["fixed_documents"] == {}
assert source["budgets"]["whole_seconds"] == 75 and source["budgets"]["max_png"] == 2
assert len(source["save_paths"]) == 15

fixture_hunks = [
    (b'"status": "NOTREADY_FINAL_REGION_DECLARATIONS_AND_DEPLOYMENT_PENDING"', b'"status": "ROOT32_BOUNDED_GATE_CIVIC_TEMPLE_READY_NOT_EXECUTED"'),
    (b'"ready": false', b'"ready": true'),
    (json.dumps(source["blockers"][0], ensure_ascii=False).encode(), b'"ROOT_FIXED_DOCUMENTS_VERIFIED"'),
    (b'"fixed_documents": {}', ('"fixed_documents": ' + json.dumps(PINS, ensure_ascii=False, separators=(",", ":"))).encode()),
]
fixture = old_fixture
for before, after in fixture_hunks:
    fixture = replace_once(fixture, before, after)
# Keep the original surrounding byte layout; the cleared blocker is one exact span.
before_block = b'"blockers": [\n    "ROOT_FIXED_DOCUMENTS_VERIFIED"\n  ]'
if before_block not in fixture:
    before_block = before_block.replace(b"\n", b"\r\n")
assert fixture.count(before_block) == 1
fixture = fixture.replace(before_block, b'"blockers": []', 1)
assert json.loads(fixture)["ready"] is True
expected = json.loads(old_fixture)
actual = json.loads(fixture)
for field in ("status", "ready", "blockers", "fixed_documents"):
    actual[field] = expected[field]
assert actual == expected
fixture_reverse = replace_once(fixture, b'"blockers": []', before_block)
for before, after in reversed(fixture_hunks):
    fixture_reverse = replace_once(fixture_reverse, after, before)
assert fixture_reverse == old_fixture

fixture_name = "bounded_region_actual01_READY.json"
key_name = "bounded_region_actual01_READY.gd"
key_hunks = [
    (b'res://build/luoyang_regions_20261027d_qa01/bounded_region_actual01_NOTREADY.json', b'res://build/luoyang_regions_20261027d_qa01/bounded_region_actual01_READY.json'),
    (b'PENDING_ROOT_FINAL_FIXTURE_SHA', sha(fixture).encode()),
    (b'res://build/luoyang_regions_20261027d_qa01/bounded_region_actual01_output/', b'res://build/luoyang_regions_20261027d_qa01/bounded_region_actual01_READY_output/'),
]
key = old_key
for before, after in key_hunks:
    key = replace_once(key, before, after)
reverse = key
for before, after in reversed(key_hunks):
    reverse = replace_once(reverse, after, before)
assert reverse == old_key

receipt = {
    "status": "MECHANICAL_READY_FREEZE_NO_ENGINE",
    "key": {"path": key_name, "sha256": sha(key), "bytes": len(key)},
    "fixture": {"path": fixture_name, "sha256": sha(fixture), "bytes": len(fixture)},
    "key_exact_three_literal_byte_inverse": True,
    "original_EOF_and_EOL_preserved": True,
    "fixture_exact_byte_and_typed_inverse": True,
    "fixture_changed_fields_only": ["status", "ready", "blockers", "fixed_documents"],
    "budgets": source["budgets"],
    "independent_expected_sources": source["declared_expected_sources"],
    "Root_fixed_documents": PINS,
    "canonical_writes": 0,
    "engine_calls": 0,
}
for name, data in [(fixture_name, fixture), (key_name, key), ("bounded_region_actual01_READY_mechanical_inverse.json", (json.dumps(receipt, ensure_ascii=False, indent=2) + "\n").encode())]:
    path = QA / name
    with path.open("xb") as stream:
        stream.write(data)
print(json.dumps(receipt, ensure_ascii=False, separators=(",", ":")))
