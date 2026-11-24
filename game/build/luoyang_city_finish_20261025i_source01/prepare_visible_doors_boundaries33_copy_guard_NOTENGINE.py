"""Root-only JSON15 transport and full guard, mechanical prior-tool successor."""
from pathlib import Path
import hashlib,json
N=Path(__file__).resolve().parent
S='res://build/luoyang_city_finish_20261025i_source01/'
B=S+'visible_doors_boundaries33_repair01/'
sha=lambda b:hashlib.sha256(b).hexdigest()
proofs=[]
def emit(parent_name,child_name,changes,extra_insert=None):
    parent=(N/parent_name).read_bytes();text=parent.decode();edits=[]
    for a,b in changes:
        assert a in text,a;edits.append(dict(old=a,new=b,count=text.count(a)));text=text.replace(a,b)
    if extra_insert:
        a,b=extra_insert;assert text.count(a)==1;edits.append(dict(old=a,new=b,count=1));text=text.replace(a,b)
    back=text
    for h in reversed(edits):
        assert back.count(h['new'])==h['count'],h['new'];back=back.replace(h['new'],h['old'])
    assert back.encode()==parent
    compile(text,child_name,'exec')
    dest=N/child_name;assert not dest.exists()
    with dest.open('xb')as stream:stream.write(text.encode())
    proofs.append(dict(parent=dict(path=S+parent_name,sha256=sha(parent)),candidate=dict(path=S+child_name,sha256=sha(text.encode())),changes=edits,whole_byte_inverse=True,copy_or_guard_calls=0))
    print(child_name,sha(text.encode()),len(text.encode()))
common=[
    ('temple_signed_iid_repair01/current_377B_backup31_ROOT_ACTUAL.json','visible_doors_boundaries33_repair01/current_signed31_backup33_ROOT_ACTUAL.json'),
    ('8e8f484f0f9b0531969b4e227b5f71abd818dc4935fd568890ad79501bb76026','2b2be04ce2ee27e8f9d6782181a5f6999921a416ada094b9cafadb043742bff3'),
    ('CURRENT377B_SIGNED_TEMPLE_EXACT31_STAGED_NOT_DEPLOYED','CURRENT_SIGNED31_VISIBLE_DOORS_BOUNDARIES_EXACT33_STAGED_NOT_DEPLOYED'),
    ('dict(patch_count=17,copy_count=14,total=31)','dict(patch_count=18,copy_count=15,total=33)'),
    ('old372_backup_facts','old403_backup_facts'),
    ('ROOT_SIGNED_TEMPLE31_DEPLOYED_GD17_PATCH_JSON14_EXACTCOPY','ROOT_VISIBLE_DOORS_BOUNDARIES33_DEPLOYED_GD18_PATCH_JSON15_EXACTCOPY'),
    ('JSON14_written','JSON15_written'),
]
supplement=""" supplement=load(S+'visible_doors_boundaries33_repair01/additional_trial02_gate_for_DC81_READONLY.json','056a5840b250d12767ca66d90a90baa0393bed06f5761fe122f7876a8680773f')
 assert supplement['passed'] and supplement['stage']==dict(path=a.stage,sha256=a.stage_sha256) and supplement['new_authorization_basis']==dict(path=S+'finish8_ROOT_TRIAL_PERMISSION02.json',sha256='7bcb3165485026f4ff2c15ebb0dfa696c6780ed2cad238933201f715abdca82a')
"""
emit('copy_signed_Temple31_JSON14_after_GD17_ROOT_ONLY.py','copy_visible_doors_boundaries33_JSON15_after_GD18_ROOT_ONLY.py',common+[
    ('Root-only exact JSON14 transport after GD17 patch; current4160 immutable parent.','Root-only exact JSON15 transport after GD18 patch; signed31 exact parent plus explicit new02 supplemental authorization gate.'),
    ('temple_signed_iid_repair01/current_377B_exact31_scope_PREPARATION.json','visible_doors_boundaries33_repair01/closure_READY01/current_signed31_exact33_scope_PREPARATION.json'),
    ('9e314a4d78bf08d9e4b336a5d49a6ce95f5d84a2f266043ebf86ff1cf294b527','0bf33b2c8c103d44a1db7e7056bb56b049a0327f0c9d62087848172c97397efa'),
    ("backup['total_backups']==403","backup['total_backups']==436"),
    ("len(plan['rows'])==14","len(plan['rows'])==15"),
    ('len(targets)==31','len(targets)==33'),
    ('ROOT_EXACT_GD17_PATCH_REQUIRED','ROOT_EXACT_GD18_PATCH_REQUIRED'),
    ('ROOT_SIGNED_TEMPLE31_GD17_NEW_JSON14_OLD_PREFLIGHT_ONLY','ROOT_VISIBLE_DOORS_BOUNDARIES33_GD18_NEW_JSON15_OLD_PREFLIGHT_ONLY'),
    ('target_count=31','target_count=33'),('backup_count=403','backup_count=436'),
    ('current_377B_backup_sha256','current_signed31_backup_sha256'),
    ('targets=31','targets=33'),
],(" scope=load(",supplement+" scope=load("))

