"""Prepare Root-only JSON14 transport and full read-only guard; no execution."""
from pathlib import Path
import hashlib
N=Path(__file__).resolve().parent
def emit(name,text):
 compile(text,name,'exec');p=N/name;assert not p.exists();raw=text.encode('utf-8')
 with p.open('xb')as f:f.write(raw)
 print(name,hashlib.sha256(raw).hexdigest(),len(raw))
common=[
 ('culture_Router_pin_repair01/current_D581_backup24_ROOT_ACTUAL.json','family_visual_material_loading_repair01/current_F67E_backup31_ROOT_ACTUAL.json'),
 ('4d0ae7e6241e4a8b4ca66d4e845c134e86adaf3fed5dc8676d78fc1f0dabcd51','a6996ef5cd0ce92b52d32214555e17c2394316144df1a1b12a9cfdb6ccc7e0e9'),
 ('CULTURE_ROUTER_EXACT24_STAGED_NOT_DEPLOYED','F67E_VISUAL_MATERIAL_LOADING_EXACT31_STAGED_NOT_DEPLOYED'),
 ('dict(patch_count=10,copy_count=14,total=24)','dict(patch_count=17,copy_count=14,total=31)'),
 ('old317_backup_facts','old341_backup_facts'),
 ('ROOT_CULTURE_ROUTER24_DEPLOYED_GD10_PATCH_JSON14_EXACTCOPY','ROOT_VISUAL_MATERIAL_LOADING31_DEPLOYED_GD17_PATCH_JSON14_EXACTCOPY'),
]
t=(N/'copy_culture_Router_pin24_JSON14_after_GD10_ROOT_ONLY.py').read_text(encoding='utf-8')
changes=common+[
 ('culture_Router_pin_repair01/current_D581_exact24_scope_PREPARATION.json','family_visual_material_loading_repair01/current_F67E_exact31_scope_PREPARATION.json'),
 ('464ed8df58b3a7fc2147aa1236794bfa82da03a0382e1020825ffaa0dcd5016b','b9a60746fe3ed3e12144d88746512b6e609b6262bd7784a4b68421a22654ba07'),
 ("backup['total_backups']==341","backup['total_backups']==372"),
 ('len(targets)==24','len(targets)==31'),
 ('ROOT_EXACT_GD10_PATCH_REQUIRED','ROOT_EXACT_GD17_PATCH_REQUIRED'),
 ('ROOT_CULTURE_ROUTER24_GD10_NEW_JSON14_OLD_PREFLIGHT_ONLY','ROOT_VISUAL_MATERIAL_LOADING31_GD17_NEW_JSON14_OLD_PREFLIGHT_ONLY'),
 ('target_count=24','target_count=31'),('backup_count=341','backup_count=372'),
 ('current_D581_backup_sha256','current_F67E_backup_sha256'),('targets=24','targets=31'),
 ('after GD10 patch','after GD17 patch'),
]
for a,b in changes:assert a in t,a;t=t.replace(a,b)
emit('copy_visual_material_loading31_JSON14_after_GD17_ROOT_ONLY.py',t)
t=(N/'guard_culture_Router_pin24_current2121_ROOT_ONLY.py').read_text(encoding='utf-8')
changes=common+[
 ('culture_Router_pin_repair01/unified24_READY01/unified32_all_candidates_and_inverse_NOT_STAGE.json','family_visual_material_loading_repair01/unified31_READY01/unified32_all_candidates_and_inverse_NOT_STAGE.json'),
 ('85ca1a489a550bde0b410888110c77f322ef6e9f0464a45c7e407fddc2aa4976','75ce628d299b772f95f05065b9cb6490106130b2aaac1e26205ebe4b5f0c78ea'),
 ('len(st)==24','len(st)==31'),("'exact24'","'exact31'"),
 ('old317_backups_exactticks','old341_backups_exactticks'),('new24_backups_exactticks','new31_backups_exactticks'),
 ('ROOT_CULTURE_ROUTER24_POST_CURRENT2121_READONLY_GUARD','ROOT_VISUAL_MATERIAL_LOADING31_POST_CURRENT2121_READONLY_GUARD'),
 ('backups_total=341,authorized_targets=24','backups_total=372,authorized_targets=31'),
]
for a,b in changes:assert a in t,a;t=t.replace(a,b)
marker=" stage=load(a.stage,a.stage_sha256);dep=load(a.deployment,a.deployment_sha256)"
replacement=" classification=load(S+'family_visual_material_loading_repair01/backup31_baseline24_classification_READONLY.json','d37d676559fce588e402b97c262340d8ab981843f0054c68390c56007cf1b2ce');assert classification['passed'] and classification['classified_existing_F67E24']==24 and classification['unclassified_difference_count']==0\n"+marker
assert t.count(marker)==1;t=t.replace(marker,replacement)
emit('guard_visual_material_loading31_current2121_ROOT_ONLY.py',t)
