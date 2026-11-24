"""Mechanical two-view READY freeze; no engine or production/source writes."""
import hashlib
import json
from pathlib import Path

QA = Path(__file__).resolve().parent
ROOT = Path(__file__).resolve().parents[3]
sha = lambda raw: hashlib.sha256(raw).hexdigest()
DOCS = {
    "res://build/luoyang_city_finish_20261025i_source01/outputs/root_region_visual_finish27_stage01/receipt.json": "1cb68ac8d97914c9495edf57e7e08aab4f168396ed06cd874805a1137424ceb1",
    "res://build/luoyang_city_finish_20261025i_source01/region_visual_finish_repair04/region_visual27_deployed_ROOT_ACTUAL.json": "c1c49f44787d404b8646076ff09bc14003d92f1732b2ae77c77ea7f519cad78a",
    "res://build/luoyang_city_finish_20261025i_source01/region_visual_finish_repair04/pre_views_guard_ROOT_ACTUAL.json": "7f08c621aeafea2b9ee62e27f731e5cbf073ba030091d681a112870896cf79e2",
}
FIXED = {
    "res://build/luoyang_regions_20261027d_source01/final_views_source_contract04_BUILD.json": "2a7a9852e8d395e2194e55837d855ce25708aa2bc0c6920aff939c62e80d4629",
    "res://build/luoyang_regions_20261027d_source01/region_runtime_manifest_BUILD.json": "749e8d4e3b60f87badc57fd46e21b7122da9804d1f270fe687a2cb5ddde77b3e",
    "res://build/luoyang_regions_20261027d_source01/region_field.gd": "53736563fc853b7a4813c6ad682e91feec877f5a0c9ed224f38ca352cb60efcd",
}
parsed_docs = []
for path, digest in DOCS.items():
    raw = (ROOT / "game" / path.removeprefix("res://")).read_bytes()
    assert sha(raw) == digest, path
    parsed_docs.append(json.loads(raw))
assert parsed_docs[1]["passed"] is True and parsed_docs[1]["target_count"] == 27
assert parsed_docs[1]["stage"]["sha256"] == next(iter(DOCS.values()))
assert parsed_docs[2]["passed"] is True and parsed_docs[2]["checked"]["save15_exactticks"] == 15
for path, digest in FIXED.items():
    assert sha((ROOT / "game" / path.removeprefix("res://")).read_bytes()) == digest
decl_path = next(iter(FIXED))
declared = json.loads((ROOT / "game" / decl_path.removeprefix("res://")).read_bytes())
assert declared["status"] == "FIXED_SOURCE_EXPRESSION_DECLARATIONS_NOT_OBSERVED_RECEIPTS"
assert {key: declared["counts"][key] for key in ("civic", "temple")} == {"civic": 769, "temple": 679}
for key in ("civic", "temple"):
    assert len(declared["expected_sources"][key]) == declared["counts"][key]

old_key = (QA / "region_visual_views04_NOTREADY.gd").read_bytes()
old_fixture = (QA / "region_visual_views04_NOTREADY.json").read_bytes()
assert sha(old_key) == "4d4b34ade0874b700b163a26d7d857abe74df84b4f5100d26b3a5e8a3f203604"
assert sha(old_fixture) == "d9954af7f5c0144c5ab017dfceb3d5532bd504408135fae741ebc88a240afef0"
old = json.loads(old_fixture)
fixture = old_fixture
fixture_hunks = []
def change(before, after):
    global fixture
    before, after = before.encode(), after.encode()
    assert fixture.count(before) == 1, before
    fixture = fixture.replace(before, after, 1)
    fixture_hunks.append((before, after))

change("NOTREADY_VISUAL_RESIDUAL_FINAL_DECLARATIONS_AND_DEPLOYMENT_PENDING", "ROOT_VISUAL27_TWO_NATIVE_VIEWS_READY_NOT_EXECUTED")
change('"ready": false', '"ready": true')
change('"blockers": ' + json.dumps(old["blockers"]), '"blockers": []')
change('"fixed_sources": {}', '"fixed_sources": ' + json.dumps(FIXED))
change('"fixed_documents": {}', '"fixed_documents": ' + json.dumps(DOCS))
new_declaration = {"path": decl_path, "sha256": FIXED[decl_path], "counts": {"civic": 769, "temple": 679}}
change('"declared_expected_sources": ' + json.dumps(old["declared_expected_sources"]), '"declared_expected_sources": ' + json.dumps(new_declaration))
reverse = fixture
for before, after in reversed(fixture_hunks):
    assert reverse.count(after) == 1
    reverse = reverse.replace(after, before, 1)
assert reverse == old_fixture
new = json.loads(fixture)
for name in ("status", "ready", "blockers", "fixed_sources", "fixed_documents", "declared_expected_sources"):
    new[name] = old[name]
assert new == old

key = old_key
key_hunks = [
    (b"region_visual_views04_NOTREADY.json", b"region_visual_views04_READY.json"),
    (b"PENDING_ROOT_FINAL_VISUAL_FIXTURE_SHA", sha(fixture).encode()),
    (b"region_visual_views04_NOTREADY_output/", b"region_visual_views04_READY_output/"),
]
for before, after in key_hunks:
    assert key.count(before) == 1
    key = key.replace(before, after, 1)
reverse = key
for before, after in reversed(key_hunks):
    assert reverse.count(after) == 1
    reverse = reverse.replace(after, before, 1)
assert reverse == old_key

proof = {
    "status": "MECHANICAL_VIEWS_READY04_NO_ENGINE",
    "key": {"path": "region_visual_views04_READY.gd", "sha256": sha(key), "bytes": len(key)},
    "fixture": {"path": "region_visual_views04_READY.json", "sha256": sha(fixture), "bytes": len(fixture)},
    "key_exact_three_literal_full_byte_inverse": True,
    "fixture_full_byte_and_typed_inverse": True,
    "fixture_changed_fields_only": ["status", "ready", "blockers", "fixed_sources", "fixed_documents", "declared_expected_sources"],
    "public_uvs_and_behavior_unchanged": True,
    "whole_seconds": 45, "max_PNG": 2, "INPUT": 0, "Space": 0,
    "no_Gate_seam_or_monk_retest": True,
    "expected_sources_from_fixed_Source_declaration_not_observation": True,
    "engine_calls": 0, "canonical_writes": 0,
}
for name, raw in [(proof["key"]["path"], key), (proof["fixture"]["path"], fixture), ("region_visual_views04_READY_mechanical_inverse.json", (json.dumps(proof, indent=2) + "\n").encode())]:
    with (QA / name).open("xb") as stream:
        stream.write(raw)
print(json.dumps(proof))
