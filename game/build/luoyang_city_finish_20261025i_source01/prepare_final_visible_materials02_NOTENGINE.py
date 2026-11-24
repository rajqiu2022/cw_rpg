"""Root-approved render-only small joint / soft shoulder candidate.
No layout, floor transform, water, mask, body, NPC or door modification.
"""
from pathlib import Path
import copy,hashlib,json
N=Path(__file__).resolve().parent;G=N.parents[1];NS='res://build/luoyang_city_finish_20261025i_source01/'
def sha(b):return hashlib.sha256(b).hexdigest()
def emit(name,b):
 with (N/name).open('xb') as stream:stream.write(b)
 return {'path':NS+name,'sha256':sha(b),'bytes':len(b)}
def enc(a):return (json.dumps(a,ensure_ascii=False,indent=2)+'\n').encode()
factory_old=(N/'city_purpose_surface01_NOTREADY.gd').read_bytes();assert sha(factory_old)=='555e1f90ae1c8db567c40b532dd2352f5c0abfd0944b0b6bfe5336c11ab9e913'
shader_old=(N/'city_purpose_surface01_NOTREADY.gdshader').read_bytes();assert sha(shader_old)=='9ab7ad209c8073fbe2ef092b13b56460493224ca8e71ee45aac8b8c3ce407328'
st=shader_old.decode();shader_hunks=[]
def change_shader(o,n):
 global st
 assert st.count(o)==1;st=st.replace(o,n);shader_hunks.append({'old':o,'new':n})
change_shader('uniform bool is_path=false;','uniform bool is_path=false;\nuniform bool full_base_coverage=false;')
change_shader('float alpha=(1.0-smoothstep(-shoulder_px,shoulder_px*0.3,distance_to_edge+weather))*opacity;','float alpha=full_base_coverage ? opacity : (1.0-smoothstep(-shoulder_px,shoulder_px*0.3,distance_to_edge+weather))*opacity;')
shader=emit('city_purpose_surface02_soft_joint_NOTREADY.gdshader',st.encode())
ft=factory_old.decode();factory_hunks=[]
def change_factory(o,n):
 global ft
 assert ft.count(o)==1;ft=ft.replace(o,n);factory_hunks.append({'old':o,'new':n})
change_factory('city_purpose_surface01_NOTREADY.gdshader','city_purpose_surface02_soft_joint_NOTREADY.gdshader')
change_factory('\t\tmaterial.set_shader_parameter("opacity",float(row.get("opacity",1.0)))','\t\tmaterial.set_shader_parameter("opacity",float(row.get("opacity",1.0)))\n\t\tmaterial.set_shader_parameter("full_base_coverage",row.get("full_base_coverage",false)==true)')
change_factory('\t\tvar tile: Polygon2D=Polygon2D.new();tile.name=id;tile.material=material','\t\tvar tile: Polygon2D=Polygon2D.new();tile.name=id;tile.material=material\n\t\ttile.z_index=int(row.get("relative_z_index",0))')
factory=emit('city_purpose_surface02_soft_joint_NOTREADY.gd',ft.encode())
raw=(N/'eight_fields_purpose_surface01_NOTREADY.json').read_bytes();assert sha(raw)=='77642a5ad0169f6b1571a79cec77f3f4914da731f563a51f4fbaf5ebca698f0b'
parent=json.loads(raw);a=copy.deepcopy(parent);a['factory']=factory;a['shader']=shader
fixed=json.loads((G/'build/luoyang_street_materials_20261025f_system01/material_revision02/market_five_use_spec_BUILD.json').read_text(encoding='utf8'))
worn='res://art/maps/luoyang_modular_v3/source/worn_bluestone_v2.png'
assert fixed['source_sha256'][worn]=='7e9c7d892f86ced04ad3b8ad293208e05d87a01afffc2729804e4469f87deb7d'
a['textures']['road_stone']={'path':worn,'sha256':fixed['source_sha256'][worn],'existing_25f_source_only_no_new_media':True}
material_changes=[]
for scene_id,rows in a['scenes'].items():
 if scene_id=='luoyang_estate_riverside_20261021ai':continue
 for row in rows:
  old=copy.deepcopy(row)
  row['shoulder_px']=36 if 'polyline_px' in row else 42
  if row['texture_role'] in ['road_earth','road_gravel']:
   row['opacity']=0.72;row['contrast']=0.58
  elif 'rect_xywh' in row:
   row['opacity']=0.86;row['corner_radius_px']=36
  if scene_id=='luoyang_riverside_garden_20261022ap' and row['id']=='west_garden_soft_path':
   row['polyline_px']=[[520,1520],[640,1520],[640,1420],[740,1360],[740,1160],[860,1160]]
  if scene_id=='ch4_s2_canal_docks' and row['id']=='short_storage_work_court':
   row['rect_xywh']=[1980,1860,240,164];row['shoulder_px']=24
  if scene_id=='ch4_s2_canal_docks' and row['id']=='continuous_cargo_service_road':
   row['polyline_px']=[[1180,1348],[1280,1348],[1280,1910],[2060,1910],[2000,1910],[2000,2000],[2120,2000]]
   row['width_px']=96;row['shoulder_px']=24
  if row!=old:material_changes.append({'scene_id':scene_id,'id':row['id'],'old':old,'new':copy.deepcopy(row)})
