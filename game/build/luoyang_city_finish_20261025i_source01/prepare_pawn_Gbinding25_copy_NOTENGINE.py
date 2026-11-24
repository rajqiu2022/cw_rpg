"""Only current6C01 mechanical head of Root's JSON14 transport; never execute."""
from pathlib import Path
import hashlib,json,difflib
N=Path(__file__).resolve().parent;S='res://build/luoyang_city_finish_20261025i_source01/';P=S+'pawnshop_collision_Gbinding_repair01/'
old=N/'copy_pawn_collision25_JSON14_after_GD11_ROOT_ONLY.py';parent=old.read_bytes();text=parent.decode()
for a,b in [('Root-only exact JSON14 transport after GD11 patch; current9C1245 parent; only exact-pawn Field local nine-base collider bridge and necessary pins.','Root-only exact JSON14 transport after GD11 patch; current6C01 parent; only exact-pawn Field two G receivers and necessary pins.'),('PAWN_LOCAL_COLLISION_EXACT25_STAGED_NOT_DEPLOYED','PAWN_G_RECEIVER_EXACT25_STAGED_NOT_DEPLOYED'),('pawnshop_collision_repair01/current_9C1245_backup25_ROOT_ACTUAL.json','pawnshop_collision_Gbinding_repair01/current_6C01_backup25_ROOT_ACTUAL.json'),('50fe87abfd647b11f7dacbc5863bc294ddde389579a2b1099958ca25b3c89bf0','2f0de4cd1346436e77992b9c76cf206c61d96354a7af27a27d7f0e8d8188032d'),('pawnshop_collision_repair01/current_9C1245_exact25_scope_PREPARATION.json','pawnshop_collision_Gbinding_repair01/current_6C01_exact25_scope_PREPARATION.json'),('f1d6bfa254e836a901c3131010009328bf3e77931d7fe1bef53040f55c2b4304','c5655ce1412103a570ff8f45bb91b8d7b4d64d8005dc2c03c0db5edb78b1277e'),("backup['total_backups']==539","backup['total_backups']==564"),('pawnshop_collision_repair01/current_9C1245_backup25_ROOT_PLAN.json','pawnshop_collision_Gbinding_repair01/current_6C01_backup25_ROOT_PLAN.json'),('ecfbed6312a30eae6f7cd78bea3f975a8cf5e5058ad306babf4c027188e24f16','3428c387887bc1c37edb004251f1f161d89dc9ed7c6a08701db2c26bcafd9dca'),('old514_backup_facts','old539_backup_facts'),('ROOT_PAWN_LOCAL_BODIES25','ROOT_PAWN_G_RECEIVERS25'),('backup_count=539','backup_count=564'),('current_9C1245_backup_sha256','current_6C01_backup_sha256')]:
    assert a in text,a;text=text.replace(a,b)
aa=parent.decode().splitlines(True);bb=text.splitlines(True);hs=[]
for z in difflib.SequenceMatcher(None,aa,bb,autojunk=False).get_grouped_opcodes(2):hs.append(dict(old=''.join(aa[z[0][1]:z[-1][2]]),new=''.join(bb[z[0][3]:z[-1][4]])))
f=parent.decode();v=text
for h in hs:assert f.count(h['old'])==1;f=f.replace(h['old'],h['new'],1)
for h in reversed(hs):assert v.count(h['new'])==1;v=v.replace(h['new'],h['old'],1)
assert f==text and v.encode()==parent;compile(text,'copy_pawn_Gbinding25_JSON14_after_GD11_ROOT_ONLY.py','exec')
dest=N/'copy_pawn_Gbinding25_JSON14_after_GD11_ROOT_ONLY.py';assert not dest.exists()
with dest.open('xb')as f:f.write(text.encode())
sha=lambda b:hashlib.sha256(b).hexdigest()
proof=dict(parent=dict(path=S+old.name,sha256=sha(parent)),candidate=dict(path=S+dest.name,sha256=sha(dest.read_bytes())),hunks=hs,whole_UTF8_inverse=True,same_JSON14_only_GD11_patch_preflight_and_protection_logic=True,backup564_sourcecurrent37_media128_World54_save15=True,execution_calls=0,engine_calls=0,canonical_writes=0)
b=(json.dumps(proof,ensure_ascii=False,indent=2,allow_nan=False)+'\n').encode();p=N/'pawnshop_collision_Gbinding_repair01/copy25_transport_whole_inverse_NOT_EXECUTED.json';assert not p.exists()
with p.open('xb')as f:f.write(b)
print(json.dumps(dict(tool=proof['candidate'],proof=dict(path=P+p.name,sha256=sha(b)))))
