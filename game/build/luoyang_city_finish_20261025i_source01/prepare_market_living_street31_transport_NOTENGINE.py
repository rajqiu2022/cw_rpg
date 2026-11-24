"""Only mechanical Root JSON14 transport specialization. Does not apply/copy canonical."""
from pathlib import Path
import json,hashlib
N=Path(__file__).resolve().parent;S='res://build/luoyang_city_finish_20261025i_source01/';B=S+'market_living_street_repair01/';O=N/'market_living_street_repair01';sha=lambda b:hashlib.sha256(b).hexdigest()
p=(N/'copy_Estate_wall_source31_JSON14_after_GD17_ROOT_ONLY.py').read_bytes();t=p.decode();hs=[]
changes=[('Root-only exact JSON14 transport after GD17 patch; current0860 immutable parent; Estate type/scale repair and Yamen existing tuple only.','Root-only exact JSON14 transport after GD17 patch; currentAAF immutable parent; Market six-instance data and necessary source pointers only.'),('finish8_ROOT_TRIAL_PERMISSION02.json','finish8_ROOT_TRIAL_PERMISSION04.json'),('7bcb3165485026f4ff2c15ebb0dfa696c6780ed2cad238933201f715abdca82a','273434a5e551f8ff755c3beccb02d21227a3e6283d1dc56521527dce3cd24d36'),('ESTATE_WALL_SOURCE_EXACT31_STAGED_NOT_DEPLOYED','MARKET_SIX_INSTANCE_SOURCE_EXACT31_STAGED_NOT_DEPLOYED'),('Estate_wall_source_repair01/current_0860_exact31_scope_PREPARATION.json','market_living_street_repair01/current_AAF_exact31_scope_PREPARATION.json'),('3282faaa05a467ddf11315b78001c84705a036d9eb015802488882fd720ea957','fc3aaa0ad232d603d64eefba0d691d46d9d2a3cede67c83edc3a6d1e08a01a54'),('Estate_wall_source_repair01/current_0860_backup31_ROOT_ACTUAL.json','market_living_street_repair01/current_AAF_backup31_ROOT_ACTUAL.json'),('ad48454d8798b51b1076fe1482f842373ed78cd2b96a29a7053caaa90c6a631e','31970cb86774421e36bca2b520569f2cf17b4c0672f8aeb845abc0eb470eebc0'),("backup['total_backups']==492","backup['total_backups']==595"),('old461_backup_facts','old564_backup_facts'),("backup['current36']","backup['current37']"),('ROOT_ESTATE_WALL_SOURCE31','ROOT_MARKET_LIVING_STREET31'),('backup_count=492','backup_count=595'),('current_0860_backup_sha256','current_AAF_backup_sha256'),('no_G_DT_Router_UI_native_geometry_mask_changes=True','pawn_G_Router_UI_and_native_geometry_unchanged=True,Market_overlay_payload_six_bodies_mask_and_material_only=True')]
for a,b in changes:assert a in t,a;count=t.count(a);t=t.replace(a,b);hs.append(dict(old=a,new=b,count=count))
marker=" before={};candidates={}"
addition=""" promotion=load('res://build/luoyang_market_workcourts_20261026b_system01/mask_import01_ROOT_ONLY/promotion_ROOT_EXECUTED.json',stage['source_first']['res://build/luoyang_market_workcourts_20261026b_system01/mask_import01_ROOT_ONLY/promotion_ROOT_EXECUTED.json']);assert promotion['passed']is True and len(promotion['written'])==2
 for r in promotion['written']:
  f=fact(r['path']);assert f['sha256']==r['sha256']and f['bytes']==r['bytes'];protect(r['path'],f)
 before={};candidates={}"""
assert t.count(marker)==1;t=t.replace(marker,addition);hs.append(dict(old=marker,new=addition,count=1))
back=t
for h in reversed(hs):assert back.count(h['new'])==h['count'];back=back.replace(h['new'],h['old'])
assert back.encode()==p;compile(t,'copy_market_living_street31_JSON14_after_GD17_ROOT_ONLY.py','exec')
out=N/'copy_market_living_street31_JSON14_after_GD17_ROOT_ONLY.py';assert not out.exists()
with out.open('xb')as f:f.write(t.encode())
proof=dict(parent=dict(path=S+'copy_Estate_wall_source31_JSON14_after_GD17_ROOT_ONLY.py',sha256=sha(p)),candidate=dict(path=S+out.name,sha256=sha(t.encode())),hunks=hs,whole_byte_inverse=True,Root_only=True,canonical_writes=0,engine_calls=0)
b=(json.dumps(proof,ensure_ascii=False,indent=2)+'\n').encode()
with(O/'JSON14_copy_transport_whole_inverse_NOT_EXECUTED.json').open('xb')as f:f.write(b)
print(json.dumps(dict(tool=proof['candidate'],proof_sha256=sha(b))))
