"""Restore old EXTERNAL filtering for two B manifests; preserve old C-map keys."""
from pathlib import Path
import json,copy,hashlib,difflib
P=Path(__file__).resolve().parent;G=P.parents[1];R='res://build/luoyang_city_revision_20261025h_source01/';PREFIX=R+'external_projection_residual05/'
def sha(b):return hashlib.sha256(b).hexdigest()
def enc(v):return(json.dumps(v,ensure_ascii=False,indent=2,allow_nan=False)+'\n').encode()
def out(n,b):
 p=P/'external_projection_residual05'/n;assert not p.exists();p.parent.mkdir(parents=True,exist_ok=True)
 with p.open('xb')as f:f.write(b)
 return dict(path=PREFIX+n,sha256=sha(b),bytes=len(b))
def hunks(a,b):
 aa,bb=a.decode().splitlines(keepends=True),b.decode().splitlines(keepends=True);rows=[]
 for group in difflib.SequenceMatcher(None,aa,bb,autojunk=False).get_grouped_opcodes(2):rows.append(dict(old=''.join(aa[group[0][1]:group[-1][2]]),new=''.join(bb[group[0][3]:group[-1][4]])))
 f,v=a,b
 for r in rows:assert f.count(r['old'].encode())==1;f=f.replace(r['old'].encode(),r['new'].encode(),1)
 for r in reversed(rows):assert v.count(r['new'].encode())==1;v=v.replace(r['new'].encode(),r['old'].encode(),1)
 assert f==b and v==a;return rows
oldb=(P/'native_projection_residual04/unified28_candidates_disjoint_fields.json').read_bytes();assert sha(oldb)=='df3dbffabb41c283d486b62d7b5efc32cf3bca28156ec9a4f9fce5f5636d5b41';old=json.loads(oldb);new=copy.deepcopy(old)
external=['res://scripts/city/luoyang_environment_index_20261022ap.gd','res://scripts/city/luoyang_execution_index_20261022ap.gd'];changes={};evidence=[]
market='res://data/maps/luoyang_full_city_20261022ap/market/ch4_s3_luoyang_market/manifest.json'
finite='res://build/luoyang_city_full_rollout_20261022ap_source_finalize01/finite_adapter_production08/runtime_market_manifest_READY.json'
for target in [market,finite]:
 r=new['metadata'][target];base=json.loads((G/r['parent']['path'][6:]).read_bytes());value=json.loads((G/r['candidate']['path'][6:]).read_bytes());oldpin=copy.deepcopy(r['candidate'])
 for p in external:
  assert all(p not in base[f]for f in ['legacy_source_sha256','runtime_authority_sha256','artifacts'])
  assert p in value['legacy_source_sha256']and p not in value['runtime_authority_sha256']and p not in value['artifacts'];del value['legacy_source_sha256'][p]
 r['changes']=[c for c in r['changes']if c['pointer']!=['legacy_source_sha256',external[0]]and c['pointer']!=['legacy_source_sha256',external[1]]]
 if target==finite:
  c=changes[market];assert value['runtime_authority_sha256'].get(market)==c['old']['sha256'];value['runtime_authority_sha256'][market]=c['new']['sha256']
  row=next(c for c in r['changes']if c['pointer']==['runtime_authority_sha256',market]);assert row['new']==changes[market]['old']['sha256'];row['new']=changes[market]['new']['sha256']
 pin=out('metadata/'+r['id']+'.json',enc(value));r['candidate']=pin;changes[target]=dict(old=oldpin,new=pin)
 next(t for t in new['targets']if t['target']==target)['candidate']=pin
 evidence.append(dict(target=target,removed_only_new_keys=external,all_old_source_keys_retained=True,old=oldpin,new=pin))
index='res://scripts/city/luoyang_full_city_index_20261022ap.gd';r=new['records'][index];before=(G/r['parent']['path'][6:]).read_bytes();oldpin=copy.deepcopy(r['candidate']);raw=(G/oldpin['path'][6:]).read_bytes();offpin=new['index_proofs'][index]['disabled'];off=(G/offpin['path'][6:]).read_bytes();a,b=changes[finite]['old']['sha256'].encode(),changes[finite]['new']['sha256'].encode()
assert raw.count(a)==off.count(a)==1;raw=raw.replace(a,b,1);off=off.replace(a,b,1)
pin=out('indexes/ap_city_index.gd',raw);offpin=out('indexes/ap_city_index_disabled.gd',off);r['candidate']=pin;r['hunks']=hunks(before,raw);new['index_proofs'][index]['disabled']=offpin
for item in new['index_proofs'][index]['replacements']:
 if item['new']==a.decode():item['new']=b.decode()
next(t for t in new['targets']if t['target']==index)['candidate']=pin;changes[index]=dict(old=oldpin,new=pin)
membership=[]
for ident,r in new['maps'].items():
 parent=json.loads((G/r['parent']['path'][6:]).read_bytes())['source_sha256'];value=json.loads((G/r['candidate']['path'][6:]).read_bytes())
 for p,c in changes.items():
  if p in value['source_sha256']:assert value['source_sha256'][p]==c['old']['sha256'];value['source_sha256'][p]=c['new']['sha256']
 assert len(value['source_sha256'])==r['count']
 pin=out('maps/'+value['scene_id']+'_true.json',enc(value));r['candidate']=pin;r['value']=value
 membership.append(dict(scene=value['scene_id'],old_environment_index_key=external[0]in parent,old_execution_index_key=external[1]in parent,count=r['count'],no_old_key_deleted=True))
bundle=out('unified28_candidates_EXTERNAL_fixed.json',enc(new))
ib=(P/'native_projection_residual04/source_input_ROOT_REVIEW.json').read_bytes();assert sha(ib)=='441a96bd4ee1352579a969075714c2d302b514bd37cd3a698ee4e0e25b87336a';original=json.loads(ib);v=copy.deepcopy(original);p=next(p for p in v['pinned_inputs']if p['id']=='candidates');p.update(path=bundle['path'],sha256=bundle['sha256']);v['output_root']=R+'outputs/root_services_garden_exact28_stage05/'
for p,c in changes.items():
 v['declared_candidates'][p]=copy.deepcopy(c['new']);row=next(r for r in v['prospective_targets']if r['target']==p);row.update(candidate_path=c['new']['path'],sha256=c['new']['sha256'])
inp=out('source_input_ROOT_REVIEW.json',enc(v))
report=out('exact_external_filter_restoration_NOT_STAGE.json',enc(dict(status='ROOT_APPROVED_TWO_B_MANIFESTS_RESTORE_OLD_EXTERNAL_FILTER',old_bundle_sha256=sha(oldb),new_bundle=bundle,input=inp,changed_existing_candidate_targets=evidence+[dict(target=index,**changes[index])],four_C_map_membership=membership,all_code_except_APcity_literal_unchanged=True,owned_authority_all10_176_unchanged=True,no_new_white_list_or_permission=True,source_classification_preserved=True,Stage_calls=0,engine_calls=0,canonical_writes=0)))
print(json.dumps(dict(input=inp,bundle=bundle,proof=report,map_counts={k:r['count']for k,r in new['maps'].items()},driver_unchanged=True)))
