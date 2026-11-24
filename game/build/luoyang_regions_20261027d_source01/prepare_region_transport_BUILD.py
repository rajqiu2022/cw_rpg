"""Specialize the reviewed 27c JSON-copy/guard/Router formatter; never execute them."""
from pathlib import Path
import hashlib, json
N = Path(__file__).resolve().parent; G = N.parents[1]
S = G / 'build/luoyang_city_finish_20261025i_source01'
O = S / 'region_integration_20261027d01'
sha = lambda b: hashlib.sha256(b).hexdigest()
P = 'res://build/luoyang_city_finish_20261025i_source01/'
B = '5d406f8866427ace84600088b30748ec8bd3d30d8ed5bcd1b170316c11b882c1'
scope_sha = '1db5759bfd8ae094f8f5a7b623a55927d285d1f63cdccb378a811ddb49732494'
manifest_path = 'res://build/luoyang_regions_20261027d_source01/region_runtime_manifest_BUILD.json'
permission_path = 'res://build/luoyang_regions_20261027d_source01/root_integration_scope08_AUTHORIZED.json'
permission_sha = '9d064035022286b8337c430e635f72528e3975cce91e914f53a351ac5bd71919'
gate_pub = 'res://build/luoyang_city_rectification_20261027d_system01/GATE_REAR_ROOT_READY01/output/82020/result.json'
gate_promo = 'res://build/luoyang_city_rectification_20261027d_system01/gate_mask_import01_ROOT_ONLY/promotion_ROOT_EXECUTED.json'
media_promo = 'res://build/luoyang_city_rectification_20261027d_system01/three_building_import01_ROOT_ONLY/promotion_ROOT_EXECUTED.json'
media_sha = '15920208fcbd2c7b09fa6808623a2f146a6a531623a35404730e130b85afbbe8'
proofs = []
def emit(parent_path, dest, edits):
    parent = parent_path.read_bytes(); text = parent.decode('utf8'); hunks = []
    for old, new in edits:
        count = text.count(old); assert count >= 1, (dest.name, old[:120])
        text = text.replace(old, new); hunks.append({'old': old, 'new': new, 'occurrences': count})
    inverse = text
    for h in reversed(hunks):
        assert inverse.count(h['new']) == h['occurrences'], (dest.name, h['new'][:120])
        inverse = inverse.replace(h['new'], h['old'])
    assert inverse.encode() == parent
    compile(text, str(dest), 'exec')
    if dest.exists(): assert dest.read_bytes() == text.encode()
    else: dest.write_bytes(text.encode())
    value = {'parent': {'path': 'res://' + parent_path.relative_to(G).as_posix(), 'sha256': sha(parent)}, 'candidate': {'path': 'res://' + dest.relative_to(G).as_posix(), 'sha256': sha(text.encode()), 'bytes': len(text.encode())}, 'hunks': hunks, 'whole_UTF8_inverse': True, 'execution_calls': 0}
    proofs.append(value); return value['candidate']
common = [
    ('garden_estate_exit_repair_20261027c01/current_CE38_backup32_ROOT_ACTUAL.json', 'region_integration_20261027d01/current_01656_backup32_ROOT_ACTUAL.json'),
    ('5137bc82f3a2aee973e47eac2127d4e00c2e310cffe5d83c7a1910dd5359f148', B),
    ("stage['source_first'].get(S+'finish8_ROOT_TRIAL_PERMISSION07.json')=='439d2df41ab8767b19a76ae3d7a426e66b751f131d1df2783ac3bcb774d25b88'", "stage['source_first'].get(" + repr(permission_path) + ')=='+repr(permission_sha)),
    ("stage['status']=='GARDEN_ESTATE_SOURCE_EXACT32_STAGED_NOT_DEPLOYED'", "stage['status']=='ROOT08_REGION_GATE_EXACT32_STAGED_NOT_DEPLOYED'"),
    ("backup['old705_backup_facts']", "backup['old737_backup_facts']"),
]
copy_parent = S / 'copy_garden_estate32_JSON14_after_GD18_ROOT_ONLY.py'
copy_text = copy_parent.read_text(encoding='utf8')
start = copy_text.index(' promotion=load('); end = copy_text.index('\n before={};candidates={}', start)
media_block = ''' adopted_media_facts=[]
 promotion=load(GATE_PROMOTION,stage['source_first'][GATE_PROMOTION]);assert promotion['passed']is True and len(promotion['written'])==2
 buildings=load(BUILDING_PROMOTION,BUILDING_PROMOTION_SHA);assert buildings['passed']is True and len(buildings['written'])==9
 for r in promotion['written']+buildings['written']:
  f=fact(r['path']);assert f['sha256']==r['sha256']and f['bytes']==r['bytes'];protect(r['path'],f);adopted_media_facts.append(dict(path=r['path'],**f))
 publication=load(GATE_PUBLICATION,stage['source_first'][GATE_PUBLICATION]);m=publication['mask'];f=fact(m['path']);assert f['sha256']==m['sha256']and f['bytes']==m['bytes'];protect(m['path'],f);adopted_media_facts.append(dict(path=m['path'],**f))'''
