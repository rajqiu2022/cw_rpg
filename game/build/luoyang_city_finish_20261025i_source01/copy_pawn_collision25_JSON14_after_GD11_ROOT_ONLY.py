"""Root-only exact JSON14 transport after GD11 patch; current9C1245 parent; only exact-pawn Field local nine-base collider bridge and necessary pins."""
from pathlib import Path
import argparse,json,hashlib,datetime
N=Path(__file__).resolve().parent;GAME=N.parents[1];S='res://build/luoyang_city_finish_20261025i_source01/'
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
 stage=load(a.stage,a.stage_sha256);assert stage['source_first'].get(S+'pawnshop_collision_repair01/current_9C1245_backup25_ROOT_ACTUAL.json')=='50fe87abfd647b11f7dacbc5863bc294ddde389579a2b1099958ca25b3c89bf0';assert stage['status']=='PAWN_LOCAL_COLLISION_EXACT25_STAGED_NOT_DEPLOYED'and stage['source_first']==stage['source_final']and stage['target_partition']==dict(patch_count=11,copy_count=14,total=25)
 scope=load(S+'pawnshop_collision_repair01/current_9C1245_exact25_scope_PREPARATION.json','f1d6bfa254e836a901c3131010009328bf3e77931d7fe1bef53040f55c2b4304')
 backup=load(S+'pawnshop_collision_repair01/current_9C1245_backup25_ROOT_ACTUAL.json','50fe87abfd647b11f7dacbc5863bc294ddde389579a2b1099958ca25b3c89bf0')
 assert backup['passed']and backup['external_save_changes']==[]and backup['total_backups']==539
 plan=load(stage['byte_copy_plan']['path'],stage['byte_copy_plan']['sha256']);assert len(plan['rows'])==14 and plan['patch_copy_disjoint']and plan['union_exact_targets']and plan['no_GD_copy_or_native_write']
 targets={r['target']:r for r in stage['targets']};old={r['target']:r for r in backup['new_backups']};assert len(targets)==25 and set(targets)==set(old)=={r['target']for r in scope['targets']}
 target_abs={res(p).resolve()for p in targets};protected={}
 def protect(p,f):
  if res(p).resolve()not in target_abs:protected[str(res(p).resolve())]=sig(f)
 fixedplan=load(S+'pawnshop_collision_repair01/current_9C1245_backup25_ROOT_PLAN.json','ecfbed6312a30eae6f7cd78bea3f975a8cf5e5058ad306babf4c027188e24f16')
 for r in backup['frozen2121_current_facts']+backup['old514_backup_facts']+backup['media_facts']+fixedplan['World54']:protect(r['path'],r)
 for p,f in backup['save15'].items():protect(p,f)
 protect(backup['ui']['path'],backup['ui'])
 for r in backup['current37']:protect(r['target'],r['current'])
 for r in backup['new_backups']:
  f=fact(r['backup']);assert f['sha256']==r['sha256']and f['bytes']==r['bytes']and f['ticks']==r['backup_ticks'];protect(r['backup'],f)
 before={};candidates={}
 for p,r in targets.items():
  before[p]=fact(p);raw=res(r['candidate_path']).read_bytes();assert sha(raw)==r['candidate_sha256'];candidates[p]=raw
  if p.endswith('.gd'):assert before[p]['sha256']==r['candidate_sha256']and before[p]['bytes']==len(raw),('ROOT_EXACT_GD11_PATCH_REQUIRED',p)
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
 report=dict(status='ROOT_PAWN_LOCAL_BODIES25_DEPLOYED_GD11_PATCH_JSON14_EXACTCOPY'if a.root_authorized_apply else'ROOT_PAWN_LOCAL_BODIES25_GD11_NEW_JSON14_OLD_PREFLIGHT_ONLY',passed=True,stage=dict(path=a.stage,sha256=a.stage_sha256),target_count=25,target_partition=stage['target_partition'],targets=[dict(target=p,sha256=current[p]['sha256'],bytes=current[p]['bytes'],ticks=current[p]['ticks'],old_sha256=targets[p]['old_sha256'],candidate_path=targets[p]['candidate_path'],backup=old[p]['backup'])for p in targets],JSON14_written=written,GD_writes=0,backup_count=539,protected_count=len(protected),current_9C1245_backup_sha256='50fe87abfd647b11f7dacbc5863bc294ddde389579a2b1099958ca25b3c89bf0',no_G_DT_Router_UI_native_geometry_mask_changes=True,engine_calls=0,collector_calls=0,actual_Field_pass_claim=False,finished_utc=datetime.datetime.now(datetime.timezone.utc).isoformat())
 raw=(json.dumps(report,ensure_ascii=False,indent=2,allow_nan=False)+'\n').encode()
 with dest.open('xb')as f:f.write(raw)
 print(json.dumps(dict(path='res://'+dest.relative_to(GAME).as_posix(),sha256=sha(raw),JSON_written=len(written),targets=25)))
if __name__=='__main__':main()