for scene_id,size in [('ch4_s4_ancient_temple',[1920,1280]),('luoyang_riverside_garden_20261022ap',[3072,2048])]:
 a['scenes'][scene_id].insert(0,{'id':'existing_floor_same_texture_adult_scale_joint','rect_xywh':[0,0,*size],'texture_role':'court_stone','repeat_period_px':[384,256],'tint_rgba':[1,1,1,1],'contrast':1.0,'opacity':1.0,'full_base_coverage':True,'relative_z_index':-897,'shoulder_px':1,'corner_radius_px':0,'render_only_same_existing_floor_PNG_no_floor_transform_or_navigation_change':True})
a['render_only_revision02']={'Root_scope':'Three final bodies handled by Axis09; this file only visible material. Original floorSprite/background asset/transform remains. New full coverage source-periodic layer is above original background at-900, below all real ground/buildings/water.','Temple_Garden_source_period_px':[384,256],'soft_shoulder_px':[24,36,42],'old_25f_materials_unchanged':True,'Estate_material_rows_unchanged':True,'six_proposed_extra_walls_not_adopted':True,'Garden_Docks_paths_use_final_adjacent07_source_design_not_actual_observations':True,'no_NEW_PNG_import_nav_or_geometry':True}
pin=emit('eight_fields_purpose_surface02_soft_joint_NOTREADY.json',enc(a))
back=copy.deepcopy(a)
for c in material_changes:
 rows=back['scenes'][c['scene_id']];i=next(i for i,r in enumerate(rows) if r['id']==c['id']);rows[i]=c['old']
for scene_id in ['ch4_s4_ancient_temple','luoyang_riverside_garden_20261022ap']:back['scenes'][scene_id].pop(0)
back['factory']=parent['factory'];back['shader']=parent['shader'];back['textures']['road_stone']=parent['textures']['road_stone'];del back['render_only_revision02'];assert back==parent
for text,old,hunks in [(st,shader_old,shader_hunks),(ft,factory_old,factory_hunks)]:
 for h in reversed(hunks):assert text.count(h['new'])==1;text=text.replace(h['new'],h['old'])
 assert text.encode()==old
proof=emit('final_visible_materials02_whole_inverse_BUILD.json',enc({'status':'ROOT_APPROVED_RENDER_ONLY_SMALL_JOINT_SOFT_SHOULDER_CANDIDATE','factory':factory,'shader':shader,'spec':pin,'factory_hunks':factory_hunks,'shader_hunks':shader_hunks,'GD_shader_full_byte_inverse':True,'spec_full_typed_inverse':True,'changed_material_rows':material_changes,'new_material_dependencies':{worn:fixed['source_sha256'][worn]},'old118_artisan_material_repair_is_separate_authoring_fidelity_not_this_material_revision':True,'physics_navigation_pixel_mask_changes':0,'engine_calls':0,'canonical_writes':0}))
print(json.dumps({'factory':factory,'shader':shader,'spec':pin,'proof':proof}))
