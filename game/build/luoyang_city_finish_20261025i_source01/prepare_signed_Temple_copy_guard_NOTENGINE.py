"""Root JSON14-only transport and post guard preparation, never execution."""
from pathlib import Path
import hashlib,json
N=Path(__file__).resolve().parent
def sha(b):return hashlib.sha256(b).hexdigest()
proofs=[]
def emit(oldname,newname,changes):
 parent=(N/oldname).read_bytes();t=parent.decode('utf8');applied=[]
 for a,b in changes:
  assert a in t,a;t=t.replace(a,b);applied.append(dict(old=a,new=b))
 compile(t,newname,'exec');dest=N/newname
 with dest.open('xb')as stream:stream.write(t.encode())
 proofs.append(dict(parent=oldname,parent_sha256=sha(parent),candidate=newname,candidate_sha256=sha(t.encode()),literal_or_statement_changes=applied,all_copy_only_JSON14_and_readonly_protection_logic_retained=True))
 print(newname,sha(t.encode()),len(t.encode()))
common=[
 ('family_visual_material_loading_repair01/current_F67E_backup31_ROOT_ACTUAL.json','temple_signed_iid_repair01/current_377B_backup31_ROOT_ACTUAL.json'),
 ('a6996ef5cd0ce92b52d32214555e17c2394316144df1a1b12a9cfdb6ccc7e0e9','8e8f484f0f9b0531969b4e227b5f71abd818dc4935fd568890ad79501bb76026'),
 ('F67E_VISUAL_MATERIAL_LOADING_EXACT31_STAGED_NOT_DEPLOYED','CURRENT377B_SIGNED_TEMPLE_EXACT31_STAGED_NOT_DEPLOYED'),
 ('old341_backup_facts','old372_backup_facts'),
 ('ROOT_VISUAL_MATERIAL_LOADING31_DEPLOYED_GD17_PATCH_JSON14_EXACTCOPY','ROOT_SIGNED_TEMPLE31_DEPLOYED_GD17_PATCH_JSON14_EXACTCOPY'),
]
emit('copy_visual_material_loading31_JSON14_after_GD17_ROOT_ONLY.py','copy_signed_Temple31_JSON14_after_GD17_ROOT_ONLY.py',common+[
 ('family_visual_material_loading_repair01/current_F67E_exact31_scope_PREPARATION.json','temple_signed_iid_repair01/current_377B_exact31_scope_PREPARATION.json'),
 ('b9a60746fe3ed3e12144d88746512b6e609b6262bd7784a4b68421a22654ba07','9e314a4d78bf08d9e4b336a5d49a6ce95f5d84a2f266043ebf86ff1cf294b527'),
 ("backup['total_backups']==372","backup['total_backups']==403"),
 ('ROOT_VISUAL_MATERIAL_LOADING31_GD17_NEW_JSON14_OLD_PREFLIGHT_ONLY','ROOT_SIGNED_TEMPLE31_GD17_NEW_JSON14_OLD_PREFLIGHT_ONLY'),
 ('backup_count=372','backup_count=403'),('current_F67E_backup_sha256','current_377B_backup_sha256'),
])
classification=" classification=load(S+'family_visual_material_loading_repair01/backup31_baseline24_classification_READONLY.json','d37d676559fce588e402b97c262340d8ab981843f0054c68390c56007cf1b2ce');assert classification['passed'] and classification['classified_existing_F67E24']==24 and classification['unclassified_difference_count']==0\n"
emit('guard_visual_material_loading31_current2121_ROOT_ONLY.py','guard_signed_Temple31_current2121_ROOT_ONLY.py',common+[
 ('family_visual_material_loading_repair01/unified31_READY01/unified32_all_candidates_and_inverse_NOT_STAGE.json','temple_signed_iid_repair01/unified31_READY01/unified31_ROOT_BACKUP_FIXED_NOT_STAGE.json'),
 ('75ce628d299b772f95f05065b9cb6490106130b2aaac1e26205ebe4b5f0c78ea','c7896af45a53d8eb45f6bc0f5f6fd794fa40c8999af1757906fa8ec7812a8aa7'),
 (classification," assert backup['passed'] and backup['differences']==[] and backup['total_backups']==403 and backup['external_save_changes']==[]\n"),
 ('old341_backups_exactticks','old372_backups_exactticks'),
 ('ROOT_VISUAL_MATERIAL_LOADING31_POST_CURRENT2121_READONLY_GUARD','ROOT_SIGNED_TEMPLE31_POST_CURRENT2121_READONLY_GUARD'),
 ('backups_total=372','backups_total=403'),
])
dest=N/'temple_signed_iid_repair01/copy_guard_mechanical_source_changes_NOT_EXECUTED.json'
with dest.open('xb')as stream:stream.write((json.dumps(dict(status='ROOT_ONLY_PREPARED_NOT_EXECUTED',records=proofs,canonical_writes=0,guard_calls=0),ensure_ascii=False,indent=2)+'\n').encode())
