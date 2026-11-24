"""Last revised authoring views: real Artisan base, three bodies, soft joints.
One unchanged Estate PNG retained. Root sole execution; no engine here.
"""
from pathlib import Path
import hashlib,json,copy
N=Path(__file__).resolve().parent;G=N.parents[1];NS='res://build/luoyang_city_finish_20261025i_source01/'
def sha(b):return hashlib.sha256(b).hexdigest()
def emit(name,b):
 with (N/name).open('xb') as stream:stream.write(b)
 return {'path':NS+name,'sha256':sha(b),'bytes':len(b)}
def enc(a):return (json.dumps(a,ensure_ascii=False,indent=2)+'\n').encode()
raw=(N/'overview_eight_fields08_ROOT_READY_input.json').read_bytes();assert sha(raw)=='8504ff48082469f94dde3faf146a59e9d92c284334807117a91b878e0bdf9355'
a=json.loads(raw);a['ready']=False
def replace_input(field,name,expected):
 b=(N/name).read_bytes();assert sha(b)==expected
 old=a[field];a['sources'].pop(old,None);a[field]=NS+name;a['sources'][NS+name]=expected
replace_input('axis_author','author_gate_yamen_axis09_three_body_substitutions_NOTREADY.json','2b17aa92d9b034fc914fa2c643a41b6301da7218c1422492e5f1128b80083731')
replace_input('axis_library','axis_infill_asset_library05_processed_kitchen_SOURCE_ONLY.json','8596f11f72c3d7ad546c35269d4afecedadf83ef77c0dd665aa7c84adc697619')
replace_input('adjacent_author','author_adjacent_four_fields07_final_dry_bank_routes_NOTREADY.json','fcbfa06b2347bf89e0c86cb4c7817be6781b6e574e01507e6098446afb419d20')
replace_input('surface_factory','city_purpose_surface02_soft_joint_NOTREADY.gd','7211d2cd1ab5534b72cbe5828d0cd504948d1e5c81d5d4a6e44c8365d8fc021a')
replace_input('surface_shader','city_purpose_surface02_soft_joint_NOTREADY.gdshader','e84bd7aa9cf36c8f739445196ce7dce33e2c64cbe754072971cc18f14e6ef230')
replace_input('surface_author','eight_fields_purpose_surface02_soft_joint_NOTREADY.json','58d67384a6bbc9eb62f80cecfd1022006b255239f4005c957ca08a64073d0c17')
stage=json.loads((G/'build/luoyang_city_revision_20261025h_source01/outputs/root_services_garden_exact28_stage05/receipt.json').read_text(encoding='utf8'));authority={}
for key,node in stage['nodes'].items():
 if key.startswith('expected_'):
  for path,h in node['value']['source_sha256'].items():assert path not in authority or authority[path]==h;authority[path]=h
contract='res://build/luoyang_city_full_rollout_20261022ap_system01/artisan_a2_publication_epoch01/ground_contract_READY.json'
shader='res://build/luoyang_city_full_rollout_20261022ap_system01/artisan_a2_publication_epoch01/ground_use_candidate.gdshader'
assert authority[contract]=='87abb71b03de83e2d5c14434b52d56a8be51dfe940ed85478fc34b029a4ed5af'
assert authority[shader]=='11b32bb0efbc9b1317c2ad06d028742d9bfce899e2d9b9467874c28898c2eb1e'
a['artisan_existing_material_contract']=contract;a['artisan_existing_material_shader']=shader
for path in [contract,shader]:a['sources'][path]=authority[path]
helper='artisan_existing_floor_material_fidelity01_NOTREADY.gd';hb=(N/helper).read_bytes();assert sha(hb)=='e2281682d8f2eb402b3a749662e7dc302b84941221e8cc327b5427da79a21d9d'
a['artisan_fidelity_helper']=NS+helper;a['sources'][NS+helper]=sha(hb)
floor='res://art/modules/ancient_temple_assembled_20261016/courtyard_floor_v1.png'
for scene in a['scenes']:
 if scene['id']=='luoyang_artisan_residential_20261022ap':scene['background_path']=floor
