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
 backup=load(S+'visible_doors_boundaries33_repair01/current_signed31_backup33_ROOT_ACTUAL.json','2b2be04ce2ee27e8f9d6782181a5f6999921a416ada094b9cafadb043742bff3')
 bundle=load(S+'visible_doors_boundaries33_repair01/unified33_READY02/unified33_ROOT_BACKUP_FIXED_NOT_STAGE.json','86282dad5be672f76cb54f383e32a2c4e2a12fe3aad2377c65eade7c59e6e4c9')
 assert backup['passed'] and backup['total_backups']==436 and backup['external_save_changes']==[]
 assert len(backup['differences'])==1
 authorized=backup['differences'][0]
 assert authorized['path'].replace('\\','/').casefold().endswith('/prompts/tasks.yaml') and authorized['expected']['sha256']=='1d337a0c8f9b220f0d36cf7ff87e50159d59f468bc0f39c4a3f6927f3de976b7' and authorized['expected']['bytes']==786954 and authorized['current']['sha256']=='f1c19ee105a114ef1878219c4834afc0b5f1ce04859eaae9498370fee2db8b3f' and authorized['current']['bytes']==790177
 stage=load(a.stage,a.stage_sha256);dep=load(a.deployment,a.deployment_sha256)
 assert stage['status']=='CURRENT_SIGNED31_VISIBLE_DOORS_BOUNDARIES_EXACT33_STAGED_NOT_DEPLOYED'and stage['source_first']==stage['source_final']and stage['target_partition']==dict(patch_count=18,copy_count=15,total=33)
 assert dep['status']=='ROOT_VISIBLE_DOORS_BOUNDARIES33_DEPLOYED_GD18_PATCH_JSON15_EXACTCOPY'and dep['passed']and dep['stage']==dict(path=a.stage,sha256=a.stage_sha256)and len(dep['JSON15_written'])==15
 supplement=load(S+'visible_doors_boundaries33_repair01/additional_trial02_gate_for_DC81_READONLY.json','056a5840b250d12767ca66d90a90baa0393bed06f5761fe122f7876a8680773f')
 assert supplement['passed'] and supplement['stage']==dict(path=a.stage,sha256=a.stage_sha256) and supplement['new_authorization_basis']==dict(path=S+'finish8_ROOT_TRIAL_PERMISSION02.json',sha256='7bcb3165485026f4ff2c15ebb0dfa696c6780ed2cad238933201f715abdca82a')
 expected={r['target']:r for r in bundle['targets']};actual={r['target']:r for r in dep['targets']};st={r['target']:r for r in stage['targets']};assert set(expected)==set(actual)==set(st)and len(st)==33
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
  check(p,dict(exists=True,sha256=r['candidate']['sha256'],bytes=r['candidate']['bytes'],ticks=actual[p]['ticks']),'exact33')
 for p,r in backup['save15'].items():check(p,r,'save15_exactticks')
 for r in backup['old403_backup_facts']:check(r['path'],r,'old403_backups_exactticks')
 for r in backup['new_backups']:check(r['backup'],dict(exists=True,sha256=r['sha256'],bytes=r['bytes'],ticks=r['backup_ticks']),'new33_backups_exactticks')
 for r in backup['media_facts']:check(r['path'],r,'all125_media_exactticks')
 check(backup['ui']['path'],backup['ui'],'UI')
 for r in backup['current34']:
  p=r['target'];wanted=dict(exists=True,sha256=actual[p]['sha256'],bytes=actual[p]['bytes'],ticks=actual[p]['ticks'])if p in actual else r['current'];check(p,wanted,'current34_Runtime_Field_Router_Families_noop_preserved')
 maps={}
 for ident,r in bundle['maps'].items():
  node=stage['nodes'][ident];v=load(node['path'],node['sha256']);fixed=load(r['candidate']['path'],r['candidate']['sha256']);assert v==fixed and len(v['source_sha256'])==r['count'];maps[ident]=dict(path=node['path'],sha256=node['sha256'],count=r['count'])
 dest=res(a.output).resolve();assert dest.is_relative_to(N.resolve())and not dest.exists()
 report=dict(status='ROOT_VISIBLE_DOORS_BOUNDARIES33_POST_CURRENT2121_READONLY_GUARD',passed=not differences,stage=dict(path=a.stage,sha256=a.stage_sha256),deployment=dict(path=a.deployment,sha256=a.deployment_sha256),parent_backup_sha256='2b2be04ce2ee27e8f9d6782181a5f6999921a416ada094b9cafadb043742bff3',checked=checked,differences=differences,expected_maps=maps,backups_total=436,authorized_targets=33,extra_G_preserved=True,tasks_Root_authorized_F1C1_790177_preserved=True,engine_calls=0,collector_calls=0,canonical_writes=0,save_writes=0,processes_stopped=0,actual_Field_pass_claim=False,finished_utc=datetime.datetime.now(datetime.timezone.utc).isoformat())
 raw=(json.dumps(report,ensure_ascii=False,indent=2,allow_nan=False)+'\n').encode()
 with dest.open('xb')as f:f.write(raw)
 print(json.dumps(dict(path='res://'+dest.relative_to(GAME).as_posix(),sha256=sha(raw),passed=report['passed'],checked=checked,differences=len(differences))))
 if differences:raise SystemExit(1)
if __name__=='__main__':main()
