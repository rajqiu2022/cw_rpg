"""One old Docks artifact projection declaration correction; offline all remaining checks."""
from pathlib import Path
import copy,json,hashlib,importlib.util
P=Path(__file__).resolve().parent;G=P.parents[1];R='res://build/luoyang_city_revision_20261025h_source01/'
def sha(b):return hashlib.sha256(b).hexdigest()
def enc(v):return(json.dumps(v,ensure_ascii=False,indent=2,allow_nan=False)+'\n').encode()
def out(n,b):
 p=P/n;assert not p.exists();p.parent.mkdir(parents=True,exist_ok=True)
 with p.open('xb')as f:f.write(b)
 return dict(path=R+n,sha256=sha(b),bytes=len(b))
bp=P/'NG_bytes_residual02/unified28_candidates_exact_bytes.json';oldraw=bp.read_bytes();assert sha(oldraw)=='f13d41b4a01fb7e779598bb998b8d3a8f868dbbb5c057bcc2966cbb21791c036'
old=json.loads(oldraw);v=copy.deepcopy(old)
target='res://data/maps/luoyang_layout_bundle_20261018t_retry2/ch4_s2_canal_docks/manifest.json'
row=v['metadata'][target];assert row['id']=='legacy_manifest_4'and row['source_fields']==[['legacy_source_sha256'],['runtime_authority_sha256'],['artifacts']]
base=json.loads((G/row['parent']['path'][6:]).read_bytes());child=json.loads((G/row['candidate']['path'][6:]).read_bytes());duplicatepins=dict(base['artifacts']);assert len(duplicatepins)==3
assert all(base['runtime_authority_sha256'][p]==h for p,h in duplicatepins.items())and base['artifacts']==child['artifacts']and all(child['runtime_authority_sha256'][p]==h for p,h in duplicatepins.items())
assert ['artifacts']in row['protected_pointers']and not any(c['pointer'][0]=='artifacts'for c in row['changes'])
row['source_fields']=[['legacy_source_sha256'],['runtime_authority_sha256']]
back=copy.deepcopy(v);back['metadata'][target]['source_fields']=copy.deepcopy(old['metadata'][target]['source_fields']);assert enc(back)==oldraw
audit=[]
def at(a,ptr):
 for k in ptr:a=a[k]
 return a
refs={r['target']:r for r in v['targets']}
for p,r in v['metadata'].items():
 a=json.loads((G/r['parent']['path'][6:]).read_bytes());b=json.loads((G/r['candidate']['path'][6:]).read_bytes());old_sources={};new_sources={}
 for ptr in r['source_fields']:
  for path,h in at(a,ptr).items():assert path not in old_sources;old_sources[path]=h
  for path,h in at(b,ptr).items():assert path not in new_sources;new_sources[path]=h
 assert set(old_sources)<=set(new_sources)
 for path,h in old_sources.items():
  if h!=new_sources[path]:assert path in refs and h==refs[path]['parent']['sha256']and new_sources[path]==refs[path]['candidate']['sha256']
 rebuilt=copy.deepcopy(a)
 for c in r['changes']:
  holder=at(rebuilt,c['pointer'][:-1]);key=c['pointer'][-1];assert(key in holder)==c['existed']and(not c['existed']or holder[key]==c['old']);holder[key]=copy.deepcopy(c['new'])
 assert rebuilt==b
 for c in reversed(r['changes']):
  holder=at(rebuilt,c['pointer'][:-1]);key=c['pointer'][-1]
  if c['existed']:holder[key]=copy.deepcopy(c['old'])
  else:del holder[key]
 assert enc(rebuilt)==(G/r['parent']['path'][6:]).read_bytes()
 audit.append(dict(id=r['id'],source_fields=r['source_fields'],old_count=len(old_sources),new_count=len(new_sources),disjoint=True,whole_serialized_inverse=True))
indexaudit=[]
for p,r in v['index_proofs'].items():
 on=(G/v['records'][p]['candidate']['path'][6:]).read_bytes();off=(G/r['disabled']['path'][6:]).read_bytes();assert off.count(r['disabled_literal'].encode())==1 and r['enabled_literal'].encode()not in off and off.replace(r['disabled_literal'].encode(),r['enabled_literal'].encode())==on;indexaudit.append(dict(target=p,sole_bool=True))
