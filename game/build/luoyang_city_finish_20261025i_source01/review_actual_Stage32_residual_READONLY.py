"""Finite Source review of Root actual Stage. No engine, collector, canonical or Stage execution."""
from pathlib import Path
import json,hashlib,importlib.util,copy
N=Path(__file__).resolve().parent;G=N.parents[1];NS='res://build/luoyang_city_finish_20261025i_source01/'
def sha(b):return hashlib.sha256(b).hexdigest()
def enc(v):return (json.dumps(v,ensure_ascii=False,indent=2,allow_nan=False)+'\n').encode()
def read(p,h):
 b=(G/p[6:]).read_bytes();assert sha(b)==h,(p,h,sha(b));return b
def load(pin):return json.loads(read(pin['path'],pin['sha256']))
sp=dict(path=NS+'outputs/root_finish8_exact32_stage01/receipt.json',sha256='37d79bce73a637c46dd9790453650a48da79cc1a521c7436fbf07f326cb6ba33');stage=load(sp)
bp=dict(path=NS+'unified32_READY03/unified32_all_candidates_and_inverse_NOT_STAGE.json',sha256='be3aa94f1b6eae760888803076f80062ad4a25b3aabb349ea46e43e223099254');bundle=load(bp)
scope=load(bundle['scope']);targets={r['target']:r for r in stage['targets']};declared={r['target']:r for r in bundle['targets']};assert len(targets)==32 and set(targets)==set(declared)=={r['target']for r in scope['targets']}
checks=[]
def check(ok,name):assert ok,name;checks.append(name)
check(stage['status']=='EIGHT_EXTERIORS_EXACT32_STAGED_NOT_DEPLOYED','not_deployed_or_Field_pass_status')
check(stage['target_partition']==dict(patch_count=18,copy_count=14,total=32),'exact18_GD14_JSON_no_noop_scope')
check(stage['source_first']==stage['source_final']and len(stage['source_first'])==3450,'actual3450_source_FIRST_FINAL_same')
for p,r in targets.items():
 d=declared[p];check(r['old_sha256']==d['parent']['sha256']and r['candidate_path']==d['candidate']['path']and r['candidate_sha256']==d['candidate']['sha256']and r['old_sha256']!=r['candidate_sha256'],'exact_declared_target:'+p)
check(set(stage['nodes'])=={r['id']for r in bundle['metadata'].values()}|{'execution_final','runtime_contract_final'}|set(bundle['maps'])|set(bundle['expected_family_maps']),'exact_result_node_domains')
for ident,r in bundle['maps'].items():
 node=stage['nodes'][ident];value=load(dict(path=node['path'],sha256=node['sha256']));check(value==r['value']==node['value'],'independent_full_expected_map:'+ident);check(len(value['source_sha256'])==r['count'],'exact_map_count:'+ident)
 for p,t in targets.items():
  if p in value['source_sha256']:check(value['source_sha256'][p]==t['candidate_sha256'],'map_current_candidate_scalar:'+ident+':'+p)
for ident,pin in bundle['expected_family_maps'].items():check(stage['nodes'][ident]['value']==load(pin),'full_original_family_receipt:'+ident)
ex=stage['nodes']['execution_final']['value'];old=json.loads(read(bundle['execution']['parent']['path'],bundle['execution']['parent']['sha256']))
check(len(ex['owned'])==len(old['owned'])==10 and len(ex['source_sha256'])==183 and len(old['source_sha256'])==176,'owned10_old176_plus_exact7')
check(all(ex['source_sha256'].get(p)==h for p,h in old['source_sha256'].items()),'all_old176_proof_values_preserved')
for p in old['owned']:
 a,b=old['owned'][p],ex['owned'][p]
 if p in bundle['execution']['changed_existing_owned']:check(b['edges'][:-1]==a['edges']and len(b['edges'])==len(a['edges'])+1,'one_only_new_edge:'+p)
 else:check(a==b,'other_owned_unchanged:'+p)
check(len(bundle['execution']['changed_existing_owned'])==5 and bundle['execution']['depth_limit']==16 and bundle['execution']['no_shortcut']is True,'five_real_edges_depth16_no_shortcut')
field=next(r for p,r in bundle['records'].items()if p.endswith('/field_walkable_controller.gd'));fb=read(field['candidate']['path'],field['candidate']['sha256']);check(fb.count(b'const FINISH25I_ENABLED := true')==1 and b'const FINISH25I_ENABLED := false'not in fb,'missed_Field_flag_exact_true_successor')
core=G/'build/luoyang_city_full_rollout_20261022ap_source_finalize01/stage_unified06_04_READY.py';assert sha(core.read_bytes())=='8de0b1dc9c5f24511947221760c9efb1e48a59fff152c426800b790ec7c26b28'
spec=importlib.util.spec_from_file_location('fixed_patch_only',core);M=importlib.util.module_from_spec(spec);spec.loader.exec_module(M)
pieces=['*** Begin Patch\n']
for p,r in targets.items():
 if not p.endswith('.gd'):continue
 d=declared[p];part,_=M._strict_lf_build_file_patch((G/p[6:]).resolve().as_posix(),read(d['parent']['path'],d['parent']['sha256']),read(d['candidate']['path'],d['candidate']['sha256']));pieces.append(part)
pieces.append('*** End Patch\n');check(''.join(pieces).encode()==read(stage['patch_path'],stage['patch_sha256']),'all18_patch_literal_bytes_reconstruction')
plan=load(stage['byte_copy_plan']);check(len(plan['rows'])==14 and {r['target']for r in plan['rows']}=={p for p in targets if p.endswith('.json')},'JSON14_exact_disjoint_copyplan')
for r in plan['rows']:check(r['candidate_sha256']==targets[r['target']]['candidate_sha256']and r['candidate_bytes']==declared[r['target']]['candidate']['bytes'],'copy_candidate_exact:'+r['target'])
report=dict(status='SOURCE_FINITE_REVIEW_ROOT_ACTUAL_STAGE32_NO_NEW_FINDING',passed=True,Stage=sp,declared_candidates=bp,check_count=len(checks),checks=checks,limits=['Source is author of candidates; this is a separate finite mechanical output comparison, not independent geometry/ART evidence.','No current canonical deployment assertion while Root may apply patch.','No Field/runtime/wholecity_ART/loading pass claim.'],engine_calls=0,collector_calls=0,Stage_calls=0,canonical_writes=0)
out=N/'actual_Stage32_finite_Source_review_READONLY.json';assert not out.exists();raw=enc(report)
with out.open('xb')as f:f.write(raw)
print(json.dumps(dict(path=NS+out.name,sha256=sha(raw),checks=len(checks),passed=True)))
