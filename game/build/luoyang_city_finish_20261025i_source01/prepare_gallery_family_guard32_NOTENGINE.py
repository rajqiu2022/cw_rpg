"""NEW post-deploy read-only guard and finite new-media fact baseline; no guard execution."""
from pathlib import Path
import hashlib,json
N=Path(__file__).resolve().parent;G=N.parents[1];S='res://build/luoyang_city_finish_20261025i_source01/';P=S+'docks_gallery_family_repair01/'
def sha(b):return hashlib.sha256(b).hexdigest()
def enc(v):return(json.dumps(v,ensure_ascii=False,indent=2)+'\n').encode()
def load(p,h):
 b=(G/p[6:]).read_bytes();assert sha(b)==h;return json.loads(b)
promotion_path='res://build/luoyang_city_finish_20261025i_system01/qa_role_new/docks_gallery_mask_promotion02_ROOT_ONLY/promotion_ROOT_EXECUTED.json';promotion_sha='05ab783068ce04384faa743d313d892c88e5d6c378ef1ff665d2691bdc13f29e'
promotion=load(promotion_path,promotion_sha);pins=[dict(path=r['path'],sha256=r['sha256'],bytes=r['bytes'])for r in promotion['written']]
pins.append(dict(path=S+'docks_gallery_retirement01/isolated_ROOT_READY02/output_ROOT_READY/37092/walk_overlay.png',sha256='b546f989bc4a16e2dfb2a25ce91302b4382ba373ee7996dede9bff565211542a',bytes=31992))
facts=[]
for pin in pins:
 p=G/pin['path'][6:];a=p.stat();raw=p.read_bytes();b=p.stat();assert(a.st_mtime_ns,a.st_size)==(b.st_mtime_ns,b.st_size)and sha(raw)==pin['sha256']and len(raw)==pin['bytes']
 facts.append(dict(**pin,exists=True,ticks=str(b.st_mtime_ns//100+621355968000000000)))
media=dict(status='POST_ROOT_ACTUAL_NEW_MASK3_TICKS_OBSERVATION_NOT_HASH_EXPECTATION_BACKFILL',declared_hash_authority=dict(path=promotion_path,sha256=promotion_sha),raw_mask_authority=dict(path=S+'docks_gallery_retirement01/isolated_ROOT_READY02/output_ROOT_READY/37092/result.json',sha256='db47237fdf2839c34633708fb8d6bb8e5407a067da57c00e82bc168038d1f59b'),rows=facts,engine_calls=0,canonical_writes=0)
mb=enc(media);mp=P+'new_mask3_fixed_hash_and_current_ticks_READONLY.json'
text=(N/'guard_Market_ground25_current2121_ROOT_ONLY.py').read_text(encoding='utf-8')
changes=[
 ('market_ground_texture_repair02/current5D6C_backup25_ROOT_ACTUAL.json','docks_gallery_family_repair01/current_authority20_backup32_ROOT_ACTUAL.json'),
 ('c0a57be99104c703df9ef876a7168821497a448242c2acc86457acae4c32169a','5efc38ef1ea9f418afd9144a1db3dce773e9e5b0d9af1ac0436808f282fcceb3'),
 ('market_ground25_READY01/unified32_all_candidates_and_inverse_NOT_STAGE.json','docks_gallery_family_repair01/unified32_READY01/unified32_all_candidates_and_inverse_NOT_STAGE.json'),
 ('c699076933993a1fbdc89981b2d606260318dc764b543b85a45ea9c56dc395a4','5f7293ac4203d4e847f623cc76f0292dbd9d5edf269a1bde8f927f4df523cb5e'),
 ('MARKET_AE_TEXTURE_EXACT25_STAGED_NOT_DEPLOYED','GALLERY_FAMILY_ROUTER_EXACT32_STAGED_NOT_DEPLOYED'),
 ('dict(patch_count=11,copy_count=14,total=25)','dict(patch_count=18,copy_count=14,total=32)'),
 ('ROOT_MARKET_AE25_DEPLOYED_GD11_PATCH_JSON14_EXACTCOPY','ROOT_GALLERY_FAMILY32_DEPLOYED_GD18_PATCH_JSON14_EXACTCOPY'),
 ('len(st)==25','len(st)==32'),("'exact25'","'exact32'"),
 ('old240_backup_facts','old285_backup_facts'),('old240_backups_exactticks','old285_backups_exactticks'),('new25_backups_exactticks','new32_backups_exactticks'),
 ('ROOT_MARKET_AE25_POST_CURRENT2121_READONLY_GUARD','ROOT_GALLERY_FAMILY32_POST_CURRENT2121_READONLY_GUARD'),
 ('backups_total=265,authorized_targets=25','backups_total=317,authorized_targets=32'),
]
for a,b in changes:assert a in text,a;text=text.replace(a,b)
a="check(backup['ui']['path'],backup['ui'],'UI')"
b=a+"\n for r in load('"+mp+"','"+sha(mb)+"')['rows']:check(r['path'],r,'new_mask3_exactticks')\n for r in backup['current33']:\n  p=r['target'];expected_current=dict(exists=True,sha256=actual[p]['sha256'],bytes=actual[p]['bytes'],ticks=actual[p]['ticks'])if p in actual else r['current'];check(p,expected_current,'current33_plus_separate_Router32_target')"
assert text.count(a)==1;text=text.replace(a,b)
compile(text,'guard_gallery_family32_current2121_ROOT_ONLY.py','exec')
for file,b in [('docks_gallery_family_repair01/new_mask3_fixed_hash_and_current_ticks_READONLY.json',mb),('guard_gallery_family32_current2121_ROOT_ONLY.py',text.encode())]:
 p=N/file;assert not p.exists()
 with p.open('xb')as f:f.write(b)
 print(file,sha(b),len(b))
