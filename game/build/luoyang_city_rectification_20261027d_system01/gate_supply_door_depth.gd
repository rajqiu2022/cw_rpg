extends RefCounted
## Exact existing Gate facade child; not a new object, portal or body.
const SELF="res://build/luoyang_city_rectification_20261027d_system01/gate_supply_door_depth.gd"
const ID="finish_i_gate_east_supply"
const SCENE=&"ch4_s0_luoyang_gate"
const SPEC="res://build/luoyang_city_rectification_20261027d_system01/two_building_rear_volumes_PROPOSAL.json"
const SPEC_SHA="d5643d06fe4bf208451c87289e3be2a041aab755dcae625642345c37354b8c99"
const WING="res://art/modules/luoyang_estate_components_20261021am/wing.png"
const ATLAS="res://build/luoyang_estate_courtyard_20261021al_system01/textures/wing_door_depth.tres"
const SHELL="res://art/modules/luoyang_assembled_interiors_20261016g/shell_residential_v1.png"
const META="res://build/luoyang_estate_courtyard_20261021ak_system01/receipts/wing.meta.json"
const PINS={WING:"7e1783a9ea26ad9aa4a09c0cf5e0bf966645ee81cbe3ab6ef5d7e9a4880fee75",ATLAS:"61c70b6f98c4c399ae4356ccba9151d2621b6833a8c71ed1b2cf8a79e1ee4efd",SHELL:"88189e4971ece89443557c76f7762f28fe9c1740e780bfa9ebdeadfa8c034494",SHELL+".import":"56e7ee073ab3024a1c61e2df2e235f5095486cbddb33f1253a9545d4de226324","res://.godot/imported/shell_residential_v1.png-48ef764e649ed02b6d198116074ff76b.ctex":"336357ca36ced0b1a85313e59307ae4c8121edf5f8507266d435307509425541",META:"ea6709f5e4a7c93ccb0feb1c54d41fd50ed0a38292f358aaf4c97fc250bf2fd3"}
static func source_paths_for(id: StringName) -> Dictionary:
	if id!=SCENE: return {}
	var out: Dictionary={SELF:true,SPEC:true}
	for path: String in PINS: out[path]=true
	return out
static func rear() -> PackedVector2Array:
	var out:=PackedVector2Array()
	for point: Vector2 in [Vector2(442,800),Vector2(1755,800),Vector2(1755,958),Vector2(442,958)]: out.append(Vector2(2380,1300)+(point-Vector2(893,1068))*.41)
	return out
static func install(field: Node,entry: Dictionary,parent: Sprite2D) -> bool:
	if not is_instance_valid(field) or not is_instance_valid(parent) or field.get_script().resource_path!="res://scripts/field/field_walkable_controller.gd" or field.get("_scene_rebuilding")!=true or field.get("_field_loading_failed")==true: return false
	var scene: SceneScript=field.get("_current_scene") as SceneScript
	var lease: RefCounted=field.get("_finish25i")
	if scene==null or scene.scene_id!=SCENE or scene.map_layout==null or lease==null or not lease._owned(true,true) or field.get("_world_size")!=Vector2(3072,2048): return false
	var state: Dictionary=lease.get("_state")
	var key: String="C_ORIGINAL:"+String(SCENE)+":"+str(int(state.get("token",0)))+":"+str(scene.get_instance_id())+":"+str(scene.map_layout.get_instance_id())
	if state.get("owner_kind")!="C_COMPLETE_ORIGINAL" or int(state.get("token",0))<=0 or state.get("owner_key")!=key or state.get("binding_sha")!=lease.get_script().BIND_SHA or state.get("released")!=false: return false
	for pair: Array in [["field",field],["scene",scene],["layout",scene.map_layout]]:
		if not state.get(pair[0]) is WeakRef or state[pair[0]].get_ref()!=pair[1]: return false
	if not state.get("first") is Dictionary or state.first.get(SPEC)!=SPEC_SHA or state.first.get(SELF)!=FileAccess.get_sha256(SELF) or FileAccess.get_sha256(SPEC)!=SPEC_SHA: return false
	for path: String in PINS:
		if state.first.get(path)!=PINS[path] or FileAccess.get_sha256(path)!=PINS[path]: return false
	if entry.get("id")!=ID or entry.get("texture")!=WING or entry.get("render_size_px")!=Vector2(2202,1289)*.41 or entry.get("pos")!=(Vector2(2380,1300)+(Vector2(1101,644.5)-Vector2(893,1068))*.41)/Vector2(3072,2048) or entry.get("sort_by_feet")!=true or entry.get("depth_sort_foot_y")!=1300.0/2048.0 or entry.get("blocking")!=true: return false
	var foot: Variant=entry.get("world_foot_px")
	if not foot is Array or foot.size()!=2: return false
	for coordinate: Variant in foot:
		if typeof(coordinate) not in [TYPE_INT,TYPE_FLOAT] or not is_finite(float(coordinate)): return false
	if float(foot[0])!=2380.0 or float(foot[1])!=1300.0: return false
	var polys: Variant=entry.get("city_v3_solid_polygons_px")
	if not polys is Array or polys.size()!=3 or var_to_bytes(polys[2])!=var_to_bytes(rear()): return false
	for collection: Array in [state.payload.effective_navigation,state.payload.visual_additions]:
		var count: int=0
		for row: Dictionary in collection:
			if row.get("id")!=ID: continue
			count+=1
			if var_to_bytes(row)!=var_to_bytes(entry): return false
		if count!=1: return false
	if parent.get_parent()!=field.get("_actor_layer") or not field.get("_scene_object_nodes").has(parent) or parent.name!=StringName("SceneObject_"+ID) or parent.get_node_or_null("GateSupplySourceBoundDoorDepth")!=null or parent.texture!=load(WING) or parent.texture.get_size()!=Vector2(2202,1289) or not parent.centered or parent.flip_h or parent.flip_v or parent.region_enabled or parent.rotation!=0 or parent.scale!=entry.render_size_px/Vector2(2202,1289) or parent.position!=entry.pos*Vector2(3072,2048): return false
	var raw: Variant=JSON.parse_string(FileAccess.get_file_as_string(META))
	if not raw is Dictionary or not raw.get("output_annotations") is Dictionary or raw.output_annotations.get("door_clear_rect_px")!=[772.0,631.0,242.0,363.0] or raw.output_annotations.get("ground_anchor_px")!=[893.0,1068.0]: return false
	var texture: AtlasTexture=load(ATLAS) as AtlasTexture
	if texture==null or texture.resource_path!=ATLAS or texture.atlas!=load(SHELL) or texture.region!=Rect2(432,208,248,369) or texture.margin!=Rect2() or not texture.filter_clip or texture.get_size()!=Vector2(248,369): return false
	var child:=Sprite2D.new();child.name="GateSupplySourceBoundDoorDepth";child.texture=texture;child.centered=true
	child.position=Vector2(-208,168);child.scale=Vector2.ONE;child.z_index=-1;child.z_as_relative=true
	child.texture_filter=CanvasItem.TEXTURE_FILTER_LINEAR;child.modulate=Color(.46,.42,.38,1);child.use_parent_material=true
	child.set_meta("source_bound_parent_row_id",ID)
	child.set_meta("source_bound_door_depth",{"scene_instance":str(scene.get_instance_id()),"parent_instance":str(parent.get_instance_id()),"owner_key":key,"token":str(state.token),"binding_sha":state.binding_sha,"new_body_or_portal":false})
	parent.add_child(child)
	if child.get_parent()!=parent or child.position!=Vector2(-208,168) or not lease._owned(true,true): child.free();return false
	return true
