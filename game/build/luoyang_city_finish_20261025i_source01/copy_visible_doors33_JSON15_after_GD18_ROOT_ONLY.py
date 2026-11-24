"""Root-only exact JSON15 transport after GD18 patch; signed31 immutable parent."""
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
 stage=load(a.stage,a.stage_sha256);assert stage['status']=='CURRENT_SIGNED31_VISIBLE_DOORS_BOUNDARIES_EXACT33_STAGED_NOT_DEPLOYED'and stage['source_first']==stage['source_final']and stage['target_partition']==dict(patch_count=18,copy_count=15,total=33)
 supplement=load(S+'visible_doors_boundaries33_repair01/additional_trial02_gate_for_DC81_READONLY.json','056a5840b250d12767ca66d90a90baa0393bed06f5761fe122f7876a8680773f')
 assert supplement['passed'] and supplement['stage']==dict(path=a.stage,sha256=a.stage_sha256) and supplement['new_authorization_basis']==dict(path=S+'finish8_ROOT_TRIAL_PERMISSION02.json',sha256='7bcb3165485026f4ff2c15ebb0dfa696c6780ed2cad238933201f715abdca82a')
 scope=load(S+'visible_doors_boundaries33_repair01/closure_READY01/current_signed31_exact33_scope_PREPARATION.json','0bf33b2c8c103d44a1db7e7056bb56b049a0327f0c9d62087848172c97397efa')
 backup=load(S+'visible_doors_boundaries33_repair01/current_signed31_backup33_ROOT_ACTUAL.json','2b2be04ce2ee27e8f9d6782181a5f6999921a416ada094b9cafadb043742bff3')
 assert backup['passed']and backup['external_save_changes']==[]and backup['total_backups']==436
 plan=load(stage['byte_copy_plan']['path'],stage['byte_copy_plan']['sha256']);assert len(plan['rows'])==15 and plan['patch_copy_disjoint']and plan['union_exact_targets']and plan['no_GD_copy_or_native_write']
 targets={r['target']:r for r in stage['targets']};old={r['target']:r for r in backup['new_backups']};assert len(targets)==33 and set(targets)==set(old)=={r['target']for r in scope['targets']}
 target_abs={res(p).resolve()for p in targets};protected={}
 def protect(p,f):
  if res(p).resolve()not in target_abs:protected[str(res(p).resolve())]=sig(f)
 for r in backup['frozen2121_current_facts']+backup['old403_backup_facts']+backup['media_facts']:protect(r['path'],r)
 for p,f in backup['save15'].items():protect(p,f)
 protect(backup['ui']['path'],backup['ui'])
 for r in backup['current34']:protect(r['target'],r['current'])
 for r in backup['new_backups']:
  f=fact(r['backup']);assert f['sha256']==r['sha256']and f['bytes']==r['bytes']and f['ticks']==r['backup_ticks'];protect(r['backup'],f)
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
 report=dict(status='ROOT_VISIBLE_DOORS_BOUNDARIES33_DEPLOYED_GD18_PATCH_JSON15_EXACTCOPY'if a.root_authorized_apply else'ROOT_VISIBLE_DOORS_BOUNDARIES33_GD18_NEW_JSON15_OLD_PREFLIGHT_ONLY',passed=True,stage=dict(path=a.stage,sha256=a.stage_sha256),target_count=33,target_partition=stage['target_partition'],targets=[dict(target=p,sha256=current[p]['sha256'],bytes=current[p]['bytes'],ticks=current[p]['ticks'],old_sha256=targets[p]['old_sha256'],candidate_path=targets[p]['candidate_path'],backup=old[p]['backup'])for p in targets],JSON15_written=written,GD_writes=0,backup_count=436,protected_count=len(protected),current_signed31_backup_sha256='2b2be04ce2ee27e8f9d6782181a5f6999921a416ada094b9cafadb043742bff3',no_G_DT_UI_native_or_mask_pixel_write=True,Router_unchanged=True,engine_calls=0,collector_calls=0,actual_Field_pass_claim=False,finished_utc=datetime.datetime.now(datetime.timezone.utc).isoformat())
 raw=(json.dumps(report,ensure_ascii=False,indent=2,allow_nan=False)+'\n').encode()
 with dest.open('xb')as f:f.write(raw)
 print(json.dumps(dict(path='res://'+dest.relative_to(GAME).as_posix(),sha256=sha(raw),JSON_written=len(written),targets=33)))
if __name__=='__main__':main()
