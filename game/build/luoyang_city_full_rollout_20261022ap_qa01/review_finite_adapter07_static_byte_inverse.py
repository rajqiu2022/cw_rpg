"""Independent NEW07 byte/source-table review. No engine, geometry or image decode."""
from pathlib import Path
import hashlib
import json

GAME = Path(__file__).resolve().parents[2]
QA = Path(__file__).resolve().parent
HERE = GAME / "build/luoyang_city_full_rollout_20261022ap_source_finalize01/finite_adapter_implementation07"
OUT = QA / "finite_adapter07_independent_static_byte_review_READY.json"


def sha(raw):
    return hashlib.sha256(raw).hexdigest()


def local(path):
    assert path.startswith("res://") and ".." not in path
    return GAME / path[6:]


def pinned(path, digest):
    raw = path.read_bytes()
    assert sha(raw) == digest, str(path)
    return raw


assert not OUT.exists()
h = json.loads(pinned(HERE / "handoff_PENDING.json", "ad35db6e0ecaf04a9636ddd82dabe98f994ada3201971495b3818170192e7e32"))
old_dir = HERE.parent / "finite_adapter_implementation06"
old_h = json.loads(pinned(old_dir / "handoff_PENDING.json", h["predecessor06_handoff_sha256"]))
adapter = pinned(local(h["adapter"]["path"]), h["adapter"]["sha256"])
inverse = adapter
for row in reversed(h["adapter_exact_inverse_hunks_to06"]):
    after, before = row["new"].encode(), row["old"].encode()
    assert inverse.count(after) == 1, row["label"]
    inverse = inverse.replace(after, before, 1)
assert inverse == pinned(local(old_h["adapter"]["path"]), old_h["adapter"]["sha256"])
binding = json.loads(pinned(local(h["binding"]["path"]), h["binding"]["sha256"]))
assert h["adapter"]["READY"] is False and h["source_closure_ready"] is False and binding["source_closure_ready"] is False
consumers = []
for row in h["consumers"]:
    candidate = pinned(local(row["candidate_path"]), row["candidate_sha256"])
    original = pinned(local(row["target"]), row["old_sha256"])
    inverse = candidate
    if row["domain"] == "AP_INDEX_GENERATED":
        extra = row["append_exact_bytes"].encode()
        assert inverse.endswith(extra) and inverse.count(extra) == 1
        inverse = inverse[:-len(extra)]
        assert row["finite_geometry_enabled"] is False
    else:
        for delta in reversed(row["hunks"]):
            after, before = delta["new"].encode(), delta["old"].encode()
            assert inverse.count(after) == 1, (row["domain"], after[:80])
            inverse = inverse.replace(after, before, 1)
    assert inverse == original, row["domain"]
    consumers.append({"domain": row["domain"], "candidate_sha256": row["candidate_sha256"], "whole_byte_inverse": True})

promotion = h["fixed_mask_import_promotion"]
media = json.loads(pinned(local(promotion["path"]), promotion["sha256"]))
assert media["passed"] is True and media["error"] == "" and len(media["copied"]) == 4
copied = {}
for row in media["copied"]:
    path = Path(row["destination"])
    digest = row["fact"]["sha256"]
    assert sha(path.read_bytes()) == digest and path.stat().st_size == row["fact"]["bytes"]
    res = "res://" + path.relative_to(GAME).as_posix()
    domains = [key for key in ("market", "yamen") if binding["domains"][key]["source_sha256"].get(res) == digest]
    assert len(domains) == 1
    copied[res] = {"sha256": digest, "domain": domains[0]}

