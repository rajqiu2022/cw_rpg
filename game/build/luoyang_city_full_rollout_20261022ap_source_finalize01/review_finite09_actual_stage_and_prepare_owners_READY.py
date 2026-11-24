"""Independent source-only review/8+5 recipe after Root actual stage.

Never calls a collector, Godot, Stage, native decoder, or canonical writer.
Expected sources come from frozen independent AO recipes, old3F8D owner rows,
the new exact typed metadata nodes and fixed source declarations, not live SHA
crawls or actual observed runtime dictionaries.
"""
import argparse,copy,hashlib,json
from pathlib import Path
H=Path(__file__).resolve().parent;G=H.parents[1]
S='res://build/luoyang_city_full_rollout_20261022ap_source_finalize01/'
def sha(b):return hashlib.sha256(b).hexdigest()
def read(p,s):
 assert p.startswith('res://') and '..' not in p
 b=(G/p[6:]).read_bytes();assert sha(b)==s,('PIN',p);return json.loads(b)
def same(a,b):
 if type(a) is not type(b):return False
 if isinstance(a,dict):return a.keys()==b.keys() and all(same(a[k],b[k]) for k in a)
 if isinstance(a,list):return len(a)==len(b) and all(same(x,y) for x,y in zip(a,b))
 return a==b
def ptr(v,ks):
 for k in ks:v=v[k]
 return v
def emit(n,v):
 p=H/'finite09_independent_review'/n;assert not p.exists();p.parent.mkdir(parents=True,exist_ok=True)
 b=(json.dumps(v,ensure_ascii=False,indent=2)+'\n').encode()
 with p.open('xb') as f:f.write(b)
 return {'path':S+'finite09_independent_review/'+n,'sha256':sha(b)}
