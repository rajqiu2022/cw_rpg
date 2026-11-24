"""Mechanical current2B86 G-only JSON13 transport specialization; no application."""
from pathlib import Path
import hashlib,json,difflib
N=Path(__file__).resolve().parent;S='res://build/luoyang_city_finish_20261025i_source01/';O=N/'artisan_return_guard_repair01';sha=lambda b:hashlib.sha256(b).hexdigest()
old=N/'copy_pawnshop22_JSON13_after_GD9_ROOT_ONLY.py';parent=old.read_bytes();text=parent.decode()
for a,b in [('Root-only pawn JSON13 exact transport after GD9 patch; current47CC parent; G pawn exit/view and two service leaves only.','Root-only JSON13 exact transport after GD9 patch; current2B86 parent; only G exact Artisan final-clearance foot handling.'),('pawnshop_only_repair01/','artisan_return_guard_repair01/'),('current_47CC_backup22','current_2B86_backup22'),('current_47CC_exact22','current_2B86_exact22'),('75637d956c0d040af9b57fb6374d2b78a8b46b334fcc892c1405de57a1652639','2a6c3794c3d175a0c2a98a4ce650abf340408a2782f86a131256ea620cd6fbea'),('PAWNSHOP_ONLY_EXACT22_STAGED_NOT_DEPLOYED','ARTISAN_EFFECTIVE_RETURN_G_ONLY_EXACT22_STAGED_NOT_DEPLOYED'),('85d08f7c5f95a14c725abc0ec6d0d008c3b56f6bf17269dd2658f70d8289a026','2127d8bc78b15404b8c408bccf1b27442dac4f9ed02949337798bac553f7676d'),("backup['total_backups']==514","backup['total_backups']==648"),('cb41f51bca598a59caf5935b5c7948d0bb6894216827ba3b6b0eb5deb85c14e8','cd613316c4962afdd8df49b0302925c0fbd44b4d75d8567a322784e08ffc2057'),('old492_backup_facts','old626_backup_facts'),('ROOT_PAWNSHOP_ONLY22','ROOT_ARTISAN_EFFECTIVE_RETURN22'),('backup_count=514','backup_count=648'),('current_47CC_backup_sha256','current_2B86_backup_sha256'),('only_G_pawn_function_change_other_C_Field_ENV_DT_Router_UI_native_geometry_masks_unchanged','only_G_Artisan_final_clearance_function_change_other_C_Field_ENV_DT_Router_UI_content_geometry_masks_unchanged')]:
 assert a in text,a;text=text.replace(a,b)
hs=[];aa=parent.decode().splitlines(True);bb=text.splitlines(True)
for z in difflib.SequenceMatcher(None,aa,bb,autojunk=False).get_grouped_opcodes(2):hs.append(dict(old=''.join(aa[z[0][1]:z[-1][2]]),new=''.join(bb[z[0][3]:z[-1][4]])))
f=parent.decode();v=text
for h in hs:assert f.count(h['old'])==1;f=f.replace(h['old'],h['new'],1)
for h in reversed(hs):assert v.count(h['new'])==1;v=v.replace(h['new'],h['old'],1)
assert f==text and v.encode()==parent;compile(text,'copy_artisan_return22_JSON13_after_GD9_ROOT_ONLY.py','exec')
dest=N/'copy_artisan_return22_JSON13_after_GD9_ROOT_ONLY.py';assert not dest.exists()
with dest.open('xb')as f:f.write(text.encode())
proof=dict(parent=dict(path=S+old.name,sha256=sha(parent)),candidate=dict(path=S+dest.name,sha256=sha(text.encode())),hunks=hs,whole_UTF8_inverse=True,canonical_writes=0,engine_calls=0)
b=(json.dumps(proof,ensure_ascii=False,indent=2)+'\n').encode()
with(O/'JSON13_copy_transport_whole_inverse_NOT_EXECUTED.json').open('xb')as f:f.write(b)
print(json.dumps(dict(tool=proof['candidate'],proof_sha256=sha(b))))
