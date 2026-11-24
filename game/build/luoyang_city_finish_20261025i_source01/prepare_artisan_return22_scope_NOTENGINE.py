"""Current2B86 G-only22 backup transport. No functions, content, Stage or engine execution."""
from pathlib import Path
import json,hashlib,difflib
N=Path(__file__).resolve().parent;GAME=N.parents[1];S='res://build/luoyang_city_finish_20261025i_source01/';P=S+'artisan_return_guard_repair01/';OUT=N/'artisan_return_guard_repair01';sha=lambda b:hashlib.sha256(b).hexdigest();enc=lambda v:(json.dumps(v,ensure_ascii=False,indent=2,allow_nan=False)+'\n').encode('utf8')
def load(p,h):
 b=(GAME/p[6:]).read_bytes();assert sha(b)==h;return json.loads(b)
def emit(name,b):
 p=OUT/name;assert not p.exists();p.parent.mkdir(parents=True,exist_ok=True)
 with p.open('xb')as f:f.write(b)
 return dict(path=P+name,sha256=sha(b),bytes=len(b))
parentdep=dict(path=S+'seven_fields_layout_repair01/Seven_fields_layout31_deployed_ROOT_ACTUAL.json',sha256='2b86bb6bbe9b90952c0a4ec39e7f12a40f142aff2095982b9bba86635ef34cf3');dep=load(parentdep['path'],parentdep['sha256'])
headpin=dict(path=S+'seven_fields_layout_repair01/unified31_READY01/unified32_all_candidates_and_inverse_NOT_STAGE.json',sha256='c7ac1d0d213c7db851f93157010aeb3672633b57a87e2335bc5e101e2e69102a');head=load(headpin['path'],headpin['sha256'])
base=load(S+'seven_fields_layout_repair01/current_DFCF_backup31_ROOT_PLAN.json','34b45061b0af228c6a76bb7fa89cb2e3ec193c5817edf20620e212e13186707e');back=load(S+'seven_fields_layout_repair01/current_DFCF_backup31_ROOT_ACTUAL.json','ffc6a84395acf4fbde30c4e4bd706ffb7d8d25ed76155201861a610418139d7b')
refs={r['target']:r['candidate']for r in head['targets']if r['target']in head['metadata']or r['target']in head['index_proofs']or r['target'].endswith('/execution_successor.json')}
gp='res://scripts/city/luoyang_assembled_interiors_20261016g.gd';ex=load(head['execution']['candidate']['path'],head['execution']['candidate']['sha256']);gr=ex['owned'][gp];gs=gr['edges'][-1]['new_snapshot'];gb=(GAME/gs[6:]).read_bytes();assert sha(gb)==gr['current_sha256'];refs[gp]=dict(path=gs,sha256=sha(gb),bytes=len(gb))
rows=[]
for p,c in refs.items():
 b=(GAME/c['path'][6:]).read_bytes();assert sha(b)==c['sha256']and len(b)==c['bytes'];rows.append(dict(target=p,immutable_old=c['path'],old_sha256=c['sha256'],old_bytes=c['bytes'],backup=P+'root_only_current22_backup/'+p[6:]))
