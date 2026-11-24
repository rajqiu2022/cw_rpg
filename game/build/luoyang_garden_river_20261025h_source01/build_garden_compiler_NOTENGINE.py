"""Generate a bounded Garden compiler successor by exact source hunks; never run it."""
from pathlib import Path
import hashlib, json, copy

HERE=Path(__file__).resolve().parent
GAME=HERE.parents[1]
RES='res://build/luoyang_garden_river_20261025h_source01/'
PARENT=GAME/'build/luoyang_city_full_rollout_20261022ap_system01/garden_revision4/shore_landing_retry2/quarters_compiler.gd'
def sha(b): return hashlib.sha256(b).hexdigest()
def create(name,b):
 p=HERE/name
 assert not p.exists(),p
 with p.open('xb') as f:f.write(b)
 return {'path':RES+name,'sha256':sha(b),'bytes':len(b)}
def dump(name,v):return create(name,(json.dumps(v,ensure_ascii=False,indent=2)+'\n').encode())

raw=PARENT.read_bytes()
assert sha(raw)=='232ad60dfa8cf893fcc8f41fed1722247885e15a96bf18431966ff3a36fd0eb5'
text=raw.decode()
hunks=[]
def change(old,new):
 global text
 assert text.count(old)==1,(old[:120],text.count(old))
 hunks.append({'old':old,'new':new})
 text=text.replace(old,new)

change('## Garden scenic-only river successor; no traversable bridge or fake support.',
 '## 25h Garden-only true bridge: exact visible deck subtracts water bodies and mask.\n## This candidate grants no Family/runtime/ART admission by itself.')
change('const NATIVE_ROOT="res://data/maps/luoyang_full_city_20261022ap/quarters/revision4/"',
 'const NATIVE_ROOT="'+RES+'publication01/output/native/"')
change('author.get("status")!="ART_BOUND_AP_QUARTERS"','author.get("status")!="SOURCE_BOUND_GARDEN_RIVER_CANDIDATE_NOT_RUNTIME"')
change('\treturn {"ok":true,"visual":visual,"blocks":blocks,"supports":supports,"alpha_box":box,"foot":foot,"scale":scale_value}',
 '''	if row.get("ground_layer_only")==true:
		if row.id!="garden_stone_bridge_walkable_25h" or row.asset!="stone_bridge" or float(row.get("uniform_scale",0))!=.7 or scale_value!=.7 or blocks.size()!=2 or supports.size()!=1: return fail("EXACT_BRIDGE_UNIFORM_AND_SOURCE_GEOMETRY",row.id)
		visual["sort_by_feet"]=false;visual["z_index"]=-17;visual["garden_bridge_ground_layer"]=true
	return {"ok":true,"visual":visual,"blocks":blocks,"supports":supports,"alpha_box":box,"foot":foot,"scale":scale_value}''')
change('else ["ap_river_pavilion"]','else ["ap_river_pavilion","garden_riverside_tea_house_25h"]')
change('row.get("minimum_world_clear")!=120','row.get("minimum_world_clear")!=(128 if row.get("placement_id")=="garden_riverside_tea_house_25h" else 120)')
change('if scaled.y<120: return fail("ACTUAL_FLOAT32_DOOR_UNDER_120",','if scaled.y<float(row.minimum_world_clear): return fail("ACTUAL_FLOAT32_DOOR_UNDER_DECLARED_MINIMUM",')
change('if id not in IDS: return fail("UNKNOWN_AP_QUARTER",id)','if id!=IDS[1]: return fail("NEW_PUBLICATION_GARDEN_ONLY_NO_ARTISAN_REPLAY",id)')
change('''		waters.append(polygon);solids.append({"id":"ap_garden_deepwater_"+str(waters.size()),"polygon_px":polygon,"water_closed":true})
	if id==IDS[1] and (waters.size()!=1 or not data.get("scenic_bridge_no_walk_support",false)): return fail("GARDEN_EXACT_SCENIC_WATER")''',
 '''		waters.append(polygon)
	if waters.size()!=1 or data.get("river_bridge_walk_support")!=true or data.has("scenic_bridge_no_walk_support") or supports.size()!=1: return fail("GARDEN_ONE_RIVER_ONE_VISIBLE_DECK")
	var deck: Rect2=supports[0]
	if deck.size.y-24.0<128.0 or not Rect2(Vector2.ZERO,SIZE).encloses(deck): return fail("BRIDGE_FULL_BODY_CENTER_CLEARANCE")
	var deck_polygon: PackedVector2Array=PackedVector2Array([deck.position,Vector2(deck.end.x,deck.position.y),deck.end,Vector2(deck.position.x,deck.end.y)])
	var water_pieces: Array[PackedVector2Array]=Geometry2D.clip_polygons(waters[0],deck_polygon)
	if water_pieces.size()!=2: return fail("DECK_MUST_SPLIT_RIVER_INTO_EXACT_TWO_PHYSICAL_PIECES",water_pieces.size())
	for piece: PackedVector2Array in water_pieces:
		if piece.size()<3 or Geometry2D.is_polygon_clockwise(piece) or Geometry2D.triangulate_polygon(piece).is_empty(): return fail("WATER_MINUS_DECK_SIMPLE_OUTER_PIECES")
		if not Geometry2D.intersect_polygons(piece,deck_polygon).is_empty(): return fail("WATER_BODY_STILL_BLOCKS_DECK")
		solids.append({"id":"garden_river_minus_deck_"+str(solids.size()),"polygon_px":piece.duplicate(),"water_closed":true})
	var bridge: Dictionary={}
	for visual: Dictionary in visuals:
		if visual.id=="garden_stone_bridge_walkable_25h": bridge=visual
	if bridge.is_empty(): return fail("BRIDGE_NATIVE_VISUAL_REQUIRED")
	var source_region: Rect2=rect(author.bridge_contract.front_region_source_rect)
	var source_size: Vector2=v(author.bridge_contract.source_size)
	var uniform: float=float(author.bridge_contract.uniform_scale)
	var bridge_center: Vector2=v(author.bridge_contract.bridge_center)
	var front_center: Vector2=bridge_center+(source_region.get_center()-source_size*.5)*uniform
	var front_foot: float=bridge_center.y+(float(author.bridge_contract.front_region_depth_source_y)-source_size.y*.5)*uniform
	visuals.append({"id":"garden_stone_bridge_front_rail_25h","texture":NATIVE_ROOT+"front_rail.res","pos":front_center/SIZE,"render_size_px":source_region.size*uniform,"centered":true,"sort_by_feet":true,"depth_sort_foot_y":front_foot/SIZE.y,"garden_bridge_source_region":source_region})''')
