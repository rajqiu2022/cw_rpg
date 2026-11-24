"""Root-only CreateNew31 preparation from actual377B/current guard; never backup now."""
from pathlib import Path
import json,copy,hashlib
N=Path(__file__).resolve().parent;G=N.parents[1];S='res://build/luoyang_city_finish_20261025i_source01/';P=S+'temple_signed_iid_repair01/';O=N/'temple_signed_iid_repair01'
def sha(b):return hashlib.sha256(b).hexdigest()
def enc(v):return(json.dumps(v,ensure_ascii=False,indent=2)+'\n').encode('utf8')
def load(p,h):
 b=(G/p[6:]).read_bytes();assert sha(b)==h;return json.loads(b)
scopepin=dict(path=P+'current_377B_exact31_scope_PREPARATION.json',sha256='9e314a4d78bf08d9e4b336a5d49a6ce95f5d84a2f266043ebf86ff1cf294b527');scope=load(**dict(p=scopepin['path'],h=scopepin['sha256']))
deppin=dict(path=S+'family_visual_material_loading_repair01/visual_material_loading31_deployed_ROOT_ACTUAL.json',sha256='377b507b76264258335df71331208bed0d54182105d7713aa6229f1b20c4c2f1')
guardpin=scope['parent_post_guard'];backup_pin=dict(path=S+'family_visual_material_loading_repair01/current_F67E_backup31_ROOT_ACTUAL.json',sha256='a6996ef5cd0ce92b52d32214555e17c2394316144df1a1b12a9cfdb6ccc7e0e9')
dep=load(deppin['path'],deppin['sha256']);guard=load(guardpin['path'],guardpin['sha256']);backup=load(backup_pin['path'],backup_pin['sha256'])
assert dep['passed'] and guard['passed'] and guard['differences']==[] and backup['total_backups']==372 and dep['target_count']==31
frozen={r['path']:{k:v for k,v in r.items()if k!='path'}for r in backup['frozen2121_current_facts']}
def key(p):return str((G/p[6:])if p.startswith('res://')else Path(p)).replace('\\','/').casefold()
lookup={key(p):p for p in frozen};assert len(lookup)==2121
current={r['target']:copy.deepcopy(r)for r in backup['current34']}
for r in dep['targets']:
 fact=dict(exists=True,sha256=r['sha256'],bytes=r['bytes'],ticks=r['ticks']);fp=lookup.get(key(r['target']))
 if fp is not None:frozen[fp]=fact
 current[r['target']]=dict(target=r['target'],sha256=r['sha256'],bytes=r['bytes'],immutable_candidate=r['candidate_path'],current=fact)
assert len(current)==34 and sum(frozen[lookup[key(r['target'])]]['sha256']==r['sha256'] for r in dep['targets'])==31
old=copy.deepcopy(backup['old341_backup_facts'])
for r in backup['new_backups']:old.append(dict(path=r['backup'],exists=True,sha256=r['sha256'],bytes=r['bytes'],ticks=r['backup_ticks']))
assert len(old)==372 and len(backup['media_facts'])==116
rows=[]
for r in scope['targets']:
 row=copy.deepcopy(r);row.update(kind='GD'if row['target'].endswith('.gd')else'JSON',backup=P+'root_only_current31_backup/'+row['target'][6:]);rows.append(row)
plan=dict(status='ROOT_ONLY_CREATE_NEW31_FROM_ACTUAL377B_AND_51464_PLAN_NOT_EXECUTED',scope=scopepin,parent_deployment=deppin,parent_guard=guardpin,current31=rows,current34=list(current.values()),frozen2121_expected=frozen,save15_expected=backup['save15'],old372_backup_facts=old,media116=backup['media_facts'],ui=backup['ui'],Root_only_backup_prefix=P+'root_only_current31_backup/',expected_old_backup_total=372,expected_after_backup_total=403,canonical_writes=0,engine_calls=0,save_writes=0)
parent=(N/'family_visual_material_loading_repair01/backup_current_F67E_31_ROOT_ONLY.py').read_bytes();text=parent.decode('utf8');changes=[]
for a,b in [('F67E','377B'),('family_visual_material_loading_repair01/current_377B_backup31_ROOT_PLAN.json','temple_signed_iid_repair01/current_377B_backup31_ROOT_PLAN.json'),('old341','old372'),('341+len(rows)','372+len(rows)')]:
 assert a in text;changes.append(dict(old=a,new=b));text=text.replace(a,b)
back=text
for c in reversed(changes):back=back.replace(c['new'],c['old'])
assert back.encode()==parent;compile(text,'backup_current_377B_31_ROOT_ONLY.py','exec')
files={'current_377B_backup31_ROOT_PLAN.json':enc(plan),'backup_current_377B_31_ROOT_ONLY.py':text.encode(),'backup_tool_mechanical_inverse_NOT_EXECUTED.json':enc(dict(status='ROOT_ONLY_TOOL_NOT_EXECUTED',parent_sha256=sha(parent),candidate_sha256=sha(text.encode()),changes=changes,whole_byte_inverse=True,backup_copy_calls=0,canonical_writes=0))}
for name,b in files.items():
 with(O/name).open('xb')as stream:stream.write(b)
 print(name,sha(b),len(b))
