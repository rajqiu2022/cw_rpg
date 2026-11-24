"""Freeze only E's already-approved residual against independent stage06 owners.

No engine, live collector, canonical write, or observed-value expectation input.
Old E failures, D and visual fixtures remain untouched.
"""
from pathlib import Path
import copy
import hashlib
import json
import subprocess
import sys

ROOT = Path(__file__).resolve().parents[3]
QA = Path(__file__).resolve().parent
SYSTEM = ROOT / "game/build/luoyang_city_full_rollout_20261022ap_system01"
SOURCE = ROOT / "game/build/luoyang_city_full_rollout_20261022ap_source_finalize01"
OWNERS = SOURCE / "unified06_06_independent_qa_owner_source_maps_READY.json"
OWNERS_SHA = "3f8d04fde11e7a64b1f1364510cee817466a853c31ae3a98375ca8bcc7283ac8"
OLD = QA / "unified_finish02_E_performance_numeric_vectors_retry1_READY.json"
OLD_SHA = "17f1db0ff5b39547d53fd4c068184bf366e38112c03ae03858f75bd3b3e30644"
ASSEMBLER = QA / "assemble_bounded_fixture_remaining_READY.py"
ASSEMBLER_SHA = "3a1cb76b1416c80879e102900e4233c395e0cc2f659adc9c2e58fa4efc55c12f"
STAGE_SHA = "9aacef0735bced81c6f8b0601165b931a9cfe2f54aef682635490619319965b8"
INTERMEDIATE = QA / "E_observed06_source_base_NONRUNNING.json"
FIXTURE = QA / "E_observed06_ONLY_READY.json"
KEY_TEMPLATE = ROOT / "game/tests/test_luoyang_city_full_rollout_E_observed_06_NOTREADY_20261022ap.gd"
KEY = ROOT / "game/tests/test_luoyang_city_full_rollout_E_observed_06_READY_20261022ap.gd"


def sha(path):
    return hashlib.sha256(path.read_bytes()).hexdigest()


def fixed(path, expected):
    assert sha(path) == expected, str(path)
    return json.loads(path.read_bytes())


for path in (INTERMEDIATE, FIXTURE, KEY):
    assert not path.exists(), str(path)
owners = fixed(OWNERS, OWNERS_SHA)
old = fixed(OLD, OLD_SHA)
assert owners["status"] == "ROOT_ACTUAL_STAGE_INDEPENDENT_QA_SOURCE_MAPS"
assert owners["actual_stage_receipt"]["sha256"].lower() == STAGE_SHA
assert sha(ASSEMBLER) == ASSEMBLER_SHA
subprocess.run([
    sys.executable, str(ASSEMBLER),
    "--base-sha", "a9e0930c90c1f369b91518c89b7180715c50ceed6b10afc36532d2d2e2fb1ac4",
    "--owners", str(OWNERS), "--owners-sha", OWNERS_SHA,
    "--geometry", str(SYSTEM / "independent_raw_geometry_handoff_READY.json"),
    "--geometry-sha", "3ed674aa85b9cd8ac459a3f32baf3c90df872822bcd8cc7a26ee1a623f930f43",
    "--output", str(INTERMEDIATE),
], check=True)
base = json.loads(INTERMEDIATE.read_bytes())
for label in ("Field", "Router"):
    base["return_memory_authority"][label + "_sha256"] = base["core_source_sha256"][base["return_memory_authority"][label]]
base["return_memory_authority"]["source"] = old["return_memory_authority"]["source"]
new = copy.deepcopy(old)
replaced = ("scenes", "rooms", "core_source_sha256", "source_authority", "return_memory_authority")
for key in replaced:
    new[key] = copy.deepcopy(base[key])
assert {k: v for k, v in new.items() if k not in replaced} == {k: v for k, v in old.items() if k not in replaced}
assert new["groups"] == {"E": {"whole_ms": 90000, "captures": [], "doors": [], "links": ["market_craft"], "dialogues": []}}
assert new["arrival_ms"] == 60000 and new["return_performance_target_ms"] == 10000
assert next(r for r in new["links"] if r["id"] == "market_craft")["target_approach"] == [[2816, 1740], [2816, 1764], [2816, 1744]]
for scene_id, expected_counts in (("ch4_s3_luoyang_market", (1613, 1613)), ("luoyang_artisan_residential_20261022ap", (223, 221))):
    row = next(r for r in new["scenes"] if r["id"] == scene_id)
    assert (len(row["source_sha256"]), len(row["receipt_source_sha256"])) == expected_counts
FIXTURE.write_text(json.dumps(new, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")
raw = KEY_TEMPLATE.read_bytes()
assert raw.count(b"const AP_READY: bool = false") == 1
assert raw.count(b'"NOTREADY_AWAIT_ROOT_06_ACTUAL_STAGE_AND_INDEPENDENT_OWNER_SOURCE_MAP"') == 1
assert raw.count(b'const AP_CONTRACT_SHA: String = ""') == 1
for before, after in (
    (b"const AP_READY: bool = false", b"const AP_READY: bool = true"),
    (b'"NOTREADY_AWAIT_ROOT_06_ACTUAL_STAGE_AND_INDEPENDENT_OWNER_SOURCE_MAP"', ('"res://' + FIXTURE.relative_to(ROOT / "game").as_posix() + '"').encode()),
    (b'const AP_CONTRACT_SHA: String = ""', ('const AP_CONTRACT_SHA: String = "' + sha(FIXTURE) + '"').encode()),
):
    raw = raw.replace(before, after, 1)
assert b"NOTREADY_AWAIT" not in raw
KEY.write_bytes(raw)
print(json.dumps({"fixture": str(FIXTURE), "fixture_sha256": sha(FIXTURE), "key": str(KEY), "key_sha256": sha(KEY), "lines": len(raw.splitlines()), "engine_executed": False, "canonical_writes": 0}))
