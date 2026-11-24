"""Classify Root-recorded24 differences without touching/rescanning any target."""
from pathlib import Path
import hashlib,json
N=Path(__file__).resolve().parent;G=N.parents[1]
S='res://build/luoyang_city_finish_20261025i_source01/';P=S+'family_visual_material_loading_repair01/'
def sha(b):return hashlib.sha256(b).hexdigest()
def load(path,h):
 b=(G/path[6:]).read_bytes();assert sha(b)==h;return json.loads(b)
def as_res(path):
 if path.startswith('res://'):return path
 normalized=path.replace('\\','/')
 while '//'in normalized:normalized=normalized.replace('//','/')
 prefix='F:/Code/RPG_GAME/game/';assert normalized.startswith(prefix),path
 return 'res://'+normalized[len(prefix):]
backup_pin=dict(path=P+'current_F67E_backup31_ROOT_ACTUAL.json',sha256='a6996ef5cd0ce92b52d32214555e17c2394316144df1a1b12a9cfdb6ccc7e0e9')
dep_pin=dict(path=S+'culture_Router_pin_repair01/culture_Router24_deployed_ROOT_ACTUAL.json',sha256='f67e767260e80ea5d1e8ce9d715e7e2dec015212f041d851559cc60add56619a')
backup=load(backup_pin['path'],backup_pin['sha256']);dep=load(dep_pin['path'],dep_pin['sha256'])
assert backup['passed'] and backup['total_backups']==372 and len(backup['new_backups'])==31 and len(backup['differences'])==24
fixed={r['target']:r for r in dep['targets']};assert len(fixed)==24
facts={r['path']:{k:v for k,v in r.items()if k!='path'}for r in backup['frozen2121_current_facts']};assert len(facts)==2121
rows=[]
for difference in backup['differences']:
 target=as_res(difference['path']);assert target in fixed;expected=fixed[target]
 approved=dict(exists=True,sha256=expected['sha256'],bytes=expected['bytes'],ticks=expected['ticks'])
 assert difference['current']==approved and facts[difference['path']]==approved
 rows.append(dict(target=target,frozen_absolute_path=difference['path'],plan_old_D581_fact=difference['expected'],Root_observed_current=difference['current'],fixed_F67E_deployment_fact=approved,classification='EXACT_PREEXISTING_AUTHORIZED_F67E24_NOT_USER_DRIFT_NOT_THIS_BATCH'))
assert {r['target']for r in rows}==set(fixed)
report=dict(status='READONLY_POST_CLASSIFICATION_OF_ROOT_BACKUP31_BASELINE24_NO_RESCAN',passed=True,backup=backup_pin,fixed_deployment=dep_pin,recorded_original_difference_count=24,classified_existing_F67E24=len(rows),unclassified_difference_count=0,other2097_same_against_recorded_plan=True,rows=rows,root_cause='Preparation overlay matched resource-path keys against absolute-path2121 keys, so the plan retained oldD581 facts for24 already-authorizedF67E files. Original plan/report retained; actual current34 and protected backups/saves/media/UI gates had passed.',next_guard_parent='Use this Root backup actual frozen2121_current_facts as exact current baseline; overlay only the next approved31 candidates after actual deployment.',old_341_backups_retained=True,new31_retained=True,total_backups=372,save15_recorded_unchanged=not backup['external_save_changes'],original_plan_or_report_overwritten=False,engine_calls=0,collector_calls=0,canonical_writes=0,target_reads=0)
out=N/'family_visual_material_loading_repair01/backup31_baseline24_classification_READONLY.json';assert not out.exists();raw=(json.dumps(report,ensure_ascii=False,indent=2,allow_nan=False)+'\n').encode('utf-8')
with out.open('xb')as f:f.write(raw)
print(json.dumps(dict(path=P+out.name,sha256=sha(raw),bytes=len(raw),classified24=len(rows),unclassified=0,other2097_same=True)))
