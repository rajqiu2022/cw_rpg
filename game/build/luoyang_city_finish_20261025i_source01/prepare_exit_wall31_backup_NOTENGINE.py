"""Reuse current fresh-save/media Root backup transport for one current81C31 scope; no execution."""
from pathlib import Path
import json,hashlib
N=Path(__file__).resolve().parent;GAME=N.parents[1];S='res://build/luoyang_city_finish_20261025i_source01/';P=S+'exit_wall_repair_20261027b01/';O=N/'exit_wall_repair_20261027b01'
sha=lambda b:hashlib.sha256(b).hexdigest();enc=lambda v:(json.dumps(v,ensure_ascii=False,indent=2,allow_nan=False)+'\n').encode('utf8')
def load(p,h):
 b=(GAME/p[6:]).read_bytes();assert sha(b)==h,(p,sha(b));return json.loads(b)
def emit(name,b):
 d=O/name;assert not d.exists()
 with d.open('xb')as f:f.write(b)
 return dict(path=P+name,sha256=sha(b),bytes=len(b))
scopepin=dict(path=P+'current_81C_exact31_scope_PREPARATION.json',sha256='bb8f69b611461f35f10a32caf6486d658f14c2c406f83adb61dd18be9e2359c7');scope=load(scopepin['path'],scopepin['sha256'])
dep=load(scope['parent_deployment']['path'],scope['parent_deployment']['sha256'])
back=load(S+'Field_EOF_adoption01/current_E370_backup24plus2_ROOT_ACTUAL02.json','3018ee4d5fab88bd28266fd21fcce82dfd3b3600087ba0c6ff06d988b4c5b590')
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
oldbacks=back['old648_backup_facts']+[dict(path=r['backup'],exists=True,sha256=r['sha256'],bytes=r['bytes'],ticks=r['backup_ticks'])for r in back['new_backups']+back['adoption_backups']];assert len(oldbacks)==674
plan=dict(status='ROOT_ONLY_CURRENT_81C_CREATE_NEW31_BACKUP_PLAN_NOT_EXECUTED',scope=scopepin,parent_deployment=scope['parent_deployment'],current31=scope['targets'],current37=current,frozen2121_expected=facts,prior_save15=back['save15'],old674_backup_facts=oldbacks,media149=back['media_facts'],World54=back['World54_facts'],ui=back['ui'],Root_only_backup_prefix=P+'root_only_current31_backup/',expected_old_backup_total=674,expected_after_backup_total=705,media_timestamp_policy='FIXED_SHA_BYTES_REQUIRED_CAPTURE_CURRENT_TICKS_AT_ROOT_EXECUTION_NEVER_RESTORE_OLD_MTIME',canonical_writes=0,engine_calls=0)
pp=emit('current_81C_backup31_ROOT_PLAN.json',enc(plan))
parent=(N/'Field_EOF_adoption01/backup_current_E370_24plus2_ROOT_ONLY02.py').read_bytes();assert sha(parent)=='db8e6d64d270e7bbe8e61a7e90ede0c83262e75210a503b8f54136d476eca05d';t=parent.decode('utf8')
for a,b in [
 ('CreateNew24 plus2 Field snapshots','CreateNew31'),('Field_EOF_adoption01/current_E370_backup24plus2_ROOT_PLAN02.json','exit_wall_repair_20261027b01/current_81C_backup31_ROOT_PLAN.json'),
 ('root-authorized-backup24','root-authorized-backup31'),('root_authorized_backup24','root_authorized_backup31'),('old648_backup_facts','old674_backup_facts'),
 ("plan['current24']+plan['adoption_backup_sources']","plan['current31']"),('NEW24_BACKUP','NEW31_BACKUP'),
 ('ROOT_CURRENT_E370_FULL24_PLUS2_FIELD_BACKUP_AND_FRESH_OBSERVATION','ROOT_CURRENT_81C_FULL31_BACKUP_AND_FRESH_OBSERVATION'),('ROOT_CURRENT_E370_FRESH_OBSERVATION_ONLY','ROOT_CURRENT_81C_FRESH_OBSERVATION_ONLY'),
 ("current24=plan['current24']","current31=plan['current31']"),('new_backups=rows[:24],adoption_backups=rows[24:]','new_backups=rows'),('total_backups=648+len(rows)','total_backups=674+len(rows)')]:
 assert a in t,a;t=t.replace(a,b)
compile(t,'backup_current_81C_31_ROOT_ONLY.py','exec');tool=emit('backup_current_81C_31_ROOT_ONLY.py',t.encode('utf8'))
print(json.dumps(dict(scope=scopepin,plan=pp,tool=tool,parent_tool_sha256=sha(parent),new_backups_if_Root_executes=31,total_if_Root_executes=705,execution_calls=0)))
