"""Root-only World4 transport/guard: GD3 must be patched by Root; only NEW JSON1 may be created here.
Protection fact/signature workflow inherited from the reviewed city33 copy/guard; no Stage/import/engine.
"""
from pathlib import Path
import argparse,datetime,hashlib,json
N=Path(__file__).resolve().parent;GAME=N.parents[1];S='res://build/luoyang_city_finish_20261025i_source01/'
W=S+'world4_READY09/';OUT=W+'outputs/root_World_visual_exact4_stage09/'
STAGE=(OUT+'receipt.json','dad0ef44403b90a3759cd8e2cfd1aff8cc331fde923b3f212da67a7ee350eb06')
PLAN=(W+'world4_ninth_head_candidates_ROOT_REVIEW.json','4dd43effab39dc8ed427cf42df0e185e9b0a99433f079bfe4bd9a77be5fb4cd6')
CITY=(S+'Estate_wall_source_repair01/Estate_wall_source31_deployed_ROOT_ACTUAL.json','47cc68861ae8165dd1517cf77787165d4f48d708faa10e587a062c3193860583')
BACK=(S+'Estate_wall_source_repair01/current_0860_backup31_ROOT_ACTUAL.json','ad48454d8798b51b1076fe1482f842373ed78cd2b96a29a7053caaa90c6a631e')
WORLD_BACK=(S+'world2_old_backup_ROOT_EXECUTED.json','73ad11107810e6abb5d61956e6e2bebc773c4e4af81e6dcfd6d53422149d729f')
MEDIA=('res://build/luoyang_city_finish_20261025i_art01/world24d_heads01/world18_ingress04/world18_media54_promotion_ROOT_EXECUTED.json','c7e9baddb6c94a1b7cd0742041c147f29eb320902eae4e0fa2ea6f4fa191a2f3')
def sha(b):return hashlib.sha256(b).hexdigest()
def res(p):return GAME/p[6:]if p.startswith('res://')else Path(p)
def load(p,h):
 b=res(p).read_bytes();assert sha(b)==h,('FIXED_METADATA_SHA',p);return json.loads(b)