def main():
 ap=argparse.ArgumentParser();ap.add_argument('--receipt',required=True);ap.add_argument('--sha256',required=True);args=ap.parse_args()
 assert args.receipt==S+'outputs/root_finite09_two_domain_stage01/receipt.json'
 stage=read(args.receipt,args.sha256);assert stage['status']=='AP_SOURCE_METADATA_STAGED_NOT_DEPLOYED'
 assert stage['source_first']==stage['source_final'] and len(stage['targets'])==29
 assert stage['target_partition']=={'patch_count':28,'copy_count':1,'total':29,'intersection_empty':True,'union_exact_targets':True}
 plan=read(S+'finite09_input01_ROOT_LOCKED.json','498fc80eeedb9e443631b3e01d196491acacda5101eadc15fe0b9f5cd22d21cb')
 inputs={r['id']:r for r in plan['pinned_inputs']}
 old=read(S+'unified06_06_independent_qa_owner_source_maps_READY.json','3f8d04fde11e7a64b1f1364510cee817466a853c31ae3a98375ca8bcc7283ac8')
 assert old['actual_stage_receipt']['sha256']=='9aacef0735bced81c6f8b0601165b931a9cfe2f54aef682635490619319965b8'
 hand=read(S+'finite_adapter_production08/handoff_PRODUCTION_PROPOSAL.json','8fd3b3b04b1ce33837aa60e1ae41e8a91d86939b08cf30b15421c546aa706e6c')
 targets={r['target']:r for r in stage['targets']};assert set(targets)==set(plan['root_target_allowlist'])
 scope=read(S+'finite_adapter_production09_scope/scope_request_READY.json','1eade019a011914021f4dae7c0aaa426b0b647ac19cd5564d72bf8828cb4a8d0')
 expectedold={r['target']:r['old_sha256'] for r in scope['targets']}
 for p,r in targets.items():
  assert r['old_sha256']==expectedold[p] and r['old_sha256']!=r['candidate_sha256']
  assert sha((G/r['candidate_path'][6:]).read_bytes())==r['candidate_sha256']
 nodes=stage['nodes'];typed=[]
 for n in plan['nodes']:
  id=n['id'];v=nodes[id]
  assert sha((G/v['path'][6:]).read_bytes())==v['sha256']
  if n['kind'] not in ['metadata','finite_contract']:continue
  prior=read(inputs[n['base_input']]['path'],inputs[n['base_input']]['sha256'])
  inverse=copy.deepcopy(v['value'])
  for delta in reversed(stage['proofs'][id]['source_delta']):
   holder=ptr(inverse,delta['pointer'][:-1]);key=delta['pointer'][-1]
   if delta['existed']:holder[key]=delta['old']
   else:del holder[key]
  assert same(inverse,prior),('WHOLE_TYPED_INVERSE',id)
  typed.append(id)
 # Target substitutions are explicit exactly-old/new values, not a current
 # disk admission. Where an inherited source lacks a target, it stays absent.
 def replace_sources(values):
  out=copy.deepcopy(values)
  for p,r in targets.items():
   if p in out:
    assert out[p]==r['old_sha256'],('INHERITED_EXACT_OLD_LEAF',p,out[p],r['old_sha256'])
    out[p]=r['candidate_sha256']
  return out
 def merge(*rows):
  out={}
  for row in rows:
   for p,s in row.items():assert p not in out or out[p]==s;out[p]=s
  return out
 sceneold={r['id']:r for r in old['scenes']};scenes=[]
 for n in plan['nodes']:
  if n['kind']=='map':
   row=copy.deepcopy(sceneold[n['scene_id']]);src=nodes[n['id']]['value']['source_sha256']
   row.update(source_sha256=src,receipt_source_sha256=copy.deepcopy(src),recipe='Frozen original AO baseline + explicit28-source operations/groups + fixed89216 native declarations; never runtime collector')
   scenes.append(row)
 quarter=nodes['quarter_final'];qfamily='res://scripts/city/luoyang_quarters_family_20261022ap.gd';qindex='res://scripts/city/luoyang_quarters_index_20261022ap.gd';qmanifest='res://data/maps/luoyang_full_city_20261022ap/quarters/revision4/manifest.json'
 for id in quarter['value']['scenes']:
  row=copy.deepcopy(sceneold[id]);header=replace_sources({p:row['source_sha256'][p] for p in [qfamily,qindex,qmanifest]})
  row.update(source_sha256=merge(quarter['value']['source_sha256'],header),receipt_source_sha256=quarter['value']['source_sha256'],recipe='Quarter frozen real consumer manifest +3header; receipt manifest only; no finite adapter/native or purpose shader added')
  scenes.append(row)
 estate=nodes['estate_final'];id='luoyang_estate_riverside_20261021ai';row=copy.deepcopy(sceneold[id])
 headers={p:s for p,s in row['source_sha256'].items() if p not in row['receipt_source_sha256']};headers=replace_sources(headers)
 assert len(estate['value']['source_sha256'])==len(row['receipt_source_sha256'])==331
 row.update(source_sha256=merge(estate['value']['source_sha256'],headers),receipt_source_sha256=estate['value']['source_sha256'],recipe='Estate unchanged331-key manifest +3header; exact source successors only')
 scenes.append(row)
 # Temple consumes old complete binding/tasks/ENV/people plus the unchanged
 # execution interface. Only the seven explicitly approved proof leaves are
 # added; old proof bindings remain legitimately inherited by that interface.
 id='ch4_s4_ancient_temple';row=copy.deepcopy(sceneold[id]);src=merge(replace_sources(row['source_sha256']),hand['new_proof_pins'])
 row.update(source_sha256=src,receipt_source_sha256=copy.deepcopy(src),recipe='Frozen complete Temple owner + exact target successors + seven C668 execution proof leaves; old source domains retained, no finite-native or ground shader consumption')
 scenes.append(row)
 registry=nodes['registry_final']['value'];rooms=[]
 for oldrow in old['rooms']:
  row=copy.deepcopy(oldrow);src=merge(replace_sources(row['source_sha256']),hand['new_proof_pins'])
  row.update(source_sha256=src,receipt_source_sha256=registry['rooms'][row['id']]['source_sha256'],recipe='Frozen complete G twelve-room family collector +exact target successors +seven execution proof leaves; separate unchanged per-room receipt')
  rooms.append(row)
 assert len(scenes)==8 and len(rooms)==5
 # Distinguish full collector and receipt source domains and verify every
 # expected leaf through its immutable candidate when canonical is not yet
 # deployed. This is verification, never construction of expected SHA values.
 expectedunion={}
 for row in scenes+rooms:
  for field in ['source_sha256','receipt_source_sha256']:
   for p,s in row[field].items():
    assert p not in expectedunion or expectedunion[p]==s,('SOURCE_CONFLICT',p)
    expectedunion[p]=s
 generated={n['path']:n['sha256'] for n in nodes.values()}
 for p,s in expectedunion.items():
  cp=targets[p]['candidate_path'] if p in targets else p
  assert sha((G/cp[6:]).read_bytes())==s,('EXPECTED_DECLARED_LEAF_NOT_EXACT',p)
 core=copy.deepcopy(old['core_source_sha256']);core.update({p:r['candidate_sha256'] for p,r in targets.items()})
 out={'status':'ROOT_ACTUAL_STAGE_INDEPENDENT_QA_SOURCE_MAPS','actual_stage_receipt':{'path':args.receipt,'sha256':args.sha256},'core_source_sha256':core,'scenes':scenes,'rooms':rooms,'fixed_prior_owner_sha256':'3f8d04fde11e7a64b1f1364510cee817466a853c31ae3a98375ca8bcc7283ac8','expected_not_derived_from_live_collector_or_canonical_hash_crawl':True,'not_Field_or_runtime_credit':True,'metadata_fields_not_invented':'QA merges exact new89216 native scene/layout/world/geometry/one clerk projection separately; other visual/NPC sources remain independent prior fixed oracles'}
 desc=emit('owner_source_maps_READY.json',out)
 review=emit('stage_source_review_READY.json',{'status':'INDEPENDENT29_SOURCE_TYPED_AND_BYTE_REVIEW_NOT_RUNTIME_OR_DEPLOYMENT','actual_stage_receipt':out['actual_stage_receipt'],'owner_source_maps':desc,'typed_whole_inverse_nodes':typed,'target_count':29,'exact_partition':stage['target_partition'],'source_first_final_same':True,'source_first_count':len(stage['source_first']),'expected_union_count':len(expectedunion),'scene_counts':{r['id']:{'collector':len(r['source_sha256']),'receipt':len(r['receipt_source_sha256'])} for r in scenes},'room_counts':{r['id']:{'collector':len(r['source_sha256']),'receipt':len(r['receipt_source_sha256'])} for r in rooms},'engine_collector_or_stage_calls':0})
 print(json.dumps({'owner':desc,'review':review}))
if __name__=='__main__':main()
