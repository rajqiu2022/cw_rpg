"""Reuse JSON14-only Root transport; never executes canonical writes."""
from pathlib import Path
import hashlib,json,difflib
N=Path(__file__).resolve().parent;S='res://build/luoyang_city_finish_20261025i_source01/';P=S+'exit_wall_repair_20261027b01/';O=N/'exit_wall_repair_20261027b01';sha=lambda b:hashlib.sha256(b).hexdigest()
parent=(N/'copy_market_living_street31_JSON14_after_GD17_ROOT_ONLY.py').read_bytes();t=parent.decode('utf8')
for a,b in [('currentAAF immutable parent; Market six-instance data and necessary source pointers only.','current81C immutable parent; two public portal pairs and four adult Market walls only.'),('finish8_ROOT_TRIAL_PERMISSION04.json','finish8_ROOT_TRIAL_PERMISSION06.json'),('273434a5e551f8ff755c3beccb02d21227a3e6283d1dc56521527dce3cd24d36','56504f0f82c0f371d4179e4ecffb4dcd210d2a8f445f7de2f48e29ee7595048e'),('MARKET_SIX_INSTANCE_SOURCE_EXACT31_STAGED_NOT_DEPLOYED','EXIT_WALL_SOURCE_EXACT31_STAGED_NOT_DEPLOYED'),('market_living_street_repair01/current_AAF_exact31_scope_PREPARATION.json','exit_wall_repair_20261027b01/current_81C_exact31_scope_PREPARATION.json'),('fc3aaa0ad232d603d64eefba0d691d46d9d2a3cede67c83edc3a6d1e08a01a54','bb8f69b611461f35f10a32caf6486d658f14c2c406f83adb61dd18be9e2359c7'),('market_living_street_repair01/current_AAF_backup31_ROOT_ACTUAL.json','exit_wall_repair_20261027b01/current_81C_backup31_ROOT_ACTUAL.json'),('31970cb86774421e36bca2b520569f2cf17b4c0672f8aeb845abc0eb470eebc0','50361a4002319918b2afc17a7f4e65ea4593fec72a1812af4d384e707eb4e567'),("backup['total_backups']==595","backup['total_backups']==705"),('old564_backup_facts','old674_backup_facts'),('ROOT_MARKET_LIVING_STREET31','ROOT_EXIT_WALL31'),('backup_count=595','backup_count=705'),('current_AAF_backup_sha256','current_81C_backup_sha256'),('Market_overlay_payload_six_bodies_mask_and_material_only=True','two_portal_pairs_four_adult_Market_walls_only=True'),('res://build/luoyang_market_workcourts_20261026b_system01/mask_import01_ROOT_ONLY/promotion_ROOT_EXECUTED.json','res://build/luoyang_exit_wall_fix_20261027b_system01/mask_import01_ROOT_ONLY/promotion_ROOT_EXECUTED.json')]:
 assert a in t,a;t=t.replace(a,b)
a=" for r in backup['frozen2121_current_facts']+backup['old674_backup_facts']+backup['media_facts']:protect(r['path'],r)"
b=""" for r in backup['frozen2121_current_facts']+backup['old674_backup_facts']:protect(r['path'],r)
 media_tick_refreshes=[]
 for r in backup['media_facts']+backup['World54_facts']:
  f=fact(r['path']);assert f.get('exists')is True and f['sha256']==r['sha256']and f['bytes']==r['bytes'],('MEDIA_CONTENT_CHANGED_KEEP_NO_ROLLBACK',r['path'])
  if f['ticks']!=r['ticks']:media_tick_refreshes.append(dict(path=r['path'],before_backup_ticks=r['ticks'],current_ticks=f['ticks']))
  protect(r['path'],f)"""
assert t.count(a)==1;t=t.replace(a,b)
a=" before={};candidates={}"
b=""" publication_path='res://build/luoyang_exit_wall_fix_20261027b_system01/ROOT_READY01/output/108580/result.json'
 publication=load(publication_path,stage['source_first'][publication_path]);m=publication['components']['ch4_s3_luoyang_market']['mask'];f=fact(m['path']);assert f['sha256']==m['sha256'];protect(m['path'],f)
 before={};candidates={}"""
assert t.count(a)==1;t=t.replace(a,b)
a='protected_count=len(protected),';b='protected_count=len(protected),same_content_media_timestamp_refreshes=media_tick_refreshes,preserved_prior_save_differences=backup[\'prior_save_differences\'],';assert t.count(a)==1;t=t.replace(a,b)
compile(t,'copy_exit_wall31_JSON14_after_GD17_ROOT_ONLY.py','exec');dest=N/'copy_exit_wall31_JSON14_after_GD17_ROOT_ONLY.py';assert not dest.exists()
with dest.open('xb')as f:f.write(t.encode('utf8'))
hs=[];aa=parent.decode().splitlines(True);bb=t.splitlines(True)
for z in difflib.SequenceMatcher(None,aa,bb,autojunk=False).get_grouped_opcodes(2):hs.append(dict(old=''.join(aa[z[0][1]:z[-1][2]]),new=''.join(bb[z[0][3]:z[-1][4]])))
f=parent.decode();v=t
for h in hs:assert f.count(h['old'])==1;f=f.replace(h['old'],h['new'],1)
for h in reversed(hs):assert v.count(h['new'])==1;v=v.replace(h['new'],h['old'],1)
assert f==t and v.encode()==parent
proof=dict(parent=dict(path=S+'copy_market_living_street31_JSON14_after_GD17_ROOT_ONLY.py',sha256=sha(parent)),candidate=dict(path=S+dest.name,sha256=sha(t.encode('utf8'))),hunks=hs,whole_UTF8_inverse=True,engine_calls=0,canonical_writes=0)
raw=(json.dumps(proof,ensure_ascii=False,indent=2)+'\n').encode('utf8');out=O/'JSON14_transport_whole_inverse_NOT_EXECUTED.json';assert not out.exists()
with out.open('xb')as f:f.write(raw)
print(json.dumps(dict(tool=proof['candidate'],proof_sha256=sha(raw))))
