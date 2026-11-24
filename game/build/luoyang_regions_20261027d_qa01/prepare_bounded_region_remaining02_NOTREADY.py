"""Mechanical QA residual: remove passed Gate prefix; never runs Godot."""
import hashlib
import json
from pathlib import Path

QA = Path(__file__).resolve().parent
sha = lambda data: hashlib.sha256(data).hexdigest()
parent_key = (QA / "bounded_region_actual01_READY.gd").read_bytes()
parent_fixture = (QA / "bounded_region_actual01_READY.json").read_bytes()
assert sha(parent_key) == "ed25b432a110db493a2be31df277e92bd4a3e7983b214fbee1e8e8bdb45b9c40"
assert sha(parent_fixture) == "524e3c0dff93d54423154289f847dcb8299f4fb2da6f75c7f0709c9561363c7f"
actual = (QA / "bounded_region_actual01_READY_output/86968/result.json").read_bytes()
assert sha(actual) == "80d15c55500c29f74cd80a6c0286e88452287d00c07deba59084194f058458d8"
prior = json.loads(actual)
assert prior["complete"] is False and prior["PNG_count"] == 0
assert any(row.get("gate_new_hook_only") is True and row["source_count"] == 1628 for row in prior["records"])

key = parent_key
hunks = []

def change(before, after):
    global key
    before, after = before.encode(), after.encode()
    assert key.count(before) == 1, before
    key = key.replace(before, after, 1)
    hunks.append((before, after))

change("bounded_region_actual01_READY.json", "bounded_region_remaining02_NOTREADY.json")
change("524e3c0dff93d54423154289f847dcb8299f4fb2da6f75c7f0709c9561363c7f", "PENDING_ROOT_REPAIRED_SOURCE_FIXTURE_SHA")
change("bounded_region_actual01_READY_output/", "bounded_region_remaining02_NOTREADY_output/")
change('spec.budgets.whole_seconds==75', 'spec.budgets.whole_seconds==60')
change('ROOT_APPROVED_GATE_PLUS_TWO_CORE_75S_BOUND', 'ROOT_APPROVED_REMAINING_CIVIC_TEMPLE_60S_BOUND')
change('not spec.gate.expected_sources.is_empty() and spec.temple.task_acceptance==false', 'spec.temple.task_acceptance==false')
change('"FIXED_GATE_SOURCE_SET_AND_NO_TASK_ACCEPTANCE"', '"NO_TASK_ACCEPTANCE"')
eol = "\r\n" if b"\r\n" in parent_key else "\n"
change('\tif not await gate_admission(): finish(); return' + eol, '')
change('WHOLE_75S', 'WHOLE_60S')
change('for id: String in ["gate","civic","temple"]:', 'for id: String in ["civic","temple"]:')
begin = key.index(b"func gate_admission() -> bool:")
end = key.index(b"func enter_region(row: Dictionary) -> Node:", begin)
gate_function = key[begin:end]
assert gate_function.count(b"func gate_admission") == 1
key = key[:begin] + key[end:]
hunks.append((gate_function, b""))
change('New Gate child admission only, Civic seam and safe Temple greeting; no old services/Estate/whole city; explicit region entry not default performance', 'Civic seam and safe Temple greeting only; Gate1628/new child inherited from86968, not repeated; no old services/Estate/whole city or default performance')
# Reverse the explicit function removal at its stable next-function anchor.
reverse = key
for before, after in reversed(hunks):
    if before == gate_function:
        marker = b"func enter_region(row: Dictionary) -> Node:"
        assert reverse.count(marker) == 1
        reverse = reverse.replace(marker, gate_function + marker, 1)
    elif not after:
        assert b"await gate_admission()" in before
        marker = b"\tvar civic: Node=await enter_region(spec.civic)"
        assert reverse.count(marker) == 1
        reverse = reverse.replace(marker, before + marker, 1)
    else:
        assert reverse.count(after) == 1, after
        reverse = reverse.replace(after, before, 1)
assert reverse == parent_key

fixture = json.loads(parent_fixture)
fixture["status"] = "NOTREADY_REPAIRED_CIVIC_DECLARATIONS_AND_ROOT_GUARD_PENDING"
fixture["ready"] = False
fixture["blockers"] = ["Wait for Source immutable Family-source Civic bin/manifest/independent expected tables, and Root successful repair Stage/deployment/fresh guard. Old expected declarations below are provenance only until replaced; no observed fill."]
fixture["scope"] = "Remaining Civic seam + Temple original baima safe decline only; passed Gate prefix from86968 is not repeated. No room/old services/full-city replay."
fixture["budgets"]["whole_seconds"] = 60
old_gate = fixture.pop("gate")
old_docs = fixture["fixed_documents"]
fixture["fixed_documents"] = {}
old_gate_pin = fixture["fixed_sources"].pop("res://build/luoyang_city_rectification_20261027d_system01/gate_supply_door_depth.gd")
old_gate_count = fixture["declared_expected_sources"]["counts"].pop("gate")
fixture["inherited_gate_component_only"] = {
    "report": "res://build/luoyang_regions_20261027d_qa01/bounded_region_actual01_READY_output/86968/result.json",
    "sha256": sha(actual), "whole_complete": False,
    "component": "natural FINAL1628 and exact Gate supply child passed; no new-version Gate retest/performance credit",
    "old_fixture": {"path": "res://build/luoyang_regions_20261027d_qa01/bounded_region_actual01_READY.json", "sha256": sha(parent_fixture)},
}
fixture_bytes = (json.dumps(fixture, ensure_ascii=False, indent=2) + "\n").encode()
restored = json.loads(fixture_bytes)
restored.pop("inherited_gate_component_only")
restored["gate"] = old_gate
restored["fixed_documents"] = old_docs
restored["fixed_sources"]["res://build/luoyang_city_rectification_20261027d_system01/gate_supply_door_depth.gd"] = old_gate_pin
restored["declared_expected_sources"]["counts"]["gate"] = old_gate_count
old = json.loads(parent_fixture)
for name in ("status", "ready", "blockers", "scope", "budgets"):
    restored[name] = old[name]
assert restored == old

proof = {
    "status": "NOTREADY_RESIDUAL_PREPARATION_NO_ENGINE",
    "key": {"path": "bounded_region_remaining02_NOTREADY.gd", "sha256": sha(key), "bytes": len(key)},
    "fixture": {"path": "bounded_region_remaining02_NOTREADY.json", "sha256": sha(fixture_bytes), "bytes": len(fixture_bytes)},
    "parent_key_sha256": sha(parent_key), "parent_fixture_sha256": sha(parent_fixture),
    "full_key_byte_inverse": True, "fixture_full_typed_inverse": True,
    "original_failure_preserved": sha(actual),
    "delta": "Only passed Gate function/call/gate-specific fixture requirement removed; whole75->60; paths/hash pending; expectation source fixes not yet filled. Civic/Temple entry/routes/dialogue/static snapshots/2PNG logic unchanged.",
    "engine_calls": 0, "canonical_writes": 0,
}
for name, content in [(proof["key"]["path"], key), (proof["fixture"]["path"], fixture_bytes), ("bounded_region_remaining02_preparation_inverse.json", (json.dumps(proof, ensure_ascii=False, indent=2) + "\n").encode())]:
    with (QA / name).open("xb") as stream:
        stream.write(content)
print(json.dumps(proof, ensure_ascii=False))
