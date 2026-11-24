"""Root-only exact JSON14 transport after GD18 patch; current4160 immutable parent."""
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
 stage=load(a.stage,a.stage_sha256);assert stage['status']=='GALLERY_FAMILY_ROUTER_EXACT32_STAGED_NOT_DEPLOYED'and stage['source_first']==stage['source_final']and stage['target_partition']==dict(patch_count=18,copy_count=14,total=32)
 scope=load(S+'docks_gallery_family_repair01/current_authority20_exact32_scope_PREPARATION.json','e252869c32121af260b27d3b65fc85ce8590959035fcd47757da1675ab20a703')
 backup=load(S+'docks_gallery_family_repair01/current_authority20_backup32_ROOT_ACTUAL.json','5efc38ef1ea9f418afd9144a1db3dce773e9e5b0d9af1ac0436808f282fcceb3')
 assert backup['passed']and backup['external_save_changes']==[]and backup['total_backups']==317
 plan=load(stage['byte_copy_plan']['path'],stage['byte_copy_plan']['sha256']);assert len(plan['rows'])==14 and plan['patch_copy_disjoint']and plan['union_exact_targets']and plan['no_GD_copy_or_native_write']
 targets={r['target']:r for r in stage['targets']};old={r['target']:r for r in backup['new_backups']};assert len(targets)==32 and set(targets)==set(old)=={r['target']for r in scope['targets']}
 target_abs={res(p).resolve()for p in targets};protected={}
 def protect(p,f):
  if res(p).resolve()not in target_abs:protected[str(res(p).resolve())]=sig(f)
 for r in backup['frozen2121_current_facts']+backup['old285_backup_facts']+backup['media_facts']:protect(r['path'],r)
 for p,f in backup['save15'].items():protect(p,f)
 mask='res://build/luoyang_city_finish_20261025i_source01/docks_gallery_retirement01/isolated_ROOT_READY02/output_ROOT_READY/37092/walk_overlay.png'
 fixed=stage['nodes']['expected_ch4_s2_canal_docks_true']['value']['source_sha256'];assert fixed[mask]=='b546f989bc4a16e2dfb2a25ce91302b4382ba373ee7996dede9bff565211542a'
 for p in [mask,mask+'.import','res://.godot/imported/walk_overlay.png-9ce5987ede4d90acdf83983b51af4232.ctex']:
  f=fact(p);assert f['sha256']==fixed[p];protect(p,f)
 protect(backup['ui']['path'],backup['ui'])
 for r in backup['current33']:protect(r['target'],r['current'])
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
 report=dict(status='ROOT_GALLERY_FAMILY32_DEPLOYED_GD18_PATCH_JSON14_EXACTCOPY'if a.root_authorized_apply else'ROOT_GALLERY_FAMILY32_GD18_NEW_JSON14_OLD_PREFLIGHT_ONLY',passed=True,stage=dict(path=a.stage,sha256=a.stage_sha256),target_count=32,target_partition=stage['target_partition'],targets=[dict(target=p,sha256=current[p]['sha256'],bytes=current[p]['bytes'],ticks=current[p]['ticks'],old_sha256=targets[p]['old_sha256'],candidate_path=targets[p]['candidate_path'],backup=old[p]['backup'])for p in targets],JSON14_written=written,GD_writes=0,backup_count=317,protected_count=len(protected),current_authority20_backup_sha256='5efc38ef1ea9f418afd9144a1db3dce773e9e5b0d9af1ac0436808f282fcceb3',no_G_DT_UI_native_canonical_or_mask_pixel_write=True,Router_Root_apply_patch_and_exact13CRLF_only=True,engine_calls=0,collector_calls=0,actual_Field_pass_claim=False,finished_utc=datetime.datetime.now(datetime.timezone.utc).isoformat())
 raw=(json.dumps(report,ensure_ascii=False,indent=2,allow_nan=False)+'\n').encode()
 with dest.open('xb')as f:f.write(raw)
 print(json.dumps(dict(path='res://'+dest.relative_to(GAME).as_posix(),sha256=sha(raw),JSON_written=len(written),targets=32)))
if __name__=='__main__':main()
