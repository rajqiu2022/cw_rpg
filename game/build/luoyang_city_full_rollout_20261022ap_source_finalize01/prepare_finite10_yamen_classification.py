"""NEW exact-two formal metadata proposals; no stage/engine/canonical writes."""
import copy,hashlib,json
from pathlib import Path
H=Path(__file__).resolve().parent;G=H.parents[1]
S='res://build/luoyang_city_full_rollout_20261022ap_source_finalize01/'
P=S+'finite10_yamen_classification/'
def sha(b):return hashlib.sha256(b).hexdigest()
def pth(p):
 assert p.startswith('res://') and '..' not in p;return G/p[6:]
def read(p,s):
 b=pth(p).read_bytes();assert sha(b)==s,('PIN',p);return b
def js(v):return (json.dumps(v,ensure_ascii=False,indent=2)+'\n').encode()
def same(a,b):
 if type(a) is not type(b):return False
 if isinstance(a,dict):return a.keys()==b.keys() and all(same(a[k],b[k]) for k in a)
 if isinstance(a,list):return len(a)==len(b) and all(same(x,y) for x,y in zip(a,b))
 return a==b
outputs={}
def emit(name,b):
 if not isinstance(b,bytes):b=js(b)
 p=P+name;assert not pth(p).exists();outputs[p]=b
 return {'path':p,'sha256':sha(b),'bytes':len(b)}
authpath='res://build/luoyang_city_full_rollout_20261022ap_root01/yamen_four_parent_leaf_classification_scope_authorization_READY.json'
authbytes=pth(authpath).read_bytes();auth=json.loads(authbytes)
assert auth['approved_by_root'] is True and auth['Source_may_prepare_NEW_candidates_and_proofs'] is True
assert auth['canonical_deployment_permitted_now'] is False and len(auth['targets'])==2
target=P.replace('finite10_yamen_classification/','finite_adapter_production08/runtime_yamen_manifest_READY.json')
oldsha='f00d25e6037d1a706e53bf7c54cc846cb5bb81a72f552e1ef0a6b231c7f6b8d8'
index='res://scripts/city/luoyang_full_city_index_20261022ap.gd'
indexoldsha='b780a07ef2fc61187bcfbdf6614b87c2272c24331e51acf5b93e5c7c19fa8925'
assert {r['path']:r['old_sha256'] for r in auth['targets']}=={target:oldsha,index:indexoldsha}
oldraw=read(target,oldsha);old=json.loads(oldraw);new=copy.deepcopy(old)
root='res://data/maps/luoyang_layout_bundle_20261018t_retry2/'
bad={p:s for p,s in old['legacy_source_sha256'].items() if p.startswith(root)}
assert set(bad)=={root+'ch4_s1_luoyang_yamen/'+n for n in ['layout.res','packet.bin','scene.res','manifest.json']}
oldorders={f:list(old[f]) for f in ['legacy_source_sha256','runtime_authority_sha256']}
for p,s in bad.items():
 assert p not in new['runtime_authority_sha256'];del new['legacy_source_sha256'][p];new['runtime_authority_sha256'][p]=s
inverse=copy.deepcopy(new)
for p,s in bad.items():del inverse['runtime_authority_sha256'][p];inverse['legacy_source_sha256'][p]=s
for f,keys in oldorders.items():inverse[f]={p:inverse[f][p] for p in keys}
assert same(inverse,old) and js(inverse)==oldraw
for key in old:
 if key not in oldorders:assert same(new[key],old[key])
def union(v):
 u={}
 for f in ['legacy_source_sha256','runtime_authority_sha256','artifacts']:
  for p,s in v[f].items():assert p not in u;u[p]=s
 return u
assert union(new)==union(old) and len(union(new))==1203
assert not any(p.startswith(root) for p in new['legacy_source_sha256'])
oldmanifest=emit('before_yamen_f00D.json',oldraw)
manifest=emit('runtime_yamen_manifest_classification_READY.json',new)
indexraw=read(index,indexoldsha);assert indexraw.count(oldsha.encode())==1
indexbytes=indexraw.replace(oldsha.encode(),manifest['sha256'].encode(),1)
assert indexbytes.count(manifest['sha256'].encode())==1 and indexbytes.replace(manifest['sha256'].encode(),oldsha.encode(),1)==indexraw
indexbefore=emit('before_AP_INDEX_b780.gd',indexraw)
indexcandidate=emit('FullCityIndex_yamen_classification_READY.gd',indexbytes)
ownerpath=S+'finite09_stage02_independent_review/owner_source_maps_READY.json'
ownersha='1002af3bf3cd46ef0e1f4864d8313bfca0d82eea04349437b916e5df6f932188'
owner0=json.loads(read(ownerpath,ownersha));owner=copy.deepcopy(owner0)
cityids={'ch4_s0_luoyang_gate','ch4_s1_luoyang_yamen','ch4_s2_canal_docks','ch4_s3_luoyang_market'}
changes=[]
for row in owner['scenes']:
 for field in ['source_sha256','receipt_source_sha256']:
  values=row[field]
  if row['id'] in cityids:
   assert values.get(index)==indexoldsha;values[index]=indexcandidate['sha256']
   changes.append({'id':row['id'],'field':field,'path':index,'old':indexoldsha,'new':indexcandidate['sha256']})
  else:assert index not in values
  if row['id']=='ch4_s1_luoyang_yamen':
   assert values.get(target)==oldsha;values[target]=manifest['sha256']
   changes.append({'id':row['id'],'field':field,'path':target,'old':oldsha,'new':manifest['sha256']})
  else:assert target not in values
