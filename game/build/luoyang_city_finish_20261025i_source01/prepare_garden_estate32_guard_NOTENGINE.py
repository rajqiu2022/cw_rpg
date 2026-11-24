"""Reuse mature readonly post guard with this actual32/737 baseline; does not run the guard."""
from pathlib import Path
import hashlib,json
N=Path(__file__).resolve().parent;S='res://build/luoyang_city_finish_20261025i_source01/';P=S+'garden_estate_exit_repair_20261027c01/';sha=lambda b:hashlib.sha256(b).hexdigest()
parent=(N/'guard_Estate_wall_source31_current2121_ROOT_ONLY.py').read_bytes();t=parent.decode('utf8')
for a,b in [('Estate_wall_source_repair01/current_0860_backup31_ROOT_ACTUAL.json','garden_estate_exit_repair_20261027c01/current_CE38_backup32_ROOT_ACTUAL.json'),('ad48454d8798b51b1076fe1482f842373ed78cd2b96a29a7053caaa90c6a631e','5137bc82f3a2aee973e47eac2127d4e00c2e310cffe5d83c7a1910dd5359f148'),('Estate_wall_source_repair01/unified31_READY01/unified32_all_candidates_and_inverse_NOT_STAGE.json','garden_estate_exit_repair_20261027c01/unified32_READY01/unified32_all_candidates_and_inverse_NOT_STAGE.json'),('ccd21474dd1a99ef33b6a965da522190e4ad811f237bed3671430f5007cb7b54','307e79ad276b900caf48bdbd8210e0e96228446e641504f846e8d796b794db68'),('finish8_ROOT_TRIAL_PERMISSION02.json','finish8_ROOT_TRIAL_PERMISSION07.json'),('7bcb3165485026f4ff2c15ebb0dfa696c6780ed2cad238933201f715abdca82a','439d2df41ab8767b19a76ae3d7a426e66b751f131d1df2783ac3bcb774d25b88'),('ESTATE_WALL_SOURCE_EXACT31_STAGED_NOT_DEPLOYED','GARDEN_ESTATE_SOURCE_EXACT32_STAGED_NOT_DEPLOYED'),('dict(patch_count=17,copy_count=14,total=31)','dict(patch_count=18,copy_count=14,total=32)'),('ROOT_ESTATE_WALL_SOURCE31_DEPLOYED_GD17_PATCH_JSON14_EXACTCOPY','ROOT_GARDEN_ESTATE32_DEPLOYED_GD18_PATCH_JSON14_EXACTCOPY'),('len(st)==31','len(st)==32'),("'exact31'","'exact32'"),('old461_backup_facts','old705_backup_facts'),('old461_backups_exactticks','old705_backups_exactticks'),('new31_backups_exactticks','new32_backups_exactticks'),('current36','current37'),('ROOT_ESTATE_WALL_SOURCE31_POST_CURRENT2121_READONLY_GUARD','ROOT_GARDEN_ESTATE32_POST_CURRENT2121_READONLY_GUARD'),('backups_total=492,authorized_targets=31','backups_total=737,authorized_targets=32')]:
 assert a in t,a;t=t.replace(a,b)
a=" for r in backup['media_facts']:check(r['path'],r,'all125_media_exactticks')"
b=""" refresh={str(res(r['path']).resolve()).casefold():r['current_ticks']for r in dep.get('same_content_media_timestamp_refreshes',[])}
 for r in backup['media_facts']+backup['World54_facts']:
  f=dict(r);key=str(res(r['path']).resolve()).casefold()
  if key in refresh:f['ticks']=refresh[key]
  check(r['path'],f,'old206_media_SHA_bytes_run_ticks')
 promotion=load('res://build/luoyang_garden_estate_exit_20261027c_system01/mask_import01_ROOT_ONLY/promotion_ROOT_EXECUTED.json','37019eb81f4573c2a2d40aebb8cce4dedab974a98c4e67f523ee2ee9b5d6a2bb');assert promotion['passed']is True and len(promotion['written'])==2
 publication=load('res://build/luoyang_garden_estate_exit_20261027c_system01/ROOT_READY01/output/109852/result.json','332d92f1006bbea55fd10c95bd7ae0cf1c61ca5cc6815d9da53b42d423cbf5cd')
 frozen=load('res://build/luoyang_garden_estate_exit_20261027c_system01/mask_import01_ROOT_ONLY/plan_ROOT_FROZEN_NOT_EXECUTED.json',promotion['plan_sha256'])
 m=publication['mask'];rawfact=next(v for p,v in frozen['protected_original_facts'].items()if str(res(p).resolve()).casefold()==str(res(m['path']).resolve()).casefold());assert rawfact['sha256']==m['sha256'];check(m['path'],rawfact,'new_Garden_raw_mask_exactticks')
 for r in promotion['written']:check(r['path'],dict(exists=True,sha256=r['sha256'],bytes=r['bytes']),'new_Garden_import2_SHA_bytes',True)
 check('res://build/luoyang_city_finish_20261025i_source01/pawnshop_only_repair01/unified22_READY01/services_runtime_READY.gd',dict(exists=True,sha256='4c8371436aac631ea36523626a2696e1871f0a29e9db5fb5e1a64116fcb706e8',bytes=24677),'pawn_service_unchanged',True)
 check('res://build/luoyang_pawnshop_repair_20261026a_system01/services_author02_CANDIDATE.json',dict(exists=True,sha256='44053da474186c16863df81e6c266d21e0815c1af2e6d8d4b1a78d0effe1db1e',bytes=19525),'pawn_author_unchanged',True)"""
assert t.count(a)==1;t=t.replace(a,b)
# File lengths are declared by the prior approved pawnship publication/seal, not current observations.
g=N/'pawnshop_only_repair01/unified22_READY01/pawnshop22_all_candidates_and_inverse_NOT_STAGE.json'
data=json.loads(g.read_bytes())
def find(v,p):
 if isinstance(v,dict):
  if v.get('path')==p and 'bytes'in v:return v
  for x in v.values():
   r=find(x,p)
   if r:return r
 elif isinstance(v,list):
  for x in v:
   r=find(x,p)
   if r:return r
for p,n in [('res://build/luoyang_city_finish_20261025i_source01/pawnshop_only_repair01/unified22_READY01/services_runtime_READY.gd',24677),('res://build/luoyang_pawnshop_repair_20261026a_system01/services_author02_CANDIDATE.json',19525)]:
 r=find(data,p)
 if r:t=t.replace('bytes='+str(n)+")",'bytes='+str(r['bytes'])+")")
proof_raw=(N.parent/'luoyang_pawnshop_repair_20261026a_system01/three_files_direct_parent_whole_inverse_BUILD.json').read_bytes()
assert sha(proof_raw)=='a262558b30f63958d722ffc08303d942c67c07a5cbfb1a7ab820939f783122e5'
assert '"candidate_bytes": 80026' in proof_raw.decode('utf8')
assert t.count("bytes=19525),'pawn_author_unchanged'")==1
t=t.replace("bytes=19525),'pawn_author_unchanged'","bytes=80026),'pawn_author_unchanged'")
compile(t,'guard_garden_estate32_current2121_ROOT_ONLY02.py','exec');dest=N/'guard_garden_estate32_current2121_ROOT_ONLY02.py';assert not dest.exists()
with dest.open('xb')as f:f.write(t.encode('utf8'))
print(json.dumps(dict(tool=dict(path=S+dest.name,sha256=sha(t.encode('utf8'))),old_backups=705,new_backups=32,media_old=206,media_new=3,guard_calls=0,engine_calls=0)))
