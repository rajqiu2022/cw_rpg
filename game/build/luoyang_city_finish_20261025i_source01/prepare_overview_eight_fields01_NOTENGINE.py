"""Finite authoring GPU input. New candidates pinned; old leaves from Stage05 authority.
Does not execute Godot, collect live sources, decode packets or import any image.
"""
from pathlib import Path
import hashlib,json
N=Path(__file__).resolve().parent;G=N.parents[1];REPO=G.parent
def sha(b):return hashlib.sha256(b).hexdigest()
def load(p):return json.loads(p.read_text(encoding='utf8'))
def res(p):return 'res://'+p.relative_to(G).as_posix()
stage=load(G/'build/luoyang_city_revision_20261025h_source01/outputs/root_services_garden_exact28_stage05/receipt.json')
authority={}
for key,node in stage['nodes'].items():
 if key.startswith('expected_'):
  for p,h in node['value']['source_sha256'].items():
   assert p not in authority or authority[p]==h;authority[p]=h
for row in stage['targets']:authority[row['target']]=row['candidate_sha256']
sources={}
def old(p,h=None):
 expected=authority[p] if h is None else h
 if p in authority:assert authority[p]==expected,p
 sources[p]=expected;return p
def new(name):
 p=N/name;raw=p.read_bytes();sources[res(p)]=sha(raw);return res(p)
fixture={'status':'EIGHT_FIELDS_SOURCE_AUTHORING_OVERVIEW_PENDING_ROOT_REVIEW_NOT_FIELD','ready':False,'whole_budget_ms':45000,'repository_absolute':REPO.as_posix(),'sources':sources,'raw_sources':{},'texture_authority':{p:h for p,h in authority.items() if p.endswith(('.png','.jpg','.res'))},'output_absolute':(N/'overview_eight_fields01_NOTREADY/output').as_posix(),
 'axis_helper':new('gate_yamen_projection03_NOTREADY.gd'),'axis_author':new('author_gate_yamen_axis08_low_courts_NOTREADY.json'),'axis_library':new('axis_infill_asset_library04_SOURCE_ONLY.json'),
 'artisan_helper':new('artisan_block_projection05_NOTREADY.gd'),'artisan_author':new('author_artisan_residential_block06_threshold_short_cross_NOTREADY.json'),
 'adjacent_helper':new('adjacent_courts_projection03_NOTREADY.gd'),'adjacent_author':new('author_adjacent_four_fields04_actual_actor_id_NOTREADY.json'),'adjacent_library':new('adjacent_adopted_asset_library03_SOURCE_ONLY.json'),
 'temple_builder':new('temple_native_builder01_NOTREADY.gd'),'temple_author':new('author_temple_source_compiled03_NOTREADY.json'),
 'surface_factory':new('city_purpose_surface01_NOTREADY.gd'),'surface_shader':new('city_purpose_surface01_NOTREADY.gdshader'),'surface_author':new('eight_fields_purpose_surface01_NOTREADY.json'),
 'parent_seed':old('res://build/luoyang_city_finish_20261025i_source01/parent_projection01_ROOT_READY/output_ROOT_READY/parent_source_seeds.bin','dfd5162f2668f599a1e3362298eb1953778d9339c59069a738c732d0ef849486'),
 'artisan_old_author':old('res://build/luoyang_city_full_rollout_20261022ap_system01/artisan_a2_workyards_epoch01/author_CANDIDATE_NOT_APPROVED.json'),
 'artisan_life_author':old('res://build/luoyang_city_full_rollout_20261022ap_system01/artisan_life_delta_publication_epoch01/author_delta_NOTREADY.json'),
 'temple_old_author':old('res://data/maps/luoyang_temple_assembly_20261016/author.json'),
 'garden_river_visual':old('res://build/luoyang_garden_river_20261025h_source01/garden_river_visual_NOTREADY.gd'),
 'district_author':old('res://data/maps/luoyang_district_life_20261016f/author.json'),
 'market_surface_spec':old('res://build/luoyang_street_materials_20261025f_system01/material_revision02/market_five_use_spec_BUILD.json'),
 'market_surface_shader':old('res://build/luoyang_street_materials_20261025f_system01/material_revision02/market_use_materials_BUILD.gdshader'),
 'source_actors':{},'old_NPC_rendering_scope':'Only source-origin craft4, newEstate2 and 3 migrated work-role actors shown; not a full Field/NPC/Task-state simulation.',
 'Docks39_layer_scope':'Fixed native29 + originalDG10 authoring render projection. Not actual Task-visibility visual count. New runtime must pass through every non-target visual task row.',
 'Garden56_scope':'Whole formal native56 from fixed scene/layout, plus unchanged water/shore constructor; no old46 shortcut.',
 'artifact_creation_scope':'Only new per-scene PNG8/contact-sheet1/report1; no native/resource/physics/route/mask publication.'}
for lot in load(N/'author_artisan_residential_block06_threshold_short_cross_NOTREADY.json')['new_asset_lots']:
 m=lot['source_asset_measured_raw'];fixture['raw_sources'][m['raw_path']]=m['raw_sha256']