authorized=""" assert backup['passed'] and backup['total_backups']==436 and backup['external_save_changes']==[]
 assert len(backup['differences'])==1
 authorized=backup['differences'][0]
 assert authorized['path'].replace('\\\\','/').casefold().endswith('/prompts/tasks.yaml') and authorized['expected']['sha256']=='1d337a0c8f9b220f0d36cf7ff87e50159d59f468bc0f39c4a3f6927f3de976b7' and authorized['expected']['bytes']==786954 and authorized['current']['sha256']=='f1c19ee105a114ef1878219c4834afc0b5f1ce04859eaae9498370fee2db8b3f' and authorized['current']['bytes']==790177
"""
emit('guard_signed_Temple31_current2121_ROOT_ONLY.py','guard_visible_doors_boundaries33_current2121_ROOT_ONLY.py',common+[
    ('temple_signed_iid_repair01/unified31_READY01/unified31_ROOT_BACKUP_FIXED_NOT_STAGE.json','visible_doors_boundaries33_repair01/unified33_READY02/unified33_ROOT_BACKUP_FIXED_NOT_STAGE.json'),
    ('c7896af45a53d8eb45f6bc0f5f6fd794fa40c8999af1757906fa8ec7812a8aa7','86282dad5be672f76cb54f383e32a2c4e2a12fe3aad2377c65eade7c59e6e4c9'),
    (" assert backup['passed'] and backup['differences']==[] and backup['total_backups']==403 and backup['external_save_changes']==[]\n",authorized),
    ("len(dep['JSON15_written'])==14","len(dep['JSON15_written'])==15"),
    ('len(st)==31','len(st)==33'),('exact31','exact33'),('old372_backups_exactticks','old403_backups_exactticks'),
    ('new31_backups_exactticks','new33_backups_exactticks'),('all116_media_exactticks','all125_media_exactticks'),
    ('ROOT_SIGNED_TEMPLE31_POST_CURRENT2121_READONLY_GUARD','ROOT_VISIBLE_DOORS_BOUNDARIES33_POST_CURRENT2121_READONLY_GUARD'),
    ('backups_total=403','backups_total=436'),('authorized_targets=31','authorized_targets=33'),
    ('tasks_preexisting_1D33_preserved_not_reauthorized=True','tasks_Root_authorized_F1C1_790177_preserved=True'),
],(" expected={",supplement+" expected={"))
proof=dict(status='ROOT_ONLY_JSON15_AND_READONLY_GUARD_PREPARED_NOT_EXECUTED',records=proofs,only_JSON_copy_no_GD_copy=True,supplement_new02_required=True,copy_calls=0,guard_calls=0,canonical_writes=0)
dest=N/'visible_doors_boundaries33_repair01/copy_guard_mechanical_source_changes_NOT_EXECUTED.json';raw=(json.dumps(proof,ensure_ascii=False,indent=2)+'\n').encode()
with dest.open('xb')as stream:stream.write(raw)
print(dest.name,sha(raw),len(raw))
