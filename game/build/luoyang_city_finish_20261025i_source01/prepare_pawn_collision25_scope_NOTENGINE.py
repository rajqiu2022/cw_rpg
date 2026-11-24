"""Prepare current9C1245 exact25 old scope; Root alone may CreateNew backups."""
from pathlib import Path
import json,hashlib,difflib
N=Path(__file__).resolve().parent;GAME=N.parents[1]
S='res://build/luoyang_city_finish_20261025i_source01/';P=S+'pawnshop_collision_repair01/';OUT=N/'pawnshop_collision_repair01'
sha=lambda b:hashlib.sha256(b).hexdigest()
enc=lambda v:(json.dumps(v,ensure_ascii=False,indent=2,allow_nan=False)+'\n').encode('utf-8')
def load(p,h):
    b=(GAME/p[6:]).read_bytes();assert sha(b)==h;return json.loads(b)
def emit(name,b):
    p=OUT/name;p.parent.mkdir(parents=True,exist_ok=True)
    if p.exists():assert p.read_bytes()==b
    else:
        with p.open('xb')as f:f.write(b)
    return dict(path=P+name,sha256=sha(b),bytes=len(b))
dep=load(S+'pawnshop_only_repair01/pawnshop22_deployed_ROOT_ACTUAL.json','9c1245b2dcc4c8667e97df74ba78ebd219234f8b25eb83c6dd9c3ddb7fa10dc7')
base=load(S+'pawnshop_only_repair01/current_47CC_backup22_ROOT_PLAN.json','cb41f51bca598a59caf5935b5c7948d0bb6894216827ba3b6b0eb5deb85c14e8')
back=load(S+'pawnshop_only_repair01/current_47CC_backup22_ROOT_ACTUAL.json','75637d956c0d040af9b57fb6374d2b78a8b46b334fcc892c1405de57a1652639')
old=load(S+'Estate_wall_source_repair01/unified31_READY01/unified32_all_candidates_and_inverse_NOT_STAGE.json','ccd21474dd1a99ef33b6a965da522190e4ad811f237bed3671430f5007cb7b54')
head=load(S+'pawnshop_only_repair01/unified22_READY01/pawnshop22_all_candidates_and_inverse_NOT_STAGE.json','aceeb63c1217aa148b547fec737e9e2ae2d6da6ce5fb6993d7a7df028663eb74')
refs={r['target']:r['candidate']for r in old['targets']};refs.update({r['target']:r['candidate']for r in head['targets']})
three={'res://scripts/field/field_walkable_controller.gd','res://scripts/city/luoyang_cultural_sidequests_coordinator_20261019x.gd','res://scripts/city/luoyang_temple_assembly_20261016.gd'}
wanted=three|set(old['metadata'])|set(old['index_proofs'])|{'res://data/maps/luoyang_full_city_20261022ap/execution_successor.json','res://data/luoyang_culture_integration_20261019x/runtime_contract.json'}
assert len(wanted)==25
rows=[]
for p in sorted(wanted):
    c=refs[p];b=(GAME/p[6:]).read_bytes();assert b==(GAME/c['path'][6:]).read_bytes()and sha(b)==c['sha256']and len(b)==c['bytes'],p
    rows.append(dict(target=p,immutable_old=c['path'],old_sha256=c['sha256'],old_bytes=c['bytes'],backup=P+'root_only_current25_backup/'+p[6:]))
stagepin=dep['stage'];scope=emit('current_9C1245_exact25_scope_PREPARATION.json',enc(dict(status='PAWN_COLLISION_ONLY_EXACT25_OLD_SCOPE_NOT_BACKED_UP',parent_stage=stagepin,parent_deployment=dict(path=S+'pawnshop_only_repair01/pawnshop22_deployed_ROOT_ACTUAL.json',sha256='9c1245b2dcc4c8667e97df74ba78ebd219234f8b25eb83c6dd9c3ddb7fa10dc7'),targets=rows,count=25,partition=dict(GD=11,JSON=14),G_service_author_22_unchanged=True,canonical_writes=0,engine_calls=0)))
facts={r['path']:{k:v for k,v in r.items()if k!='path'}for r in back['frozen2121_current_facts']}
written={r['target']:r for r in dep['targets']}
for p,r in written.items():
    if p in facts:facts[p]=dict(exists=True,sha256=r['sha256'],bytes=r['bytes'],ticks=r['ticks'])