change('''		scene.set_meta("ap_garden_scenic_water",{"polygon":waters[0].duplicate(),"texture":NATIVE_ROOT+id+"/deepwater.res","rgba_sha256":"dc4ba07d16eb32cccc44ee72215e1f2904b5a1998c0163f80c7c5be78c37f63e","texture_size":Vector2i(200,280),"uniform_texture_scale":1.0,"z_index":-18,"scenic_bridge_no_support":true})''',
 '''		scene.set_meta("ap_garden_river25h",{"polygon":waters[0].duplicate(),"physics_pieces":water_pieces.duplicate(true),"deck":deck,"texture":"res://data/maps/luoyang_full_city_20261022ap/quarters/revision4/luoyang_riverside_garden_20261022ap/deepwater.res","rgba_sha256":"dc4ba07d16eb32cccc44ee72215e1f2904b5a1998c0163f80c7c5be78c37f63e","texture_size":Vector2i(200,280),"uniform_texture_scale":1.0,"z_index":-18,"front_region":source_region,"front_texture":NATIVE_ROOT+"front_rail.res","front_source":author.assets.stone_bridge.texture,"bridge_center":bridge_center,"bridge_scale":uniform,"whole_bridge_below_actors":true,"physics_is_visual_water_minus_visible_deck":true})''')
change('''"exact_natural_depth_overlaps":overlaps,"adult_doors":adult.doors}''',
 '''"exact_natural_depth_overlaps":overlaps,"adult_doors":adult.doors,"bridge_deck":deck,"water_visual_polygon":waters[0].duplicate(),"water_physics_pieces":water_pieces.duplicate(true)}''')

after=text.encode()
reverse=text
for h in reversed(hunks):
 assert reverse.count(h['new'])==1
 reverse=reverse.replace(h['new'],h['old'])
assert reverse.encode()==raw
compiler=create('garden_river_compiler_NOTREADY.gd',after)

author=json.loads((HERE/'author_river_bridge_NOTREADY.json').read_bytes())
before=copy.deepcopy(author)
# Full original A1 includes low-alpha historical dust. Permit only these precise
# depth-layer image overlaps; compiler still rejects every true-body overlap.
author['scenes'][0]['visual_depth_overlap_pairs']=[
 ['ap_river_pavilion','garden_stone_bridge_walkable_25h'],
 ['ap_garden_tree_west','garden_stone_bridge_walkable_25h']]
author['bridge_contract']['front_region_native_texture']=RES+'publication01/output/native/front_rail.res'
author['bridge_contract']['front_region_contract']='Native AtlasTexture referencing unchanged complete bridge, regionRect[200,522,1374,208], same original-canvas transform; full base bridge remains below actors. Foreground uses existing Field actor alpha/depth pipeline.'
doc=dump('author_river_bridge02_NOTREADY.json',author)
check=copy.deepcopy(author)
check['scenes'][0]['visual_depth_overlap_pairs']=before['scenes'][0]['visual_depth_overlap_pairs']
check['bridge_contract'].pop('front_region_native_texture')
check['bridge_contract'].pop('front_region_contract')
assert check==before
proof=dump('compiler_exact_hunks_and_author02_inverse_NOT_RUNTIME.json',{
 'status':'GARDEN_COMPILER_SOURCE_ONLY_WHOLEBYTE_INVERSE_PASS_NOT_PARSED_OR_RUN',
 'parent_compiler':{'path':'res://'+str(PARENT.relative_to(GAME)).replace('\\','/'),'sha256':sha(raw),'bytes':len(raw)},
 'compiler':compiler,'author':doc,'hunks':hunks,'whole_byte_inverse':True,
 'author02_inverse':{'whole_typed_inverse':True,'only_two_declared_alpha_overlap_pairs_and_front_Atlas_contract':True},
 'engine':0,'canonical_writes':0})
print(json.dumps({'compiler':compiler,'author':doc,'proof':proof}))
