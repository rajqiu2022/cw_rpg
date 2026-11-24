"""Prepare currentAAF exact31 backup scope only; no source sealing or Stage."""
from pathlib import Path
import json,hashlib,difflib
N=Path(__file__).resolve().parent;GAME=N.parents[1];S='res://build/luoyang_city_finish_20261025i_source01/';P=S+'market_living_street_repair01/';OUT=N/'market_living_street_repair01'
sha=lambda b:hashlib.sha256(b).hexdigest()
enc=lambda v:(json.dumps(v,ensure_ascii=False,indent=2,allow_nan=False)+'\n').encode('utf-8')
def load(p,h):
    b=(GAME/p[6:]).read_bytes();assert sha(b)==h;return json.loads(b)
def emit(name,b):
    p=OUT/name;assert not p.exists();p.parent.mkdir(parents=True,exist_ok=True)
    with p.open('xb')as f:f.write(b)
    return dict(path=P+name,sha256=sha(b),bytes=len(b))
dep=load(S+'pawnshop_collision_Gbinding_repair01/pawn_Gbinding25_deployed_ROOT_ACTUAL.json','aaf3125769c2b20bc9fc5bb7485d123026349ae704cb36728c8e9087ea037786')
base=load(S+'pawnshop_collision_Gbinding_repair01/current_6C01_backup25_ROOT_PLAN.json','3428c387887bc1c37edb004251f1f161d89dc9ed7c6a08701db2c26bcafd9dca')
back=load(S+'pawnshop_collision_Gbinding_repair01/current_6C01_backup25_ROOT_ACTUAL.json','2f0de4cd1346436e77992b9c76cf206c61d96354a7af27a27d7f0e8d8188032d')
old=load(S+'Estate_wall_source_repair01/unified31_READY01/unified32_all_candidates_and_inverse_NOT_STAGE.json','ccd21474dd1a99ef33b6a965da522190e4ad811f237bed3671430f5007cb7b54')
head=load(S+'pawnshop_collision_Gbinding_repair01/unified25_READY01/pawn_Gbinding25_all_candidates_and_inverse_NOT_STAGE.json','4e8f536f2517ff331f376bac871bd26a0d33cc87e29f5a7230a889d6b534ece4')
refs={r['target']:r['candidate']for r in old['targets']};refs.update({r['target']:r['candidate']for r in head['targets']})
wanted=[r['target']for r in old['targets']];assert len(wanted)==31
rows=[]
for p in wanted:
    c=refs[p];b=(GAME/p[6:]).read_bytes();assert b==(GAME/c['path'][6:]).read_bytes()and sha(b)==c['sha256']and len(b)==c['bytes'],p
    rows.append(dict(target=p,immutable_old=c['path'],old_sha256=c['sha256'],old_bytes=c['bytes'],backup=P+'root_only_current31_backup/'+p[6:]))
parentdep=dict(path=S+'pawnshop_collision_Gbinding_repair01/pawn_Gbinding25_deployed_ROOT_ACTUAL.json',sha256='aaf3125769c2b20bc9fc5bb7485d123026349ae704cb36728c8e9087ea037786')
scope=emit('current_AAF_exact31_scope_PREPARATION.json',enc(dict(status='CURRENT_AAF_MARKET_SIX_INSTANCES_SOURCE_SCOPE_NOT_SEALED_NOT_BACKED_UP',count=31,partition=dict(GD=17,JSON=14),parent_stage=dep['stage'],parent_deployment=parentdep,targets=rows,only_Market_data_and_unavoidable_source_pointers=True,unchanged_C_Field_Router_algorithms=True,pawnshop_and_paused_batches_unchanged=True,canonical_writes=0,engine_calls=0)))
facts={r['path']:{k:v for k,v in r.items()if k!='path'}for r in back['frozen2121_current_facts']};written={r['target']:r for r in dep['targets']};absolute={str((GAME/p[6:]).resolve()).casefold():r for p,r in written.items()}
for p in facts:
    k=str((GAME/p[6:]if p.startswith('res://')else Path(p)).resolve()).casefold()
    if k in absolute:
        r=absolute[k];facts[p]=dict(exists=True,sha256=r['sha256'],bytes=r['bytes'],ticks=r['ticks'])
current=[]
for row in base['current37']:
    row=dict(row);row.pop('current',None)
    if row['target']in written:
        r=written[row['target']];row.update(sha256=r['sha256'],bytes=r['bytes'])
    current.append(row)
oldbacks=base['old539_backup_facts']+[dict(path=r['backup'],exists=True,sha256=r['sha256'],bytes=r['bytes'],ticks=r['backup_ticks'])for r in back['new_backups']];assert len(oldbacks)==564
plan=emit('current_AAF_backup31_ROOT_PLAN.json',enc(dict(status='ROOT_ONLY_CURRENT_AAF_CREATE_NEW31_BACKUP_PLAN_NOT_EXECUTED',scope=scope,parent_deployment=parentdep,current31=rows,current37=current,frozen2121_expected=facts,save15_expected=back['save15'],old564_backup_facts=oldbacks,media128=base['media128'],World54=base['World54'],ui=base['ui'],Root_only_backup_prefix=P+'root_only_current31_backup/',expected_old_backup_total=564,expected_after_backup_total=595,canonical_writes=0,engine_calls=0)))
oldtool=N/'pawnshop_collision_Gbinding_repair01/backup_current_6C01_25_ROOT_ONLY.py';parent=oldtool.read_bytes();text=parent.decode()
for a,b in [('CreateNew25','CreateNew31'),('pawnshop_collision_Gbinding_repair01/current_6C01_backup25_ROOT_PLAN.json','market_living_street_repair01/current_AAF_backup31_ROOT_PLAN.json'),('backup25','backup31'),('current25','current31'),('old539_backup_facts','old564_backup_facts'),('539+len(rows)','564+len(rows)'),('NEW25','NEW31'),('CURRENT6C01_FULL25','CURRENT_AAF_FULL31'),('CURRENT6C01_FRESH','CURRENT_AAF_FRESH')]:assert a in text,a;text=text.replace(a,b)
aa=parent.decode().splitlines(True);bb=text.splitlines(True);hs=[]
for z in difflib.SequenceMatcher(None,aa,bb,autojunk=False).get_grouped_opcodes(2):hs.append(dict(old=''.join(aa[z[0][1]:z[-1][2]]),new=''.join(bb[z[0][3]:z[-1][4]])))
f=parent.decode();v=text
for h in hs:assert f.count(h['old'])==1;f=f.replace(h['old'],h['new'],1)
for h in reversed(hs):assert v.count(h['new'])==1;v=v.replace(h['new'],h['old'],1)
assert f==text and v.encode()==parent;compile(text,'backup_current_AAF_31_ROOT_ONLY.py','exec')
tool=emit('backup_current_AAF_31_ROOT_ONLY.py',text.encode());proof=emit('backup31_transport_whole_inverse_NOT_EXECUTED.json',enc(dict(parent=dict(path=S+'pawnshop_collision_Gbinding_repair01/'+oldtool.name,sha256=sha(parent)),candidate=tool,hunks=hs,whole_UTF8_inverse=True,no_final_source_head_or_Stage_generated=True,execution_calls=0,canonical_writes=0)))
print(json.dumps(dict(scope=scope,plan=plan,tool=tool,proof=proof)))