assert len(rows)==22 and sum(r['target'].endswith('.gd')for r in rows)==9
scope=emit('current_2B86_exact22_scope_PREPARATION.json',enc(dict(status='CURRENT_2B86_G_ARTISAN_FINAL_CLEARANCE_ONLY_NOT_BACKED_UP',expected_count=22,count=22,partition=dict(GD=9,JSON=13),parent_stage=dep['stage'],parent_deployment=parentdep,parent_descriptor=headpin,targets=rows,only_G_final_clearance_foot_and_necessary_source_pins=True,payload_geometry_masks_and_all_other_functions_unchanged=True,canonical_writes=0,engine_calls=0)))
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
oldbacks=base['old595_backup_facts']+[dict(path=r['backup'],exists=True,sha256=r['sha256'],bytes=r['bytes'],ticks=r['backup_ticks'])for r in back['new_backups']];assert len(oldbacks)==626
pub=load('res://build/luoyang_seven_fields_layout_20261026c_system01/RESIDUAL02_ROOT_READY/output/113704/result.json','5ab16b81ff959b17b8860ec9fbab89495a9144eec752345e6f3e794d1926df91');mp=load('res://build/luoyang_seven_fields_layout_20261026c_system01/mask_import01_ROOT_ONLY/promotion_ROOT_EXECUTED.json','35e7e14d0c0562225c4af20fd707a5a80f54a0534b92f0ebf4affba90b24261d')
newmedia=[dict(path=r['mask']['path'],sha256=r['mask']['sha256'],bytes=r['mask']['bytes'])for id,r in pub['scenes'].items()if id not in ['ch4_s3_luoyang_market','ch4_s4_ancient_temple']]+[{k:r[k]for k in ['path','sha256','bytes']}for r in mp['written']];assert len(newmedia)==18
media=list(base['media131'])
for r in newmedia:
 p=GAME/r['path'][6:];a=p.stat();raw=p.read_bytes();z=p.stat();assert sha(raw)==r['sha256']and len(raw)==r['bytes']and(a.st_size,a.st_mtime_ns)==(z.st_size,z.st_mtime_ns);media.append(dict(path=r['path'],exists=True,sha256=r['sha256'],bytes=r['bytes'],ticks=str(z.st_mtime_ns//100+621355968000000000)))
assert len(media)==149
plan=emit('current_2B86_backup22_ROOT_PLAN.json',enc(dict(status='ROOT_ONLY_CURRENT_2B86_CREATE_NEW22_BACKUP_PLAN_NOT_EXECUTED',scope=scope,parent_deployment=parentdep,current22=rows,current37=current,frozen2121_expected=facts,save15_expected=back['save15'],old626_backup_facts=oldbacks,media149=media,World54=base['World54'],ui=base['ui'],Root_only_backup_prefix=P+'root_only_current22_backup/',expected_old_backup_total=626,expected_after_backup_total=648,canonical_writes=0,engine_calls=0)))
oldtool=N/'seven_fields_layout_repair01/backup_current_DFCF_31_ROOT_ONLY.py';parent=oldtool.read_bytes();text=parent.decode()
for a,b in [('CreateNew31','CreateNew22'),('seven_fields_layout_repair01/current_DFCF_backup31_ROOT_PLAN.json','artisan_return_guard_repair01/current_2B86_backup22_ROOT_PLAN.json'),('backup31','backup22'),('current31','current22'),('old595_backup_facts','old626_backup_facts'),('595+len(rows)','626+len(rows)'),('media131','media149'),('NEW31','NEW22'),('CURRENT_DFCF_FULL31','CURRENT_2B86_FULL22'),('CURRENT_DFCF_FRESH','CURRENT_2B86_FRESH')]:assert a in text,a;text=text.replace(a,b)
aa=parent.decode().splitlines(True);bb=text.splitlines(True);hs=[]
for z in difflib.SequenceMatcher(None,aa,bb,autojunk=False).get_grouped_opcodes(2):hs.append(dict(old=''.join(aa[z[0][1]:z[-1][2]]),new=''.join(bb[z[0][3]:z[-1][4]])))
f=parent.decode();v=text
for h in hs:assert f.count(h['old'])==1;f=f.replace(h['old'],h['new'],1)
for h in reversed(hs):assert v.count(h['new'])==1;v=v.replace(h['new'],h['old'],1)
assert f==text and v.encode()==parent;compile(text,'backup_current_2B86_22_ROOT_ONLY.py','exec');tool=emit('backup_current_2B86_22_ROOT_ONLY.py',text.encode());proof=emit('backup22_transport_whole_inverse_NOT_EXECUTED.json',enc(dict(parent=dict(path=S+'seven_fields_layout_repair01/'+oldtool.name,sha256=sha(parent)),candidate=tool,hunks=hs,whole_UTF8_inverse=True,execution_calls=0,canonical_writes=0)))
print(json.dumps(dict(scope=scope,plan=plan,tool=tool,proof=proof)))
