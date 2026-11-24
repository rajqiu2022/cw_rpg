"""Exact two-target, nine existing Router snapshot source admissions. No canonical writes."""
from pathlib import Path
import copy,difflib,hashlib,json
TASK=Path(__file__).resolve().parent
GAME=TASK.parents[1]
PREFIX='res://'+TASK.relative_to(GAME).as_posix()+'/'
M='res://data/maps/luoyang_docks_workyard_20261019ac/runtime/ch4_s2_canal_docks/manifest.json'
I='res://scripts/city/luoyang_docks_workyard_index_20261019ac.gd'
DIAG='res://build/city_navigation_20261101d_docks_diagnostic02/actual/115984/result.json'
PRIOR='res://build/luoyang_navigation_docks_20261101d_successor02/apply_ACTUAL.json'
def need(v,s):
 if not v:raise ValueError(s)
def read(p):return(GAME/p.removeprefix('res://')).read_bytes()
def sha(b):return hashlib.sha256(b).hexdigest()
def enc(v):return(json.dumps(v,ensure_ascii=False,indent=2)+'\n').encode()
def hunks(old,new):
 a=old.decode().splitlines(keepends=True);b=new.decode().splitlines(keepends=True);rows=[]
 for op,i,j,k,l in difflib.SequenceMatcher(None,a,b,autojunk=False).get_opcodes():
  if op!='equal':rows.append({'old_offset':len(''.join(a[:i]).encode()),'new_offset':len(''.join(b[:k]).encode()),'old':''.join(a[i:j]),'new':''.join(b[k:l])})
 test=old
 for r in reversed(rows):
  at=r['old_offset'];x=r['old'].encode();need(test[at:at+len(x)]==x,'EXACT_FORWARD_SLICE');test=test[:at]+r['new'].encode()+test[at+len(x):]
 need(test==new,'WHOLE_FORWARD')
 for r in reversed(rows):
  at=r['new_offset'];x=r['new'].encode();need(test[at:at+len(x)]==x,'EXACT_INVERSE_SLICE');test=test[:at]+r['old'].encode()+test[at+len(x):]
 need(test==old,'WHOLE_INVERSE');return rows
need(sha(read(DIAG))=='f5603c7bbf7ca06a843399fc84e63dea22eebea9c75047c173372cdcf843f369','ROOT_ACTUAL115984_DIAGNOSTIC')
diag=json.loads(read(DIAG))
need(diag['actual_count']==2583 and diag['expected_count']==2574 and diag['missing']==[] and diag['stale']==[] and len(diag['added'])==9 and diag['B_describe_pass']==False,'EXACT9_ADDED_ONLY')
need(sha(read(PRIOR))=='3cb1b0163d1f508a055ea14bda399b9ba314bb5eaad3e2deb01af21752e40491','ROOT_ACTUAL21_APPLY')
prior=json.loads(read(PRIOR));prior_rows={r['res_path']:r for r in prior['actual_targets']}
before={p:read(p)for p in(M,I)}
for p in before:
 row=prior_rows[p];need(sha(before[p])==row['actual_after_sha256'] and len(before[p])==row['actual_after_bytes'] and before[p]==read(row['candidate']),('EXACT_STAGE2_AFTER_EQUALS_STAGE3_BEFORE_AND_FULL_BYTES',p))
data=json.loads(before[M]);added={r['path']:r['actual']for r in diag['added']}
gate=json.loads(read('res://data/maps/luoyang_layout_bundle_20261018t_retry2/ch4_s0_luoyang_gate/manifest.json'))
for p,h in added.items():
 need(p.endswith('/scene_router.gd') and p.startswith('res://build/luoyang_') and p not in data['legacy_source_sha256'],'ONLY9_EXISTING_LUOYANG_ROUTER_SNAPSHOTS')
 need(sha(read(p))==h and gate['legacy_source_sha256'].get(p)==h,('EXACT_CURRENT_AND_ALREADY_GATE_ADMITTED_SNAPSHOT',p))
