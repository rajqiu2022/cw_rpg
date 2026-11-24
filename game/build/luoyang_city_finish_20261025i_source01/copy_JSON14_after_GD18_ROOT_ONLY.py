"""Root-only JSON transport after exact approved GD18 patch; never engine/GD/native writes."""
from pathlib import Path
import json,hashlib,argparse,datetime
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
 stage=load(a.stage,a.stage_sha256);assert stage['status']=='EIGHT_EXTERIORS_EXACT32_STAGED_NOT_DEPLOYED'and stage['source_first']==stage['source_final']and stage['target_partition']==dict(patch_count=18,copy_count=14,total=32)
 scope=load(S+'finish8_existing_target_scope32_PREPARATION.json','2b74b371ea336b4725a76d4b23fce46d4c1e6cd26d987c515c6791016a9c6589');backup=load(S+'immutable_current32_ROOT_EXECUTED.json','d11ebf3713b0a3fde47c335e6c37a8d367bcb7388c484efd3275e352f8e1ef1f');fresh=load(S+'fresh25i_protection_observation02.json','53f2f27efaac24701cc807c648fd0d4d38930c7905eed18fc0dd1589dddfef58')
 plan=load(stage['byte_copy_plan']['path'],stage['byte_copy_plan']['sha256']);assert len(plan['rows'])==14 and plan['patch_copy_disjoint']and plan['union_exact_targets']and plan['no_GD_copy_or_native_write']
 targets={r['target']:r for r in stage['targets']};old={r['target']:r for r in backup['rows']};assert len(targets)==32 and set(targets)==set(old)=={r['target']for r in scope['targets']}
 protected={}
 for r in fresh['groups']['current33']:
  if r['path']not in targets:protected[r['path']]=sig(r)
 for r in fresh['groups']['backups_current']+fresh['groups']['old_media_current']:protected[r['path']]=sig(r)
 for p,v in backup['save_before'].items():protected[p]=sig(v)
 ui=next(r for r in fresh['groups']['current_facts']if r['path'].replace('\\','/').endswith('/game/scripts/ui/dialog_box.gd'));protected[ui['path']]=sig(ui)
 for r in backup['rows']:
  f=fact(r['immutable_old']);assert f['sha256']==r['backup_sha256']and f['bytes']==r['before']['bytes'];protected[r['immutable_old']]=f
 for pin,pathkey in [('43289bd6757cb470cdafb955658a386b04faea0143a91d18916fd76461d798a1','res://build/luoyang_city_finish_20261025i_art01/ten_media30_promotion_ROOT_EXECUTED.json'),('aba31957cb919a94a6138b39f253c48cd390e486e989cb3ac979a36d47806d3b','res://build/luoyang_city_finish_20261025i_system01/qa_role_new/finish7_mask_media_promotion07_ROOT_ONLY/promotion_ROOT_EXECUTED.json')]:
  media=load(pathkey,pin);assert media['passed']is True
  for r in media['written']:
   p=r['path'];f=fact(p);assert f['sha256']==r['sha256']and f['bytes']==r['bytes'];protected[p]=f
 before={};candidates={}
 for p,r in targets.items():
  before[p]=fact(p);raw=res(r['candidate_path']).read_bytes();assert sha(raw)==r['candidate_sha256'];candidates[p]=raw
  if p.endswith('.gd'):assert before[p]['sha256']==r['candidate_sha256']and before[p]['bytes']==len(raw),('ROOT_EXACT_GD18_PATCH_REQUIRED',p)
  else:assert p.endswith('.json')and before[p]['sha256']==r['old_sha256']==old[p]['backup_sha256']and before[p]['bytes']==old[p]['before']['bytes'];json.loads(raw)
 assert{r['target']for r in plan['rows']}=={p for p in targets if p.endswith('.json')}
 for p,r in protected.items():assert fact(p)==r,('PROTECTED_EXTERNAL_CHANGE_KEEP_NO_ROLLBACK',p)
 dest=res(a.receipt).resolve();assert dest.is_relative_to(res(S).resolve())and not dest.exists();written=[]
 if a.root_authorized_apply:
  for row in plan['rows']:
   p=row['target'];assert fact(p)==before[p]and len(candidates[p])==row['candidate_bytes']and row['mechanism']=='EXACT_MECHANICAL_BYTE_COPY_NO_NORMALIZATION'
   with res(p).open('wb')as f:f.write(candidates[p])
   assert fact(p)['sha256']==targets[p]['candidate_sha256'];written.append(p)
 current={p:fact(p)for p in targets}
 for p,r in current.items():assert r['sha256']==(targets[p]['candidate_sha256']if a.root_authorized_apply or p.endswith('.gd')else targets[p]['old_sha256'])
 for p,r in protected.items():assert fact(p)==r,('PROTECTION_CHANGED_DURING_COPY',p)
 report=dict(status='ROOT_EXACT32_DEPLOYED_GD18_PATCH_JSON14_EXACTCOPY'if a.root_authorized_apply else'ROOT_GD18_NEW_JSON14_OLD_PREFLIGHT_ONLY',passed=True,stage=dict(path=a.stage,sha256=a.stage_sha256),stage_sha256=a.stage_sha256,target_count=32,target_partition=stage['target_partition'],targets=[dict(target=p,sha256=current[p]['sha256'],bytes=current[p]['bytes'],ticks=current[p]['ticks'],old_sha256=targets[p]['old_sha256'],candidate_path=targets[p]['candidate_path'],backup=old[p]['immutable_old'])for p in targets],JSON14_written=written,GD_writes=0,older176_and_new32_backups_preserved=True,backup_count=208,unchanged_Router_UI_save15_exactticks=True,media44_fixed_current_pre_post_exact=True,engine_calls=0,collector_calls=0,actual_Field_pass_claim=False,finished_utc=datetime.datetime.now(datetime.timezone.utc).isoformat())
 raw=(json.dumps(report,ensure_ascii=False,indent=2,allow_nan=False)+'\n').encode()
 with dest.open('xb')as f:f.write(raw)
 print(json.dumps(dict(path='res://'+dest.relative_to(GAME).as_posix(),sha256=sha(raw),JSON_written=len(written),targets=32)))
if __name__=='__main__':main()