for row in owner['rooms']:
 for field in ['source_sha256','receipt_source_sha256']:assert index not in row[field] and target not in row[field]
assert owner['core_source_sha256'][index]==indexoldsha
owner['core_source_sha256'][index]=indexcandidate['sha256']
restore=copy.deepcopy(owner)
for row in changes:
 r=next(r for r in restore['scenes'] if r['id']==row['id']);assert r[row['field']][row['path']]==row['new'];r[row['field']][row['path']]=row['old']
restore['core_source_sha256'][index]=indexoldsha
assert same(restore,owner0) and len(changes)==10
owner['status']='INDEPENDENT_EXPECTED_OWNER_EXACT_TWO_METADATA_SUCCESSOR_PENDING_ROOT_DEPLOYMENT'
owner['parent_source_owner']={'path':ownerpath,'sha256':ownersha}
owner['bounded_runtime_metadata_successor']={'status':'EXPECTED_ONLY_NOT_ACTUAL_DEPLOYMENT','root_scope_authority':{'path':authpath,'sha256':sha(authbytes)},'prior_actual_stage_receipt_retained_as_history_not_claim_of_new_metadata_stage':True,'exact_two_replacements':[{'path':target,'old_sha256':oldsha,'new_sha256':manifest['sha256']},{'path':index,'old_sha256':indexoldsha,'new_sha256':indexcandidate['sha256']}],'no_absent_source_expansion':True,'all_scene_room_source_keysets_counts_unchanged':True}
ownerdesc=emit('owner_source_maps_EXPECTED_NOT_DEPLOYED.json',owner)
proof=emit('four_leaf_classification_and_two_owner_headers_proof_READY.json',{
 'status':'EXACT_FOUR_CLASS_MOVES_AND_ONE_INDEX_LITERAL_NOT_STAGE_OR_DEPLOYMENT',
 'scope_authority':{'path':authpath,'sha256':sha(authbytes)},'parent_manifest':oldmanifest,'manifest_candidate':manifest,
 'moves':[{'path':p,'sha256':s,'from':'legacy_source_sha256','to':'runtime_authority_sha256'} for p,s in bad.items()],
 'original_source_field_key_orders':oldorders,'complete_manifest_typed_inverse':True,'complete_manifest_byte_inverse_with_original_field_orders':True,'all_other_typed_fields_identical':True,'source_union_count_before_after':1203,'source_union_keys_values_exact':True,'disjoint_source_classes':True,
 'index_parent':indexbefore,'index_candidate':indexcandidate,'index_only_literal':{'old':oldsha,'new':manifest['sha256']},'index_complete_byte_inverse':True,
 'owner_parent':{'path':ownerpath,'sha256':ownersha},'owner_candidate':ownerdesc,'ten_existing_scene_source_header_value_changes':changes,'one_existing_core_index_header_value_change':True,'whole_old_owner_typed_inverse_before_status_provenance_fields':True,'all_other_five_scenes_and_five_rooms_unchanged':True,'no_new_source_keys':True,
 'native_artifacts_or_B_C_adapter_binding_OWNED_changes':False,'source_stage_engine_collector_calls':0,'canonical_writes':0})
handoff=emit('handoff_CANDIDATES_READY_NOT_DEPLOYED.json',{'status':'ROOT_AUTHORIZED_EXACT_TWO_METADATA_CANDIDATES_READY_NOT_DEPLOYED','scope_authority':{'path':authpath,'sha256':sha(authbytes)},'targets':[{'target':target,'old_sha256':oldsha,'old_snapshot':oldmanifest,'candidate':manifest},{'target':index,'old_sha256':indexoldsha,'old_snapshot':indexbefore,'candidate':indexcandidate}],'proof':proof,'owner_candidate':ownerdesc,'existing_paths_unchanged':True,'no_stage_engine_collector_or_canonical_write':True,'original885A_and_f00D_snapshots_preserved':True,'requires_Root_fresh2_backup_plan_and_predeploy_authorization':True})
assert read(target,oldsha)==oldraw and read(index,indexoldsha)==indexraw
assert not pth(P).exists()
for p,b in outputs.items():
 pth(p).parent.mkdir(parents=True,exist_ok=True)
 with pth(p).open('xb') as f:f.write(b)
print(json.dumps({'handoff':handoff,'manifest':manifest,'index':indexcandidate,'proof':proof,'owners':ownerdesc,'canonical_writes':0}))
