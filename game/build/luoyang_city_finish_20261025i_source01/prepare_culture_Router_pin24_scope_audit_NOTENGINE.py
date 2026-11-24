"""Finite strict-pin audit and Root-only backup plan. No engine/collector/Stage."""
from pathlib import Path
import json,hashlib,copy
N=Path(__file__).resolve().parent;G=N.parents[1];S='res://build/luoyang_city_finish_20261025i_source01/';P=S+'culture_Router_pin_repair01/';OUT=N/'culture_Router_pin_repair01'
def sha(b):return hashlib.sha256(b).hexdigest()
def enc(v):return(json.dumps(v,ensure_ascii=False,indent=2)+'\n').encode()
def read(pin):
 b=(G/pin['path'][6:]).read_bytes();assert sha(b)==pin['sha256'];return b
def load(pin):return json.loads(read(pin))
dp=dict(path=S+'docks_gallery_family_repair01/gallery_family32_deployed_ROOT_ACTUAL.json',sha256='d58160a60473eb962836f603842ef618b357f99c09339d28eaed67091a43797c');dep=load(dp)
bp=dict(path=S+'docks_gallery_family_repair01/unified32_READY01/unified32_all_candidates_and_inverse_NOT_STAGE.json',sha256='5f7293ac4203d4e847f623cc76f0292dbd9d5edf269a1bde8f927f4df523cb5e');bundle=load(bp)
parents={r['target']:r['candidate']for r in bundle['targets']};assert len(parents)==32 and dep['passed']
CT='res://data/luoyang_culture_integration_20261019x/runtime_contract.json';R='res://scripts/autoload/scene_router.gd'
ct=load(parents[CT]);ctrows=[]
for p,h in ct['source_sha256'].items():
 actual=sha((G/p[6:]).read_bytes());ctrows.append(dict(path=p,declared=h,physical_sha256=actual,match=h==actual,consumer='Coordinator.readiness52-57 EXACT FileAccess SHA; no EX fallback'))
ctdiff=[r for r in ctrows if not r['match']];assert len(ctrows)==26 and [r['path']for r in ctdiff]==[R]
tb=load(bundle['temple_binding']['candidate']);base=load(dict(path=tb['parent_binding_path'],sha256=tb['parent_binding_sha256']));effective={**base['source_sha256'],**tb['source_delta']};tbrows=[]
for p in set(effective)&set(parents):
 actual=parents[p]['sha256'];tbrows.append(dict(path=p,declared=effective[p],current_fixed_actual=actual,match=effective[p]==actual))
tbdiff=[r for r in tbrows if not r['match']];assert [r['path']for r in tbdiff]==[R]
# All current metadata classes are compared only on this actual changed domain.
metarows=[]
def at(v,ptr):
 for k in ptr:v=v[k]
 return v
for p,n in bundle['metadata'].items():
 v=load(n['candidate']);observations=[]
 for ptr in n['source_fields']:
  for k,h in at(v,ptr).items():
   if k in parents:assert h==parents[k]['sha256'];observations.append(dict(pointer=ptr+[k],sha256=h))
 metarows.append(dict(path=p,id=n['id'],actual_changed_domain_exact_source_entries=observations,policy='Existing disjoint class/source fields exact values; no reclassification'))
strategies=[
 dict(consumer='Cultural Coordinator readiness',scope='all26 CT entries',policy='EXACT bytes and every source SHA, no history fallback',required_change='Only CT.Router; Coordinator CONTRACT_SHA follows CT'),
 dict(consumer='Temple prepare',scope='parent source table +74 delta',policy='Hash all natural sources, then strict _source_first[path]==config.source_sha256[path]',required_change='delta Router + new CT and Coordinator; T BIND path/SHA follows'),
 dict(consumer='Quarter/ Estate validation',policy='full declared manifest source table exact FIRST; all corresponding changed entries already current',required_change='Only new EX206 ordinary evidence and necessary canonical counter hashes; no Family code'),
 dict(consumer='NPC presentation_execution / quarter_people_execution',policy='Exact current OR OWNED+F120 approved with per-edge SHA/UTF8 inverse',required_change='Original immutable authors unchanged; preserve old edges/values, add genuine Coord/T edges only'),
 dict(consumer='G assembled interiors scene_path',policy='Exact declared row source OR OWNED F120 historical approval; all original row/native storage gates retained',required_change='No G/12room/native changes'),
 dict(consumer='Finish runtime/ ambient / original receipts',policy='Fixed immutable helper/author/binding/required_original scene-layout pins plus original owner FIRST/FINAL',required_change='All helper/BIND/Field/Router unchanged; no hot-query logic'),
]
skip={p for p in parents if p.endswith(('/C_READY.gd',))} # explicit canonical set below
skip={S for S in [
 'res://scripts/city/luoyang_enclosure_v11_candidate_contract.gd','res://scripts/city/luoyang_quarters_family_20261022ap.gd','res://scripts/city/luoyang_estate_family_20261021am.gd','res://scripts/city/luoyang_environment_layer_20261022ap.gd','res://scripts/field/field_walkable_controller.gd','res://scripts/city/luoyang_docks_district08_20261019aa.gd','res://scripts/city/luoyang_docks_workyard_20261019ac.gd',R]}
