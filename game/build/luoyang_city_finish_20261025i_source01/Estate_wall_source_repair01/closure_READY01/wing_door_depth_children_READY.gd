extends RefCounted
## One source-bound child of the existing facade. Not another SceneObject/depth/body.
const READY: bool=true
const SELF: String="res://build/luoyang_city_finish_20261025i_source01/Estate_wall_source_repair01/closure_READY01/wing_door_depth_children_READY.gd"
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
		var result: Dictionary={SELF:true,META:true,ATLAS:true,SHELL:true,"res://art/modules/luoyang_assembled_interiors_20261016g/shell_residential_v1.png.import":true,"res://.godot/imported/shell_residential_v1.png-48ef764e649ed02b6d198116074ff76b.ctex":true}
		result.merge(_monk_paths())
		return result
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
	var world_foot: Variant=entry.get("world_foot_px")
	if not world_foot is Array or world_foot.size()!=2: return false
	for coordinate: Variant in world_foot:
		if typeof(coordinate) not in [TYPE_INT,TYPE_FLOAT] or not is_finite(float(coordinate)): return false
	if world_foot[0]!=650.0 or world_foot[1]!=1710.0: return false
	if matches!=1 or entry.get("texture")!=WING or entry.get("render_size_px")!=Vector2(2202,1289)*.44 or entry.get("pos")!=(Vector2(650,1710)+(Vector2(1101,644.5)-Vector2(893,1068))*.44)/Vector2(3072,2048) or entry.get("depth_sort_foot_y")!=1710.0/2048.0 or entry.get("sort_by_feet")!=true: return false
	if parent.get_parent()!=field.get("_actor_layer") or not field.get("_scene_object_nodes").has(parent) or parent.name!=StringName("SceneObject_"+ID) or parent.get_node_or_null(NodePath(CHILD))!=null or parent.texture!=load(WING) or parent.texture.get_size()!=Vector2(2202,1289) or not parent.centered or parent.flip_h or parent.flip_v or parent.region_enabled or parent.rotation!=0 or parent.scale!=Vector2(entry.render_size_px.x/2202.0,entry.render_size_px.y/1289.0) or parent.position!=entry.pos*Vector2(3072,2048): return false
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

# Display-only successor of the two original Task rows. False until Root/ART
# frozen media are available. No NPCNode, Scene, task row, body or scale writes.
const MONK_VISUAL_READY: bool=true
const ELDER_PAIR_ADOPTED: bool=false
# Filled only from ART's actual native-format proof, not raw A1/noise bounds.
const ELDER_NATIVE_A1_RECT: Rect2i=Rect2i()
const TEMPLE_ID: StringName=&"ch4_s4_ancient_temple"
const MONK_TASK: String="res://scripts/city/luoyang_layout_quest_20261018t.gd"
const MONK_OLD: String="res://art/characters/luoyang_layout_quest_20261018t/npc_temple_gate_monk_idle_down_1f_v1.png"
const MONK_SCALE: float=0.9459459459459459
const MONK_IDS: Array[String]=["temple_cave_keeper_20261018t","temple_bell_keeper_20261018t"]
# Empty values are an explicit NOTREADY data contract, never observed hash pins.
# Root may adopt only bell portrait while the entire elder pair remains old.
const MONK_MEDIA: Dictionary={
	"elder_sprite":{"path":"","sha256":"","import_path":"","import_sha256":"","ctex_path":"","ctex_sha256":""},
	"elder_portrait":{"path":"","sha256":"","import_path":"","import_sha256":"","ctex_path":"","ctex_sha256":""},
	"bell_portrait":{"path":"res://art/characters/portraits/luoyang_city_finish_20261025i/bell_keeper_middleaged_portrait_v1.png","sha256":"db102e07a46e1115b78358636aeb1bf135f78bbc501a89c18124a5aa7d6a9108","import_path":"res://art/characters/portraits/luoyang_city_finish_20261025i/bell_keeper_middleaged_portrait_v1.png.import","import_sha256":"566f5cdd4768d694f9e571285b75d15754bd9179de685a284b9446be47c2558b","ctex_path":"res://.godot/imported/bell_keeper_middleaged_portrait_v1.png-dfd804c7c980ca74f0d6add383a9d03f.ctex","ctex_sha256":"1ba3f20995a12381f8622aa193b7fc4d53761020c416e6b034fa92d134c7e5f0"}
}

static func _monk_paths() -> Dictionary:
	var result: Dictionary={}
	if not MONK_VISUAL_READY: return result
	for role: String in ["elder_portrait","bell_portrait","elder_sprite"]:
		if role.begins_with("elder_") and not ELDER_PAIR_ADOPTED: continue
		var media: Dictionary=MONK_MEDIA[role]
		for key: String in ["path","import_path","ctex_path"]:
			var path: String=String(media[key])
			if path.is_empty(): return {}
			result[path]=true
	return result

