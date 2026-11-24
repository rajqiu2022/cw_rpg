"""Two boardwalk side fixes + exact old-foot adapter, new namespace only.
Original3targets remain read-only. No engine/process/save/art operations.
"""
from pathlib import Path
import difflib,hashlib,json,re
HERE=Path(__file__).resolve().parent;GAME=HERE.parents[1]
SCENE=GAME/'scenes/drafts/miao_terrain_20261029i/miao_town.tscn'
NATIVE=GAME/'build/three_towns_world_20261029j_system01/native_sources.json'
REG=GAME/'build/three_towns_world_20261029j_system01/town_registry.gd'
HELPER=HERE/'boardwalk_controller.gd'
def sha(b):return hashlib.sha256(b).hexdigest()
def fact(p):return {'sha256':sha(p.read_bytes()),'bytes':p.stat().st_size}
def put(name,b):
 with (HERE/name).open('xb') as f:f.write(b)
def encoded(v):return (json.dumps(v,ensure_ascii=False,indent=2)+'\n').encode()
def once(s,a,b):assert s.count(a)==1,(a[:80],s.count(a));return s.replace(a,b,1)
def hunks(a,b):
 aa=a.decode().splitlines(keepends=True);bb=b.decode().splitlines(keepends=True)
 for context in [4,8,16,32,10000]:
  rows=[{'old':''.join(aa[g[0][1]:g[-1][2]]),'new':''.join(bb[g[0][3]:g[-1][4]])} for g in difflib.SequenceMatcher(None,aa,bb,autojunk=False).get_grouped_opcodes(context)]
  if all(a.count(r['old'].encode())==1 and b.count(r['new'].encode())==1 for r in rows):
   proof=a
   for r in rows:proof=proof.replace(r['old'].encode(),r['new'].encode(),1)
   assert proof==b
   for r in reversed(rows):proof=proof.replace(r['new'].encode(),r['old'].encode(),1)
   assert proof==a
   return rows
 raise AssertionError('NONUNIQUE_HUNK')
before_scene=SCENE.read_bytes();before_native=NATIVE.read_bytes();before_reg=REG.read_bytes()
assert sha(before_scene)=='de7ea4a4db4582acf6477e4dd6d63ebfda78b2a77bd9e79146f6e9e1c1d79552'
assert sha(before_native)=='44e291a295dec854a3c3bbb21ceb6bf4cded52f7bcf96abc70309402b331693d'
assert sha(before_reg)=='229d6b687db124b5277d74530b0dbaf8fede9ca779752dd9bb0bd2a19be49e08'
eol='\r\n' if before_scene.count(b'\r\n')==before_scene.count(b'\n') and b'\r\n' in before_scene else '\n'
old=before_scene.decode().replace('\r\n','\n');scene=old
old_controller='res://build/lanxi_revision_20261030l/controller.gd'
new_controller='res://build/lanxi_boardwalk_edges_20261031a_system01/boardwalk_controller.gd'
scene=once(scene,old_controller,new_controller)
poly_old='polygon = PackedVector2Array(-494.5602, -34.3, 494.5602, -34.3, 494.5602, -22.3, -494.5602, -22.3)'
poly_new='polygon = PackedVector2Array(-574.2, -34.3, 575.94, -34.3, 575.94, -22.3, -574.2, -22.3)'
ids={3:'1420414662',4:'2071180086'}
for number in [3,4]:
 header=f'[node name="Outline" type="CollisionPolygon2D" parent="Town/RaisedMarket{number}/BackRail" unique_id={ids[number]}]\n'
 front=f'''[node name="FrontRail" type="StaticBody2D" parent="Town/RaisedMarket{number}"]
collision_layer = 16
collision_mask = 0

[node name="Outline" type="CollisionPolygon2D" parent="Town/RaisedMarket{number}/FrontRail"]
polygon = PackedVector2Array(-574.2, 20.3, 575.94, 20.3, 575.94, 32.3, -574.2, 32.3)

'''
 scene=once(scene,header+poly_old+'\n\n',header+poly_new+'\n\n'+front)
new_scene=scene.replace('\n',eol).encode()
def blocks(s):
 out={}
 for m in re.finditer(r'^\[node name="([^"]+)"[^\n]*\]\n.*?(?=^\[node |\Z)',s,re.M|re.S):
  header=m[0].split('\n',1)[0];p=re.search(r'parent="([^"]+)"',header)
  parent=p[1] if p else ''
  key=(parent+'/' if parent not in ['', '.'] else '')+m[1]
  assert key not in out,key;out[key]=m[0]
 return out
a=blocks(old);b=blocks(scene)
added=sorted(set(b)-set(a));changed=sorted(k for k in a if a[k]!=b[k])
assert added==['Town/RaisedMarket3/FrontRail','Town/RaisedMarket3/FrontRail/Outline','Town/RaisedMarket4/FrontRail','Town/RaisedMarket4/FrontRail/Outline']
assert changed==['Town/RaisedMarket3/BackRail/Outline','Town/RaisedMarket4/BackRail/Outline']
assert all(a[k].replace(poly_old,poly_new)==b[k] for k in changed)
for bridge in ['GateBridge','MiddleBridge','UpperBridge']:
 assert all(a[k]==b[k] for k in a if k.startswith('Town/'+bridge))