current=[]
for row in base['current37']:
    row=dict(row);p=row['target']
    if p in written:
        d=written[p];row.update(sha256=d['sha256'],bytes=d['bytes']);row.pop('current',None)
    current.append(row)
gp='res://scripts/city/luoyang_assembled_interiors_20261016g.gd';assert gp in {r['target']for r in current}
assert len(current)==37
oldbacks=base['old492_backup_facts']+[dict(path=r['backup'],exists=True,sha256=r['sha256'],bytes=r['bytes'],ticks=r['backup_ticks'])for r in back['new_backups']]
assert len(oldbacks)==514
plan=emit('current_9C1245_backup25_ROOT_PLAN.json',enc(dict(status='ROOT_ONLY_CREATE_NEW25_BACKUP_PLAN_NOT_EXECUTED',scope=scope,parent_deployment=dict(path=S+'pawnshop_only_repair01/pawnshop22_deployed_ROOT_ACTUAL.json',sha256='9c1245b2dcc4c8667e97df74ba78ebd219234f8b25eb83c6dd9c3ddb7fa10dc7'),current25=rows,current37=current,frozen2121_expected=facts,save15_expected=back['save15'],old514_backup_facts=oldbacks,media128=base['media128'],World54=base['World54'],ui=base['ui'],Root_only_backup_prefix=P+'root_only_current25_backup/',expected_old_backup_total=514,expected_after_backup_total=539,canonical_writes=0,engine_calls=0)))
oldtool=N/'pawnshop_only_repair01/backup_current_47CC_22_ROOT_ONLY.py';parent=oldtool.read_bytes();text=parent.decode('utf-8')
for a,b in [('CreateNew22','CreateNew25'),('pawnshop_only_repair01/current_47CC_backup22_ROOT_PLAN.json','pawnshop_collision_repair01/current_9C1245_backup25_ROOT_PLAN.json'),('backup22','backup25'),('current22','current25'),('old492_backup_facts','old514_backup_facts'),('492+len(rows)','514+len(rows)'),('CURRENT32_CODE_DRIFT_KEEP_NO_BACKUP','CURRENT37_CODE_DRIFT_KEEP_NO_BACKUP'),('NEW22','NEW25'),('CURRENT47CC_FULL22','CURRENT9C1245_FULL25'),('CURRENT47CC_FRESH','CURRENT9C1245_FRESH')]:
    assert a in text,a;text=text.replace(a,b)
aa=parent.decode().splitlines(keepends=True);bb=text.splitlines(keepends=True);hs=[]
for group in difflib.SequenceMatcher(None,aa,bb,autojunk=False).get_grouped_opcodes(2):hs.append(dict(old=''.join(aa[group[0][1]:group[-1][2]]),new=''.join(bb[group[0][3]:group[-1][4]])))
f=parent.decode();v=text
for h in hs:assert f.count(h['old'])==1;f=f.replace(h['old'],h['new'],1)
for h in reversed(hs):assert v.count(h['new'])==1;v=v.replace(h['new'],h['old'],1)
assert f==text and v.encode()==parent;compile(text,'backup_current_9C1245_25_ROOT_ONLY.py','exec')
tool=emit('backup_current_9C1245_25_ROOT_ONLY.py',text.encode())
proof=emit('backup25_transport_whole_inverse_NOT_EXECUTED.json',enc(dict(parent=dict(path=S+'pawnshop_only_repair01/'+oldtool.name,sha256=sha(parent)),candidate=tool,hunks=hs,whole_UTF8_inverse=True,execution_calls=0,canonical_writes=0)))
print(json.dumps(dict(scope=scope,plan=plan,tool=tool,proof=proof)))
