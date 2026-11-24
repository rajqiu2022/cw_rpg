"""Reuse currentCE38 full31 plus Router Root backup transport; no backup, Stage or engine execution."""
from pathlib import Path
import json,hashlib
N=Path(__file__).resolve().parent;GAME=N.parents[1];S='res://build/luoyang_city_finish_20261025i_source01/';P=S+'garden_estate_exit_repair_20261027c01/';O=N/'garden_estate_exit_repair_20261027c01'
sha=lambda b:hashlib.sha256(b).hexdigest();enc=lambda v:(json.dumps(v,ensure_ascii=False,indent=2,allow_nan=False)+'\n').encode('utf8')
def load(p,h):
 b=(GAME/p[6:]).read_bytes();assert sha(b)==h,(p,sha(b));return json.loads(b)
def emit(name,b):
 d=O/name;assert not d.exists();d.parent.mkdir(parents=True,exist_ok=True)
 with d.open('xb')as f:f.write(b)
 return dict(path=P+name,sha256=sha(b),bytes=len(b))
dep_pin=dict(path=S+'exit_wall_repair_20261027b01/exit_wall31_deployed_ROOT_ACTUAL.json',sha256='ce38ef86b2c171ef3f323f2285f81cea569911f9d873f221105054d2ba92ba27');dep=load(dep_pin['path'],dep_pin['sha256'])
headpin=dict(path=S+'exit_wall_repair_20261027b01/unified31_READY01/unified32_all_candidates_and_inverse_NOT_STAGE.json',sha256='02f60be34643cbe2d62278dcd85b97ea8798e0874edadf6eb314bc2533df9899');head=load(headpin['path'],headpin['sha256'])
back=load(S+'exit_wall_repair_20261027b01/current_81C_backup31_ROOT_ACTUAL.json','50361a4002319918b2afc17a7f4e65ea4593fec72a1812af4d384e707eb4e567')
refs={r['target']:r['candidate']for r in head['targets']};router=next(r for r in back['current37']if r['target']=='res://scripts/autoload/scene_router.gd');refs[router['target']]=dict(path=router['immutable_candidate'],sha256=router['sha256'],bytes=router['bytes'])
rows=[]
for p,c in refs.items():
 b=(GAME/c['path'][6:]).read_bytes();assert sha(b)==c['sha256']and len(b)==c['bytes']and (GAME/p[6:]).read_bytes()==b,p
 rows.append(dict(target=p,immutable_old=c['path'],old_sha256=c['sha256'],old_bytes=c['bytes'],backup=P+'root_only_current32_backup/'+p[6:]))
assert len(rows)==32 and sum(r['target'].endswith('.gd')for r in rows)==18
scope=emit('current_CE38_exact32_scope_PREPARATION.json',enc(dict(status='CURRENT_CE38_GARDEN_ISOLATED_WALL_AND_COLD_ESTATE_SCOPE_NOT_SEALED',count=32,partition=dict(GD=18,JSON=14),parent_stage=dep['stage'],parent_deployment=dep_pin,parent_descriptor=headpin,targets=rows,content_pending=['Garden_remove_one_wall_one_ground_polygon_local_mask','Router_exact_Garden_to_Estate_independent_begin_finish'],candidate_EOF_single_LF=True,G_pawnshop_and_other_seven_payloads_unchanged=True,canonical_writes=0,engine_calls=0)))
facts={r['path']:{k:v for k,v in r.items()if k!='path'}for r in back['frozen2121_current_facts']};written={r['target']:r for r in dep['targets']};absolute={str((GAME/p[6:]).resolve()).casefold():r for p,r in written.items()}
for p in facts:
 k=str((GAME/p[6:]if p.startswith('res://')else Path(p)).resolve()).casefold()
 if k in absolute:
  r=absolute[k];facts[p]=dict(exists=True,sha256=r['sha256'],bytes=r['bytes'],ticks=r['ticks'])
current=[]
for r in back['current37']:
 v={k:x for k,x in r.items()if k!='current'}
 if v['target']in written:
  w=written[v['target']];v.update(sha256=w['sha256'],bytes=w['bytes'])
 current.append(v)