code = adapter.decode()
b_row = next(r for r in h["consumers"] if r["domain"] == "B")
bcode = local(b_row["candidate_path"]).read_text()
assert "FileAccess.get_sha256(path)!=spec.fixed_source_sha256[path]" not in code
assert "var rows: Array=wrapped.array_values" in code
assert "_same(_render_storage(parent_objects),_packets.yamen.layout_storage.fields.visual_objects)" in code
assert 'sources.get(source_path)!=expected[source_path]' in code
assert 'int(_c()._live_source_token)!=token' in code
assert 'if _is_cancelled() or _finite_worker_result.get("ok")!=true' in bcode
assert '_joined=token==_token and id==_id and not _is_cancelled()' in bcode
assert 'validate_packet_worker(_finite_context,data,_manifest.artifacts[path])' in bcode
assert 'accept_joined_native(token,id,_finite_context,_finite_worker_result)' in bcode
fade = next(r for r in consumers if r["domain"] == "Fade")
assert f'var next: String="{fade["candidate_sha256"]}"' in bcode
assert 'first in history and older in history and previous in history' in bcode
assert 'var previous: String="3f2d43276f89341a450579fa07a0dd0bb2369d059ad928e7187fb35df59f1ac7"' in bcode

result = {
    "status": "INDEPENDENT_STATIC_BYTE_INVERSE_AND_FINITE_WORKER_REVIEW_NOT_RUNTIME_READY",
    "handoff_sha256": sha((HERE / "handoff_PENDING.json").read_bytes()),
    "adapter_sha256": h["adapter"]["sha256"],
    "adapter_exact_whole_byte_inverse_to06": True,
    "adapter_hunk_count": len(h["adapter_exact_inverse_hunks_to06"]),
    "consumers": consumers,
    "actual_four_promoted_mask_leaves": copied,
    "mask_import_source_report_sha256": promotion["sha256"],
    "code_review": {
        "typed_wrappers": "Only array_values is edited; wrapper metadata and all nested encoded values remain in final complete equality. Actual render Arrays are encoded with the same pure B._storage_value graph before complete comparison.",
        "worker": "Existing C completed source-first -> B.configure -> current-token context -> original B.run streamed packet SHA/full mask -> finite same-domain native/parent inverse -> original joined/cancel/token checks -> accept on main -> native Scene session -> C source-first proof -> District prepare -> original source-final.",
        "cancellation": "Worker returns plain data only. Runtime _parents/_packets/_sessions are published only after B.mark_joined original conditions and accept's current C token check. A cancelled worker can populate immutable exact-SHA parent data cache, not admission state.",
        "cache": "Cached fixed parents require this attempt's exact source-first path/SHA fact. There is no current-hash fallback or cross-token freshness credit. Existing E resident return has no new rebinding path.",
        "performance_delta": "Original72-leaf/256557141-byte synchronous scan removed. Domain-specific inverse remains in original worker; main retains required packet/Scene storage identity checks. No measured loading duration claim.",
        "Fade": "Fixed historical F359/BC295/3F2D to actual new Fade candidate is consumed by the existing source-only gate; exact history/current-before/candidate/manifest source proof remain mandatory.",
        "DAG": "Binding no longer contains the final runtime manifest SHA. Existing AP index gets only appended false finite methods/entries; original formal methods are byte exact. Full manifest/source closure remains pending, not accepted from this review.",
        "source_scope": "Shared fixed provenance and exact selected-domain sources, no other-domain packet scan or old fixture/stage-receipt sweep. Source finalizer still must produce every dependent four-city/room/execution/Temple closure demanded by changed shared code. No runtime whole-source credit is generated by this static review."
    },
    "new_definite_blocker_identified": False,
    "not_admitted": ["GDScript parse", "threaded actual run", "source closure", "READY flags", "canonical deployment", "Field/Physics/ghost", "any loading target", "all-city art"],
    "operations": {"engine": 0, "native_decode": 0, "PNG_decode": 0, "geometry_sampling": 0, "collector": 0, "canonical_write": 0}
}
OUT.write_text(json.dumps(result, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")
print(json.dumps({"review": OUT.name, "sha256": sha(OUT.read_bytes()), "consumer_byte_inverses": len(consumers), "promoted_leaves": len(copied), "engine": 0}))
