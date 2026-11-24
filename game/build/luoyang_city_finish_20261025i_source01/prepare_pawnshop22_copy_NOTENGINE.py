"""Prepare only Root's JSON13 transport after GD9 apply_patch; never execute it."""
from pathlib import Path
import json,hashlib,difflib
N=Path(__file__).resolve().parent;S='res://build/luoyang_city_finish_20261025i_source01/';P=S+'pawnshop_only_repair01/'
old=N/'copy_Estate_wall_source31_JSON14_after_GD17_ROOT_ONLY.py';before=old.read_bytes();text=before.decode('utf-8')
changes=[
('Root-only exact JSON14 transport after GD17 patch; current0860 immutable parent; Estate type/scale repair and Yamen existing tuple only.','Root-only pawn JSON13 exact transport after GD9 patch; current47CC parent; G pawn exit/view and two service leaves only.'),
("stage['source_first'].get(S+'finish8_ROOT_TRIAL_PERMISSION02.json')=='7bcb3165485026f4ff2c15ebb0dfa696c6780ed2cad238933201f715abdca82a'","stage['source_first'].get(S+'pawnshop_only_repair01/current_47CC_backup22_ROOT_ACTUAL.json')=='75637d956c0d040af9b57fb6374d2b78a8b46b334fcc892c1405de57a1652639'"),
('ESTATE_WALL_SOURCE_EXACT31_STAGED_NOT_DEPLOYED','PAWNSHOP_ONLY_EXACT22_STAGED_NOT_DEPLOYED'),
('dict(patch_count=17,copy_count=14,total=31)','dict(patch_count=9,copy_count=13,total=22)'),
('Estate_wall_source_repair01/current_0860_exact31_scope_PREPARATION.json','pawnshop_only_repair01/current_47CC_exact22_scope_PREPARATION.json'),
('3282faaa05a467ddf11315b78001c84705a036d9eb015802488882fd720ea957','85d08f7c5f95a14c725abc0ec6d0d008c3b56f6bf17269dd2658f70d8289a026'),
('Estate_wall_source_repair01/current_0860_backup31_ROOT_ACTUAL.json','pawnshop_only_repair01/current_47CC_backup22_ROOT_ACTUAL.json'),
('ad48454d8798b51b1076fe1482f842373ed78cd2b96a29a7053caaa90c6a631e','75637d956c0d040af9b57fb6374d2b78a8b46b334fcc892c1405de57a1652639'),
("backup['total_backups']==492","backup['total_backups']==514"),
("len(plan['rows'])==14","len(plan['rows'])==13"),('len(targets)==31','len(targets)==22'),
("backup['old461_backup_facts']","backup['old492_backup_facts']"),
("backup['current36']","backup['current37']"),('ROOT_EXACT_GD17_PATCH_REQUIRED','ROOT_EXACT_GD9_PATCH_REQUIRED'),
('ROOT_ESTATE_WALL_SOURCE31_DEPLOYED_GD17_PATCH_JSON14_EXACTCOPY','ROOT_PAWNSHOP_ONLY22_DEPLOYED_GD9_PATCH_JSON13_EXACTCOPY'),
('ROOT_ESTATE_WALL_SOURCE31_GD17_NEW_JSON14_OLD_PREFLIGHT_ONLY','ROOT_PAWNSHOP_ONLY22_GD9_NEW_JSON13_OLD_PREFLIGHT_ONLY'),
('target_count=31','target_count=22'),('JSON14_written=written','JSON13_written=written'),('backup_count=492','backup_count=514'),
('current_0860_backup_sha256','current_47CC_backup_sha256'),
('no_G_DT_Router_UI_native_geometry_mask_changes=True','only_G_pawn_function_change_other_C_Field_ENV_DT_Router_UI_native_geometry_masks_unchanged=True'),
('targets=31','targets=22')]
for a,b in changes:assert a in text,a;text=text.replace(a,b)
a=" for r in backup['frozen2121_current_facts']+backup['old492_backup_facts']+backup['media_facts']:protect(r['path'],r)"
b=" frozenplan=load(S+'pawnshop_only_repair01/current_47CC_backup22_ROOT_PLAN.json','cb41f51bca598a59caf5935b5c7948d0bb6894216827ba3b6b0eb5deb85c14e8')\n for r in backup['frozen2121_current_facts']+backup['old492_backup_facts']+backup['media_facts']+frozenplan['World54']:protect(r['path'],r)"
assert text.count(a)==1;text=text.replace(a,b)
aa=before.decode().splitlines(keepends=True);bb=text.splitlines(keepends=True);hs=[]
for group in difflib.SequenceMatcher(None,aa,bb,autojunk=False).get_grouped_opcodes(2):hs.append(dict(old=''.join(aa[group[0][1]:group[-1][2]]),new=''.join(bb[group[0][3]:group[-1][4]])))
f=before.decode();v=text
for h in hs:assert f.count(h['old'])==1;f=f.replace(h['old'],h['new'],1)
for h in reversed(hs):assert v.count(h['new'])==1;v=v.replace(h['new'],h['old'],1)
assert f==text and v.encode()==before;compile(text,'copy_pawnshop22_JSON13_after_GD9_ROOT_ONLY.py','exec')
dest=N/'copy_pawnshop22_JSON13_after_GD9_ROOT_ONLY.py';assert not dest.exists()
with dest.open('xb')as f:f.write(text.encode('utf-8'))
sha=lambda b:hashlib.sha256(b).hexdigest()
proof=dict(parent=dict(path=S+old.name,sha256=sha(before)),candidate=dict(path=S+dest.name,sha256=sha(dest.read_bytes())),hunks=hs,whole_UTF8_inverse=True,only_JSON13_exact_copy=True,GD_writes=0,additional_World54_protection_from_fixed_current_plan=True,execution_calls=0,canonical_writes=0)
raw=(json.dumps(proof,ensure_ascii=False,indent=2,allow_nan=False)+'\n').encode();p=N/'pawnshop_only_repair01/copy22_transport_whole_inverse_NOT_EXECUTED.json';assert not p.exists()
with p.open('xb')as f:f.write(raw)
print(json.dumps(dict(tool=proof['candidate'],proof=dict(path=P+p.name,sha256=sha(raw)))))