rows=[]
for p,pin in parents.items():
 raw=read(pin);assert (G/p[6:]).read_bytes()==raw,('CURRENT_D581_DRIFT_KEEP',p)
 if p not in skip:rows.append(dict(target=p,immutable_old=pin['path'],old_sha256=pin['sha256'],old_bytes=len(raw),kind='GD'if p.endswith('.gd')else'JSON',backup=P+'root_only_current24_backup/'+p[6:]))
assert len(rows)==24 and sum(r['kind']=='GD'for r in rows)==10
audit=dict(status='FINITE_D581_ALL_CT26_TEMPLE_CHANGED_DOMAIN_AND_32_CONSUMER_POLICY_AUDIT_NOT_ENGINE',passed=True,parent_deployment=dp,CT_source_count=26,CT_entries=ctrows,CT_only_difference=ctdiff,Temple_delta_count=len(tb['source_delta']),Temple_effective_source_count=len(effective),Temple_changed_domain_entries=tbrows,Temple_only_difference=tbdiff,metadata12_current_domain=metarows,consumer_policies=strategies,Root_C91108_wholeFAIL_preserved=True,engine_calls=0,collector_calls=0,Stage_calls=0,canonical_writes=0)
scope=dict(status='D581_EXACT24_CT_ROUTER_PIN_SOURCE_SUCCESSOR_PREPARATION',count=24,partition=dict(GD=10,JSON=14),parent_deployment=dp,parent_stage=dep['stage'],parent_descriptor=bp,targets=rows,excluded_noop=sorted(skip),old202_values_all_edges_preserved=True,owned10_unchanged=True,new_real_edges=['Coordinator','Temple'],new_proof_count_expected=206,Authority_F120_unchanged=True,no_shortcut=True)
sb=enc(scope);sp=dict(path=P+'current_D581_exact24_scope_PREPARATION.json',sha256=sha(sb))
bkp=dict(path=S+'docks_gallery_family_repair01/current_authority20_backup32_ROOT_ACTUAL.json',sha256='5efc38ef1ea9f418afd9144a1db3dce773e9e5b0d9af1ac0436808f282fcceb3');bk=load(bkp);assert bk['total_backups']==317
current={r['target']:copy.deepcopy(r)for r in bk['current33']}
for r in dep['targets']:current[r['target']]=dict(target=r['target'],sha256=r['sha256'],bytes=r['bytes'],immutable_candidate=r['candidate_path'],current=dict(exists=True,sha256=r['sha256'],bytes=r['bytes'],ticks=r['ticks']))
assert len(current)==34
frozen={r['path']:{k:v for k,v in r.items()if k!='path'}for r in bk['frozen2121_current_facts']};byabs={str((G/p[6:]).resolve()):r for p,r in current.items()}
for p in frozen:
 r=byabs.get(str(Path(p).resolve()))
 if r:frozen[p]=r['current']
backups=bk['old285_backup_facts']+[dict(path=r['backup'],exists=True,sha256=r['sha256'],bytes=r['bytes'],ticks=r['backup_ticks'])for r in bk['new_backups']];assert len(backups)==317
extra=load(dict(path=S+'docks_gallery_family_repair01/new_mask3_fixed_hash_and_current_ticks_READONLY.json',sha256='45e708490054f024bec459d0d7f82f0d5b4c06da2489cd3637bd4006b5cd3649'))['rows']
plan=dict(status='ROOT_ONLY_CREATENEW24_D581_PIN_REPAIR_PLAN_NOT_EXECUTED',scope=sp,parent_deployment=dp,current34=list(current.values()),current24=rows,frozen2121_expected=frozen,save15_expected=bk['save15'],old317_backup_facts=backups,media116=bk['media_facts']+extra,ui=bk['ui'],Root_only_backup_prefix=P+'root_only_current24_backup/',engine_calls=0,collector_calls=0,canonical_writes=0)
script=(N/'docks_gallery_family_repair01/backup_current_authority20_32_ROOT_ONLY.py').read_text()
for a,b in [("docks_gallery_family_repair01/current_authority20_backup32_ROOT_PLAN.json","culture_Router_pin_repair01/current_D581_backup24_ROOT_PLAN.json"),('current33','current34'),('observed33','observed34'),('current32','current24'),('backup32','backup24'),('CreateNew32','CreateNew24'),('FULL32','FULL24'),('old285','old317'),('285+len(rows)','317+len(rows)'),('media113','media116'),('CURRENT_AUTHORITY20','CURRENT_D581'),('NEW32_BACKUP','NEW24_BACKUP')]:assert a in script,a;script=script.replace(a,b)
assert not OUT.exists();OUT.mkdir()
for name,b in [('current_D581_exact24_scope_PREPARATION.json',sb),('all_CT26_Temple_consumer_pin_audit_READONLY.json',enc(audit)),('current_D581_backup24_ROOT_PLAN.json',enc(plan)),('backup_current_D581_24_ROOT_ONLY.py',script.encode())]:
 with(OUT/name).open('xb')as f:f.write(b)
 print(name,sha(b),len(b))
