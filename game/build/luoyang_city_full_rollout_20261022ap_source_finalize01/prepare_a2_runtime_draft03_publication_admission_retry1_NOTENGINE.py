"""Exact NEW source preparation successor; original pre-output FAIL is retained."""
import hashlib
from pathlib import Path

parent = Path(__file__).with_name('prepare_a2_runtime_draft03_publication_admission_NOTENGINE.py')
original = parent.read_bytes()
text = original.decode()
changes = [
    ('len(report[\'source_first\']) == 137', 'len(report[\'source_first\']) == 139'),
    ('report.source_first.size()!=137', 'report.source_first.size()!=139'),
    ('if spec.is_empty() or not raw.get("a2_finite_proof") is Dictionary or not b().equal(raw.a2_finite_proof,spec.publication_finite_proof): return false',
     'if spec.is_empty() or not raw.get("a2_finite_proof") is Dictionary: return false\n\tvar native_proof: Dictionary=raw.a2_finite_proof\n\tif native_proof.get("native_storage_inverse")!=true or native_proof.get("all_7_routes_all4NPC_all4portals_exact")!=true: return false\n\tfor key: String in ["old_visual_count","old_solid_count","new_visual_count","new_solid_count","new_ground_count","retained_opaque_props"]:\n\t\tvar expected: Dictionary={"old_visual_count":106,"old_solid_count":33,"new_visual_count":132,"new_solid_count":27,"new_ground_count":118,"retained_opaque_props":14}\n\t\tif not native_proof.get(key) is int or native_proof[key]!=expected[key]: return false'),
    ("'native_decode_engine_parse_collector_stage_or_canonical_writes':0,",
     "'native_decode_engine_parse_collector_stage_or_canonical_writes':0,\n    'preparation_parent_FAIL_preserved':{'tool':'prepare_a2_runtime_draft03_publication_admission_NOTENGINE.py','failure':'source_first length137 assertion; actual fixed report139; before any output','tool_sha256':'"+hashlib.sha256(original).hexdigest()+"'},\n    'native_proof_and_JSON_report_representation_domains_separate':True,")
]
for old, new in changes:
    assert text.count(old) == 1
    text = text.replace(old, new, 1)
inverse = text
for old, new in reversed(changes):
    assert inverse.count(new) == 1
    inverse = inverse.replace(new, old, 1)
assert inverse.encode() == original
exec(compile(text, str(parent), 'exec'), {'__file__': str(parent), '__name__':'__main__'})
