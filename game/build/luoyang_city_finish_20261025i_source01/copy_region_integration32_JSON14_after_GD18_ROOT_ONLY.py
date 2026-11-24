"""Root-only Region/Gate exact JSON14 copy after GD18 patch; no engine or GD copy."""
from pathlib import Path
import argparse,json,hashlib,datetime
N=Path(__file__).resolve().parent;GAME=N.parents[1];S='res://build/luoyang_city_finish_20261025i_source01/'

GATE_PROMOTION='res://build/luoyang_city_rectification_20261027d_system01/gate_mask_import01_ROOT_ONLY/promotion_ROOT_EXECUTED.json'
BUILDING_PROMOTION='res://build/luoyang_city_rectification_20261027d_system01/three_building_import01_ROOT_ONLY/promotion_ROOT_EXECUTED.json'
BUILDING_PROMOTION_SHA='15920208fcbd2c7b09fa6808623a2f146a6a531623a35404730e130b85afbbe8'
GATE_PUBLICATION='res://build/luoyang_city_rectification_20261027d_system01/GATE_REAR_ROOT_READY01/output/82020/result.json'
def sha(b):return hashlib.sha256(b).hexdigest()
def res(p):return GAME/p[6:]if p.startswith('res://')else Path(p)
def load(p,h):
 b=res(p).read_bytes();assert sha(b)==h,(p,sha(b));return json.loads(b)