worn='res://art/maps/luoyang_modular_v3/source/worn_bluestone_v2.png'
assert authority[worn]=='7e9c7d892f86ced04ad3b8ad293208e05d87a01afffc2729804e4469f87deb7d'
a['sources'][worn]=authority[worn];a['texture_authority'][worn]=authority[worn]
a['output_absolute']=(N/'overview_eight_fields09_NOTREADY/output_NOTREADY').as_posix()
a['last_visual_revision_scope']={'three_bodies_Axis09':True,'Artisan_background_and118_ground_shader_faithful_existing_consumer':True,'Temple_Garden_same_floor_texture_world_period_px':[384,256],'only_render_material_deltas_no_NAV':True,'Estate_unchanged_full_PNG_inherited':True,'replayed_old_prior_or_physics':False}
ipin=emit('overview_eight_fields09_NOTREADY_input.json',enc(a))
old=(N/'overview_eight_fields08_ROOT_READY.gd').read_bytes();assert sha(old)=='0d94f29d09e90dcab82364d119ed5773466b3977f48b07448a3bf34e3b5e3b01'
text=old.decode();hunks=[]
def change(o,n):
 global text
 assert text.count(o)==1;text=text.replace(o,n);hunks.append({'old':o,'new':n})
change('const READY: bool=true','const READY: bool=false')
change('const INPUT: String="'+NS+'overview_eight_fields08_ROOT_READY_input.json"\nconst INPUT_SHA: String="'+sha(raw)+'"\nconst SELF: String="'+NS+'overview_eight_fields08_ROOT_READY.gd"','const INPUT: String="'+ipin['path']+'"\nconst INPUT_SHA: String="'+ipin['sha256']+'"\nconst SELF: String="'+NS+'overview_eight_fields09_NOTREADY.gd"')
change('\t\tif index<6:\n\t\t\tvar inherited:', '\t\tif id=="luoyang_estate_riverside_20261021ai":\n\t\t\tvar inherited:')
change('var base: Sprite2D=Sprite2D.new();base.texture=texture;base.centered=false;base.scale=size/texture.get_size();base.z_index=-25;world.add_child(base)','var base: Sprite2D=Sprite2D.new();base.texture=texture;base.centered=false;base.scale=Vector2.ONE*(size.x/float(texture.get_width()));base.texture_filter=CanvasItem.TEXTURE_FILTER_LINEAR;base.z_index=-1000;world.add_child(base)')
change('\t\tif not add_rows(world,rows,size): break\n\t\tvar visible:', '\t\tif not add_rows(world,rows,size): break\n\t\tif id=="luoyang_artisan_residential_20261022ap":\n\t\t\tvar fidelity: Variant=load(fixture.artisan_fidelity_helper)\n\t\t\tvar existing_shader: Shader=load(fixture.artisan_existing_material_shader) as Shader\n\t\t\tif not check(fidelity is GDScript and fidelity.can_instantiate() and fidelity.attach_authoring_only(world,j(fixture.artisan_existing_material_contract),existing_shader),"FAITHFUL_EXISTING_ARTISAN_118_MATERIALS"): break\n\t\tvar visible:')
inverse=text
for h in reversed(hunks):assert inverse.count(h['new'])==1;inverse=inverse.replace(h['new'],h['old'])
assert inverse.encode()==old
key=emit('overview_eight_fields09_NOTREADY.gd',text.encode())
proof=emit('overview09_final_visible_delta_whole_inverse_NOTREADY.json',enc({'status':'ROOT_APPROVED_MINIMUM_LAST_VISUAL_DELTA_PENDING_EXECUTION','key':key,'input':ipin,'full_byte_inverse_to08':True,'hunks':hunks,'Estate_full_PNG_inherited':a['inherited_images']['luoyang_estate_riverside_20261021ai'],'no_explicit_old_five_dependency_parse_replay':True,'new_fidelity_helper_normally_loaded_once':True,'floor_fidelity_provenance':'Formal Field._spawn_world_background at1506 and ENV._attach_a2_exact_material -> life_production100_READY/material_runtime_life_READY.gd original118 uniforms. No fake runtime owner/136gate bypass is invoked by this authoring-only drawing.','no_newgeometry_or_mask':True,'engine_calls':0,'canonical_writes':0}))
print(json.dumps({'key':key,'input':ipin,'proof':proof}))
