"""Prepare exact same25 targets from actual6C01; Root-only backup transport."""
from pathlib import Path
import json,hashlib,difflib
N=Path(__file__).resolve().parent;GAME=N.parents[1];S='res://build/luoyang_city_finish_20261025i_source01/';P=S+'pawnshop_collision_Gbinding_repair01/';OUT=N/'pawnshop_collision_Gbinding_repair01'
sha=lambda b:hashlib.sha256(b).hexdigest()
enc=lambda v:(json.dumps(v,ensure_ascii=False,indent=2,allow_nan=False)+'\n').encode('utf-8')
def load(p,h):
    b=(GAME/p[6:]).read_bytes();assert sha(b)==h;return json.loads(b)
def emit(name,b):
    p=OUT/name;assert not p.exists();p.parent.mkdir(parents=True,exist_ok=True)
    with p.open('xb')as f:f.write(b)
    return dict(path=P+name,sha256=sha(b),bytes=len(b))
dep=load(S+'pawnshop_collision_repair01/pawn_collision25_deployed_ROOT_ACTUAL.json','6c01adf472ebb1d7530236a53b88b7c1c26a0af75c52f06a9a5b8c4a4f689c30')
base=load(S+'pawnshop_collision_repair01/current_9C1245_backup25_ROOT_PLAN.json','ecfbed6312a30eae6f7cd78bea3f975a8cf5e5058ad306babf4c027188e24f16')
back=load(S+'pawnshop_collision_repair01/current_9C1245_backup25_ROOT_ACTUAL.json','50fe87abfd647b11f7dacbc5863bc294ddde389579a2b1099958ca25b3c89bf0')
prior=load(S+'pawnshop_collision_repair01/unified25_READY01/pawn_collision25_all_candidates_and_inverse_NOT_STAGE.json','4d850a9d16b675af9262b345140643cfa3dcb28e3abe8f9b81c9ae405dc87df9')
rows=[]
for row in prior['targets']:
    p=row['target'];c=row['candidate'];b=(GAME/p[6:]).read_bytes();assert b==(GAME/c['path'][6:]).read_bytes()and sha(b)==c['sha256']and len(b)==c['bytes'],p
    rows.append(dict(target=p,immutable_old=c['path'],old_sha256=c['sha256'],old_bytes=c['bytes'],backup=P+'root_only_current25_backup/'+p[6:]))
assert len(rows)==25
parentdep=dict(path=S+'pawnshop_collision_repair01/pawn_collision25_deployed_ROOT_ACTUAL.json',sha256='6c01adf472ebb1d7530236a53b88b7c1c26a0af75c52f06a9a5b8c4a4f689c30')
scope=emit('current_6C01_exact25_scope_PREPARATION.json',enc(dict(status='CURRENT6C01_EXACT25_TWO_G_RECEIVERS_ONLY_NOT_BACKED_UP',count=25,partition=dict(GD=11,JSON=14),parent_stage=dep['stage'],parent_deployment=parentdep,targets=rows,canonical_writes=0,engine_calls=0)))
facts={r['path']:{k:v for k,v in r.items()if k!='path'}for r in back['frozen2121_current_facts']};written={r['target']:r for r in dep['targets']}
absolute={str((GAME/p[6:]).resolve()).casefold():r for p,r in written.items()}
for p in facts:
    key=str((GAME/p[6:]if p.startswith('res://')else Path(p)).resolve()).casefold()
    if key in absolute:
        r=absolute[key];facts[p]=dict(exists=True,sha256=r['sha256'],bytes=r['bytes'],ticks=r['ticks'])
current=[]
for row in base['current37']:
    row=dict(row);p=row['target'];row.pop('current',None)
    if p in written:row.update(sha256=written[p]['sha256'],bytes=written[p]['bytes'])
    current.append(row)
assert len(current)==37
oldbacks=base['old514_backup_facts']+[dict(path=r['backup'],exists=True,sha256=r['sha256'],bytes=r['bytes'],ticks=r['backup_ticks'])for r in back['new_backups']];assert len(oldbacks)==539
plan=emit('current_6C01_backup25_ROOT_PLAN.json',enc(dict(status='ROOT_ONLY_CURRENT6C01_CREATE_NEW25_BACKUP_PLAN_NOT_EXECUTED',scope=scope,parent_deployment=parentdep,current25=rows,current37=current,frozen2121_expected=facts,save15_expected=back['save15'],old539_backup_facts=oldbacks,media128=base['media128'],World54=base['World54'],ui=base['ui'],Root_only_backup_prefix=P+'root_only_current25_backup/',expected_old_backup_total=539,expected_after_backup_total=564,canonical_writes=0,engine_calls=0)))
old=N/'pawnshop_collision_repair01/backup_current_9C1245_25_ROOT_ONLY.py';parent=old.read_bytes();text=parent.decode()
for a,b in [('pawnshop_collision_repair01/current_9C1245_backup25_ROOT_PLAN.json','pawnshop_collision_Gbinding_repair01/current_6C01_backup25_ROOT_PLAN.json'),('old514_backup_facts','old539_backup_facts'),('514+len(rows)','539+len(rows)'),('CURRENT9C1245','CURRENT6C01')]:assert a in text;text=text.replace(a,b)
aa=parent.decode().splitlines(True);bb=text.splitlines(True);hs=[]
for z in difflib.SequenceMatcher(None,aa,bb,autojunk=False).get_grouped_opcodes(2):hs.append(dict(old=''.join(aa[z[0][1]:z[-1][2]]),new=''.join(bb[z[0][3]:z[-1][4]])))
f=parent.decode();v=text
for h in hs:assert f.count(h['old'])==1;f=f.replace(h['old'],h['new'],1)
for h in reversed(hs):assert v.count(h['new'])==1;v=v.replace(h['new'],h['old'],1)
assert f==text and v.encode()==parent;compile(text,'backup_current_6C01_25_ROOT_ONLY.py','exec')
tool=emit('backup_current_6C01_25_ROOT_ONLY.py',text.encode());proof=emit('backup25_transport_whole_inverse_NOT_EXECUTED.json',enc(dict(parent=dict(path=S+'pawnshop_collision_repair01/'+old.name,sha256=sha(parent)),candidate=tool,hunks=hs,whole_UTF8_inverse=True,execution_calls=0,canonical_writes=0)))
print(json.dumps(dict(scope=scope,plan=plan,tool=tool,proof=proof)))