static func _monk_owner(field: Node) -> Dictionary:
	if not READY or not MONK_VISUAL_READY or not is_instance_valid(field) or field.get("_scene_rebuilding")!=true or field.get("_field_loading_failed")==true: return {}
	var scene: Variant=field.get("_current_scene")
	var lease: Variant=field.get("_finish25i")
	var temple: Variant=field.get("_temple_session")
	if scene==null or scene.scene_id!=TEMPLE_ID or scene.resource_path!="res://data/scenes/luoyang_temple_layout_quest_20261018t/temple.tres" or scene.map_layout==null or lease==null or not temple is RefCounted or temple.get_script()!=load("res://scripts/city/luoyang_temple_assembly_20261016.gd") or not lease._owned(true,true): return {}
	var state: Dictionary=lease.get("_state")
	var owner: Dictionary=temple.state()
	var key: String="TEMPLE_ORIGINAL_INSTANCE:"+str(temple.get_instance_id())+":"+str(scene.get_instance_id())+":"+str(scene.map_layout.get_instance_id())
	if state.is_empty() or state.get("owner_kind")!="TEMPLE_OWN_FIELD_ORIGINAL" or state.get("token")==0 or state.get("token")!=temple.get_instance_id() or state.get("owner_key")!=key or state.get("binding_sha")!=lease.get_script().BIND_SHA or not state.get("field") is WeakRef or state.field.get_ref()!=field or not state.get("scene") is WeakRef or state.scene.get_ref()!=scene or not state.get("layout") is WeakRef or state.layout.get_ref()!=scene.map_layout or not state.get("temple_ref") is WeakRef or state.temple_ref.get_ref()!=temple: return {}
	if temple.get("_released")!=false or temple.get("_scene")!=scene or owner.get("released")!=false or owner.get("scene_instance")!=scene.get_instance_id() or owner.get("error")!="" or not owner.get("source_first") is Dictionary or owner.source_first.is_empty() or var_to_bytes(owner.source_first)!=var_to_bytes(state.get("first")): return {}
	var city: Variant=load("res://scripts/city/luoyang_enclosure_v11_candidate_contract.gd")
	if not city._equal_value(temple.get("_scene_storage"),city._transition_storage(scene)) or not city._equal_value(temple.get("_layout_storage"),city._transition_storage(scene.map_layout)) or var_to_bytes(state.get("parent_blockers"))!=var_to_bytes(scene.map_layout.blockers) or var_to_bytes(state.payload.get("parent_native_navigation"))!=var_to_bytes(scene.map_layout.visual_objects): return {}
	if field.get("_world_size")!=Vector2(1920,1280) or scene.npc_visual_scale!=1.0 or not scene.actor_positions_are_feet: return {}
	for path: String in [SELF,MONK_TASK,MONK_OLD]:
		if not state.first.get(path) is String or String(state.first[path]).length()!=64 or FileAccess.get_sha256(path)!=state.first[path]: return {}
	for role: String in ["elder_portrait","bell_portrait","elder_sprite"]:
		if role.begins_with("elder_") and not ELDER_PAIR_ADOPTED: continue
		var media: Dictionary=MONK_MEDIA[role]
		for pair: Array in [["path","sha256"],["import_path","import_sha256"],["ctex_path","ctex_sha256"]]:
			var path: String=String(media[pair[0]])
			var sha: String=String(media[pair[1]])
			if path.is_empty() or sha.length()!=64 or state.first.get(path)!=sha or FileAccess.get_sha256(path)!=sha: return {}
		var texture: Texture2D=load(String(media.path)) as Texture2D
		var expected_size: Vector2=Vector2(160,160) if role=="elder_sprite" else Vector2(1254,1254)
		if texture==null or texture.resource_path!=media.path or texture.get_size()!=expected_size: return {}
		if role=="elder_sprite":
			if ELDER_NATIVE_A1_RECT.size.x<=0 or ELDER_NATIVE_A1_RECT.size.y<=0 or not Rect2i(0,0,160,160).encloses(ELDER_NATIVE_A1_RECT): return {}
			var image: Image=texture.get_image()
			if image==null or image.is_empty() or image.get_used_rect()!=ELDER_NATIVE_A1_RECT: return {}
	return state

static func _monk_actor_protected(actor: NPCNode) -> Dictionary:
	return {"npc_id":actor.npc_id,"npc_name":actor.npc_name,"dialog_id":actor.dialog_id,"interaction_action":actor.interaction_action,"dialog_variants":actor.dialog_variants.duplicate(true),"walk_sprite_path":actor.walk_sprite_path,"conversation_sprite_paths":actor.conversation_sprite_paths.duplicate(true),"conversation_base_facing":actor.conversation_base_facing,"sprite_scale":actor.sprite_scale,"movement_mode":actor.movement_mode,"patrol_axis":actor.patrol_axis,"patrol_distance":actor.patrol_distance,"patrol_speed":actor.patrol_speed,"invert_patrol_facing":actor.invert_patrol_facing,"idle_frame_seconds":actor.idle_frame_seconds,"walk_frame_seconds":actor.walk_frame_seconds,"position":actor.position,"calibrate":actor._calibrate_adult_body,"ground_anchored":actor._ground_anchored}

