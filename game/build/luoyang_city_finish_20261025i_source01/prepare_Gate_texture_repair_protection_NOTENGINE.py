"""Only builds the Root-only observation/backup plan; does not observe or copy current files."""
from pathlib import Path
import json,hashlib,re
N=Path(__file__).resolve().parent;G=N.parents[1];NS='res://build/luoyang_city_finish_20261025i_source01/';OUT=N/'gate_texture_repair01';P=NS+OUT.name+'/'
def sha(b):return hashlib.sha256(b).hexdigest()
def enc(v):return(json.dumps(v,ensure_ascii=False,indent=2,allow_nan=False)+'\n').encode()
def load(path,h):
 b=(G/path[6:]).read_bytes();assert sha(b)==h,(path,sha(b));return json.loads(b)
dp=dict(path=NS+'exact32_deployed_ROOT_ACTUAL.json',sha256='4160b4c149a71bd0e6dfa8975b0fc5f463f782f0fcff50acd630335b5ccd3142');dep=load(**dict(path=dp['path'],h=dp['sha256']));assert dep['passed']is True and dep['target_count']==32
fp=dict(path=NS+'fresh25i_protection_observation02.json',sha256='53f2f27efaac24701cc807c648fd0d4d38930c7905eed18fc0dd1589dddfef58');fresh=load(fp['path'],fp['sha256'])
bp=dict(path=NS+'immutable_current32_ROOT_EXECUTED.json',sha256='d11ebf3713b0a3fde47c335e6c37a8d367bcb7388c484efd3275e352f8e1ef1f');oldbackup=load(bp['path'],bp['sha256'])
save_by_file={Path(p).name:p for p in oldbackup['save_before']};assert len(save_by_file)==15
def fixed_path(p):
 # Prior observation contains console-encoded user directory aliases; the Root
 # actual backup supplies the independently fixed real fifteen absolute paths.
 name=Path(p).name
 if name in save_by_file and 'app_userdata' in p:return save_by_file[name]
 return p
baseline={}
for r in fresh['groups']['current_facts']:
 p=fixed_path(r['path']);assert p not in baseline;baseline[p]={k:r[k]for k in ['exists','sha256','bytes','ticks']if k in r}
assert len(baseline)==2121
current32=[dict(target=r['target'],sha256=r['sha256'],bytes=r['bytes'],deployment_ticks=r['ticks'],immutable_candidate=r['candidate_path'],backup=P+'root_only_current32_backup/'+r['target'][6:])for r in dep['targets']]
for r in current32:
 # Upgrade old frozen current-source expectations only by actual deployment values.
 p=r['target'];absolute=str((G/p[6:]).resolve());matches=[k for k in baseline if k.replace('\\','/').lower()==absolute.replace('\\','/').lower()or k==p]
 if matches:
  assert len(matches)==1;baseline[matches[0]]=dict(exists=True,sha256=r['sha256'],bytes=r['bytes'],ticks=r['deployment_ticks'])
oldbacks=list(fresh['groups']['backups_current']);assert len(oldbacks)==176
newbacks=[dict(path=r['immutable_old'],sha256=r['backup_sha256'],bytes=r['before']['bytes'],original_source_ticks=r['before']['ticks'])for r in oldbackup['rows']];assert len(newbacks)==32
media={}
def m(p,h,n,provenance):
 if p in media:assert media[p]['sha256']==h
 media[p]=dict(path=p,sha256=h,bytes=n,provenance=provenance)
for r in fresh['groups']['old_media_current']:m(r['path'],r['sha256'],r['bytes'],'original8_current_observation')
for path,h in [('res://build/luoyang_city_finish_20261025i_art01/ten_media30_promotion_ROOT_EXECUTED.json','43289bd6757cb470cdafb955658a386b04faea0143a91d18916fd76461d798a1'),('res://build/luoyang_city_finish_20261025i_system01/qa_role_new/finish7_mask_media_promotion07_ROOT_ONLY/promotion_ROOT_EXECUTED.json','aba31957cb919a94a6138b39f253c48cd390e486e989cb3ac979a36d47806d3b')]:
 for r in load(path,h)['written']:m(r['path'],r['sha256'],r['bytes'],path)
publication=load(NS+'publication11/output_ROOT_READY/109200/result.json','f4925d3ff6e57900a0f7ac0c1549b9477fe9ce3ad255882096a3cd956222df66')
for r in publication['scenes'].values():
 if r.get('mask',{}).get('path'):m(r['mask']['path'],r['mask']['sha256'],r['mask'].get('bytes'), 'fixed_F492_mask_raw')
# World was only prepared, not deployed. Its promoted54 media remain separate protection.
world=load('res://build/luoyang_city_finish_20261025i_art01/world24d_heads01/world18_ingress04/world18_ROOT_TRIAL_source_handoff01.json','6eecf2f353d62646ec2160c382a885f3dca6247340f0a8155875d718bfdf3038')
world_media=[{k:r[k]for k in ['path','sha256','bytes']}for r in world['54_actual_media']]
plan=dict(status='ROOT_ONLY_CURRENT4160_PROTECTION_AND_OPTIONAL32_BACKUP_PLAN_NOT_EXECUTED',parent_deployment=dp,parent_Stage=dep['stage'],parent_fresh=fp,older32_backup=bp,counts=dict(current32=32,frozen_observation=2121,saves=15,old_backups=176,previous_root_backups=32,backups_total=208,city_media=len(media),separate_World_media=54),current32=current32,frozen2121_expected=baseline,save15_paths=sorted(save_by_file.values()),save15_old_Root_actual_facts=oldbackup['save_before'],old176_backup_facts=oldbacks,previous32_backup_sources=newbacks,city_media=list(media.values()),separate_World_media=world_media,ui_expected=next(dict(path=r['path'],**{k:r[k]for k in ['exists','sha256','bytes','ticks']if k in r})for r in fresh['groups']['current_facts']if r['path'].replace('\\','/').endswith('/game/scripts/ui/dialog_box.gd')),no_new_source_authority_from_observation=True,unexpected_changes_preserved_not_rolled_back=True,final_repair_scope_not_frozen=True,preparation_only=True,backup_execution_requires_Root_flag=True,backup_superset_may_exceed_final_nonnoop_targets_but_is_never_deleted=True,World_deployment_paused=True,canonical_writes=0,engine_calls=0,collector_calls=0)
assert not OUT.exists();OUT.mkdir();raw=enc(plan)
with(OUT/'current4160_protection_and_backup32_ROOT_PLAN.json').open('xb')as f:f.write(raw)
print(json.dumps(dict(path=P+'current4160_protection_and_backup32_ROOT_PLAN.json',sha256=sha(raw),counts=plan['counts'])))
