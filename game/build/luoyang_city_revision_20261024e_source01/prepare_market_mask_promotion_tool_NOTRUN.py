"""Exact2 import-leaf promotion tool, only Root may execute after actual admit."""
from pathlib import Path
import hashlib,json
B=Path(__file__).resolve().parent;G=B.parents[1];N=B/'market_mask_import01'
old=(G/'build/luoyang_city_revision_20261024c_source01/promote_courts_mask_two_NOTRUN.ps1').read_bytes()
text=old.decode('utf8')
cfg=json.loads((N/'input_ROOT_PREPARE02.json').read_bytes());t=cfg['texture']
ops=[('F:/Code/RPG_GAME/assets/staging/luoyang_yamen_courts_mask_20261024c_import','F:/Code/RPG_GAME/assets/staging/luoyang_market_blocks_mask_20261024e_import01'),
 ('F:/Code/RPG_GAME/game/build/luoyang_city_revision_20261024c_root01','F:/Code/RPG_GAME/game/build/luoyang_city_revision_20261024e_root01'),
 ('res://build/luoyang_yamen_courts_20261024c_system01/publication02/output/54592/walk_overlay.png',t['png']),
 ('res://.godot/imported/walk_overlay.png-53da40f2b4702ac38ad0636f09873742.ctex',t['compiled']),
 ('ROOT_APPROVED_COURTS_OVERLAY_EXACT_TWO_IMPORT_MEDIA_PROMOTION','ROOT_APPROVED_MARKET_BLOCK_OVERLAY_EXACT_TWO_IMPORT_MEDIA_PROMOTION'),
 ('ONLY_ONE_PUBLISHED_COURTS_OVERLAY_MASK_ISOLATED_FULL_RGBA_NOT_RUNTIME','ONLY_ONE_PUBLISHED_MARKET_BLOCK_OVERLAY_MASK_ISOLATED_FULL_RGBA_NOT_RUNTIME'),
 ("$row.domain -cne 'courts_overlay'","$row.domain -cne 'market_block_overlay'"),
 ('56fb2f381fe129ed8f9b5292dfc49c765a4f3e5fba144da3e84d979d1cae1b5b',t['png_sha256']),
 ('635fffe3c760155d5db61122d19efd88a1e8e6f0bb903515ff35afbdfecfdc3c',t['decoded_RGBA_sha256']),
 ('EXACT_TWO_COURTS_OVERLAY_IMPORT_MEDIA_PROMOTED_NOT_RUNTIME','EXACT_TWO_MARKET_BLOCK_OVERLAY_IMPORT_MEDIA_PROMOTED_NOT_RUNTIME')]
for a,b in ops:assert text.count(a)==1,(a,text.count(a));text=text.replace(a,b,1)
back=text
for a,b in reversed(ops):assert back.count(b)==1;back=back.replace(b,a,1)
assert back.encode('utf8')==old
p=N/'promote_two_NOTRUN.ps1';assert not p.exists();p.write_bytes(text.encode('utf8'))
proof=dict(status='ROOT_ONLY_ACTUAL_TWO_MEDIA_PROMOTION_TOOL_NOT_RUN',path=p.as_posix(),sha256=hashlib.sha256(p.read_bytes()).hexdigest(),wholebyte_inverse_to24c=True,
 old_template_sha256=hashlib.sha256(old).hexdigest(),replacements=[dict(old=a,new=b) for a,b in ops],
 auth_schema=dict(status='ROOT_APPROVED_MARKET_BLOCK_OVERLAY_EXACT_TWO_IMPORT_MEDIA_PROMOTION',approved_by_root=True,actual_report=dict(sha256='PENDING_ROOT_NATIVE_ACTUAL_SHA'),ordered_targets='Exact two rows in sidecar then compiled order; target absolute/hash/bytes, Root preauthorized'),
 engine_calls=0,main_writes=0,media_SHA_expected='Unknown actual two bytes are never filled before Root native proof; require exact Root ordered_rows to match isolated verifier report.',md5='Not promoted or ordinary runtime source by this exact2 tool; optional separately admitted cache bookkeeping only.')
q=N/'promotion_tool_inverse_NOTRUN.json';assert not q.exists();q.write_bytes((json.dumps(proof,ensure_ascii=False,indent=2)+'\n').encode())
print(json.dumps(dict(tool=p.as_posix(),sha256=proof['sha256'],proof_sha256=hashlib.sha256(q.read_bytes()).hexdigest(),compiled=t['compiled'])))
