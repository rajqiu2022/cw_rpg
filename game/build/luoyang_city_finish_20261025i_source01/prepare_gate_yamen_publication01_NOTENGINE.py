"""Freeze hardfalse ROOT CPU input; independent prior remains explicitly pending."""
from pathlib import Path
import hashlib,json
HERE=Path(__file__).resolve().parent;GAME=HERE.parents[1]
NS='res://build/luoyang_city_finish_20261025i_source01/'
def sha(b):return hashlib.sha256(b).hexdigest()
def fixed(p,h):
 b=(GAME/p[6:]).read_bytes();assert sha(b)==h,p
 return json.loads(b)
authorp=NS+'author_gate_yamen_axis03_exact_domains_NOTREADY.json';authorh='0652fabb2ec0ca6a9c40fa0b96ec366f2422f7f77d15386811acc4204eff9785'
author=fixed(authorp,authorh);libraryp=NS+'reuse_asset_library01_SOURCE_ONLY.json';libraryh='17217d76c081e3a53a3b7c13c02f075c216c6a36ec8d8304c66f4f1f4df2ae9d';library=fixed(libraryp,libraryh)
compilerp=NS+'gate_yamen_projection03_NOTREADY.gd';compilerh='97c2c9eae3f5d8da500b6c4b45788d835503840fa65350b073f35c8b90336248'
assert sha((GAME/compilerp[6:]).read_bytes())==compilerh
seedp=NS+'parent_projection01_ROOT_READY/output_ROOT_READY/parent_source_seeds.bin';seedh='dfd5162f2668f599a1e3362298eb1953778d9339c59069a738c732d0ef849486';assert sha((GAME/seedp[6:]).read_bytes())==seedh
sources={authorp:authorh,libraryp:libraryh,compilerp:compilerh,seedp:seedh}
for scene in author['scenes']:
 for key in ['parent_mask_source','raw_support_source']:
  row=scene[key];assert sha((GAME/row['path'][6:]).read_bytes())==row['sha256'];sources[row['path']]=row['sha256']
 for placement in scene['placements']:
  row=library['assets'][placement['asset_id']];sources[row['texture']]=row['source_sha256']
config={'status':'ROOT_ONLY_NEW_GATE_YAMEN_LOCAL_DOMAIN_PUBLICATION_WAITING_INDEPENDENT_PRIOR','ready':False,'root_run_authorized':False,
 'whole_budget_ms':20000,'author_path':authorp,'library_path':libraryp,'compiler_path':compilerp,'parent_seed_path':seedp,
 'independent_prior':None,'output_root':NS+'gate_yamen_publication01/output','sources':sources,
 'only_original_primitive_seed_is_actual':True,'new_geometry_expectation_is_independent_prior_not_Source_model':True,
 'no_packet_decode_or_old_route_replay':True,'no_Field_Scene_import_collector':True,
 'mask_layers':{'Gate':'old28 mask outside exact domains; new47 union within; no claim old39 mask; final runtime DG-after lease must replace combined ground, not add old native2 again','Yamen':'old effective24c40 mask and source ground to42'}}
b=(json.dumps(config,ensure_ascii=False,indent=2)+'\n').encode();p=HERE/'gate_yamen_publication_input01_NOTREADY.json'
with p.open('xb') as stream:stream.write(b)
print(json.dumps({'path':NS+p.name,'sha256':sha(b),'bytes':len(b),'fixed_sources':len(sources),'prior':'PENDING_FALSE'}))
