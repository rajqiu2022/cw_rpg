"""Join fixed actual terminals with ART's explicit station and owner authors.
BUILD only; Root authorizes and runs the one cold pure compiler separately.
"""
from pathlib import Path
import json,hashlib,re,sys,copy
N=Path(__file__).resolve().parent;G=N.parents[1];A=G/'build/luoyang_city_rebuild_20261027d_art01'
sha=lambda data:hashlib.sha256(data).hexdigest()
res=lambda path:'res://'+path.relative_to(G).as_posix()
def fixed(path,want):
 raw=path.read_bytes();assert sha(raw)==want.lower(),str(path)
 return json.loads(raw)
def put(path,data):
 assert not path.exists(),str(path)
 raw=(json.dumps(data,ensure_ascii=False,indent=2)+'\n').encode('utf8');path.write_bytes(raw)
 return {'path':res(path),'sha256':sha(raw),'bytes':len(raw)}
assert len(sys.argv)==3,'Explicit ART Market patch path and SHA required, never select newest automatically.'
market_path=Path(sys.argv[1]).resolve();market=fixed(market_path,sys.argv[2])
fragment_path=A/'three_regions_space_fragment01_BUILD_ONLY.json';fragment=fixed(fragment_path,'94ac0e251a633c36f05f725cf54672e134b2b26c75c66fb2e4fba6261fab3416')
yamen_path=A/'yamen_exact_stations_and_room_residents02_BUILD_ONLY.json';yamen=fixed(yamen_path,'79f114e0c6742fce856142f6a4d754295ed9cb5b4e1141696faf1d2c458c4eea')
author=json.loads((N/'regions_author01_BUILD.json').read_text(encoding='utf8'))
author['regions']=copy.deepcopy(fragment['regions']);author['status']='REAL_CIVIC_AUTHOR_FIRST_COMPILE_NOT_RUNTIME_ADOPTION';author['adoption_enabled']=False
civic=author['regions']['luoyang_civic_market_region_27d'];civic['internal_legacy_ids']=['ch4_s1_luoyang_yamen','ch4_s3_luoyang_market']
patches={row['logical_id']:row for row in [yamen['yamen_district_patch'],market['market_district_patch']]}
for district in civic['districts']:
 patch=patches[district['logical_id']]
 for key in ['legacy_version','legacy_frame_origin','save_fallback_uv','actors','portals','interactions','station_transforms','migrations','display_name']:
  if key in patch:district[key]=copy.deepcopy(patch[key])
 district['legacy_version_migrations']={str(version):[{**copy.deepcopy(row),'reason':row['reason']+'_legacy_version_'+str(version)}for row in district['migrations']]for version in [1,2]}
civic['routes']=[row for row in civic['routes']if row['id']not in market.get('routes_replace_ids',[])]+yamen['routes_additions']+market['routes_additions']
civic['ground']+=market['region_ground_additions']
civic['interaction_geometry_overrides']=[{**copy.deepcopy(row),'logical_id':'ch4_s3_luoyang_market'}for row in market['interaction_geometry_overrides']]
civic['interaction_visual_bindings']=copy.deepcopy(market['interaction_visual_bindings'])
market_district=next(row for row in civic['districts']if row['logical_id']=='ch4_s3_luoyang_market')
catalog=fixed(N/'legacy_layout_owner_catalog01_BUILD.json','59086d270f356997d4142e5d5d8bfc3748c2441e877bdfdc72fba892b5a97b0f')
for placement in market['pending_legacy_front_placements']:
 plots=[row for row in market_district['plots']if placement['owner_id']in row['owners']]
 if not plots:
  originals=[row for row in catalog['scenes']['ch4_s3_luoyang_market']['owners']if row['id']==placement['owner_id']];assert len(originals)==1
  market_district['plots'].append({'id':'pending_whole_legacy_'+placement['owner_id'],'owners':[placement['owner_id']],'source_anchor_px':originals[0]['world_foot_px'],'target_anchor_px':placement['target_foot_px'][:],'retained_pending_native_scale':True})
 else:
  assert len(plots)==1 and plots[0]['owners']==[placement['owner_id']]
  plots[0]['target_anchor_px']=placement['target_foot_px'][:]
