extends RefCounted
## One source-bound child of the existing facade. Not another SceneObject/depth/body.
const READY: bool=false
const SELF: String="res://build/luoyang_city_finish_20261025i_system01/wing_door_children02_NOTREADY/wing_door_depth_children_CANDIDATE.gd"
const ID: String="finish_i_estate_family_ancestral_wing"
const SCENE: StringName=&"luoyang_estate_riverside_20261021ai"
const META: String="res://build/luoyang_estate_courtyard_20261021ak_system01/receipts/wing.meta.json"
const ATLAS: String="res://build/luoyang_estate_courtyard_20261021al_system01/textures/wing_door_depth.tres"
const SHELL: String="res://art/modules/luoyang_assembled_interiors_20261016g/shell_residential_v1.png"
const WING: String="res://art/modules/luoyang_estate_components_20261021am/wing.png"
const CHILD: StringName=&"EstateSourceBoundWingDoorDepth"
const PINS: Dictionary={META:"ea6709f5e4a7c93ccb0feb1c54d41fd50ed0a38292f358aaf4c97fc250bf2fd3",ATLAS:"61c70b6f98c4c399ae4356ccba9151d2621b6833a8c71ed1b2cf8a79e1ee4efd",SHELL:"88189e4971ece89443557c76f7762f28fe9c1740e780bfa9ebdeadfa8c034494",WING:"7e1783a9ea26ad9aa4a09c0cf5e0bf966645ee81cbe3ab6ef5d7e9a4880fee75"}

static func source_paths_for(id: StringName) -> Dictionary:
	if not READY: return {}
	if id==SCENE: return {SELF:true,META:true}
	if id==&"ch4_s4_ancient_temple":
		return {SELF:true,META:true,ATLAS:true,SHELL:true,"res://art/modules/luoyang_assembled_interiors_20261016g/shell_residential_v1.png.import":true,"res://.godot/imported/shell_residential_v1.png-48ef764e649ed02b6d198116074ff76b.ctex":true}
	return {}

static func install(field: Node,entry: Dictionary,parent: Sprite2D) -> bool:
	if is_instance_valid(field) and field.get("_current_scene")!=null and field.get("_current_scene").scene_id==&"ch4_s4_ancient_temple": return _install_temple(field,entry,parent)
	if not READY or not is_instance_valid(field) or not is_instance_valid(parent): return false
	var scene: Variant=field.get("_current_scene")
	var lease: Variant=field.get("_finish25i")
	var world: Node2D=field.get("world_container") as Node2D
	if scene==null or scene.scene_id!=SCENE or lease==null or world==null or entry.get("id")!=ID: return false
	var family: Variant=load("res://scripts/city/luoyang_estate_family_20261021am.gd")
	if not field.call("_finish25i_family_visual_setup_matches",family,"ESTATE_ORIGINAL"): return false
	var state: Dictionary=lease.get("_state")
	if field.get("_world_size")!=Vector2(3072,2048) or not state.first.has(SELF) or FileAccess.get_sha256(SELF)!=state.first[SELF]: return false
	for path: String in PINS:
		if state.first.get(path)!=PINS[path] or FileAccess.get_sha256(path)!=PINS[path]: return false
	var matches: int=0
	for row: Dictionary in state.payload.visual_additions:
		if row.get("id")==ID:
			matches+=1
			if var_to_bytes(row)!=var_to_bytes(entry): return false
	if matches!=1: return false
	matches=0
	for row: Dictionary in state.payload.effective_navigation:
		if row.get("id")==ID:
			matches+=1
			if var_to_bytes(row)!=var_to_bytes(entry): return false
	if matches!=1 or entry.get("texture")!=WING or entry.get("world_foot_px")!=Vector2(650,1710) or entry.get("render_size_px")!=Vector2(2202,1289)*.44 or entry.get("pos")!=(Vector2(650,1710)+(Vector2(1101,644.5)-Vector2(893,1068))*.44)/Vector2(3072,2048) or entry.get("depth_sort_foot_y")!=1710.0/2048.0 or entry.get("sort_by_feet")!=true: return false
	if parent.get_parent()!=field.get("_actor_layer") or not field.get("_scene_object_nodes").has(parent) or parent.name!=StringName("SceneObject_"+ID) or parent.get_node_or_null(NodePath(CHILD))!=null or parent.texture!=load(WING) or parent.texture.get_size()!=Vector2(2202,1289) or not parent.centered or parent.flip_h or parent.flip_v or parent.region_enabled or parent.rotation!=0 or parent.scale!=Vector2.ONE*.44 or parent.position!=entry.pos*Vector2(3072,2048): return false
	var raw: Variant=JSON.parse_string(FileAccess.get_file_as_string(META))
	if not raw is Dictionary or not raw.get("output_annotations") is Dictionary: return false
	var annotation: Dictionary=raw.output_annotations
	if not annotation.get("door_clear_rect_px") is Array or annotation.door_clear_rect_px.size()!=4 or not annotation.get("ground_anchor_px") is Array or annotation.ground_anchor_px.size()!=2: return false
	var a: Array=annotation.door_clear_rect_px
	var door: Rect2=Rect2(float(a[0]),float(a[1]),float(a[2]),float(a[3]))
	if door!=Rect2(772,631,242,363) or Vector2(float(annotation.ground_anchor_px[0]),float(annotation.ground_anchor_px[1]))!=Vector2(893,1068): return false
	var grown: Rect2=door.grow(3)
	var texture: AtlasTexture=load(ATLAS) as AtlasTexture
	if texture==null or texture.resource_path!=ATLAS or texture.atlas!=load(SHELL) or texture.region!=Rect2(432,208,248,369) or texture.margin!=Rect2() or not texture.filter_clip or texture.get_size()!=grown.size: return false
	# Allocate only after all schema/source/object gates. Child lifetime, transform,
	# relative depth and parent modulation follow the unchanged original facade.
	var child: Sprite2D=Sprite2D.new()
	child.name=CHILD;child.texture=texture;child.centered=true
	child.position=grown.get_center()-Vector2(2202,1289)*.5
	child.scale=Vector2.ONE;child.z_index=-1;child.z_as_relative=true
	child.texture_filter=CanvasItem.TEXTURE_FILTER_LINEAR
	child.modulate=Color(.46,.42,.38,1);child.use_parent_material=true
	child.set_meta("source_bound_parent_row_id",ID)
	child.set_meta("source_bound_door_depth",{"parent_instance":str(parent.get_instance_id()),"scene_instance":str(scene.get_instance_id()),"owner_key":state.owner_key,"original_token":str(state.token),"binding_sha":state.binding_sha,"atlas_sha":PINS[ATLAS],"wing_meta_sha":PINS[META],"local_center":Vector2(-208,168),"new_SceneObject_body_or_portal":false})
	parent.add_child(child)
	if child.get_parent()!=parent or child.position!=Vector2(-208,168) or not lease._owned(true,true):
		child.free();return false
	return true

