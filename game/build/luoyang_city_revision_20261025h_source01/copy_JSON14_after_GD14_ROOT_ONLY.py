"""Root-only exact JSON transport after approved GD patch. No engine or candidate generation."""
from pathlib import Path
import json,hashlib,argparse,datetime
P=Path(__file__).resolve().parent;GAME=P.parents[1]
R='res://build/luoyang_city_revision_20261025h_root01/'
S='res://build/luoyang_city_revision_20261025h_source01/'
def sha(b):return hashlib.sha256(b).hexdigest()
def res(p):return GAME/p[6:]if p.startswith('res://')else Path(p)
def load(p,h):
 b=res(p).read_bytes();assert sha(b)==h,(p,sha(b));return json.loads(b)
def fact(p):
 p=res(p)
 if not p.exists():return dict(exists=False)
 a=p.stat();h=sha(p.read_bytes());b=p.stat();assert(a.st_size,a.st_mtime_ns)==(b.st_size,b.st_mtime_ns)
 return dict(exists=True,sha256=h,bytes=b.st_size,ticks=str(b.st_mtime_ns//100+621355968000000000))
def sig(r):return {k:r[k]for k in ['exists','sha256','bytes','ticks']if k in r}
def main():
 ap=argparse.ArgumentParser();ap.add_argument('--stage',required=True);ap.add_argument('--stage-sha256',required=True);ap.add_argument('--root-authorized-apply',action='store_true');ap.add_argument('--receipt',required=True);a=ap.parse_args()
 stage=load(a.stage,a.stage_sha256);assert stage['status']=='SERVICE_GARDEN_EXACT28_STAGED_NOT_DEPLOYED'and stage['source_first']==stage['source_final']and stage['target_partition']==dict(patch_count=14,copy_count=14,total=28)
 scope=load(S+'service_garden_exact28_scope_PREPARATION.json','a249b542308b2173133d3c868980465a8b90eee7042daa9e509fdb4f3cc9a19f')
 backup=load(R+'exact28_backup_actual.json','e173e63f85e29df84edba04a6326ce54762eeddd397afc545475d8c133ff1e50')
 fresh=load(S+'fresh_current25h_READONLY.json','7b26d75eaad7d95b7d7ab33e572d0ab10c52d02e6b5e07f4ecb8609fa6ed1dcb')
 plan=load(stage['byte_copy_plan']['path'],stage['byte_copy_plan']['sha256']);assert len(plan['rows'])==14 and plan['patch_copy_disjoint']and plan['union_exact_targets']and plan['no_GD_copy_or_native_write']
 targets={r['target']:r for r in stage['targets']};old={r['target']:r for r in backup['rows']};assert len(targets)==28 and set(targets)==set(old)=={r['target']for r in scope['targets']}
 protected={}
 for r in fresh['current33_fixed_target_checks']:
  if r['target']not in targets:protected[r['target']]=sig(r['current'])
 for r in fresh['current_save_protection_start15']+fresh['backups_current148']+fresh['new_media_current8']:protected[r['path']]=sig(r)
 ui=next(r for r in fresh['current_facts']if r['path'].replace('\\','/').endswith('/game/scripts/ui/dialog_box.gd'));protected[ui['path']]=sig(ui)
 for r in backup['rows']:
  b=fact(r['backup']);assert b['sha256']==r['sha256']and b['bytes']==r['bytes']and b['ticks']==r['backup_ticks'];protected[r['backup']]=b
 before={};candidates={}
 for p,r in targets.items():
  before[p]=fact(p);raw=res(r['candidate_path']).read_bytes();assert sha(raw)==r['candidate_sha256'];candidates[p]=raw
  if p.endswith('.gd'):assert before[p]['sha256']==r['candidate_sha256']and before[p]['bytes']==len(raw),('ROOT_EXACT_GD14_APPLY_REQUIRED',p)
  else:assert p.endswith('.json')and before[p]['sha256']==r['old_sha256']==old[p]['sha256']and before[p]['bytes']==old[p]['bytes'];json.loads(raw)
 assert{r['target']for r in plan['rows']}=={p for p in targets if p.endswith('.json')}
 for p,r in protected.items():assert fact(p)==r,('PROTECTED_EXTERNAL_CHANGE_PRESERVE_NO_ROLLBACK',p)
 dest=res(a.receipt).resolve();assert dest.is_relative_to(res(R).resolve())and not dest.exists()
 written=[]
 if a.root_authorized_apply:
  for row in plan['rows']:
   p=row['target'];assert fact(p)==before[p]and len(candidates[p])==row['candidate_bytes']and row['mechanism']=='EXACT_MECHANICAL_BYTE_COPY_NO_NORMALIZATION'
   with res(p).open('wb')as stream:stream.write(candidates[p])
   assert fact(p)['sha256']==targets[p]['candidate_sha256'];written.append(p)
 current={p:fact(p)for p in targets}
 for p,r in current.items():assert r['sha256']==(targets[p]['candidate_sha256']if a.root_authorized_apply or p.endswith('.gd')else targets[p]['old_sha256'])
 for p,r in protected.items():assert fact(p)==r,('PROTECTION_CHANGED_DURING_COPY',p)
 report=dict(status='ROOT_EXACT28_DEPLOYED_GD14_PATCH_JSON14_EXACTCOPY'if a.root_authorized_apply else'ROOT_GD14_NEW_JSON14_OLD_PREFLIGHT_ONLY',passed=True,stage=dict(path=a.stage,sha256=a.stage_sha256),stage_sha256=a.stage_sha256,target_count=28,target_partition=stage['target_partition'],targets=[dict(target=p,sha256=current[p]['sha256'],bytes=current[p]['bytes'],ticks=current[p]['ticks'],old_sha256=targets[p]['old_sha256'],candidate_path=targets[p]['candidate_path'],backup=old[p]['backup'])for p in targets],JSON14_written=written,GD_writes=0,older148_and_new28_full_backups_preserved=True,backup_count=176,unchanged33_Router_UI_save15_exactticks=True,old_media8_exactticks=True,engine_calls=0,collector_calls=0,actual_Field_pass_claim=False,finished_utc=datetime.datetime.now(datetime.timezone.utc).isoformat())
 raw=(json.dumps(report,ensure_ascii=False,indent=2,allow_nan=False)+'\n').encode()
 with dest.open('xb')as stream:stream.write(raw)
 print(json.dumps(dict(path='res://'+dest.relative_to(GAME).as_posix(),sha256=sha(raw),JSON_written=len(written),targets=28)))
if __name__=='__main__':main()