for building in civic['pending_buildings']:building['logical_id']='ch4_s3_luoyang_market'
civic['pending_replacements']=[{**copy.deepcopy(row),'owner_id':row['legacy_owner_id'],'logical_id':district['logical_id']}for district in civic['districts']for row in district.get('pending_replacements',[])]
civic['portal_region_return_feet']={'ch4_s1_luoyang_yamen':yamen['portal_region_return_feet'],'ch4_s3_luoyang_market':market['portal_region_return_feet']}
author['terminal_bindings']={}
for logical,pid,dirname,want in [('ch4_s1_luoyang_yamen',124012,'terminal_cold_output','287198326f64837ea87883a8a3c0866f5e59eec7cb9e4a22f5b25d1a093e8aac'),('ch4_s3_luoyang_market',107588,'terminal_market_residual_output','d847e0aa20fc15c8d018a15b41ef2334e7fd5a7373cc9ae23191a89c52cf98a4')]:
 path=N/dirname/str(pid)/(logical+'_terminal.bin');raw=path.read_bytes();assert sha(raw)==want
 author['terminal_bindings'][logical]={'path':res(path),'sha256':want,'bytes':len(raw)}
lookup=json.loads((N/'terminal_market_media04_input_NOTREADY.json').read_text(encoding='utf8'))['available_parent_sources']
def media(path):
 assert path in lookup,path
 pins={path:lookup[path]};side=path+'.import';assert side in lookup,side
 text=(G/side[6:]).read_bytes();assert sha(text)==lookup[side]
 ctex=re.search(rb'path="(res://[^"\r\n]+\.ctex)"',text)[1].decode();assert ctex in lookup,ctex
 pins.update({side:lookup[side],ctex:lookup[ctex]});return {'path':path,'source_sha256':pins}
rolepaths={'court_stone':'res://art/modules/ancient_temple_assembled_20261016/courtyard_floor_v1.png','public_stone':'res://art/maps/luoyang_modular_v3/source/worn_bluestone_v2.png','shop_pavers':'res://art/maps/luoyang_modular_v3/source/worn_bluestone_v2.png','service_earth':'res://art/external/polyhaven/world_terrain_v14_sixth/brown_mud_03/brown_mud_03_diff_2k.jpg','workyard_earth':'res://art/external/polyhaven/world_terrain_v14_sixth/brown_mud_03/brown_mud_03_diff_2k.jpg'}
author['texture_roles']={role:media(path)for role,path in rolepaths.items()}
author['compile_provenance']=[{'path':res(fragment_path),'sha256':sha(fragment_path.read_bytes())},{'path':res(yamen_path),'sha256':sha(yamen_path.read_bytes())},{'path':res(market_path),'sha256':sys.argv[2].lower()}]
author_pin=put(N/'regions_author02_real_civic_BUILD.json',author)
modules={res(N/name):sha((N/name).read_bytes())for name in ['region_compiler.gd','region_content_compiler.gd','civic_author_compile_worker_NOTREADY.gd']}
input={'root_authorized':True,'authorization_scope':'Root expressly authorized this fixed pure compile candidate preparation, not execution or canonical adoption.','author':author_pin,'region_id':'luoyang_civic_market_region_27d','module_sources':modules,'output_root':res(N/'civic_compile_output'),'scope':'Pure first real civic author compilation. Both immutable terminals inherited; no NPC/portal re-projection, Field or legacy collectors.'}
inp=put(N/'civic_author_compile_input_ROOT_READY01.json',input)
boot=(N/'terminal_market_media04_bootstrap_NOTREADY.gd').read_text(encoding='utf8')
boot=boot.replace('terminal_market_media04_input_NOTREADY.json','civic_author_compile_input_ROOT_READY01.json').replace('3955871bfbd504d3bfd21fc417084d90166f0f564e7eea9d8398c1ce8c3dba6f',inp['sha256']).replace('terminal_market_media04_worker_NOTREADY.gd','civic_author_compile_worker_NOTREADY.gd').replace('51ee58aeb0917ce21260458585e4e6ed80769e899f203e3a77008bc19f45e7b4',modules[res(N/'civic_author_compile_worker_NOTREADY.gd')])
out=N/'civic_author_compile_bootstrap_ROOT_READY01.gd';assert not out.exists();out.write_text(boot,encoding='utf8',newline='\n')
print(json.dumps({'author':author_pin,'input':inp,'worker_sha256':modules[res(N/'civic_author_compile_worker_NOTREADY.gd')],'bootstrap_sha256':sha(out.read_bytes())}))