def fact(p):
 p=res(p)
 if not p.exists():return dict(exists=False)
 a=p.stat();h=sha(p.read_bytes());b=p.stat();assert(a.st_size,a.st_mtime_ns)==(b.st_size,b.st_mtime_ns)
 return dict(exists=True,sha256=h,bytes=b.st_size,ticks=str(b.st_mtime_ns//100+621355968000000000))
def sig(v):return {k:v[k]for k in ['exists','sha256','bytes','ticks']if k in v}
def exactrow(r):return dict(exists=True,sha256=r['sha256'],bytes=r['bytes'],ticks=r['ticks'])
def main():
 ap=argparse.ArgumentParser();ap.add_argument('--stage-sha256',required=True);ap.add_argument('--mode',choices=['preflight','copy','guard'],required=True);ap.add_argument('--root-authorized-apply',action='store_true');ap.add_argument('--deployment');ap.add_argument('--deployment-sha256');ap.add_argument('--output',required=True);a=ap.parse_args()
 global STAGE
 assert len(a.stage_sha256)==64 and all(c in '0123456789abcdef'for c in a.stage_sha256),'EXACT_ROOT_ACTUAL_STAGE09_SHA_REQUIRED'
 STAGE=(STAGE[0],a.stage_sha256)
 assert a.root_authorized_apply==(a.mode=='copy'),'ONLY_EXPLICIT_ROOT_COPY_AUTHORIZATION'
 dest=res(a.output).resolve();assert dest.is_relative_to(N.resolve())and not dest.exists(),'NEW_OWNBUILD_RECEIPT_ONLY'
 stage=load(*STAGE);plan=load(*PLAN);city=load(*CITY);backup=load(*BACK);worldback=load(*WORLD_BACK);media=load(*MEDIA)
 assert stage['status']=='SEPARATE_WORLD_EXACT4_STAGED_NOT_DEPLOYED_NOT_RESULT'and stage['source_first']==stage['source_final']and stage['city_Stage']==plan['current_city_Stage']and stage['city_deployment']==plan['current_city_necessary_Estate_wall_source31_deployment']
 assert stage['target_partition']==dict(patch_count=3,copy_count=1,total=4)
 assert city['passed']and city['target_count']==31 and len(city['JSON14_written'])==14
 assert backup['passed']and backup['total_backups']==492 and backup['external_save_changes']==[]
 assert worldback['count']==2 and worldback['canonical_writes']==0 and media['passed']and len(media['written'])==54
 targets={r['target']:r for r in stage['targets']};declared={r['target']:r for r in plan['targets']}
 assert len(targets)==4 and set(targets)==set(declared)
 gd={p for p in targets if p.endswith('.gd')};js={p for p in targets if p.endswith('.json')};assert len(gd)==3 and len(js)==1
 copyplan=load(stage['byte_copy_plan']['path'],stage['byte_copy_plan']['sha256']);assert copyplan['GD_writes']==0 and copyplan['overwrite_existing']is False and len(copyplan['rows'])==1
 row=copyplan['rows'][0];jp=next(iter(js));assert row['target']==jp and row['mechanism']=='CREATE_NEW_EXACT_BYTES_ABSENT_ONLY'and targets[jp]['old_sha256']=='ABSENT'
 current_city={r['target']:r for r in city['targets']};target_abs={res(p).resolve()for p in targets};protected={};groups={}
 def protect(p,f,group):
  path=str(res(p).resolve());wanted=sig(f)
  if Path(path)in target_abs:return
  if path in protected:assert protected[path]==wanted,('CONFLICTING_FIXED_PROTECTION',p,group)
  protected[path]=wanted;groups[group]=groups.get(group,0)+1
 assert len(backup['frozen2121_current_facts'])==2121
 city_abs={str(res(p).resolve()):r for p,r in current_city.items()}
 for r in backup['frozen2121_current_facts']:
  cr=city_abs.get(str(res(r['path']).resolve()));protect(r['path'],exactrow(cr)if cr else r,'current2121_except_World4')
 for r in backup['old461_backup_facts']:protect(r['path'],r,'old461_backups')
 for r in backup['new_backups']:protect(r['backup'],dict(exists=True,sha256=r['sha256'],bytes=r['bytes'],ticks=r['backup_ticks']),'new31_backups')
 for p,f in backup['save15'].items():protect(p,f,'save15')
 for r in backup['media_facts']:protect(r['path'],r,'city125media')
 protect(backup['ui']['path'],backup['ui'],'UI')
 oldcity={r['target']:r['current']for r in backup['current36']}
 assert len(plan['current_city36_expected'])==36
 for r in plan['current_city36_expected']:
  p=r['target'];f=exactrow(current_city[p])if p in current_city else oldcity[p]
  assert f['sha256']==r['sha256']and f['bytes']==r['bytes'];protect(p,f,'current_city36')
 for r in media['written']:
  rp='res://'+res(r['path']).resolve().relative_to(GAME.resolve()).as_posix()
  assert stage['nodes']['expected_World_visual_sources']['value']['source_sha256'][rp]==r['sha256'];protect(r['path'],exactrow(r),'World54media')
 for r in worldback['rows']:
  f=fact(r['backup']);assert f['sha256']==r['expected_sha256']==targets[r['target']]['old_sha256']and f['bytes']==r['bytes']
  # 73AD records original source ticks, not backup ticks. Preserve today's verified backup facts; never pretend these are the original tick field.
  protect(r['backup'],f,'World2wholebackups_verified_SHA_bytes_current_ticks')
 for p,h in plan['protected_unchanged'].items():
  f=fact(p);assert f['sha256']==h,('ORIGINAL_WORLD_LAYOUT_SOURCE_WALKS',p)
  if str(res(p).resolve())not in protected:protect(p,f,'World_original_unchanged_SHA_and_boundary_ticks')
 for p,f in protected.items():assert fact(p)==f,('PROTECTED_EXTERNAL_CHANGE_KEEP_NO_ROLLBACK',p)
 raw_candidates={};before={}
 for p,r in targets.items():
  d=declared[p];b=res(r['candidate_path']).read_bytes();assert sha(b)==r['candidate_sha256']==d['candidate']['sha256']and len(b)==d['candidate']['bytes']and r['old_sha256']==d['old_sha256'];raw_candidates[p]=b;before[p]=fact(p)
  if p in gd:assert before[p]['exists']and before[p]['sha256']==r['candidate_sha256']and before[p]['bytes']==len(b),('ROOT_GD3_APPLY_PATCH_FIRST',p)
  elif a.mode!='guard':assert before[p]==dict(exists=False),'NEW_MANIFEST_MUST_REMAIN_ABSENT_BEFORE_COPY'
  else:assert before[p]['exists']and before[p]['sha256']==r['candidate_sha256']and before[p]['bytes']==len(b)
 assert len(raw_candidates[jp])==row['candidate_bytes'];json.loads(raw_candidates[jp])
 dep=None
 if a.mode=='guard':
  assert a.deployment and a.deployment_sha256;dep=load(a.deployment,a.deployment_sha256)
  assert dep['passed']and dep['status']=='ROOT_WORLD4_GD3_PATCH_NEW_JSON1_DEPLOYED_NOT_FIELD_RESULT'and dep['stage']==dict(path=STAGE[0],sha256=STAGE[1])and dep['city_deployment']==dict(path=CITY[0],sha256=CITY[1])and dep['JSON1_written']==[jp]
  assert set(dep['protection_first'])==set(protected)
  for p,f in dep['protection_first'].items():assert fact(p)==f,('POST_DEPLOY_EXACT_PROTECTION',p)
  actual={r['target']:r for r in dep['targets']};assert set(actual)==set(targets)
  for p,r in actual.items():assert fact(p)==exactrow(r)and r['sha256']==targets[p]['candidate_sha256']
 written=[]
 if a.mode=='copy':
  assert fact(jp)==dict(exists=False)
  res(jp).parent.mkdir(parents=True,exist_ok=True)
  with res(jp).open('xb')as f:f.write(raw_candidates[jp])
  written=[jp]
 current={p:fact(p)for p in targets}
 for p,f in current.items():
  assert f==dict(exists=False)if a.mode=='preflight'and p==jp else f['sha256']==targets[p]['candidate_sha256']and f['bytes']==len(raw_candidates[p])
 for p,f in protected.items():assert fact(p)==f,('PROTECTION_CHANGED_DURING_ROOT_TOOL',p)
 expected=load(stage['nodes']['expected_World_visual_sources']['path'],stage['nodes']['expected_World_visual_sources']['sha256'])
 assert expected['source_sha256']==stage['nodes']['expected_World_visual_sources']['value']['source_sha256']and len(expected['source_sha256'])==88
 for p,h in expected['source_sha256'].items():
  if a.mode=='preflight'and p==jp:continue
  assert fact(p)['sha256']==h,('WORLD88_FIXED_SOURCE',p)
 report=dict(status='ROOT_WORLD4_GD3_PATCH_NEW_JSON1_DEPLOYED_NOT_FIELD_RESULT'if a.mode=='copy'else'ROOT_WORLD4_POST_READONLY_GUARD'if a.mode=='guard'else'ROOT_WORLD4_GD3_PATCH_NEW_JSON1_ABSENT_PREFLIGHT',passed=True,stage=dict(path=STAGE[0],sha256=STAGE[1]),city_deployment=dict(path=CITY[0],sha256=CITY[1]),target_count=4,target_partition=stage['target_partition'],targets=[dict(target=p,**{k:v for k,v in f.items()if k!='exists'},old_sha256=targets[p]['old_sha256'],candidate_path=targets[p]['candidate_path'])for p,f in current.items()],JSON1_written=written,GD_writes=0,canonical_JSON_writes=len(written),city_writes=0,engine_calls=0,import_calls=0,Stage_calls=0,collector_calls=0,backups_copied=0,city_backups=492,World_old_backups=2,protection_first=protected,protection_final=protected,protection_groups=groups,World_expected_map=dict(path=stage['nodes']['expected_World_visual_sources']['path'],sha256=stage['nodes']['expected_World_visual_sources']['sha256'],count=88),actual_World_Field_pass=False,whole_city_ART_pass=False,finished_utc=datetime.datetime.now(datetime.timezone.utc).isoformat())
 if dep:report['deployment']=dict(path=a.deployment,sha256=a.deployment_sha256)
 b=(json.dumps(report,ensure_ascii=False,indent=2,allow_nan=False)+'\n').encode()
 with dest.open('xb')as f:f.write(b)
 print(json.dumps(dict(path='res://'+dest.relative_to(GAME).as_posix(),sha256=sha(b),passed=True,mode=a.mode,JSON_written=len(written),protected=len(protected))))
if __name__=='__main__':main()
