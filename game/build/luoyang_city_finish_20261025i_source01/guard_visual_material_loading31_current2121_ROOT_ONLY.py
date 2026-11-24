"""Read-only Root pre/post guard. No collectors, engine, backup copying or canonical writes."""
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
def signature(v):return {k:v[k]for k in ['exists','sha256','bytes','ticks']if k in v}
def main():
 ap=argparse.ArgumentParser();ap.add_argument('--stage',required=True);ap.add_argument('--stage-sha256',required=True);ap.add_argument('--deployment',required=True);ap.add_argument('--deployment-sha256',required=True);ap.add_argument('--output',required=True);a=ap.parse_args()
 backup=load(S+'family_visual_material_loading_repair01/current_F67E_backup31_ROOT_ACTUAL.json','a6996ef5cd0ce92b52d32214555e17c2394316144df1a1b12a9cfdb6ccc7e0e9')
 bundle=load(S+'family_visual_material_loading_repair01/unified31_READY01/unified32_all_candidates_and_inverse_NOT_STAGE.json','75ce628d299b772f95f05065b9cb6490106130b2aaac1e26205ebe4b5f0c78ea')
 classification=load(S+'family_visual_material_loading_repair01/backup31_baseline24_classification_READONLY.json','d37d676559fce588e402b97c262340d8ab981843f0054c68390c56007cf1b2ce');assert classification['passed'] and classification['classified_existing_F67E24']==24 and classification['unclassified_difference_count']==0
 stage=load(a.stage,a.stage_sha256);dep=load(a.deployment,a.deployment_sha256)
 assert stage['status']=='F67E_VISUAL_MATERIAL_LOADING_EXACT31_STAGED_NOT_DEPLOYED'and stage['source_first']==stage['source_final']and stage['target_partition']==dict(patch_count=17,copy_count=14,total=31)
 assert dep['status']=='ROOT_VISUAL_MATERIAL_LOADING31_DEPLOYED_GD17_PATCH_JSON14_EXACTCOPY'and dep['passed']and dep['stage']==dict(path=a.stage,sha256=a.stage_sha256)and len(dep['JSON14_written'])==14
 expected={r['target']:r for r in bundle['targets']};actual={r['target']:r for r in dep['targets']};st={r['target']:r for r in stage['targets']};assert set(expected)==set(actual)==set(st)and len(st)==31
 differences=[];checked={}
 def check(p,old,label,ignore_authorized_ticks=False):
  current=fact(p);wanted=signature(old)
  if ignore_authorized_ticks:
   current={k:v for k,v in current.items()if k!='ticks'};wanted={k:v for k,v in wanted.items()if k!='ticks'}
  if current!=wanted:differences.append(dict(path=p,group=label,expected=wanted,current=current,disposition='PRESERVED_NO_ROLLBACK'))
  checked.setdefault(label,0);checked[label]+=1
 overlay={str(res(p).resolve()):p for p in expected}
 assert len(backup['frozen2121_current_facts'])==2121
 for r in backup['frozen2121_current_facts']:
  p=overlay.get(str(res(r['path']).resolve()))
  check(r['path'],dict(exists=True,sha256=actual[p]['sha256'],bytes=actual[p]['bytes'],ticks=actual[p]['ticks'])if p else r,'current2121')
 for p,r in expected.items():
  assert actual[p]['sha256']==st[p]['candidate_sha256']==r['candidate']['sha256']and actual[p]['bytes']==r['candidate']['bytes']
  check(p,dict(exists=True,sha256=r['candidate']['sha256'],bytes=r['candidate']['bytes'],ticks=actual[p]['ticks']),'exact31')
 for p,r in backup['save15'].items():check(p,r,'save15_exactticks')
 for r in backup['old341_backup_facts']:check(r['path'],r,'old341_backups_exactticks')
 for r in backup['new_backups']:check(r['backup'],dict(exists=True,sha256=r['sha256'],bytes=r['bytes'],ticks=r['backup_ticks']),'new31_backups_exactticks')
 for r in backup['media_facts']:check(r['path'],r,'all116_media_exactticks')
 check(backup['ui']['path'],backup['ui'],'UI')
 for r in backup['current34']:
  p=r['target'];wanted=dict(exists=True,sha256=actual[p]['sha256'],bytes=actual[p]['bytes'],ticks=actual[p]['ticks'])if p in actual else r['current'];check(p,wanted,'current34_Runtime_Field_Router_Families_noop_preserved')
 maps={}
 for ident,r in bundle['maps'].items():
  node=stage['nodes'][ident];v=load(node['path'],node['sha256']);fixed=load(r['candidate']['path'],r['candidate']['sha256']);assert v==fixed and len(v['source_sha256'])==r['count'];maps[ident]=dict(path=node['path'],sha256=node['sha256'],count=r['count'])
 dest=res(a.output).resolve();assert dest.is_relative_to(N.resolve())and not dest.exists()
 report=dict(status='ROOT_VISUAL_MATERIAL_LOADING31_POST_CURRENT2121_READONLY_GUARD',passed=not differences,stage=dict(path=a.stage,sha256=a.stage_sha256),deployment=dict(path=a.deployment,sha256=a.deployment_sha256),parent_backup_sha256='a6996ef5cd0ce92b52d32214555e17c2394316144df1a1b12a9cfdb6ccc7e0e9',checked=checked,differences=differences,expected_maps=maps,backups_total=372,authorized_targets=31,extra_G_preserved=True,tasks_preexisting_1D33_preserved_not_reauthorized=True,engine_calls=0,collector_calls=0,canonical_writes=0,save_writes=0,processes_stopped=0,actual_Field_pass_claim=False,finished_utc=datetime.datetime.now(datetime.timezone.utc).isoformat())
 raw=(json.dumps(report,ensure_ascii=False,indent=2,allow_nan=False)+'\n').encode()
 with dest.open('xb')as f:f.write(raw)
 print(json.dumps(dict(path='res://'+dest.relative_to(GAME).as_posix(),sha256=sha(raw),passed=report['passed'],checked=checked,differences=len(differences))))
 if differences:raise SystemExit(1)
if __name__=='__main__':main()