assert all(a[k]==b[k] for k in a if k.startswith('Terrain'))
assert old[:old.index('[node ')].replace(old_controller,new_controller)==scene[:scene.index('[node ')]
manifest=json.loads(before_native);native_old=manifest['sources'].copy();assert len(native_old)==200
scene_uri='res://scenes/drafts/miao_terrain_20261029i/miao_town.tscn'
assert native_old[scene_uri]==sha(before_scene) and new_controller not in native_old
manifest['sources'][scene_uri]=sha(new_scene);manifest['sources'][new_controller]=fact(HELPER)['sha256']
assert len(manifest['sources'])==201
assert all(manifest['sources'][k]==v for k,v in native_old.items() if k!=scene_uri)
new_native=encoded(manifest)
assert before_reg.count(sha(before_native).encode())==1
new_reg=before_reg.replace(sha(before_native).encode(),sha(new_native).encode(),1)
targets=[]
for p,before,after,name in [(SCENE,before_scene,new_scene,'miao_town_READY.tscn'),(NATIVE,before_native,new_native,'native_sources_READY.json'),(REG,before_reg,new_reg,'town_registry_READY.gd')]:
 put(p.name+'.BEFORE',before);put(name,after)
 targets.append({'target':p.relative_to(GAME.parent).as_posix(),'candidate':'game/build/lanxi_boardwalk_edges_20261031a_system01/'+name,'old_sha256':sha(before),'new_sha256':sha(after),'bytes':len(after),'replacements':hunks(before,after),'whole_byte_inverse':True})
audit={'root_confirmed_same_family_two_instances':True,'current_controller':{'path':'game/build/lanxi_revision_20261030l/controller.gd',**fact(GAME/'build/lanxi_revision_20261030l/controller.gd')},'actor_original_foot_shape':[34,24],'restore_conservative_foot':[35,25],'ground_level':0,'elevation':0,'projected_foot_equals_ground_at_scope':True,'actor_mask':24,'side_body_layer':16,'side_body_mask':0,'deck_local_xy':[-574.2,-20.3,575.94,20.3],'south_visual_supports_to_local_y':292.9,'old_back_local_xy':[-494.5602,-34.3,494.5602,-22.3],'new_back_local_xy':[-574.2,-34.3,575.94,-22.3],'new_front_local_xy':[-574.2,20.3,575.94,32.3],'added_nodes':added,'only_changed_existing_node_blocks':changed,'all_other_original_node_blocks_byte_equal':True,'all_original_material_visual_UV_resource_nodes_equal':True,'original_three_bridge_subtrees_equal':True,'all_Terrain_nodes_including_original_four_stairs_equal':True,'boardwalks':[{'name':'RaisedMarket3','path':'Town/RaisedMarket3','origin':[3650,3560],'usable_dry_centerline_foot_examples':[[3360,3560],[3650,3560],[4160,3560]],'inherited_water_blocked_left_visual_tip':[3075.8,3560],'left_tip_NOT_claimed_passable':True},{'name':'RaisedMarket4','path':'Town/RaisedMarket4','origin':[6740,3930],'open_x_end_centerline_examples':[[6120,3930],[6740,3930],[7360,3930]]}],'legacy_restore':'ONLY actual original actor overlaps new front/back extensions + old full35foot clear excluding4edgeBodies and exact oldBack check + fullX inside deck + outdoorlevel0/ramp<0 + authored centerline Y target full35 and originalfoot_clear; exact global X preserved','far_supports_ground_not_relocated':True,'no_end_caps':True,'no_texture_or_render_changes':True,'static_only_not_engine_or_Physics':True}
receipt={'schema_version':1,'status':'ROOT_AUTHORIZED_TWO_BOARDWALK_EDGE_CANDIDATE_NOT_ENGINE_RUN','targets':targets,'new_modules':{'game/build/lanxi_boardwalk_edges_20261031a_system01/boardwalk_controller.gd':fact(HELPER)},'native_old200_keys_preserved_only_scene_hash_changes':True,'native_new_count':201,'registry_only_native_header_changes':True,'source_guard_not_relaxed':True,'audit':audit,'engine_runs':0,'canonical_writes':0,'user_process_control':False,'save_content_reads':0,'save_writes':0,'other_cities_sect_adoption_World_bridges_untouched':True}
data=encoded(receipt);put('receipt_READY.json',data)
put('diagnosis_STATIC_READY.json',encoded(audit))
print(json.dumps({'receipt_sha256':sha(data),'bytes':len(data),'targets':[{k:r[k] for k in ['target','new_sha256','bytes']} for r in targets],'new_module':fact(HELPER),'native_count':201,'hunks':sum(len(r['replacements']) for r in targets)},ensure_ascii=False))