# Exact two original wing PNGs in Temple. Estate install() guards above remain
# byte-for-byte unchanged; Temple does not borrow an Estate Family receipt.
static func _install_temple(field: Node,entry: Dictionary,parent: Sprite2D) -> bool:
	if not READY or not is_instance_valid(field) or not is_instance_valid(parent) or field.get("_scene_rebuilding")!=true or field.get("_field_loading_failed")==true: return false
	var scene: Variant=field.get("_current_scene")
	var lease: Variant=field.get("_finish25i")
	var temple: Variant=field.get("_temple_session")
	if scene==null or scene.scene_id!=&"ch4_s4_ancient_temple" or scene.resource_path!="res://data/scenes/luoyang_temple_layout_quest_20261018t/temple.tres" or scene.map_layout==null or scene.map_layout.design_size!=Vector2i(1536,1024) or lease==null or not temple is RefCounted or temple.get_script()!=load("res://scripts/city/luoyang_temple_assembly_20261016.gd") or not lease._owned(true,true): return false
	var state: Dictionary=lease.get("_state")
	var owner: Dictionary=temple.state()
	var key: String="TEMPLE_ORIGINAL_INSTANCE:"+str(temple.get_instance_id())+":"+str(scene.get_instance_id())+":"+str(scene.map_layout.get_instance_id())
	if state.is_empty() or state.get("owner_kind")!="TEMPLE_OWN_FIELD_ORIGINAL" or state.get("token")==0 or state.get("token")!=temple.get_instance_id() or state.get("owner_key")!=key or state.get("binding_sha")!=lease.get_script().BIND_SHA or not state.get("field") is WeakRef or state.field.get_ref()!=field or not state.get("scene") is WeakRef or state.scene.get_ref()!=scene or not state.get("layout") is WeakRef or state.layout.get_ref()!=scene.map_layout or not state.get("temple_ref") is WeakRef or state.temple_ref.get_ref()!=temple: return false
	if temple.get("_released")!=false or temple.get("_scene")!=scene or owner.get("released")!=false or owner.get("scene_instance")!=scene.get_instance_id() or owner.get("error")!="" or not owner.get("source_first") is Dictionary or owner.source_first.is_empty() or var_to_bytes(owner.source_first)!=var_to_bytes(state.get("first")): return false
	var city: Variant=load("res://scripts/city/luoyang_enclosure_v11_candidate_contract.gd")
	if not city._equal_value(temple.get("_scene_storage"),city._transition_storage(scene)) or not city._equal_value(temple.get("_layout_storage"),city._transition_storage(scene.map_layout)) or var_to_bytes(state.get("parent_blockers"))!=var_to_bytes(scene.map_layout.blockers) or var_to_bytes(state.payload.get("parent_native_navigation"))!=var_to_bytes(scene.map_layout.visual_objects): return false
	if field.get("_world_size")!=Vector2(1920,1280) or not state.first.has(SELF) or FileAccess.get_sha256(SELF)!=state.first[SELF]: return false
	for path: String in PINS:
		if state.first.get(path)!=PINS[path] or FileAccess.get_sha256(path)!=PINS[path]: return false
	if state.first.get("res://art/modules/luoyang_assembled_interiors_20261016g/shell_residential_v1.png.import")!="56e7ee073ab3024a1c61e2df2e235f5095486cbddb33f1253a9545d4de226324" or state.first.get("res://.godot/imported/shell_residential_v1.png-48ef764e649ed02b6d198116074ff76b.ctex")!="336357ca36ced0b1a85313e59307ae4c8121edf5f8507266d435307509425541": return false
	var id: String=String(entry.get("id",""))
	var foot: Vector2=Vector2(360,884) if id=="finish_i_temple_west_monks_house" else (Vector2(1050,884) if id=="finish_i_temple_east_sutra_house" else Vector2.INF)
	if not foot.is_finite(): return false
	# Preserve the actual source -> UV -> world f32 stages, not an assumed .4125.
	var expected: Dictionary={"id":id,"texture":WING,"centered":false,"pos":(foot-Vector2(893,1068)*.33)/Vector2(1536,1024),"render_size_px":(Vector2(2202,1289)*.33)*1.25,"sort_by_feet":true,"depth_sort_foot_y":884.0/1024.0}
	if var_to_bytes(entry)!=var_to_bytes(expected): return false
	var found: int=0
	for row: Dictionary in state.payload.visual_additions:
		if row.get("id")==id:
			found+=1
			if var_to_bytes(row)!=var_to_bytes(expected): return false
	if found!=1: return false
	found=0
	for row: Dictionary in state.payload.effective_navigation:
		if row.get("id")==id:
			found+=1
			if var_to_bytes(row)!=var_to_bytes(expected): return false
	if found!=1 or parent.get_parent()!=field.get("_actor_layer") or not field.get("_scene_object_nodes").has(parent) or parent.name!=StringName("SceneObject_"+id) or parent.get_node_or_null(NodePath(CHILD))!=null or parent.texture!=load(WING) or parent.texture.get_size()!=Vector2(2202,1289) or parent.centered or parent.flip_h or parent.flip_v or parent.region_enabled or parent.rotation!=0 or parent.scale!=expected.render_size_px/Vector2(2202,1289) or parent.position!=expected.pos*Vector2(1920,1280): return false
	var raw: Variant=JSON.parse_string(FileAccess.get_file_as_string(META))
	if not raw is Dictionary or not raw.get("output_annotations") is Dictionary: return false
	var annotation: Dictionary=raw.output_annotations
	if not annotation.get("door_clear_rect_px") is Array or annotation.door_clear_rect_px.size()!=4 or not annotation.get("ground_anchor_px") is Array or annotation.ground_anchor_px.size()!=2: return false
	var a: Array=annotation.door_clear_rect_px
	var door: Rect2=Rect2(float(a[0]),float(a[1]),float(a[2]),float(a[3]))
	if door!=Rect2(772,631,242,363) or Vector2(float(annotation.ground_anchor_px[0]),float(annotation.ground_anchor_px[1]))!=Vector2(893,1068): return false
	var grown: Rect2=door.grow(3)
	var texture: AtlasTexture=load(ATLAS) as AtlasTexture
	if texture==null or texture.resource_path!=ATLAS or texture.atlas!=load(SHELL) or texture.region!=Rect2(432,208,248,369) or texture.margin!=Rect2() or not texture.filter_clip or texture.get_size()!=grown.size: return false
	var child: Sprite2D=Sprite2D.new()
	child.name=CHILD;child.texture=texture;child.centered=true
	child.position=grown.get_center() # Actual Temple parent.centered=false.
	child.scale=Vector2.ONE;child.z_index=-1;child.z_as_relative=true
	child.texture_filter=CanvasItem.TEXTURE_FILTER_LINEAR
	child.modulate=Color(.46,.42,.38,1);child.use_parent_material=true
	child.set_meta("source_bound_parent_row_id",id)
	child.set_meta("source_bound_door_depth",{"parent_instance":str(parent.get_instance_id()),"scene_instance":str(scene.get_instance_id()),"owner_key":key,"original_token":str(temple.get_instance_id()),"binding_sha":state.binding_sha,"atlas_sha":PINS[ATLAS],"wing_meta_sha":PINS[META],"local_center":Vector2(893,812.5),"new_SceneObject_body_or_portal":false,"cold_FIRST_not_assumed_FINAL":true})
	parent.add_child(child)
	if child.get_parent()!=parent or child.position!=Vector2(893,812.5) or not lease._owned(true,true):
		child.free();return false
	return true
