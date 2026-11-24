"""Fixed F67E current31 backup preparation only. No backups/Stage/engine are run."""
from pathlib import Path
import copy,hashlib,json
N=Path(__file__).resolve().parent;G=N.parents[1]
S='res://build/luoyang_city_finish_20261025i_source01/'
P=S+'family_visual_material_loading_repair01/';OUT=N/'family_visual_material_loading_repair01'
def sha(b):return hashlib.sha256(b).hexdigest()
def enc(v):return(json.dumps(v,ensure_ascii=False,indent=2,allow_nan=False)+'\n').encode('utf-8')
def load(pin):
 b=(G/pin['path'][6:]).read_bytes();assert sha(b)==pin['sha256'];return json.loads(b)
dep_pin=dict(path=S+'culture_Router_pin_repair01/culture_Router24_deployed_ROOT_ACTUAL.json',sha256='f67e767260e80ea5d1e8ce9d715e7e2dec015212f041d851559cc60add56619a')
guard_pin=dict(path=S+'culture_Router_pin_repair01/post_F67E_all_four_actual_guard_ROOT_ACTUAL.json',sha256='b494e5eedaa5e5603f8f0d41286ae4245458f293c9a24d5ef2eb2b48f1caea01')
backup_pin=dict(path=S+'culture_Router_pin_repair01/current_D581_backup24_ROOT_ACTUAL.json',sha256='4d0ae7e6241e4a8b4ca66d4e845c134e86adaf3fed5dc8676d78fc1f0dabcd51')
base_pin=dict(path=S+'docks_gallery_family_repair01/unified32_READY01/unified32_all_candidates_and_inverse_NOT_STAGE.json',sha256='5f7293ac4203d4e847f623cc76f0292dbd9d5edf269a1bde8f927f4df523cb5e')
latest_pin=dict(path=S+'culture_Router_pin_repair01/unified24_READY01/unified32_all_candidates_and_inverse_NOT_STAGE.json',sha256='85ca1a489a550bde0b410888110c77f322ef6e9f0464a45c7e407fddc2aa4976')
dep,guard,backup,base,latest=[load(p)for p in [dep_pin,guard_pin,backup_pin,base_pin,latest_pin]]
assert dep['passed'] and guard['passed'] and backup['passed'] and backup['total_backups']==341
parents={r['target']:r['candidate']for r in base['targets']}
parents.update({r['target']:r['candidate']for r in latest['targets']})
assert len(parents)==32
router='res://scripts/autoload/scene_router.gd'
assert parents[router]['sha256']=='e983a3b2b8c3cc031262100755c1f9e2f37c03a618d1a0a4cf268f8c6ccd3745'
rows=[]
for target,pin in parents.items():
 raw=(G/pin['path'][6:]).read_bytes();assert sha(raw)==pin['sha256'] and len(raw)==pin['bytes']
 if target==router:continue
 rows.append(dict(target=target,immutable_old=pin['path'],old_sha256=pin['sha256'],old_bytes=len(raw),kind='GD'if target.endswith('.gd')else'JSON',backup=P+'root_only_current31_backup/'+target[6:]))
assert len(rows)==31 and sum(r['kind']=='GD'for r in rows)==17
scope=dict(status='F67E_EXACT31_VISUAL_MATERIAL_AND_LOADING_NECESSARY_SOURCE_PREPARATION_NOT_STAGE',parent_deployment=dep_pin,parent_stage=dep['stage'],parent_descriptor=latest_pin,immutable_parent_overlay=[base_pin,latest_pin],parent_guard=guard_pin,count=31,partition=dict(GD=17,JSON=14),targets=rows,excluded_noop=[router],functional_scope=['System Artisan exact136-to139 material bridge, existing118ground shader unchanged','System Garden original source-bound water visual only; no old NG bodies','System exactEstate original generic V14 overlap bootstrap','Source loading NPC20601840->19401840 and packing approach only'],all_native_geometry_masks_import_media_unchanged=True,original10_OWNED_and_all206_proof_values_edges_preserved=True,Authority_F120_unchanged=True,no_shortcut=True,final_candidate_noops_must_be_removed=True,engine_calls=0,collector_calls=0,Stage_calls=0,canonical_writes=0)
scope_raw=enc(scope);scope_pin=dict(path=P+'current_F67E_exact31_scope_PREPARATION.json',sha256=sha(scope_raw))
frozen={r['path']:{k:v for k,v in r.items()if k!='path'}for r in backup['frozen2121_current_facts']}
current={r['target']:copy.deepcopy(r)for r in backup['current34']}
for r in dep['targets']:
 fact=dict(exists=True,sha256=r['sha256'],bytes=r['bytes'],ticks=r['ticks'])
 if r['target']in frozen:frozen[r['target']]=fact
 current[r['target']]=dict(target=r['target'],sha256=r['sha256'],bytes=r['bytes'],immutable_candidate=r['candidate_path'],current=fact)
assert len(frozen)==2121 and len(current)==34
old_facts=copy.deepcopy(backup['old317_backup_facts'])
for r in backup['new_backups']:old_facts.append(dict(path=r['backup'],exists=True,sha256=r['sha256'],bytes=r['bytes'],ticks=r['backup_ticks']))
assert len(old_facts)==341 and len(backup['media_facts'])==116
plan=dict(status='ROOT_ONLY_CREATE_NEW31_FROM_FIXED_F67E_PARENT_PLAN_NOT_EXECUTED',scope=scope_pin,parent_deployment=dep_pin,parent_guard=guard_pin,current31=rows,current34=list(current.values()),frozen2121_expected=frozen,save15_expected=backup['save15'],old341_backup_facts=old_facts,media116=backup['media_facts'],ui=backup['ui'],Root_only_backup_prefix=P+'root_only_current31_backup/',expected_old_backup_total=341,expected_after_backup_total=372,canonical_writes=0,engine_calls=0,save_writes=0)
oldtool=(N/'culture_Router_pin_repair01/backup_current_D581_24_ROOT_ONLY.py').read_text(encoding='utf-8')
tool=oldtool.replace('CreateNew24','CreateNew31').replace('culture_Router_pin_repair01/current_D581_backup24_ROOT_PLAN.json','family_visual_material_loading_repair01/current_F67E_backup31_ROOT_PLAN.json').replace('backup24','backup31').replace('current24','current31').replace('old317','old341').replace('NEW24','NEW31').replace('FULL24','FULL31').replace('D581','F67E').replace('317+len(rows)','341+len(rows)')
assert tool!=oldtool and 'current24'not in tool and 'old317'not in tool
assert not OUT.exists();OUT.mkdir()
files={'current_F67E_exact31_scope_PREPARATION.json':scope_raw,'current_F67E_backup31_ROOT_PLAN.json':enc(plan),'backup_current_F67E_31_ROOT_ONLY.py':tool.encode('utf-8')}
for name,raw in files.items():
 with(OUT/name).open('xb')as f:f.write(raw)
print(json.dumps({name:dict(path=P+name,sha256=sha(raw),bytes=len(raw))for name,raw in files.items()}))
