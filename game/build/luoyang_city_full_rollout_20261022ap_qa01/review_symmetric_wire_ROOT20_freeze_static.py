"""Mechanical READY freeze check only; never runs the pure comparison."""
import copy
import hashlib
import json
from pathlib import Path
ROOT=Path(__file__).resolve().parents[2];QA=Path(__file__).parent;D=ROOT/'build/luoyang_city_full_rollout_20261022ap_source_finalize01/performance11_symmetric_wire_candidate01'
def sha(b):return hashlib.sha256(b).hexdigest()
def raw(name,h):
    b=(D/name).read_bytes();assert sha(b)==h;return b
oldkey=raw('test_pure_record_comparison_PENDING_ROOT.gd','c25f6c5dcf8474999e9de4e2388dec94f0767b07724eabf10cb2aebe4df85123')
newkey=raw('test_pure_record_comparison_ROOT20_READY.gd','38d22bca5f88023cf919632967048df645df688dbb4de656a6d681373c9f06dc')
oldfix=raw('pure_record_comparison_fixture_PENDING_ROOT.json','621ca879dafc115c1f1b7d6029b7543dd5bfe0b2d1816cdf8fc79a7005f63321')
newfix=raw('pure_record_comparison_fixture_ROOT20_READY.json','5351b756f22860ef7e73a8f0c8fd6eff071df02ef8f4deded6f2b962ee823925')
text=newkey.decode()
for a,b in [('pure_record_comparison_fixture_ROOT20_READY.json','pure_record_comparison_fixture_PENDING_ROOT.json'),('5351b756f22860ef7e73a8f0c8fd6eff071df02ef8f4deded6f2b962ee823925','621ca879dafc115c1f1b7d6029b7543dd5bfe0b2d1816cdf8fc79a7005f63321')]:
    assert text.count(a)==1;text=text.replace(a,b,1)
assert text.encode()==oldkey
old=json.loads(oldfix);new=json.loads(newfix);back=copy.deepcopy(new)
back['status']=old['status'];back['ready']=old['ready'];del back['root_authorization'];back['blocker']=old['blocker']
assert back==old and new['ready']is True and new['source_sha256']==old['source_sha256'] and new['scope']==old['scope']
authpath=ROOT/new['root_authorization'][6:];ab=authpath.read_bytes();auth=json.loads(ab)
assert auth['execution_count_limit']==1 and auth['candidate_sha256']==new['source_sha256'][new['candidate_path']]and auth['pending_key_sha256']==sha(oldkey)and auth['pending_fixture_sha256']==sha(oldfix)
out=QA/'symmetric_wire_ROOT20_READY_freeze_independent_static_admission_READY.json'
r={'status':'INDEPENDENT_ROOT20_ONE_PURE_RECORD_READY_STATIC_NO_BLOCKER_NOT_RUN','key_sha256':sha(newkey),'fixture_sha256':sha(newfix),'root_authorization_sha256':sha(ab),'key_only_two_literal_full_byte_inverse':True,'fixture_only_readiness_authority_blocker_changes':True,'three_source_SHA_and_test_scope_unchanged':True,'parent_candidate_semantic_review_sha256':'811086483bb5c045ac8ecefee2269e9892c1478dbd1a4b25880ad2ef6d7806be','Root_only_execution_limit':1,'require_Root_external_bounded_process_timeout':True,'engine_parse_or_parent_record_decode_by_QA':False,'blocking_findings':[],'performance_or_deployment_credit':False}
assert not out.exists();out.write_text(json.dumps(r,indent=2)+'\n',encoding='utf-8');print(json.dumps({'path':str(out),'sha256':sha(out.read_bytes())}))
