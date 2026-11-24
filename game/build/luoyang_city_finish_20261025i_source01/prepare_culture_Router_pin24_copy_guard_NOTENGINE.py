"""Root exact JSON14 transport and read-only postguard. No execution."""
from pathlib import Path
import hashlib
N=Path(__file__).resolve().parent
def emit(name,t):
 compile(t,name,'exec');p=N/name;assert not p.exists();b=t.encode()
 with p.open('xb')as f:f.write(b)
 print(name,hashlib.sha256(b).hexdigest(),len(b))
t=(N/'copy_gallery_family32_JSON14_after_GD18_ROOT_ONLY.py').read_text()
for a,b in [
 ('GD18','GD10'),('GALLERY_FAMILY_ROUTER_EXACT32_STAGED_NOT_DEPLOYED','CULTURE_ROUTER_EXACT24_STAGED_NOT_DEPLOYED'),('dict(patch_count=18,copy_count=14,total=32)','dict(patch_count=10,copy_count=14,total=24)'),
 ('docks_gallery_family_repair01/current_authority20_exact32_scope_PREPARATION.json','culture_Router_pin_repair01/current_D581_exact24_scope_PREPARATION.json'),
 ('e252869c32121af260b27d3b65fc85ce8590959035fcd47757da1675ab20a703','464ed8df58b3a7fc2147aa1236794bfa82da03a0382e1020825ffaa0dcd5016b'),
 ('docks_gallery_family_repair01/current_authority20_backup32_ROOT_ACTUAL.json','culture_Router_pin_repair01/current_D581_backup24_ROOT_ACTUAL.json'),
 ('5efc38ef1ea9f418afd9144a1db3dce773e9e5b0d9af1ac0436808f282fcceb3','4d0ae7e6241e4a8b4ca66d4e845c134e86adaf3fed5dc8676d78fc1f0dabcd51'),
 ("backup['total_backups']==317","backup['total_backups']==341"),('len(targets)==32','len(targets)==24'),('old285_backup_facts','old317_backup_facts'),("backup['current33']","backup['current34']"),
 ('ROOT_GALLERY_FAMILY32_DEPLOYED_GD10_PATCH_JSON14_EXACTCOPY','ROOT_CULTURE_ROUTER24_DEPLOYED_GD10_PATCH_JSON14_EXACTCOPY'),('ROOT_GALLERY_FAMILY32_GD10_NEW_JSON14_OLD_PREFLIGHT_ONLY','ROOT_CULTURE_ROUTER24_GD10_NEW_JSON14_OLD_PREFLIGHT_ONLY'),
 ('target_count=32','target_count=24'),('backup_count=317','backup_count=341'),('current_authority20_backup_sha256','current_D581_backup_sha256'),('targets=32','targets=24'),('Router_Root_apply_patch_and_exact13CRLF_only=True','Router_unchanged=True'),
]:assert a in t,a;t=t.replace(a,b)
start=t.index(" mask='res://build/luoyang_city_finish_20261025i_source01/docks_gallery_retirement01/");end=t.index(" protect(backup['ui']",start)
# New mask3 already belong to Root actual116 media with fixed exactticks. Never
# overwrite those expected ticks with a fresh observation during this transaction.
t=t[:start]+t[end:]
emit('copy_culture_Router_pin24_JSON14_after_GD10_ROOT_ONLY.py',t)
t=(N/'guard_Market_ground25_current2121_ROOT_ONLY.py').read_text(encoding='utf-8')
for a,b in [
 ('market_ground_texture_repair02/current5D6C_backup25_ROOT_ACTUAL.json','culture_Router_pin_repair01/current_D581_backup24_ROOT_ACTUAL.json'),
 ('c0a57be99104c703df9ef876a7168821497a448242c2acc86457acae4c32169a','4d0ae7e6241e4a8b4ca66d4e845c134e86adaf3fed5dc8676d78fc1f0dabcd51'),
 ('market_ground25_READY01/unified32_all_candidates_and_inverse_NOT_STAGE.json','culture_Router_pin_repair01/unified24_READY01/unified32_all_candidates_and_inverse_NOT_STAGE.json'),
 ('c699076933993a1fbdc89981b2d606260318dc764b543b85a45ea9c56dc395a4','85ca1a489a550bde0b410888110c77f322ef6e9f0464a45c7e407fddc2aa4976'),
 ('MARKET_AE_TEXTURE_EXACT25_STAGED_NOT_DEPLOYED','CULTURE_ROUTER_EXACT24_STAGED_NOT_DEPLOYED'),('dict(patch_count=11,copy_count=14,total=25)','dict(patch_count=10,copy_count=14,total=24)'),
 ('ROOT_MARKET_AE25_DEPLOYED_GD11_PATCH_JSON14_EXACTCOPY','ROOT_CULTURE_ROUTER24_DEPLOYED_GD10_PATCH_JSON14_EXACTCOPY'),('len(st)==25','len(st)==24'),("'exact25'","'exact24'"),
 ('old240_backup_facts','old317_backup_facts'),('old240_backups_exactticks','old317_backups_exactticks'),('new25_backups_exactticks','new24_backups_exactticks'),('all113_media_exactticks','all116_media_exactticks'),
 ('ROOT_MARKET_AE25_POST_CURRENT2121_READONLY_GUARD','ROOT_CULTURE_ROUTER24_POST_CURRENT2121_READONLY_GUARD'),('backups_total=265,authorized_targets=25','backups_total=341,authorized_targets=24'),
]:assert a in t,a;t=t.replace(a,b)
a="check(backup['ui']['path'],backup['ui'],'UI')"
b=a+"\n for r in backup['current34']:\n  p=r['target'];wanted=dict(exists=True,sha256=actual[p]['sha256'],bytes=actual[p]['bytes'],ticks=actual[p]['ticks'])if p in actual else r['current'];check(p,wanted,'current34_Runtime_Field_Router_Families_noop_preserved')"
assert t.count(a)==1;t=t.replace(a,b)
emit('guard_culture_Router_pin24_current2121_ROOT_ONLY.py',t)