def fact(p):
 p=res(p)
 if not p.exists():return dict(exists=False)
 a=p.stat();h=sha(p.read_bytes());b=p.stat();assert(a.st_size,a.st_mtime_ns)==(b.st_size,b.st_mtime_ns)
 return dict(exists=True,sha256=h,bytes=b.st_size,ticks=str(b.st_mtime_ns//100+621355968000000000))
def sig(v):return {k:v[k]for k in ['exists','sha256','bytes','ticks']if k in v}
def main():
 ap=argparse.ArgumentParser();ap.add_argument('--stage',required=True);ap.add_argument('--stage-sha256',required=True);ap.add_argument('--root-authorized-apply',action='store_true');ap.add_argument('--receipt',required=True);a=ap.parse_args()
 stage=load(a.stage,a.stage_sha256);assert stage['source_first'].get('res://build/luoyang_regions_20261027d_source01/root_integration_scope08_AUTHORIZED.json')=='9d064035022286b8337c430e635f72528e3975cce91e914f53a351ac5bd71919';assert stage['status']=='ROOT08_REGION_GATE_EXACT32_STAGED_NOT_DEPLOYED'and stage['source_first']==stage['source_final']and stage['target_partition']==dict(patch_count=18,copy_count=14,total=32)
 scope=load(S+'region_integration_20261027d01/current_01656_exact32_scope_PREPARATION.json','1db5759bfd8ae094f8f5a7b623a55927d285d1f63cdccb378a811ddb49732494')
 backup=load(S+'region_integration_20261027d01/current_01656_backup32_ROOT_ACTUAL.json','5d406f8866427ace84600088b30748ec8bd3d30d8ed5bcd1b170316c11b882c1')
 assert backup['passed']and backup['external_save_changes']==[]and backup['total_backups']==769 and type(backup['media_content_changes'])is int and backup['media_content_changes']==0
 plan=load(stage['byte_copy_plan']['path'],stage['byte_copy_plan']['sha256']);assert len(plan['rows'])==14 and plan['patch_copy_disjoint']and plan['union_exact_targets']and plan['no_GD_copy_or_native_write']
 targets={r['target']:r for r in stage['targets']};old={r['target']:r for r in backup['new_backups']};assert len(targets)==32 and set(targets)==set(old)=={r['target']for r in scope['targets']}
 target_abs={res(p).resolve()for p in targets};protected={}
 def protect(p,f):
  if res(p).resolve()not in target_abs:protected[str(res(p).resolve())]=sig(f)
 for r in backup['frozen2121_current_facts']+backup['old737_backup_facts']:protect(r['path'],r)
 media_tick_refreshes=[]
 for r in backup['media_facts']+backup['World54_facts']:
  f=fact(r['path']);assert f.get('exists')is True and f['sha256']==r['sha256']and f['bytes']==r['bytes'],('MEDIA_CONTENT_CHANGED_KEEP_NO_ROLLBACK',r['path'])
  if f['ticks']!=r['ticks']:media_tick_refreshes.append(dict(path=r['path'],before_backup_ticks=r['ticks'],current_ticks=f['ticks']))
  protect(r['path'],f)
 for p,f in backup['save15'].items():protect(p,f)
 protect(backup['ui']['path'],backup['ui'])
 for r in backup['current37']:protect(r['target'],r['current'])
 for r in backup['new_backups']:
  f=fact(r['backup']);assert f['sha256']==r['sha256']and f['bytes']==r['bytes']and f['ticks']==r['backup_ticks'];protect(r['backup'],f)
 adopted_media_facts=[]
 promotion=load(GATE_PROMOTION,stage['source_first'][GATE_PROMOTION]);assert promotion['passed']is True and len(promotion['written'])==2
 buildings=load(BUILDING_PROMOTION,BUILDING_PROMOTION_SHA);assert buildings['passed']is True and len(buildings['written'])==9
 for r in promotion['written']+buildings['written']:
  f=fact(r['path']);assert f['sha256']==r['sha256']and f['bytes']==r['bytes'];protect(r['path'],f);adopted_media_facts.append(dict(path=r['path'],**f))
 publication=load(GATE_PUBLICATION,stage['source_first'][GATE_PUBLICATION]);m=publication['mask'];f=fact(m['path']);assert f['sha256']==m['sha256']and f['bytes']==m['bytes'];protect(m['path'],f);adopted_media_facts.append(dict(path=m['path'],**f))
 before={};candidates={}
 for p,r in targets.items():
  before[p]=fact(p);raw=res(r['candidate_path']).read_bytes();assert sha(raw)==r['candidate_sha256'];candidates[p]=raw
  if p.endswith('.gd'):assert before[p]['sha256']==r['candidate_sha256']and before[p]['bytes']==len(raw),('ROOT_EXACT_GD18_PATCH_REQUIRED',p)
  else:assert p.endswith('.json')and before[p]['sha256']==r['old_sha256']==old[p]['sha256']and before[p]['bytes']==old[p]['bytes'];json.loads(raw)
 assert {r['target']for r in plan['rows']}=={p for p in targets if p.endswith('.json')}
 for p,f in protected.items():assert fact(p)==f,('PROTECTED_EXTERNAL_CHANGE_KEEP_NO_ROLLBACK',p)
 dest=res(a.receipt).resolve();assert dest.is_relative_to(N.resolve())and not dest.exists();written=[]
 if a.root_authorized_apply:
  for row in plan['rows']:
   p=row['target'];assert fact(p)==before[p]and len(candidates[p])==row['candidate_bytes']and row['mechanism']=='EXACT_MECHANICAL_BYTE_COPY_NO_NORMALIZATION'
   with res(p).open('wb')as f:f.write(candidates[p])
   assert fact(p)['sha256']==targets[p]['candidate_sha256'];written.append(p)
 current={p:fact(p)for p in targets}
 for p,f in current.items():assert f['sha256']==(targets[p]['candidate_sha256']if a.root_authorized_apply or p.endswith('.gd')else targets[p]['old_sha256'])
 for p,f in protected.items():assert fact(p)==f,('PROTECTION_CHANGED_DURING_COPY',p)
 report=dict(status='ROOT_REGION_INTEGRATION32_DEPLOYED_GD18_PATCH_JSON14_EXACTCOPY'if a.root_authorized_apply else'ROOT_REGION_INTEGRATION32_GD18_NEW_JSON14_OLD_PREFLIGHT_ONLY',passed=True,stage=dict(path=a.stage,sha256=a.stage_sha256),target_count=32,target_partition=stage['target_partition'],targets=[dict(target=p,sha256=current[p]['sha256'],bytes=current[p]['bytes'],ticks=current[p]['ticks'],old_sha256=targets[p]['old_sha256'],candidate_path=targets[p]['candidate_path'],backup=old[p]['backup'])for p in targets],JSON14_written=written,GD_writes=0,backup_count=769,protected_count=len(protected),same_content_media_timestamp_refreshes=media_tick_refreshes,preserved_prior_save_differences=backup['prior_save_differences'],current_01656_backup_sha256='5d406f8866427ace84600088b30748ec8bd3d30d8ed5bcd1b170316c11b882c1',pawn_G_UI_and_native_storage_unchanged=True,Root08_Region_and_Gate_exact_integration=True,adopted_media_facts=adopted_media_facts,engine_calls=0,collector_calls=0,actual_Field_pass_claim=False,finished_utc=datetime.datetime.now(datetime.timezone.utc).isoformat())
 raw=(json.dumps(report,ensure_ascii=False,indent=2,allow_nan=False)+'\n').encode()
 with dest.open('xb')as f:f.write(raw)
 print(json.dumps(dict(path='res://'+dest.relative_to(GAME).as_posix(),sha256=sha(raw),JSON_written=len(written),targets=32)))
if __name__=='__main__':main()
