"""Existing JSON14 transport specialization; generates a Root-only tool, never executes it."""
from pathlib import Path
import argparse,json,hashlib,difflib
N=Path(__file__).resolve().parent;S='res://build/luoyang_city_finish_20261025i_source01/';O=N/'seven_fields_layout_repair01';sha=lambda b:hashlib.sha256(b).hexdigest()
ap=argparse.ArgumentParser();ap.add_argument('--promotion',required=True);a=ap.parse_args()
parent=(N/'copy_market_living_street31_JSON14_after_GD17_ROOT_ONLY.py').read_bytes();text=parent.decode()
for old,new in [('currentAAF immutable parent; Market six-instance data and necessary source pointers only.','currentDFCF immutable parent; seven-field layout and one Market patrol migration only.'),('finish8_ROOT_TRIAL_PERMISSION04.json','finish8_ROOT_TRIAL_PERMISSION05.json'),('273434a5e551f8ff755c3beccb02d21227a3e6283d1dc56521527dce3cd24d36','772cff2bc2c3199df2026427dd3f2bc7a022b9bb090a1bda7a9be46ed0d1b581'),('MARKET_SIX_INSTANCE_SOURCE_EXACT31_STAGED_NOT_DEPLOYED','SEVEN_FIELDS_LAYOUT_SOURCE_EXACT31_STAGED_NOT_DEPLOYED'),('market_living_street_repair01/current_AAF_exact31_scope_PREPARATION.json','seven_fields_layout_repair01/current_DFCF_exact31_scope_PREPARATION.json'),('fc3aaa0ad232d603d64eefba0d691d46d9d2a3cede67c83edc3a6d1e08a01a54','c2fbb7dca13b28548199cdf06872cd8933afe03d7c11ca6ee1935258ebb70818'),('market_living_street_repair01/current_AAF_backup31_ROOT_ACTUAL.json','seven_fields_layout_repair01/current_DFCF_backup31_ROOT_ACTUAL.json'),('31970cb86774421e36bca2b520569f2cf17b4c0672f8aeb845abc0eb470eebc0','ffc6a84395acf4fbde30c4e4bd706ffb7d8d25ed76155201861a610418139d7b'),("backup['total_backups']==595","backup['total_backups']==626"),('old564_backup_facts','old595_backup_facts'),('ROOT_MARKET_LIVING_STREET31','ROOT_SEVEN_FIELDS_LAYOUT31'),('backup_count=595','backup_count=626'),('current_AAF_backup_sha256','current_DFCF_backup_sha256'),('Market_overlay_payload_six_bodies_mask_and_material_only=True','seven_layout_and_one_Market_patrol_only=True'),('res://build/luoyang_market_workcourts_20261026b_system01/mask_import01_ROOT_ONLY/promotion_ROOT_EXECUTED.json',a.promotion),("len(promotion['written'])==2","len(promotion['written'])==12")]:
 assert old in text,old;text=text.replace(old,new)
marker=" for r in backup['frozen2121_current_facts']+backup['old595_backup_facts']+backup['media_facts']:protect(r['path'],r)"
replacement=marker+"\n for r in load(backup['plan']['path'],backup['plan']['sha256'])['World54']:protect(r['path'],r)"
assert text.count(marker)==1;text=text.replace(marker,replacement)
hs=[];aa=parent.decode().splitlines(True);bb=text.splitlines(True)
for z in difflib.SequenceMatcher(None,aa,bb,autojunk=False).get_grouped_opcodes(2):hs.append(dict(old=''.join(aa[z[0][1]:z[-1][2]]),new=''.join(bb[z[0][3]:z[-1][4]])))
f=parent.decode();v=text
for h in hs:assert f.count(h['old'])==1;f=f.replace(h['old'],h['new'],1)
for h in reversed(hs):assert v.count(h['new'])==1;v=v.replace(h['new'],h['old'],1)
assert f==text and v.encode()==parent;compile(text,'copy_seven_fields31_JSON14_after_GD17_ROOT_ONLY.py','exec')
dest=N/'copy_seven_fields31_JSON14_after_GD17_ROOT_ONLY.py';assert not dest.exists()
with dest.open('xb')as f:f.write(text.encode())
proof=dict(parent=dict(path=S+'copy_market_living_street31_JSON14_after_GD17_ROOT_ONLY.py',sha256=sha(parent)),candidate=dict(path=S+dest.name,sha256=sha(text.encode())),hunks=hs,whole_byte_inverse=True,Root_only=True,canonical_writes=0,engine_calls=0)
b=(json.dumps(proof,ensure_ascii=False,indent=2)+'\n').encode()
with(O/'JSON14_copy_transport_whole_inverse_NOT_EXECUTED.json').open('xb')as f:f.write(b)
print(json.dumps(dict(tool=proof['candidate'],proof_sha256=sha(b))))
