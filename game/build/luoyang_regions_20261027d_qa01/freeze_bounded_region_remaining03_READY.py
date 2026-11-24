"""Only fixed proof/header replacements from residual02; no engine or source writes."""
import hashlib
import json
from pathlib import Path

QA = Path(__file__).resolve().parent
ROOT = Path(__file__).resolve().parents[3]
sha = lambda data: hashlib.sha256(data).hexdigest()
DOCS = {
    "res://build/luoyang_city_finish_20261025i_source01/outputs/root_region_phase_lifetime27_stage01/receipt.json": "d141e156f5b0bb0fdc7cf10e0cabc312bc27b8c3774324c14dd0a232e56830ce",
    "res://build/luoyang_city_finish_20261025i_source01/region_phase_lifetime_repair03/region_phase27_deployed_ROOT_ACTUAL.json": "b78d8866036117ddbe0f09719a0cc8d15596a2eb7e467b238a13107b0d1e021b",
    "res://build/luoyang_city_finish_20261025i_source01/region_phase_lifetime_repair03/pre_remaining_guard_ROOT_ACTUAL.json": "4e7249a43575d81199ebd660affe634a947c8ed25a922157fa4486b9dbb5c4fc",
}
for path, digest in DOCS.items():
    assert sha((ROOT / "game" / path.removeprefix("res://")).read_bytes()) == digest
old_key = (QA / "bounded_region_remaining02_READY.gd").read_bytes()
old_fixture = (QA / "bounded_region_remaining02_READY.json").read_bytes()
assert sha(old_key) == "1428e9f97742a1d0d3116cd9b8ce6c569c40dee119bfb91627afefa38134f534"
assert sha(old_fixture) == "b4327c2fb5433f0339a17484724a49c2b7b8f3d464055e29a05ff2f8ff027484"
old = json.loads(old_fixture)
source_root = ROOT / "game/build/luoyang_regions_20261027d_source01"
source_bytes = (source_root / "final_bounded_source_contract03_BUILD.json").read_bytes()
assert sha(source_bytes) == "abce7a59fdc91d589741e95b0ebe3ef6f781c1d032ea0ce053de4cfefd61e751"
source = json.loads(source_bytes)
previous = json.loads((source_root / "final_bounded_source_contract02_BUILD.json").read_bytes())
assert source["civic"] == previous["civic"] and source["temple"] == previous["temple"]
assert {key: source["counts"][key] for key in ("civic", "temple")} == old["declared_expected_sources"]["counts"]

fixture = old_fixture
fixture_hunks = []
def change(before, after, count=1):
    global fixture
    before, after = before.encode(), after.encode()
    assert fixture.count(before) == count, before
    fixture = fixture.replace(before, after)
    fixture_hunks.append((before, after, count))

change("ROOT26_REPAIRED_CIVIC_TEMPLE_REMAINING_READY_NOT_EXECUTED", "ROOT27_PHASE_LIFETIME_CIVIC_TEMPLE_REMAINING_READY_NOT_EXECUTED")
change(json.dumps(old["fixed_documents"], separators=(",", ":")), json.dumps(DOCS, separators=(",", ":")))
change("final_bounded_source_contract02_BUILD.json", "final_bounded_source_contract03_BUILD.json", 2)
change("fbea2783d833c0c942670604fbcc40f3325157a70565ad568955fd2cb1d1e783", "abce7a59fdc91d589741e95b0ebe3ef6f781c1d032ea0ce053de4cfefd61e751", 2)
change("77c638a7d229a6dfd2437b9b9374c15af68232899690d2d7dda52e17c44327ff", "85c16eb0506e60bb3b0310218bb942beafd90840f447b503d5e231de43be6023")
change("c8930e13dba3073343c6c013a10b1776a844b5fef16572049b576ec79cf19d11", "e61e0ebc917735683a5f720eb3cbfa7157bd1eb2c97d463f2a7a94c1b489a4cd")
reverse = fixture
for before, after, count in reversed(fixture_hunks):
    assert reverse.count(after) == count
    reverse = reverse.replace(after, before)
assert reverse == old_fixture

key_hunks = [
    (b"bounded_region_remaining02_READY.json", b"bounded_region_remaining03_READY.json"),
    (sha(old_fixture).encode(), sha(fixture).encode()),
    (b"bounded_region_remaining02_READY_output/", b"bounded_region_remaining03_READY_output/"),
]
key = old_key
for before, after in key_hunks:
    assert key.count(before) == 1
    key = key.replace(before, after, 1)
reverse = key
for before, after in reversed(key_hunks):
    assert reverse.count(after) == 1
    reverse = reverse.replace(after, before, 1)
assert reverse == old_key
new = json.loads(fixture)
assert new["ready"] is True and new["budgets"]["whole_seconds"] == 60 and new["budgets"]["max_png"] == 2
assert "gate" not in new and b"gate_admission" not in key
proof = {
    "status": "MECHANICAL_READY03_NO_ENGINE",
    "key": {"path": "bounded_region_remaining03_READY.gd", "sha256": sha(key), "bytes": len(key)},
    "fixture": {"path": "bounded_region_remaining03_READY.json", "sha256": sha(fixture), "bytes": len(fixture)},
    "key_exact_three_literal_full_byte_inverse": True,
    "fixture_full_byte_inverse": True,
    "fixture_changed_only": "status, Source03 path/SHA, manifest SHA, RegionField SHA, three Root documents; all source-derived anchors/routes/dialogue/static snapshot/60s2PNG unchanged",
    "old_failure102304_preserved": True, "Gate_retest": False,
    "engine_calls": 0, "canonical_writes": 0,
}
for name, data in [(proof["key"]["path"], key), (proof["fixture"]["path"], fixture), ("bounded_region_remaining03_READY_mechanical_inverse.json", (json.dumps(proof, indent=2) + "\n").encode())]:
    with (QA / name).open("xb") as stream:
        stream.write(data)
print(json.dumps(proof))
