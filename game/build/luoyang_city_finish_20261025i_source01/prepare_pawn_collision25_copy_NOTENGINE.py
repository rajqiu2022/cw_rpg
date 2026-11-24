"""Prepare Root-only JSON14 exact transport after GD11; no execution."""
from pathlib import Path
import hashlib,json,difflib
N=Path(__file__).resolve().parent;S='res://build/luoyang_city_finish_20261025i_source01/';P=S+'pawnshop_collision_repair01/'
old=N/'copy_Temple_actor_receipt25_JSON14_after_GD11_ROOT_ONLY.py';parent=old.read_bytes();text=parent.decode()
changes=[('Root-only exact JSON14 transport after GD11 patch; current E53E immutable parent; only Temple receipt bridge logic plus source pins.','Root-only exact JSON14 transport after GD11 patch; current9C1245 parent; only exact-pawn Field local nine-base collider bridge and necessary pins.'),("stage['source_first'].get(S+'finish8_ROOT_TRIAL_PERMISSION02.json')=='7bcb3165485026f4ff2c15ebb0dfa696c6780ed2cad238933201f715abdca82a'","stage['source_first'].get(S+'pawnshop_collision_repair01/current_9C1245_backup25_ROOT_ACTUAL.json')=='50fe87abfd647b11f7dacbc5863bc294ddde389579a2b1099958ca25b3c89bf0'"),('TEMPLE_ACTOR_RECEIPT_EXACT25_STAGED_NOT_DEPLOYED','PAWN_LOCAL_COLLISION_EXACT25_STAGED_NOT_DEPLOYED'),('Temple_actor_receipt_repair01/current_E53E_exact25_scope_PREPARATION.json','pawnshop_collision_repair01/current_9C1245_exact25_scope_PREPARATION.json'),('f3736e4206935a35f5055bf0d7518f2ef1941e554329e7e6e828a29ba676e974','f1d6bfa254e836a901c3131010009328bf3e77931d7fe1bef53040f55c2b4304'),('Temple_actor_receipt_repair01/current_E53E_backup25_ROOT_ACTUAL.json','pawnshop_collision_repair01/current_9C1245_backup25_ROOT_ACTUAL.json'),('6cbdb68683733bc819978936225476bf4bf5ff16b2efb7f01b05a7af23b9e6bf','50fe87abfd647b11f7dacbc5863bc294ddde389579a2b1099958ca25b3c89bf0'),("backup['total_backups']==461","backup['total_backups']==539"),("backup['old436_backup_facts']","backup['old514_backup_facts']"),("backup['current36']","backup['current37']"),('ROOT_TEMPLE_ACTOR_RECEIPT25_DEPLOYED_GD11_PATCH_JSON14_EXACTCOPY','ROOT_PAWN_LOCAL_BODIES25_DEPLOYED_GD11_PATCH_JSON14_EXACTCOPY'),('ROOT_TEMPLE_ACTOR_RECEIPT25_GD11_NEW_JSON14_OLD_PREFLIGHT_ONLY','ROOT_PAWN_LOCAL_BODIES25_GD11_NEW_JSON14_OLD_PREFLIGHT_ONLY'),('backup_count=461','backup_count=539'),('current_E53E_backup_sha256','current_9C1245_backup_sha256')]
for a,b in changes:assert a in text,a;text=text.replace(a,b)
a=" for r in backup['frozen2121_current_facts']+backup['old514_backup_facts']+backup['media_facts']:protect(r['path'],r)"
b=" fixedplan=load(S+'pawnshop_collision_repair01/current_9C1245_backup25_ROOT_PLAN.json','ecfbed6312a30eae6f7cd78bea3f975a8cf5e5058ad306babf4c027188e24f16')\n for r in backup['frozen2121_current_facts']+backup['old514_backup_facts']+backup['media_facts']+fixedplan['World54']:protect(r['path'],r)"
assert text.count(a)==1;text=text.replace(a,b)
aa=parent.decode().splitlines(keepends=True);bb=text.splitlines(keepends=True);hs=[]
for z in difflib.SequenceMatcher(None,aa,bb,autojunk=False).get_grouped_opcodes(2):hs.append(dict(old=''.join(aa[z[0][1]:z[-1][2]]),new=''.join(bb[z[0][3]:z[-1][4]])))
f=parent.decode();v=text
for h in hs:assert f.count(h['old'])==1;f=f.replace(h['old'],h['new'],1)
for h in reversed(hs):assert v.count(h['new'])==1;v=v.replace(h['new'],h['old'],1)
assert f==text and v.encode()==parent;compile(text,'copy_pawn_collision25_JSON14_after_GD11_ROOT_ONLY.py','exec')
dest=N/'copy_pawn_collision25_JSON14_after_GD11_ROOT_ONLY.py';assert not dest.exists()
with dest.open('xb')as f:f.write(text.encode())
sha=lambda b:hashlib.sha256(b).hexdigest()
proof=dict(parent=dict(path=S+old.name,sha256=sha(parent)),candidate=dict(path=S+dest.name,sha256=sha(dest.read_bytes())),hunks=hs,whole_UTF8_inverse=True,only_JSON14_copy_after_Root11GD_patch=True,fixed539_backup_and128city54World_media_saves_protected=True,engine_calls=0,execution_calls=0,canonical_writes=0)
content=(json.dumps(proof,ensure_ascii=False,indent=2,allow_nan=False)+'\n').encode();p=N/'pawnshop_collision_repair01/copy25_transport_whole_inverse_NOT_EXECUTED.json';assert not p.exists()
with p.open('xb')as f:f.write(content)
print(json.dumps(dict(tool=proof['candidate'],proof=dict(path=P+p.name,sha256=sha(content)))))
