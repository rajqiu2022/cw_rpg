"""NEW JSON-only Root transport, never executes copy."""
from pathlib import Path
import hashlib
N=Path(__file__).resolve().parent
t=(N/'copy_repair31_JSON14_after_GD17_ROOT_ONLY.py').read_text();changes=[
 ('GD17','GD18'),
 ('GATE_TEXTURE_MARKET_PORTAL_EXACT31_STAGED_NOT_DEPLOYED','GALLERY_FAMILY_ROUTER_EXACT32_STAGED_NOT_DEPLOYED'),
 ('dict(patch_count=17,copy_count=14,total=31)','dict(patch_count=18,copy_count=14,total=32)'),
 ('gate_texture_repair01/closure_READY01/current4160_repair31_scope_PREPARATION.json','docks_gallery_family_repair01/current_authority20_exact32_scope_PREPARATION.json'),
 ('227681de2bf6c156427f147b992e8945b18648c12c57f2eaf1041bc32d86644b','e252869c32121af260b27d3b65fc85ce8590959035fcd47757da1675ab20a703'),
 ('gate_texture_repair01/current4160_backup32_ROOT_ACTUAL.json','docks_gallery_family_repair01/current_authority20_backup32_ROOT_ACTUAL.json'),
 ('392b00f8fb19e36d58c7f2207ba6ad34f31c7f4f04991d7c05f295e39e962431','5efc38ef1ea9f418afd9144a1db3dce773e9e5b0d9af1ac0436808f282fcceb3'),
 ("backup['unexpected32_code_drift']==[]and backup['external_save_changes']==[]and backup['total_backups']==240","backup['external_save_changes']==[]and backup['total_backups']==317"),
 ("len(targets)==31 and set(targets)=={r['target']for r in scope['targets']}and set(old)-set(targets)=={scope['excluded_noop_G']}","len(targets)==32 and set(targets)==set(old)=={r['target']for r in scope['targets']}"),
 ('old208_backup_facts','old285_backup_facts'),("backup['current32']","backup['current33']"),
 ('ROOT_REPAIR31_DEPLOYED_GD18_PATCH_JSON14_EXACTCOPY','ROOT_GALLERY_FAMILY32_DEPLOYED_GD18_PATCH_JSON14_EXACTCOPY'),
 ('ROOT_REPAIR_GD18_NEW_JSON14_OLD_PREFLIGHT_ONLY','ROOT_GALLERY_FAMILY32_GD18_NEW_JSON14_OLD_PREFLIGHT_ONLY'),
 ('target_count=31','target_count=32'),('backup_count=240','backup_count=317'),('current4160_backup_sha256','current_authority20_backup_sha256'),('targets=31','targets=32'),
 ('no_G_DT_Router_UI_native_geometry_mask_changes=True','no_G_DT_UI_native_canonical_or_mask_pixel_write=True,Router_Root_apply_patch_and_exact13CRLF_only=True'),
]
for a,b in changes:assert a in t,a;t=t.replace(a,b)
# Full fixed hashes for the new mask/raw tuple are inherited from the already
# Root-locked Stage map. Capturing ticks does not create an expected source value.
a="for p,f in backup['save15'].items():protect(p,f)"
b="""for p,f in backup['save15'].items():protect(p,f)
 mask='res://build/luoyang_city_finish_20261025i_source01/docks_gallery_retirement01/isolated_ROOT_READY02/output_ROOT_READY/37092/walk_overlay.png'
 fixed=stage['nodes']['expected_ch4_s2_canal_docks_true']['value']['source_sha256'];assert fixed[mask]=='b546f989bc4a16e2dfb2a25ce91302b4382ba373ee7996dede9bff565211542a'
 for p in [mask,mask+'.import','res://.godot/imported/walk_overlay.png-9ce5987ede4d90acdf83983b51af4232.ctex']:
  f=fact(p);assert f['sha256']==fixed[p];protect(p,f)"""
assert t.count(a)==1;t=t.replace(a,b)
compile(t,'copy_gallery_family32_JSON14_after_GD18_ROOT_ONLY.py','exec')
dest=N/'copy_gallery_family32_JSON14_after_GD18_ROOT_ONLY.py';assert not dest.exists();raw=t.encode()
with dest.open('xb')as f:f.write(raw)
print(dest.name,hashlib.sha256(raw).hexdigest(),len(raw))