DG=load(G/'data/maps/luoyang_district_life_20261016f/author.json')
gate_manifest=load(G/'build/luoyang_harbour_life_publication_20261016/93032_1727/ch4_s0_luoyang_gate/manifest.json')
yamen_manifest=load(G/DG['districts']['ch4_s1_luoyang_yamen']['parent_manifest']['path'][6:])
scenes=[{'id':'ch4_s0_luoyang_gate','label':'Gate / inspection axis','world_size_px':[3072,2048],'background_path':old(gate_manifest['record']['ground_path'])},
 {'id':'ch4_s1_luoyang_yamen','label':'Yamen / archive courts','world_size_px':[3072,2048],'background_path':old(yamen_manifest['record']['ground_path'])},
 {'id':'luoyang_artisan_residential_20261022ap','label':'Artisan / residential block','world_size_px':[3072,2048],'parent_layout':old('res://build/luoyang_city_full_rollout_20261022ap_root01/integration59/artisan_life_READY/output/native/layout.res')},
 {'id':'ch4_s4_ancient_temple','label':'Temple / bamboo loop','world_size_px':[1920,1280],'parent_scene':old('res://data/scenes/luoyang_temple_layout_quest_20261018t/temple.tres')},
 {'id':'ch4_s3_luoyang_market','label':'Market / inn service court','world_size_px':[3072,2048],'parent_projection':old('res://build/luoyang_market_courtyard_links_20261025g_system01/publication03/output/115716/projection.bin')},
 {'id':'luoyang_estate_riverside_20261021ai','label':'Estate / family and wash courts','world_size_px':[3072,2048],'parent_scene':old('res://data/maps/luoyang_estate_courtyard_20261021am/scene.res')},
 {'id':'luoyang_riverside_garden_20261022ap','label':'Garden / river banks','world_size_px':[3072,2048],'parent_scene':old('res://build/luoyang_garden_river_20261025h_source01/publication01/output/native/luoyang_riverside_garden_20261022ap/scene.res')},
 {'id':'ch4_s2_canal_docks','label':'Docks / working bays','world_size_px':[3072,2048],'parent_scene':old('res://data/maps/luoyang_docks_workyard_20261019ac/runtime/ch4_s2_canal_docks/scene.res'),'parent_projection':old('res://build/luoyang_city_blocks_20261024e_system01/docks_three_frontages01/publication01/output/78128/projection.bin')}]
fixture['scenes']=scenes
people=load(G/'build/luoyang_city_full_rollout_20261022ap_npc01/quarter_people.json')
craft=[]
for row in people['people']:
 if row['scene_id']!='luoyang_artisan_residential_20261022ap':continue
 family=people['families'][row['family']]
 craft.append({'npc_id':row['npc_id'],'sprite_path':family['sprite_path'],'idle_frames':4,'sprite_scale':1.0,'foot_px':row['foot_px']})
fixture['source_actors']['luoyang_artisan_residential_20261022ap']=craft
adj=load(N/'author_adjacent_four_fields04_actual_actor_id_NOTREADY.json')
identities=load(G/'build/luoyang_city_finish_20261025i_system01/runtime_ambient44_mapping_READONLY.json')
for scene in adj['scenes']:
 actors=[]
 for row in scene.get('new_NPC_rows',[]):actors.append({'npc_id':row['npc_id'],'sprite_path':row['sprite_path'],'idle_frames':4,'sprite_scale':1.0,'foot_px':row['foot_px']})
 for row in scene.get('npc_migrations',[]):
  identity=next(r for r in identities['rows'] if r['npc_id']==row['npc_id'])
  actors.append({'npc_id':row['npc_id'],'sprite_path':identity['sprite_path'],'idle_frames':1 if '_1f_' in identity['sprite_path'] else 4,'sprite_scale':1.0,'foot_px':row['new_source_origin_px']})
 fixture['source_actors'][scene['scene_id']]=actors
for rows in fixture['source_actors'].values():
 for row in rows:assert row['sprite_path'] in authority
old('res://build/luoyang_city_full_rollout_20261022ap_npc01/quarter_people.json')
new_mapping=G/'build/luoyang_city_finish_20261025i_system01/runtime_ambient44_mapping_READONLY.json'
sources[res(new_mapping)]='46f1792fb2652427f343f9ef927dddbfc7f93e58a7c89584189ab6e44b46a138'
fixture['save_absolute_paths']=load(N/'parent_projection01_ROOT_READY/fixture_ROOT_READY.json')['save_absolute_paths']
fixture['source_candidate_scope']='Not ROOT_READY; all resource/texture expected old hashes inherited Stage05, new inputs explicit SHA only, no current-livefill.'
raw=(json.dumps(fixture,ensure_ascii=False,indent=2)+'\n').encode('utf8');out=N/'overview_eight_fields01_input_NOTREADY.json'
with out.open('xb') as stream:stream.write(raw)
print(json.dumps({'input_path':res(out),'sha256':sha(raw),'bytes':len(raw),'pinned_inputs':len(sources),'all_pixels_unchanged_by_this_tool':True}))
