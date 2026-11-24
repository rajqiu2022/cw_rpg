"""Exact source-header successor only, retaining every finite INPUT assertion."""
import copy,hashlib,json
from pathlib import Path
ROOT=Path(__file__).resolve().parents[2];QA=Path(__file__).resolve().parent
S=ROOT/'build/luoyang_city_full_rollout_20261022ap_source_finalize01'
def sha(p):return hashlib.sha256(p.read_bytes()).hexdigest()
def load(p):return json.loads(p.read_bytes())
def key(p):return 'res://'+p.relative_to(ROOT).as_posix()
def same(a,b):
    if type(a) is not type(b):return False
    if isinstance(a,dict):return a.keys()==b.keys() and all(same(a[k],b[k]) for k in a)
    if isinstance(a,list):return len(a)==len(b) and all(same(x,y) for x,y in zip(a,b))
    return a==b
op=S/'finite10_yamen_classification/actual_deployment_review/owner_source_maps_ROOT_DEPLOYED_READY.json'
review=S/'finite10_yamen_classification/actual_deployment_review/deployment_source_review_READY.json'
assert sha(op)=='690fba034f8b865e0cbbe31e21a8ee8095ede2471b73235f500fbcb4052c8902'
assert sha(review)=='cb9211c2f50efce423411d83a9db46982611ae8287dee5680cb52502b1508c9b'
owner=load(op);expect=load(S/'finite10_yamen_classification/owner_source_maps_EXPECTED_NOT_DEPLOYED.json')
for k in ['scenes','rooms','core_source_sha256']:assert same(owner[k],expect[k])
assert owner['actual_stage_receipt']['sha256']=='885a813db26487582bc7cb31d02ec89827dc929a9e2653e71137defd8ff8c3a0'
assert 'actual_metadata_deployment_receipt' in owner
y=next(x for x in owner['scenes'] if x['id']=='ch4_s1_luoyang_yamen')
oldplan=QA/'yamen_three_low_props_metrics_fixture_READY.json'
oldkey=ROOT/'tests/test_luoyang_ap_yamen_three_low_props_METRICS_READY_20261023.gd'
assert sha(oldplan)=='3dbbf8a18ea0cca78af775037d4eb441ca567e5d506e23fad85633d7fa2f4db8'
assert sha(oldkey)=='e11bcd0a37648c45e3be1474df89c406ac0c882e1a6144524a6f3d8cff9f9341'
fixture=load(oldplan);oldprod=fixture['expected_city_source_sha256']
assert oldprod.keys()==y['source_sha256'].keys() and len(oldprod)==1211
diff={p:(oldprod[p],y['source_sha256'][p]) for p in oldprod if oldprod[p]!=y['source_sha256'][p]}
expectedpaths={'res://scripts/city/luoyang_full_city_index_20261022ap.gd','res://build/luoyang_city_full_rollout_20261022ap_source_finalize01/finite_adapter_production08/runtime_yamen_manifest_READY.json'}
assert set(diff)==expectedpaths
for p,(old,new) in diff.items():assert fixture['source_sha256'][p]==old;fixture['source_sha256'][p]=new
fixture['expected_city_source_sha256']=copy.deepcopy(y['source_sha256'])
fixture['independent_owner_sha256']=sha(op)
for p in [op,review,QA/'yamen_classification_actual_guard_independent_review_READY.json']:
    fixture['source_sha256'][key(p)]=sha(p)
fixture['qa_classification_actual_header_successor_only']={'production_source_keys_unchanged':1211,'exact_two_changed_header_paths':sorted(diff),'Root_guard_sha256':'e5e524144f5340f5367808f5452f347b230f14484e655b1ed16dded531c389c4','no_ASSERTION_station_budget_or_oracle_change':True}
fp=QA/'yamen_three_low_props_classification_fixture_READY.json'
sp=ROOT/'tests/test_luoyang_ap_yamen_three_low_props_CLASSIFIED_READY_20261023.gd'
hp=QA/'yamen_classification_actual_headers_handoff_READY.json'
assert not any(p.exists() for p in [fp,sp,hp])
fp.write_text(json.dumps(fixture,ensure_ascii=False,indent=2)+'\n',encoding='utf-8')
body=oldkey.read_text(encoding='utf-8')
changes=[(key(oldplan),key(fp)),(sha(oldplan),sha(fp)),('yamen_three_low_props_metrics/%d_%d','yamen_three_low_props_classified/%d_%d')]
for a,b in changes:assert body.count(a)==1;body=body.replace(a,b)
back=body
for a,b in reversed(changes):back=back.replace(b,a)
assert back.encode()==oldkey.read_bytes()
sp.write_text(body,encoding='utf-8',newline='\n')
h={'status':'ROOT_ACTUAL_EXACT_TWO_METADATA_SOURCE_BOUND_YAMEN_KEY_NOT_EXECUTED','script':{'path':key(sp),'sha256':sha(sp),'lines':len(body.splitlines())},'fixture':{'path':key(fp),'sha256':sha(fp)},'owner':{'path':key(op),'sha256':sha(op)},'owner_source_review':{'path':key(review),'sha256':sha(review)},'only_three_child_fixture_SHA_output_literal_changes_byte_inverse_toE11':True,'exact_two_production_header_value_changes':diff,'production_expected_keyset_1211_unchanged':True,'same_metrics_parent_and_every_actual_assertion':True,'scope':{'default_entry_only':True,'whole_ms':60000,'arrival_cap_in_whole_ms':60000,'max_pictures':2,'endpoint_tolerance_px':.3,'same_seven_fixed_connections':True,'no_teleport_or_fallback_or_old_replay':True},'Root_external_full_key_hash_required_before_launch':True,'engine_or_parse_runs':0,'canonical_writes':0}
hp.write_text(json.dumps(h,ensure_ascii=False,indent=2)+'\n',encoding='utf-8')
print(json.dumps({'script':h['script'],'fixture':h['fixture'],'handoff_sha256':sha(hp)}))