text=before[M].decode();marker='  "legacy_source_sha256": ';at=text.index(marker)+len(marker);_,count=json.JSONDecoder().raw_decode(text[at:]);block=text[at:at+count];end=block.rfind('\n  }');need(end>=0,'SOURCE_MAP_END')
block=block[:end]+''.join(',\n    '+json.dumps(p)+': '+json.dumps(h)for p,h in added.items())+block[end:]
manifest=(text[:at]+block+text[at+count:]).encode();updated=json.loads(manifest)
inverse=copy.deepcopy(updated)
for p in added:inverse['legacy_source_sha256'].pop(p)
need(inverse==data,'ALL_ORIGINAL_FIELDS_AND_SOURCE_VALUES_IDENTICAL')
old_literal='const MANIFEST_SHA="'+sha(before[M])+'"';new_literal='const MANIFEST_SHA="'+sha(manifest)+'"'
need(before[I].count(old_literal.encode())==1,'EXACT_INDEX_SHA_LITERAL')
index=before[I].replace(old_literal.encode(),new_literal.encode(),1)
after={M:manifest,I:index}
# Virtual complete original C/B equality based on Root's actual collector,
# updating ONLY the selected manifest and its original dynamic index hashes.
actual=diag['actual_complete'].copy();expected=diag['expected_complete'].copy();expected.update(added)
for p,b in after.items():actual[p]=sha(b);expected[p]=sha(b)
need(actual==expected and len(actual)==2583,'EXACT_ACTUAL_C_SET_EQUALS_VIRTUAL_B_EXPECTED_2583')
need(all(sha(after.get(p,read(p)))==h for p,h in expected.items()),'FULL_VIRTUAL2583_HASHES_MATCH')
# Finite current consumer audit: the existing33 owner domain plus original
# independent96/113 manifests. Historical reports/snapshots are not rewritten.
scope=json.loads(read('res://build/luoyang_gate_front_walls_20261101c_system01/capture_targets_READY.json'))
literal_hits={p:[]for p in(M,I)}
for source in ['res://'+r['target'].removeprefix('game/')for r in scope['targets']]:
 for p in before:
  if source!=p and sha(before[p]).encode()in read(source):literal_hits[p].append(source)
need(literal_hits[M]==[I] and literal_hits[I]==[],('ONLY_ORIGINAL_AC_INDEX_STATIC_CONSUMER',literal_hits))
pins96=json.loads(read('res://build/city_navigation_20261101d_candidate01/source_pins_READY.json'))['source_pins']
old113=json.loads(read('res://build/city_navigation_20261101d_guard01/capture_before_ACTUAL.json'))['before_facts']
need(not set(after)&set(pins96) and not set(after)&set(old113),'NO96_OR113_TARGET')
rows=[];all_hunks=[];outputs={}
for p,b in after.items():
 name='AC_manifest_CANDIDATE.json'if p==M else'AC_index_CANDIDATE.gd'
 outputs[name]=b
 rows.append({'path':'game/'+p[6:],'res_path':p,'candidate':PREFIX+name,'before_sha256':sha(before[p]),'before_bytes':len(before[p]),'after_sha256':sha(b),'after_bytes':len(b),'stage2_full_before_snapshot':prior_rows[p]['candidate'],'stage2_actual_apply_receipt':PRIOR,'stage2_after_equals_stage3_before':True,'reason':'append exactly9 existing approved Router snapshots to legacy_source_sha256'if p==M else'only selected AC manifest SHA literal'})
 all_hunks.append({'target':'game/'+p[6:],'whole_forward_and_inverse_exact':True,'hunks':hunks(before[p],b)})
report={'schema':'CITYNAV_DOCKS_20261101D_EXACT9_SNAPSHOTS_TWO_TARGET_SUCCESSOR03_V1','canonical_writes':0,'engine_runs':0,'actual_Root_diagnostic':DIAG,'actual_Root_diagnostic_sha256':sha(read(DIAG)),'prior21_apply_receipt':PRIOR,'prior21_apply_receipt_sha256':sha(read(PRIOR)),'actual_targets':rows,'exact9_added':diag['added'],'actual_C_count':2583,'previous_B_expected_count':2574,'virtual_B_expected_count':2583,'actual_C_and_virtual_B_key_set_and_full_hash_values_identical':True,'existing_all_other_JSON_fields_and_original2497_legacy_values_identical':True,'index_only_MANIFEST_SHA_changed':True,'finite_static_consumer_literal_hits':literal_hits,'new_runtime_sources':{},'frozen96_and_original113_target_overlap':[],'requires_Root_authorization_before_apply':True}
outputs['candidate_closure_READY.json']=enc(report);outputs['all_source_hunks_READY.json']=enc(all_hunks)
need(all(not(TASK/n).exists()for n in outputs),'NEW_OUTPUTS_ONLY')
for p in before:need(read(p)==before[p],('CANONICAL_UNCHANGED_FINAL',p))
for name,b in outputs.items():
 with(TASK/name).open('xb')as f:f.write(b)
print(json.dumps({'passed':True,'targets':rows,'report_sha256':sha(outputs['candidate_closure_READY.json']),'complete_virtual_expected_count':2583,'canonical_writes':0,'engine_runs':0},indent=2))
