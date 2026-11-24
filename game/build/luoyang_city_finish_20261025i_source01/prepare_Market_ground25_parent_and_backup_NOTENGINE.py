from pathlib import Path
import json,hashlib,copy
N=Path(__file__).resolve().parent;G=N.parents[1];S='res://build/luoyang_city_finish_20261025i_source01/';P=S+'market_ground_texture_repair02/'
def sha(b):return hashlib.sha256(b).hexdigest()
def enc(v):return(json.dumps(v,ensure_ascii=False,indent=2,allow_nan=False)+'\n').encode()
def load(p,h):
 b=(G/p[6:]).read_bytes();assert sha(b)==h;return json.loads(b)
def emit(name,b):
 p=N/'market_ground_texture_repair02'/name;p.parent.mkdir(parents=True,exist_ok=True)
 with p.open('xb')as f:f.write(b)
 return dict(path=P+name,sha256=sha(b),bytes=len(b))
dep_pin=dict(path=S+'repair31_Field11_deployed_ROOT_ACTUAL.json',sha256='5d6c2f7aa10d5c4763ade8d3eb7ce60983f011bbb677ed0e6b5e4e5148dc29a1');dep=load(dep_pin['path'],dep_pin['sha256']);assert dep['passed']and dep['target_count']==31
old_pin=dict(path=S+'gate_texture_repair01/current4160_backup32_ROOT_ACTUAL.json',sha256='392b00f8fb19e36d58c7f2207ba6ad34f31c7f4f04991d7c05f295e39e962431');old=load(old_pin['path'],old_pin['sha256'])
skip={'res://scripts/city/'+name for name in ['luoyang_enclosure_v11_candidate_contract.gd','luoyang_quarters_family_20261022ap.gd','luoyang_estate_family_20261021am.gd','luoyang_environment_layer_20261022ap.gd','luoyang_docks_district08_20261019aa.gd','luoyang_docks_workyard_20261019ac.gd']}
rows=[dict(target=r['target'],old_sha256=r['sha256'],old_bytes=r['bytes'],immutable_old=r['candidate_path'],kind='GD'if r['target'].endswith('.gd')else'JSON',backup=P+'root_only_current25_backup/'+r['target'][6:])for r in dep['targets']if r['target']not in skip]
assert len(rows)==25 and sum(r['kind']=='GD'for r in rows)==11
scope=emit('current5D6C_exact25_scope_PREPARATION.json',enc(dict(status='EXACT_CURRENT5D6C_MARKET_GROUND25_SCOPE_NOT_BACKUP_NOT_STAGE',count=25,partition=dict(GD=11,JSON=14),parent_stage=dep['stage'],parent_deployment=dep_pin,targets=rows,excluded_noop_current31=sorted(skip),unchanged_G_from4160=True,old_owned_proofs=189,new_real_owned_edges=3,expected_new_proofs=5,depth16_unchanged=True,no_shortcut=True)))
current={r['target']:copy.deepcopy(r)for r in old['current32']}
for r in dep['targets']:current[r['target']]=dict(target=r['target'],sha256=r['sha256'],bytes=r['bytes'],immutable_candidate=r['candidate_path'],current=dict(exists=True,sha256=r['sha256'],bytes=r['bytes'],ticks=r['ticks']))
frozen={r['path']:{k:v for k,v in r.items()if k!='path'}for r in old['frozen2121_current_facts']};byabs={str((G/p[6:]).resolve()):r for p,r in current.items()}
for p in frozen:
 r=byabs.get(str(Path(p).resolve()))
 if r:frozen[p]=r['current']
old240=old['old208_backup_facts']+[dict(path=r['backup'],exists=True,sha256=r['sha256'],bytes=r['bytes'],ticks=r['backup_ticks'])for r in old['new_backups']];assert len(old240)==240
plan=emit('current5D6C_protection_backup25_ROOT_PLAN.json',enc(dict(status='ROOT_ONLY_CREATE_NEW25_FROM_FIXED5D6C_PARENT_NOT_EXECUTED',scope=scope,parent_deployment=dep_pin,current32=list(current.values()),current25=rows,frozen2121_expected=frozen,save15_expected=old['save15'],old240_backup_facts=old240,media113=old['media_facts'],ui=old['ui'],Root_only_backup_prefix=P+'root_only_current25_backup/',engine_calls=0,collector_calls=0,canonical_writes=0)))
print(json.dumps(dict(scope=scope,plan=plan)))