oldbacks=back['old674_backup_facts']+[dict(path=r['backup'],exists=True,sha256=r['sha256'],bytes=r['bytes'],ticks=r['backup_ticks'])for r in back['new_backups']];assert len(oldbacks)==705
pub=load('res://build/luoyang_exit_wall_fix_20261027b_system01/ROOT_READY01/output/108580/result.json','8f14b9bf11ce635fe037e3cb9689a59052bbc04653dc6861bd99740375d7fb2e')
promotion=load('res://build/luoyang_exit_wall_fix_20261027b_system01/mask_import01_ROOT_ONLY/promotion_ROOT_EXECUTED.json','88dd999c0b68d792bb0fb2763e36048a5955eb339517ea51e453436e2a5744de')
media=list(back['media_facts']);mr=pub['components']['ch4_s3_luoyang_market']['mask'];newmedia=[dict(path=mr['path'],sha256=mr['sha256'])]+[{k:r[k]for k in ['path','sha256','bytes']}for r in promotion['written']]
for r in newmedia:
 p=GAME/r['path'][6:];a=p.stat();b=p.read_bytes();z=p.stat();assert sha(b)==r['sha256']and (a.st_size,a.st_mtime_ns)==(z.st_size,z.st_mtime_ns)
 if 'bytes'in r:assert len(b)==r['bytes']
 media.append(dict(path=r['path'],exists=True,sha256=r['sha256'],bytes=len(b),ticks=str(z.st_mtime_ns//100+621355968000000000)))
assert len(media)==152
plan=emit('current_CE38_backup32_ROOT_PLAN.json',enc(dict(status='ROOT_ONLY_CURRENT_CE38_CREATE_NEW32_BACKUP_PLAN_NOT_EXECUTED',scope=scope,parent_deployment=dep_pin,current32=rows,current37=current,frozen2121_expected=facts,prior_save15=back['save15'],old705_backup_facts=oldbacks,media152=media,World54=back['World54_facts'],ui=back['ui'],Root_only_backup_prefix=P+'root_only_current32_backup/',expected_old_backup_total=705,expected_after_backup_total=737,media_timestamp_policy='FIXED_SHA_BYTES_REQUIRED_CAPTURE_CURRENT_TICKS_AT_ROOT_EXECUTION_NEVER_RESTORE_OLD_MTIME',canonical_writes=0,engine_calls=0)))
parent=(N/'exit_wall_repair_20261027b01/backup_current_81C_31_ROOT_ONLY.py').read_bytes();assert sha(parent)=='ecbd165f95b4081475c33dac9870d448da7445de5bae0f25b3c2b469020dcfe2';t=parent.decode('utf8')
for a,b in [('CreateNew31','CreateNew32'),('exit_wall_repair_20261027b01/current_81C_backup31_ROOT_PLAN.json','garden_estate_exit_repair_20261027c01/current_CE38_backup32_ROOT_PLAN.json'),('root-authorized-backup31','root-authorized-backup32'),('root_authorized_backup31','root_authorized_backup32'),('old674_backup_facts','old705_backup_facts'),("plan['current31']","plan['current32']"),('NEW31_BACKUP','NEW32_BACKUP'),('ROOT_CURRENT_81C_FULL31_BACKUP_AND_FRESH_OBSERVATION','ROOT_CURRENT_CE38_FULL32_BACKUP_AND_FRESH_OBSERVATION'),('ROOT_CURRENT_81C_FRESH_OBSERVATION_ONLY','ROOT_CURRENT_CE38_FRESH_OBSERVATION_ONLY'),('current31=','current32='),('total_backups=674+len(rows)','total_backups=705+len(rows)'),('media149','media152'),('fresh_media[:149]','fresh_media[:152]'),('fresh_media[149:]','fresh_media[152:]')]:
 assert a in t,a;t=t.replace(a,b)
compile(t,'backup_current_CE38_32_ROOT_ONLY.py','exec');tool=emit('backup_current_CE38_32_ROOT_ONLY.py',t.encode('utf8'))
print(json.dumps(dict(scope=scope,plan=plan,tool=tool,old_backups=705,new_backups_if_Root_executes=32,total_if_Root_executes=737,execution_calls=0)))
