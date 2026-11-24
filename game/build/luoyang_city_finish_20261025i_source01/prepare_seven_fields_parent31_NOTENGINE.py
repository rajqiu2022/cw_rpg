"""Current DFCF parent/backup transport only. No seven-field content seal, Stage or engine."""
from pathlib import Path
import json,hashlib,difflib
N=Path(__file__).resolve().parent;GAME=N.parents[1];S='res://build/luoyang_city_finish_20261025i_source01/';P=S+'seven_fields_layout_repair01/';OUT=N/'seven_fields_layout_repair01'
sha=lambda b:hashlib.sha256(b).hexdigest()
enc=lambda v:(json.dumps(v,ensure_ascii=False,indent=2,allow_nan=False)+'\n').encode('utf8')
def load(p,h):
 b=(GAME/p[6:]).read_bytes();assert sha(b)==h;return json.loads(b)
def emit(name,b):
 p=OUT/name;assert not p.exists();p.parent.mkdir(parents=True,exist_ok=True)
 with p.open('xb')as f:f.write(b)
 return dict(path=P+name,sha256=sha(b),bytes=len(b))
parentdep=dict(path=S+'market_living_street_repair01/Market_living_street31_deployed_ROOT_ACTUAL.json',sha256='dfcf3f6f30eb2d003e45fcfd210d1f530aab0918c72ccc24346deca1cd95495b')
dep=load(**{'p':parentdep['path'],'h':parentdep['sha256']})
headpin=dict(path=S+'market_living_street_repair01/unified31_READY01/unified32_all_candidates_and_inverse_NOT_STAGE.json',sha256='60f7504c23c9bfa98e8d8c8e436bd72da29c9a640c28b4c9003610c8a597b485');head=load(headpin['path'],headpin['sha256'])
base=load(S+'market_living_street_repair01/current_AAF_backup31_ROOT_PLAN.json','89ed27c1e04e48ad487007f256a73c6c162962979eebf47ed825c64432fb7ac0')
back=load(S+'market_living_street_repair01/current_AAF_backup31_ROOT_ACTUAL.json','31970cb86774421e36bca2b520569f2cf17b4c0672f8aeb845abc0eb470eebc0')
refs={r['target']:r['candidate']for r in head['targets']};assert len(refs)==31
rows=[]
for p,c in refs.items():
 b=(GAME/c['path'][6:]).read_bytes();assert sha(b)==c['sha256']and len(b)==c['bytes']
 rows.append(dict(target=p,immutable_old=c['path'],old_sha256=c['sha256'],old_bytes=c['bytes'],backup=P+'root_only_current31_backup/'+p[6:]))
scope=emit('current_DFCF_exact31_scope_PREPARATION.json',enc(dict(status='CURRENT_DFCF_SEVEN_FIELDS_SOURCE_SCOPE_CONTENT_PENDING_NOT_SEALED',count=31,partition=dict(GD=17,JSON=14),parent_stage=dep['stage'],parent_deployment=parentdep,parent_descriptor=headpin,targets=rows,Market_six_instances_and_pawn_G_and_Router_unchanged=True,all252_execution_values_and_ten_owned_edges_to_preserve=True,content_freeze_pending=True,canonical_writes=0,engine_calls=0)))
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
oldbacks=base['old564_backup_facts']+[dict(path=r['backup'],exists=True,sha256=r['sha256'],bytes=r['bytes'],ticks=r['backup_ticks'])for r in back['new_backups']];assert len(oldbacks)==595
# Three newly adopted Market mask files have explicit Root publication/promotion SHA/bytes.
# Only their ticks are the current parent snapshot here; no observed SHA is made an expectation.
pub=load('res://build/luoyang_market_workcourts_20261026b_system01/ROOT_READY01/output/80492/result.json','aacb4919b73fdab6f71de5a6606c9b279a992684c8b415f6b6048da61d3256cd')
mp=load('res://build/luoyang_market_workcourts_20261026b_system01/mask_import01_ROOT_ONLY/promotion_ROOT_EXECUTED.json','255425f3be0b07fbf7dee8d8063152b25d97bf08ca7c88c1a4a5b22fbd595506')
maskrows=[dict(path=pub['mask']['path'],sha256=pub['mask']['sha256'])]+[{k:r[k]for k in ['path','sha256','bytes']}for r in mp['written']]
media=list(base['media128'])
for r in maskrows:
 p=GAME/r['path'][6:];a=p.stat();raw=p.read_bytes();z=p.stat();assert sha(raw)==r['sha256']and(a.st_size,a.st_mtime_ns)==(z.st_size,z.st_mtime_ns)
 if 'bytes'in r:assert len(raw)==r['bytes']
 media.append(dict(path=r['path'],exists=True,sha256=r['sha256'],bytes=len(raw),ticks=str(z.st_mtime_ns//100+621355968000000000)))
assert len(media)==131
plan=emit('current_DFCF_backup31_ROOT_PLAN.json',enc(dict(status='ROOT_ONLY_CURRENT_DFCF_CREATE_NEW31_BACKUP_PLAN_NOT_EXECUTED',scope=scope,parent_deployment=parentdep,current31=rows,current37=current,frozen2121_expected=facts,save15_expected=back['save15'],old595_backup_facts=oldbacks,media131=media,World54=base['World54'],ui=base['ui'],Root_only_backup_prefix=P+'root_only_current31_backup/',expected_old_backup_total=595,expected_after_backup_total=626,canonical_writes=0,engine_calls=0)))
oldtool=N/'market_living_street_repair01/backup_current_AAF_31_ROOT_ONLY.py';parent=oldtool.read_bytes();text=parent.decode()
for a,b in [('market_living_street_repair01/current_AAF_backup31_ROOT_PLAN.json','seven_fields_layout_repair01/current_DFCF_backup31_ROOT_PLAN.json'),('old564_backup_facts','old595_backup_facts'),('564+len(rows)','595+len(rows)'),('media128','media131'),('CURRENT_AAF_FULL31','CURRENT_DFCF_FULL31'),('CURRENT_AAF_FRESH','CURRENT_DFCF_FRESH')]:assert a in text,a;text=text.replace(a,b)
aa=parent.decode().splitlines(True);bb=text.splitlines(True);hs=[]
for z in difflib.SequenceMatcher(None,aa,bb,autojunk=False).get_grouped_opcodes(2):hs.append(dict(old=''.join(aa[z[0][1]:z[-1][2]]),new=''.join(bb[z[0][3]:z[-1][4]])))
f=parent.decode();v=text
for h in hs:assert f.count(h['old'])==1;f=f.replace(h['old'],h['new'],1)
for h in reversed(hs):assert v.count(h['new'])==1;v=v.replace(h['new'],h['old'],1)
assert f==text and v.encode()==parent;compile(text,'backup_current_DFCF_31_ROOT_ONLY.py','exec')
tool=emit('backup_current_DFCF_31_ROOT_ONLY.py',text.encode());proof=emit('backup31_transport_whole_inverse_NOT_EXECUTED.json',enc(dict(parent=dict(path=S+'market_living_street_repair01/'+oldtool.name,sha256=sha(parent)),candidate=tool,hunks=hs,whole_UTF8_inverse=True,no_final_source_head_or_Stage_generated=True,execution_calls=0,canonical_writes=0)))
print(json.dumps(dict(scope=scope,plan=plan,tool=tool,proof=proof)))
