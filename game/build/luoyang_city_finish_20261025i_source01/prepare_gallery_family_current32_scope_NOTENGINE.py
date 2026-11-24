"""Fixed authority20 parent overlay and NEW Root-only backup plan, no backup execution."""
from pathlib import Path
import json, hashlib, copy
N=Path(__file__).resolve().parent; G=N.parents[1]
S='res://build/luoyang_city_finish_20261025i_source01/'
Y='res://build/luoyang_city_finish_20261025i_system01/'
P=S+'docks_gallery_family_repair01/'; OUT=N/'docks_gallery_family_repair01'
def sha(b): return hashlib.sha256(b).hexdigest()
def enc(v): return (json.dumps(v,ensure_ascii=False,indent=2)+'\n').encode()
def read(pin):
 b=(G/pin['path'][6:]).read_bytes(); assert sha(b)==pin['sha256']; return b
def load(pin): return json.loads(read(pin))
def pin(p,h): return dict(path=p,sha256=h)
dp=pin(Y+'execution_declared_edges_source02/authority20_deployed_ROOT_ACTUAL.json','1bc99c391cfda77412aef982cb94a2d3dc169be19ba1c84a9d40d24051cd0812')
dep=load(dp); assert dep['passed'] and dep['execution_source_count']==195
bundles=[
 pin(S+'unified32_READY03/unified32_all_candidates_and_inverse_NOT_STAGE.json','be3aa94f1b6eae760888803076f80062ad4a25b3aabb349ea46e43e223099254'),
 pin(S+'repair31_READY03/unified32_all_candidates_and_inverse_NOT_STAGE.json','319fc714cb589608c9dc200d47d7e517abc534fc2e540073eee9f3f3b9044a98'),
 pin(S+'market_ground25_READY01/unified32_all_candidates_and_inverse_NOT_STAGE.json','c699076933993a1fbdc89981b2d606260318dc764b543b85a45ea9c56dc395a4'),
 pin(Y+'execution_declared_edges_source02/stage20_READY02/all_candidates20_full_inverse_NOT_STAGE.json','b88801a505b0136ecf7e69f09543e190ee6c7bd55c72b05831071c77e1e8bfb1')]
parents={}
for bp in bundles:
 for r in load(bp)['targets']: parents[r['target']]=r['candidate']
assert len(parents)==33
rp=pin(Y+'family_direct_entry01_NOTREADY/Router_family_direct_exactEOL_full_inverse_BUILD.json','')
rp['sha256']=sha((G/rp['path'][6:]).read_bytes())
router=load(rp); parents[router['target']]=router['parent'];parents[router['target']]['bytes']=len(read(router['parent']))
noops=['res://scripts/city/luoyang_assembled_interiors_20261016g.gd','res://scripts/city/luoyang_execution_authority_20261022ap.gd']
rows=[]
for p,v in parents.items():
 b=read(v); actual=(G/p[6:]).read_bytes(); assert actual==b,('CURRENT_PARENT_DRIFT_PRESERVE',p)
 if p in noops:continue
 rows.append(dict(target=p,immutable_old=v['path'],old_sha256=v['sha256'],old_bytes=len(b),kind='GD' if p.endswith('.gd') else 'JSON',backup=P+'root_only_current32_backup/'+p[6:]))
assert len(rows)==32 and sum(r['kind']=='GD' for r in rows)==18
oldpin=pin(Y+'execution_declared_edges_source02/currentE8AF_backup20_ROOT_ACTUAL.json','448fd9851c1d47b0fa99c2ba037fe887b15594fdf808d215b8586589a20a0e05')
bk=load(oldpin);assert bk['total_backups']==285
frozen={r['path']:{k:v for k,v in r.items() if k!='path'} for r in bk['frozen2121_current_facts']}
current={r['target']:copy.deepcopy(r) for r in bk['current33']}
for r in dep['targets']:
 current[r['target']]=dict(target=r['target'],sha256=r['sha256'],bytes=r['bytes'],immutable_candidate=r['candidate_path'],current=dict(exists=True,sha256=r['sha256'],bytes=r['bytes'],ticks=r['ticks']))
assert len(current)==33
byabs={str((G/p[6:]).resolve()):r for p,r in current.items()}
for p in frozen:
 r=byabs.get(str(Path(p).resolve()))
 if r:frozen[p]=r['current']
old285=bk['old265_backup_facts']+[dict(path=r['backup'],exists=True,sha256=r['sha256'],bytes=r['bytes'],ticks=r['backup_ticks'])for r in bk['new_backups']]
assert len(old285)==285
scope=dict(status='CURRENT_AUTHORITY20_EXACT32_GALLERY_FAMILY_ROUTER_REPAIR_PREPARATION_NOT_STAGE',count=32,partition=dict(GD=18,JSON=14),parent_deployment=dp,parent_stage=dep['stage'],authority_chain=bundles,targets=rows,excluded_noop=noops,owned10_unchanged=True,old195_all_values_edges_preserved=True,new_owned_edges=['Router','Field','Coordinator','Temple','AC'],new_proofs_expected=7,source_proof202_expected=True,authority_F120_unchanged=True,no_shortcut=True)
scopebytes=enc(scope);sp=pin(P+'current_authority20_exact32_scope_PREPARATION.json',sha(scopebytes))
plan=dict(status='ROOT_ONLY_CREATENEW32_CURRENT_AUTHORITY20_PLAN_NOT_EXECUTED',scope=sp,parent_deployment=dp,current33=list(current.values()),current32=rows,frozen2121_expected=frozen,save15_expected=bk['save15'],old285_backup_facts=old285,media113=bk['media_facts'],ui=bk['ui'],Root_only_backup_prefix=P+'root_only_current32_backup/',Router_fixed_parent=router['parent'],router_proof=rp,old_authority20_backup=oldpin,engine_calls=0,collector_calls=0,canonical_writes=0)
script=(N/'backup_Market_ground25_current5D6C_ROOT_ONLY.py').read_text(encoding='utf-8')
for a,b in [("PLAN=S+'market_ground_texture_repair02/current5D6C_protection_backup25_ROOT_PLAN.json'","PLAN=S+'docks_gallery_family_repair01/current_authority20_backup32_ROOT_PLAN.json'"),('current25','current32'),('current32=[]','observed33=[]'),('current32.append','observed33.append'),("plan['current32']:\n  f=fact", "plan['current33']:\n  f=fact"),('current32=current32','current33=observed33'),('old240','old285'),('240+len(rows)','285+len(rows)'),('backup25','backup32'),('25_BACKUP','32_BACKUP'),('CURRENT5D6C','CURRENT_AUTHORITY20')]:
 assert a in script,a
 script=script.replace(a,b)
assert 'current33=observed33' in script and "for r in plan['current32']" in script
assert not OUT.exists();OUT.mkdir()
for name,b in [('current_authority20_exact32_scope_PREPARATION.json',scopebytes),('current_authority20_backup32_ROOT_PLAN.json',enc(plan)),('backup_current_authority20_32_ROOT_ONLY.py',script.encode())]:
 with(OUT/name).open('xb')as f:f.write(b)
 print(name,sha(b),len(b))