core=G/'build/luoyang_city_full_rollout_20261022ap_source_finalize01/stage_unified06_04_READY.py';assert sha(core.read_bytes())=='8de0b1dc9c5f24511947221760c9efb1e48a59fff152c426800b790ec7c26b28'
sp=importlib.util.spec_from_file_location('fixed_patch_only',core);m=importlib.util.module_from_spec(sp);sp.loader.exec_module(m)
patchaudit=[]
for p,r in v['records'].items():
 a=(G/r['parent']['path'][6:]).read_bytes();b=(G/r['candidate']['path'][6:]).read_bytes();assert sha(a)==r['parent']['sha256']and sha(b)==r['candidate']['sha256']and len(b)==r['candidate']['bytes']
 f,x=a.decode(),b.decode()
 for h in r['hunks']:assert f.count(h['old'])==1;f=f.replace(h['old'],h['new'],1)
 for h in reversed(r['hunks']):assert x.count(h['new'])==1;x=x.replace(h['new'],h['old'],1)
 assert f.encode()==b and x.encode()==a
 _,proof=m._strict_lf_build_file_patch((G/p[6:]).resolve().as_posix(),a,b);patchaudit.append(dict(target=p,proof=proof))
mapaudit=[]
for name,r in v['maps'].items():
 oldmap=json.loads((G/r['parent']['path'][6:]).read_bytes())['source_sha256'];expected=copy.deepcopy(oldmap)
 for p,t in refs.items():
  if p in expected:assert expected[p]==t['parent']['sha256'];expected[p]=t['candidate']['sha256']
 additions=dict(v['source_additions']['new_execution_proof6'])
 if name!='expected_ch4_s0_luoyang_gate_true':additions.update(v['source_additions']['services_flat2'])
 if name=='expected_ch4_s3_luoyang_market_true':additions.update(v['source_additions']['Garden_full47'])
 for p,h in additions.items():assert p not in expected or expected[p]==h;expected[p]=h
 actual_decl=json.loads((G/r['candidate']['path'][6:]).read_bytes())['source_sha256'];assert actual_decl==expected and len(expected)==r['count']and all(len(h)==64 and all(c in '0123456789abcdef'for c in h)for h in expected.values())
 mapaudit.append(dict(node=name,count=len(expected),whole_keys_values_expected_equal=True))
bundle=out('native_projection_residual04/unified28_candidates_disjoint_fields.json',enc(v))
ip=P/'CT_raw_inverse_residual03/source_input_ROOT_REVIEW.json';oldinput=ip.read_bytes();assert sha(oldinput)=='8abec0a36c0a688926c946d1b6ac6e1525d768317ca9bf1046cfa15410448b1b';original=json.loads(oldinput);new=copy.deepcopy(original);pin=next(p for p in new['pinned_inputs']if p['id']=='candidates');pin.update(path=bundle['path'],sha256=bundle['sha256']);new['output_root']=R+'outputs/root_services_garden_exact28_stage04/'
back=copy.deepcopy(new);back['pinned_inputs']=copy.deepcopy(original['pinned_inputs']);back['output_root']=original['output_root'];assert enc(back)==oldinput
inp=out('native_projection_residual04/source_input_ROOT_REVIEW.json',enc(new))
proof=out('native_projection_residual04/schema_evidence_and_full_offline_preflight_NOT_STAGE.json',enc(dict(status='EXACT_OLD_DOCKS_ARTIFACT_PROJECTION_DECLARATION_REPAIR',cause='Only legacy_manifest_4 historical artifacts repeats three immutable native pins already in runtime_authority_sha256. This is the protected artifact projection, not a second source class. All values same, zero conflict; no other metadata duplicate.',duplicate_fixed_native_pins=duplicatepins,old_source_fields=old['metadata'][target]['source_fields'],new_source_fields=row['source_fields'],source_fields_one_pointer_only=True,artifact_JSON_fields_and_partitions_and_candidate_bytes_unchanged=True,whole_bundle_typed_serialized_inverse=True,all12_metadata_audit=audit,all8_index_sole_bool_audit=indexaudit,all14_GD_patch_full_byte_and_LF_audit=patchaudit,all4_incremental_map_audit=mapaudit,input=inp,bundle=bundle,driver_unchanged=next(p for p in new['pinned_inputs']if p['id']=='driver'),Stage_class_calls=0,engine_calls=0,collector_calls=0,canonical_writes=0)))
print(json.dumps(dict(input=inp,bundle=bundle,proof=proof,metadata_count=len(audit),indexes=len(indexaudit),GD=len(patchaudit),maps=len(mapaudit),driver_unchanged=True)))
