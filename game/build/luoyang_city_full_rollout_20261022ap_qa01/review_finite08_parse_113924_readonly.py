"""Read exactly one completed Root parse; do not reparse or load shaders."""
from pathlib import Path
import hashlib
import json

GAME = Path(__file__).resolve().parents[2]
QA = Path(__file__).resolve().parent
OUT = QA / "finite08_parse_113924_independent_readonly_review_READY.json"
HERE = GAME / "build/luoyang_city_full_rollout_20261022ap_source_finalize01/finite08_parse"
report = HERE / "output/113924_1693/result.json"
sha = lambda p: hashlib.sha256(p.read_bytes()).hexdigest()
assert not OUT.exists() and sha(report) == "3a217cdc1c1439377d8ff6bba2ba7b326a163d5d66d8b4e96a93987b842f3f69"
r = json.loads(report.read_bytes())
assert r["complete"] is True and r["checks"] == 65 and r["failures"] == [] and r["elapsed_ms"] == 1455
assert r["source_first"] == r["source_final"] and len(r["source_first"]) == 12
assert sha(HERE / "fixture_READY.json") == "2d279d7f4ab19d6499a6293d6efb328b46fb3f081912e30d19ba4843b43b4196"
for path,digest in r["source_first"].items():
    assert path.startswith("res://") and sha(GAME / path[6:]) == digest
fixture = json.loads((HERE / "fixture_READY.json").read_bytes())
assert len(r["rows"]) == 9 and len({row["path"] for row in r["rows"]}) == 9
for row in r["rows"]:
    assert row["compiled"] is True and row["instances_created"] == 0 and row["module_methods_called"] == 0
    assert r["source_first"][row["path"]] == row["sha256"]
for key in ("Field_created","UI_or_performance_admission","geometry_or_collector_executed","shader_load_or_compile_claimed","prior_17_parse_replayed","prior_two_visual_scripts_reloaded"):
    assert r[key] is False
for key in ("instances_created","candidate_methods_called","public_requests"):
    assert r[key] == 0
result = {
    "status":"INDEPENDENT_READONLY_ROOT_NINE_SCRIPT_PARSE_COMPONENTS_VERIFIED",
    "actual_report_sha256":sha(report),
    "actual":{"complete":True,"checks":65,"failures":0,"elapsed_ms":1455,"compiled_rows":9},
    "exact_source_SHA_first_final_current_count":12,
    "actual_nine_rows":[{"path":row["path"],"sha256":row["sha256"],"compiled":True} for row in r["rows"]],
    "historical_scope_text_preserved":r["scope"],
    "scope_correction":"Actual fixture and result cover nine current08 candidate scripts; inherited remaining-three wording is historical and is not the actual row count. No actual Router/resident module from that old scope was re-executed.",
    "not_admitted":["candidate methods or instances","shader compile","source closure","Field/Physics","runtime/visual/loading performance","canonical deployment"],
    "saves":"This parse report does not contain15save facts; no save protection credit invented here. Root guard is separate.",
    "nonclean_exit":"Root reports one ObjectDB exit warning. Do not call clean or repeat parse.",
    "QA_engine_runs":0
}
OUT.write_text(json.dumps(result,ensure_ascii=False,indent=2)+"\n",encoding="utf-8")
print(json.dumps({"review":OUT.name,"sha256":sha(OUT),"rows":9,"sources":12,"QA_engine":0}))