constants = '\nGATE_PROMOTION='+repr(gate_promo)+'\nBUILDING_PROMOTION='+repr(media_promo)+'\nBUILDING_PROMOTION_SHA='+repr(media_sha)+'\nGATE_PUBLICATION='+repr(gate_pub)+'\n'
copy_edits = common + [
    (copy_text.splitlines()[0], '"""Root-only Region/Gate exact JSON14 copy after GD18 patch; no engine or GD copy."""'),
    ("def sha(b):", constants + 'def sha(b):'),
    ('garden_estate_exit_repair_20261027c01/current_CE38_exact32_scope_PREPARATION.json', 'region_integration_20261027d01/current_01656_exact32_scope_PREPARATION.json'),
    ('3d847a210c3ef7fdfa3aef840f3f067b5019db36e2d46389d47f23b263a0c6f8', scope_sha),
    ("backup['total_backups']==737", "backup['total_backups']==769 and type(backup['media_content_changes'])is int and backup['media_content_changes']==0"),
    (copy_text[start:end], media_block),
    ("'ROOT_GARDEN_ESTATE32_DEPLOYED_GD18_PATCH_JSON14_EXACTCOPY'", "'ROOT_REGION_INTEGRATION32_DEPLOYED_GD18_PATCH_JSON14_EXACTCOPY'"),
    ("'ROOT_GARDEN_ESTATE32_GD18_NEW_JSON14_OLD_PREFLIGHT_ONLY'", "'ROOT_REGION_INTEGRATION32_GD18_NEW_JSON14_OLD_PREFLIGHT_ONLY'"),
    ('backup_count=737', 'backup_count=769'),
    ('current_CE38_backup_sha256=', 'current_01656_backup_sha256='),
    ('one_Garden_wall_and_exact_original_Estate_cold_lifecycle_only=True', 'Root08_Region_and_Gate_exact_integration=True,adopted_media_facts=adopted_media_facts'),
]
copy_pin = emit(copy_parent, S / 'copy_region_integration32_JSON14_after_GD18_ROOT_ONLY.py', copy_edits)
guard_parent = S / 'guard_garden_estate32_current2121_ROOT_ONLY02.py'
guard_text = guard_parent.read_text(encoding='utf8'); start=guard_text.index(' promotion=load('); end=guard_text.index('\n check(\'res://build/luoyang_city_finish_20261025i_source01/pawnshop_only', start)
guard_edits = common + [
    ('garden_estate_exit_repair_20261027c01/unified32_READY01/unified32_all_candidates_and_inverse_NOT_STAGE.json', 'region_integration_20261027d01/unified32_READY01/unified32_all_candidates_and_inverse_NOT_STAGE.json'),
    ('307e79ad276b900caf48bdbd8210e0e96228446e641504f846e8d796b794db68', 'ddb955b71625acc92f02d23a896f9f5f306062ee623248a485b1be2e7ef29a47'),
    ("dep['status']=='ROOT_GARDEN_ESTATE32_DEPLOYED_GD18_PATCH_JSON14_EXACTCOPY'", "dep['status']=='ROOT_REGION_INTEGRATION32_DEPLOYED_GD18_PATCH_JSON14_EXACTCOPY'"),
    ("'old705_backups_exactticks'", "'old737_backups_exactticks'"),
    ("'old206_media_SHA_bytes_run_ticks'", "'old212_media_SHA_bytes_run_ticks'"),
    (guard_text[start:end], " assert len(dep['adopted_media_facts'])==12\n for r in dep['adopted_media_facts']:check(r['path'],r,'adopted_Gate_and_three_building_media_exactticks')"),
    ("status='ROOT_GARDEN_ESTATE32_POST_CURRENT2121_READONLY_GUARD'", "status='ROOT_REGION_INTEGRATION32_POST_CURRENT2121_READONLY_GUARD'"),
    ('backups_total=737', 'backups_total=769'),
]
guard_pin=emit(guard_parent, S / 'guard_region_integration32_current2121_ROOT_ONLY.py', guard_edits)
format_parent=S/'garden_estate_exit_repair_20261027c01/restore_Router13CRLF_after_apply_patch_ROOT_ONLY.py'
formatter=emit(format_parent, O/'restore_Router13CRLF_after_apply_patch_ROOT_ONLY.py', [
    ('build/luoyang_garden_estate_exit_20261027c_system01/Router_garden_estate_CANDIDATE.gd', 'build/luoyang_city_finish_20261025i_source01/region_integration_20261027d01/closure_READY01/Router_READY.gd'),
    ('2687a0d72d6bf34654894905b9caf2082c3fdf97e7db4633e518996569d2650c', 'eddb274e6c09d573879234ba7b303b490ffccd33dff2c91d329e46e0c52840f4'),
    ("(GAME/'build/luoyang_city_finish_20261025i_source01/garden_estate_exit_repair_20261027c01').resolve()", "(GAME/'build/luoyang_city_finish_20261025i_source01/region_integration_20261027d01').resolve()"),
])
out=O/'copy_guard_Router_transport_whole_inverse_NOT_EXECUTED.json';assert not out.exists()
out.write_bytes((json.dumps({'transports':proofs,'canonical_writes':0,'engine_calls':0},ensure_ascii=False,indent=2)+'\n').encode())
print(json.dumps({'copy':copy_pin,'guard':guard_pin,'Router_formatter':formatter,'whole_inverse':{'path':'res://'+out.relative_to(G).as_posix(),'sha256':sha(out.read_bytes())},'executed':False}))
