"""Ready-only byte inverse; no packet decode, engine or pure-test execution."""
import copy
import hashlib
import json
from pathlib import Path
ROOT=Path(__file__).resolve().parents[2];QA=Path(__file__).parent;D=ROOT/'build/luoyang_city_full_rollout_20261022ap_source_finalize01/performance19_typed_pair_key01'
def sha(b):return hashlib.sha256(b).hexdigest()
def raw(name,h):
    b=(D/name).read_bytes();assert sha(b)==h;return b
oldkey=raw('test_typed_packet_comparison_PENDING_ROOT.gd','c7161b354d5f95b7c6103ecb20d68cbcf79586d13f64b33e22b220d2c684e1dc')
key=raw('test_typed_packet_comparison_ROOT23_READY.gd','2e0fa343608c9f183dc23e2baf11e3d94caa7f38188b9bc921fa8f0502764f17')
oldfix=raw('typed_packet_comparison_fixture_PENDING_ROOT.json','e84ce87487ce2c298e70b8ed8757aa430ed6bc87d66b5d0efc8909fdad95ee13')
fixture=raw('typed_packet_comparison_fixture_ROOT23_READY.json','61e2d643a4a66bb18299bf5e3c86ad1ca59c84c63efa107639d8fee727911b08')
t=key.decode()
for a,b in [('typed_packet_comparison_fixture_ROOT23_READY.json','typed_packet_comparison_fixture_PENDING_ROOT.json'),('61e2d643a4a66bb18299bf5e3c86ad1ca59c84c63efa107639d8fee727911b08','e84ce87487ce2c298e70b8ed8757aa430ed6bc87d66b5d0efc8909fdad95ee13')]:assert t.count(a)==1;t=t.replace(a,b,1)
assert t.encode()==oldkey
old=json.loads(oldfix);new=json.loads(fixture);back=copy.deepcopy(new)
back['status']=old['status'];back['ready']=old['ready'];del back['root_authorization'];back['blocker']=old['blocker']
assert back==old and new['ready']is True and new['source_sha256']==old['source_sha256']and len(new['source_sha256'])==4
assert new['allowed_binary_decode_count']==1 and new['large_pairs']==2
ab=(ROOT/new['root_authorization'][6:]).read_bytes();a=json.loads(ab)
assert a['approved_by_root']and a['execution_limit']==1 and a['allowed_fixed_T_packet_dictionary_decodes']==1 and a['allowed_fixed_JSON_parent_parses']==1 and a['large_independent_record_pairs']==2
assert a['candidate_sha256']==new['source_sha256'][new['candidate_path']]and a['pending_key_sha256']==sha(oldkey)and a['pending_fixture_sha256']==sha(oldfix)
assert a['independent_static_review_sha256']=='46b402a0498eb7bc2623b8e909bbfbbd7129cea232b0acaae78810ab2c6033d5'
assert not a['production_or_save_writes']and not a['Scene_ResourceLoader_image_geometry_collector_Field_calls']and not a['old_JSON_only_test_or_public_entry_replay']
out=QA/'typed_pair_ROOT23_READY_independent_freeze_static_admission_READY.json'
r={'status':'INDEPENDENT_ROOT23_ONE_TYPED_PAIR_DIAGNOSTIC_READY_NO_STATIC_BLOCKER_NOT_RUN','key_sha256':sha(key),'fixture_sha256':sha(fixture),'Root_authorization_sha256':sha(ab),'key_only_two_literal_whole_byte_inverse_C716':True,'fixture_only_status_ready_blocker_rootauthority_changes':True,'four_source_pins_and_two_pairs_and_counterexample_scope_unchanged':True,'parent_semantic_review_sha256':a['independent_static_review_sha256'],'Root_only_execution_count':1,'packet_dictionary_decode_count':1,'fixed_JSON_parent_parse_count':1,'Root_external_wall_bound_and_true_WaitForExit_required':True,'QA_engine_parse_packet_decode_collector_canonical_write':False,'blocking_findings':[],'loading_performance_or_deployment_credit':False}
assert not out.exists();out.write_text(json.dumps(r,indent=2)+'\n',encoding='utf-8');print(json.dumps({'path':str(out),'sha256':sha(out.read_bytes())}))