static func project_actor(field: Node,row: Dictionary,actor: NPCNode) -> Dictionary:
	if not is_instance_valid(field) or not is_instance_valid(actor): return {"ok":false}
	var scene: Variant=field.get("_current_scene")
	if scene==null or scene.scene_id!=TEMPLE_ID or not String(row.get("npc_id","")) in MONK_IDS: return {"ok":true,"matched":false}
	var state: Dictionary=_monk_owner(field)
	if state.is_empty() or actor.is_inside_tree() or actor.get_parent()!=null or actor.get_script()!=load("res://scripts/field/npc_node.gd") or field.get("_actor_layer")==null: return {"ok":false}
	for previous: Variant in field.get("_npc_nodes"):
		if is_instance_valid(previous) and previous.npc_id==row.npc_id: return {"ok":false}
	var receipt: Dictionary=field.get("_city_tasks_receipt")
	if receipt.get("matched")!=true or receipt.get("source_scene_id")!=String(TEMPLE_ID) or receipt.get("original_scene_identity")!=scene.get_instance_id() or receipt.get("render_applied")!=true or not receipt.get("phase") is Dictionary: return {"ok":false}
	var phases: Dictionary=receipt.phase
	for kind: String in ["longmen","baima"]:
		if not phases.get(kind) is String or not String(phases[kind]) in ["not_started","evidence","completed","started","accepted_without_stage","failed","invalid"]: return {"ok":false}
	var task: Variant=load(MONK_TASK)
	var temple: Variant=field.get("_temple_session")
	var expected: Array=temple.get_script().successor_npcs().duplicate(true)
	if not task._project_monk(expected,MONK_IDS[0],"守窟僧",Vector2(936,900),task._npc_dialog("longmen",phases.longmen)) or not task._project_monk(expected,MONK_IDS[1],"守钟僧",Vector2(600,900),task._npc_dialog("baima",phases.baima)): return {"ok":false}
	var source: Dictionary={}
	for original: Dictionary in expected:
		if original.npc_id==row.npc_id: source=original
	if source.is_empty() or var_to_bytes(source)!=var_to_bytes(row): return {"ok":false}
	var expected_variants: Array[Dictionary]=[]
	expected_variants.assign(source.dialog_variants)
	if actor.npc_id!=source.npc_id or actor.npc_name!=source.npc_name or actor.dialog_id!=source.dialog_id or actor.interaction_action!=source.interaction_action or var_to_bytes(actor.dialog_variants)!=var_to_bytes(expected_variants) or actor.sprite_path!=MONK_OLD or actor.portrait_path!=MONK_OLD or actor.sprite_scale!=MONK_SCALE or actor._calibrate_adult_body or actor._ground_anchored or actor.position!=source.pos*Vector2(1920,1280) or actor.movement_mode!="idle" or actor.conversation_base_facing!="front" or not actor.walk_sprite_path.is_empty() or not actor.conversation_sprite_paths.is_empty(): return {"ok":false}
	# Elder portrait belongs only to the new elder body. While that pair is
	# unapproved, keep this whole actor unchanged, never pair it to MONK_OLD.
	if actor.npc_id==MONK_IDS[0] and not ELDER_PAIR_ADOPTED:
		return {"ok":true,"matched":false,"elder_pair_pending":true}
	var protected_before: PackedByteArray=var_to_bytes(_monk_actor_protected(actor))
	var row_before: PackedByteArray=var_to_bytes(row)
	var old_sprite: String=actor.sprite_path
	var old_portrait: String=actor.portrait_path
	var portrait: String=String(MONK_MEDIA.elder_portrait.path) if actor.npc_id==MONK_IDS[0] else String(MONK_MEDIA.bell_portrait.path)
	if actor.npc_id==MONK_IDS[0] and ELDER_PAIR_ADOPTED: actor.sprite_path=String(MONK_MEDIA.elder_sprite.path)
	actor.portrait_path=portrait
	if var_to_bytes(_monk_actor_protected(actor))!=protected_before or var_to_bytes(row)!=row_before or not field.get("_finish25i")._owned(true,true):
		actor.sprite_path=old_sprite;actor.portrait_path=old_portrait
		return {"ok":false}
	return {"ok":true,"matched":true,"display_only":true,"elder_pair_adopted":ELDER_PAIR_ADOPTED,"task_phase":phases.duplicate(true)}
