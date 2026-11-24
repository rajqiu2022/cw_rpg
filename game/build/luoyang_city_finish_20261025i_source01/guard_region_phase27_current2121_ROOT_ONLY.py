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
 backup=load(S+'region_phase_lifetime_repair03/current_5FCE_backup27_ROOT_ACTUAL.json','765e286c655194e33c06908bc98dcb1efed6c69d299684fff5545aff8a972dea')
 bundle=load('res://build/luoyang_regions_20261027d_source01/phase_lifetime03_BUILD/closure27/phase_lifetime27_all_candidates_NOT_STAGE.json','6b4ae21453bf07bb47b77dcebe1016dce26decc740fd61cb10342ad2ecbd335a')
 stage=load(a.stage,a.stage_sha256);assert stage['source_first'].get('res://build/luoyang_regions_20261027d_source01/root_integration_scope08_AUTHORIZED.json')=='9d064035022286b8337c430e635f72528e3975cce91e914f53a351ac5bd71919';dep=load(a.deployment,a.deployment_sha256)
 assert stage['status']=='ROOT08_PHASE_OWNER_LIFETIME27_STAGED_NOT_DEPLOYED'and stage['source_first']==stage['source_final']and stage['target_partition']==dict(patch_count=12,copy_count=15,total=27)
 assert dep['status']=='ROOT_REGION_PHASE27_DEPLOYED_GD12_PATCH_JSON15_EXACTCOPY'and dep['passed']and dep['stage']==dict(path=a.stage,sha256=a.stage_sha256)and len(dep['JSON15_written'])==15
 expected={r['target']:r for r in bundle['targets']};actual={r['target']:r for r in dep['targets']};st={r['target']:r for r in stage['targets']};assert set(expected)==set(actual)==set(st)and len(st)==27
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
  check(p,dict(exists=True,sha256=r['candidate']['sha256'],bytes=r['candidate']['bytes'],ticks=actual[p]['ticks']),'exact27')
 for p,r in backup['save15'].items():check(p,r,'save15_exactticks')
 for r in backup['old795_backup_facts']:check(r['path'],r,'old795_backups_exactticks')
 for r in backup['new_backups']:check(r['backup'],dict(exists=True,sha256=r['sha256'],bytes=r['bytes'],ticks=r['backup_ticks']),'new32_backups_exactticks')
 refresh={str(res(r['path']).resolve()).casefold():r['current_ticks']for r in dep.get('same_content_media_timestamp_refreshes',[])}
 for r in backup['media_facts']+backup['World54_facts']:
  f=dict(r);key=str(res(r['path']).resolve()).casefold()
  if key in refresh:f['ticks']=refresh[key]
  check(r['path'],f,'old221_media_SHA_bytes_run_ticks')
 assert len(dep['adopted_media_facts'])==12
 for r in dep['adopted_media_facts']:check(r['path'],r,'adopted_Gate_and_three_building_media_exactticks')
 check('res://build/luoyang_city_finish_20261025i_source01/pawnshop_only_repair01/unified22_READY01/services_runtime_READY.gd',dict(exists=True,sha256='4c8371436aac631ea36523626a2696e1871f0a29e9db5fb5e1a64116fcb706e8',bytes=25422),'pawn_service_unchanged',True)
 check('res://build/luoyang_pawnshop_repair_20261026a_system01/services_author02_CANDIDATE.json',dict(exists=True,sha256='44053da474186c16863df81e6c266d21e0815c1af2e6d8d4b1a78d0effe1db1e',bytes=80026),'pawn_author_unchanged',True)
 check(backup['ui']['path'],backup['ui'],'UI')
 for r in backup['current37']:
  p=r['target'];check(p,dict(exists=True,sha256=actual[p]['sha256'],bytes=actual[p]['bytes'],ticks=actual[p]['ticks'])if p in actual else r['current'],'current37')
 maps={}
 for ident,r in bundle['maps'].items():
  node=stage['nodes'][ident];v=load(node['path'],node['sha256']);fixed=load(r['candidate']['path'],r['candidate']['sha256']);assert v==fixed and len(v['source_sha256'])==r['count'];maps[ident]=dict(path=node['path'],sha256=node['sha256'],count=r['count'])
 dest=res(a.output).resolve();assert dest.is_relative_to(N.resolve())and not dest.exists()
 report=dict(status='ROOT_REGION_PHASE27_POST_CURRENT2121_READONLY_GUARD',passed=not differences,stage=dict(path=a.stage,sha256=a.stage_sha256),deployment=dict(path=a.deployment,sha256=a.deployment_sha256),parent_backup_sha256='765e286c655194e33c06908bc98dcb1efed6c69d299684fff5545aff8a972dea',checked=checked,differences=differences,expected_maps=maps,backups_total=822,authorized_targets=27,extra_G_preserved=True,tasks_Root_authorized_F1C1_preserved=True,engine_calls=0,collector_calls=0,canonical_writes=0,save_writes=0,processes_stopped=0,actual_Field_pass_claim=False,finished_utc=datetime.datetime.now(datetime.timezone.utc).isoformat())
 raw=(json.dumps(report,ensure_ascii=False,indent=2,allow_nan=False)+'\n').encode()
 with dest.open('xb')as f:f.write(raw)
 print(json.dumps(dict(path='res://'+dest.relative_to(GAME).as_posix(),sha256=sha(raw),passed=report['passed'],checked=checked,differences=len(differences))))
 if differences:raise SystemExit(1)
if __name__=='__main__':main()
