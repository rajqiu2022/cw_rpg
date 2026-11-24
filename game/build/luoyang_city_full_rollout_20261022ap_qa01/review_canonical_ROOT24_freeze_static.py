"""Final readiness-only inverse, zero candidate or diagnostic execution."""
import copy
import hashlib
import json
from pathlib import Path
ROOT=Path(__file__).resolve().parents[2];QA=Path(__file__).parent;D=ROOT/'build/luoyang_city_full_rollout_20261022ap_source_finalize01/performance23_canonical_ROOT24_READY'
def sha(b):return hashlib.sha256(b).hexdigest()
def pin(r):
    assert r['path'].startswith('res://');b=(ROOT/r['path'][6:]).read_bytes();assert sha(b)==r['sha256'];return b
hb=(D/'handoff_ROOT24_READY_NOT_RUN.json').read_bytes();assert sha(hb)=='da93f5e72c68c8612b721f85b862d6dd682249d73b621cddf0a9d7730fcd6df4';h=json.loads(hb)
key=pin(h['key']);parent=pin(h['parent_key']);fixture=pin(h['fixture']);oldfixture=pin(h['parent_fixture'])
s=key.decode()
for row in reversed(h['key_hunks']):assert s.count(row['new'])==1;s=s.replace(row['new'],row['old'],1)
assert s.encode()==parent and len(h['key_hunks'])==3
f=json.loads(fixture);old=json.loads(oldfixture);back=copy.deepcopy(f)
for k in ['status','ready','blocker']:back[k]=old[k]
assert back==old and (json.dumps(back,indent=2,ensure_ascii=False)+'\n').encode()==oldfixture
assert f['ready']is True and f['source_sha256']==old['source_sha256']and len(f['source_sha256'])==4 and f['allowed_binary_decode_count']==1 and f['large_pairs']==2
assert f['source_sha256'][f['candidate_path']]=='9d5b9b379f5e7962d91550a95b2b9a12a35b98d7fb4402cdfa5947e7152f9e54'
assert 'no source or formal promotion'in f['blocker']and 'Unknown, incomplete-fast-hit or slower outcomes'in f['blocker']
pin(h['key_diff']);pin(h['fixture_diff'])
out=QA/'canonical_ROOT24_READY_independent_freeze_static_admission_READY.json'
r={'status':'INDEPENDENT_ROOT24_UNIQUE_TYPED_PROBE_READY_NO_STATIC_BLOCKER_NOT_RUN','key_sha256':sha(key),'fixture_sha256':sha(fixture),'whole_key_three_header_output_literal_inverse_A590':True,'fixture_only_status_ready_blocker_serialized_inverse_C586':True,'semantic_review_sha256':'5de1afd9245f0d5f418ddddca396966d35851c6916dc8282fdac83afc8c9c797','same_four_source_pins_two_actualpairs_singledecode_fullrejectrule':True,'candidate9D5B_unchanged':True,'Root_only_one_externally_bounded_execution':True,'unknown_nonhit_or_slower_does_not_authorize_source_promotion':True,'QA_engine_parse_packetdecode_parentJSONparse_collector_formalwrite':0,'blocking_findings':[]}
assert not out.exists();out.write_text(json.dumps(r,indent=2)+'\n',encoding='utf-8');print(json.dumps({'path':str(out),'sha256':sha(out.read_bytes())}))
