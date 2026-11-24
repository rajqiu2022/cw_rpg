extends "res://tests/test_luoyang_city_life_gpu_key_retry2_20261016f.gd"
## One actual default Docks birth. No cold C.prepare oracle, four-district loop or room trip.
const M=preload("res://scripts/city/luoyang_docks_office_roles_20261016h.gd")
const H=preload("res://scripts/city/luoyang_harbour_life_runtime_20261016.gd")
const OFFICE_CPU="res://build/luoyang_docks_office_roles_cpu_20261016h/103104_1655/result.json"
const OFFICE_CPU_SHA="ae03627078d1726e63958052ffdeccf3fbaf54fe10d54d0c1e1cf599223a336d"
const FIXED={
	"res://scripts/city/luoyang_docks_office_roles_20261016h.gd":"0ae49505fbe837da8a06e35add9e857532d03ee70c9c9260ffa6f9a0c9e31117",
	"res://data/maps/luoyang_docks_office_20261016h/author.json":"dc8d7ae836735f349360ca0bd69cc0290ebc6461470e7bd3af359ded568ec9e7",
	"res://scripts/city/luoyang_harbour_life_runtime_20261016.gd":"1e1e52210dbe7d5e1158ca9521835eb5f9f4d0e59b8f049141e8143e9b371cae",
	"res://scripts/city/luoyang_harbour_life_crowd_retry3_20261016.gd":"1aaea6ca19ab8abb1f164b155f24ac8a11ca43e7e4d73b1fa4fd899937b5e83b",
	"res://scripts/city/luoyang_enclosure_v11_candidate_contract.gd":"82df07a7411aa10327485db7c9e7d90df7770defb4b677907a9bc0a57c62d1d1",
	"res://scripts/field/field_walkable_controller.gd":"638cd8f0a37aacff56d074383d868f2d00bab3b81fcf56bf4d148fb84f556839",
	"res://scripts/autoload/scene_router.gd":"1082a842eb283a7eba339f9589bbcb0a5803d934c79f60d9e7a7f0413069bd92",
	"res://scripts/autoload/loading_manager.gd":"5550a037e8001069713b0af317a6db2cd2ac427189f8f75d2e87e755ece210db",
	"res://scripts/city/luoyang_resident_field_20261016.gd":"20086323c7aca3bb3efe51b77cdad393ec5e4ccdacdf98856eaca4beccd22624",
	"res://scripts/city/luoyang_district_life_20261016f.gd":"2cbea52cd129e49eabfc74983f5172a671bf1f7521cd7f5c639f864ef451a3f5",
	"res://scripts/field/npc_node.gd":"67c0f3deafef65445918b5815f4acdcb4cc577206248f20cd67a998930d00bea",
	"res://scenes/npc_node.tscn":"fd497082cbb1c7e2028cb6063074aeb066f81d4c8505d35f5428bb0607ca4191",
	"res://tests/test_luoyang_city_life_gpu_key_retry2_20261016f.gd":"e8254a46de3e82475b13b8f7fd431e2f57e6dd9b4f753a2951f01df75c84b41c",
	"res://tests/test_luoyang_city_life_cpu_key_retry2_20261016f.gd":"00ed4cd77ede1a470470726bcba60c2b5fe3099c11218e74d1b708ec3b9cef93",
	"res://tests/test_luoyang_city_life_cpu_draft_20261016f.gd":"a8d112574bf860fb595c78e34524abba1693cbeb6d65f43c23be50e667ef8895",
	"res://tests/helpers/city_life_independent_oracle_retry2_20261016f.gd":"8b5394da7751f330c7240909cfd7d4660f4aae16ada5db3098179c2ce3b8fcc2",
	"res://tests/helpers/temple_assembly_raw_oracle_20261016.gd":"d66cdad0a2f1cfd172f7ffc083f142e22723ae181f2b1ca0451389d801a506ae",
	"res://tests/helpers/v15_input_driver.gd":"a3c59fde8d9f55d71919276286dc720e177ef3dc046d224204868a24881de5d7"
}
var office_author: Dictionary={}
func precheck() -> bool:
	if not check(not M.FORMAL_ENABLED and M.FLAG in OS.get_cmdline_user_args(),"Explicit h candidate only, not g/warm/eleven rooms"): return false
	for path: String in FIXED:
		if not track(path,FIXED[path]): return false
	if not track(OFFICE_CPU,OFFICE_CPU_SHA): return false
	var cpu: Dictionary=JSON.parse_string(FileAccess.get_file_as_string(OFFICE_CPU))
	if not check(cpu.complete and cpu.failures==0,"Actual independent three-texture/fullstorage/two-role CPU evidence"): return false
	office_author=M.author()
	for path: String in office_author.source_sha256:
		if not track(path,office_author.source_sha256[path]): return false
	if not track(R.BIND_PATH,FINAL_BIND_SHA): return false
	package=R.binding();author=R.author(package)
	if not check(R.cpu_proof_valid(package,author),"Existing district CPU proof reused, no live-route re-audit"): return false
	for path: String in R.source_paths():
		if not source_before.has(path) and not track(path,FileAccess.get_sha256(path)): return false
	return track(get_script().resource_path,FileAccess.get_sha256(get_script().resource_path))
func _failed_visual_leaves(a: Variant,b: Variant,path: Array,out: Array[Dictionary]) -> void:
	if out.size()>=64: return
	if a is Dictionary and b is Dictionary:
		for key: Variant in a:
			if b.has(key): _failed_visual_leaves(a[key],b[key],path+[key],out)
			else: out.append({"path":path+[key],"missing_persisted":true})
		for key: Variant in b:
			if not a.has(key): out.append({"path":path+[key],"missing_actual":true})
		return
	if a is Array and b is Array:
		if a.size()!=b.size(): out.append({"path":path,"actual_size":a.size(),"persisted_size":b.size()});return
		for index: int in a.size(): _failed_visual_leaves(a[index],b[index],path+[index],out)
		return
	if typeof(a)==typeof(b) and a==b: return
	var row: Dictionary={"path":path,"actual_type":typeof(a),"persisted_type":typeof(b),"actual_value":str(a),"persisted_value":str(b),"actual_variant_bytes":var_to_bytes(a).hex_encode(),"persisted_variant_bytes":var_to_bytes(b).hex_encode()}
	if a is float and b is float:
		row.actual_f32=PackedFloat32Array([a]).to_byte_array().hex_encode();row.persisted_f32=PackedFloat32Array([b]).to_byte_array().hex_encode()
		row.finite_float32_equal=is_finite(a) and is_finite(b) and is_finite(PackedFloat32Array([a])[0]) and is_finite(PackedFloat32Array([b])[0]) and row.actual_f32==row.persisted_f32
	out.append(row)
func _same_visual_path(a: Variant,b: Variant,path: Array,label: String) -> bool:
	var equal: bool=C.equal_visual_serialized_value(a,b,path)
	if not equal:
		var leaves: Array[Dictionary]=[];_failed_visual_leaves(a,b,path,leaves)
		records.append({"kind":"ACTUAL_FAILED_VISUAL_STORAGE_LEAVES","label":label,"path":path,"differences":leaves})
	return equal
func _office_actual() -> bool:
	var proof: Dictionary=C.resident_receipt(scene)
	var required: Dictionary=office_author.source_sha256.duplicate(true)
	required[M.SELF]=FIXED[M.SELF];required[M.AUTHOR_PATH]=M.AUTHOR_SHA
	if not check(proof.get("sources_finalized",false),"Actual C owner finished full source first/final validation"): return false
	for path: String in required:
		if not check(proof.get("sources",{}).has(path) and proof.sources[path]==required[path],"Actual finalized C proof includes complete h source closure "+path): return false
	if not check(scene.get_meta(M.META,"")==M.AUTHOR_SHA and H.bound(scene),"Actual materialized h metadata and original Harbour identity"): return false
	var manifest: Dictionary=JSON.parse_string(FileAccess.get_file_as_string(office_author.parent_manifest))
	var old: SceneScript=ResourceLoader.load(manifest.scene_path,"",ResourceLoader.CACHE_MODE_IGNORE) as SceneScript
	if not check(old!=null and C._equal_value(scene.map_layout.portals,old.map_layout.portals) and C._equal_value(scene.map_layout.interactions,old.map_layout.interactions) and C._equal_value(scene.npcs,old.npcs),"No door/task/NPC source semantics added by office visual"): return false
	var actual_objects: Array=scene.map_layout.visual_objects
	if not check(actual_objects.size()==old.map_layout.visual_objects.size(),"Original28 authored visual entries, no duplicated office"): return false
	var office_entry: Dictionary={};var old_entry: Dictionary={};var unchanged:=0;var office_index: int=-1
	for index: int in actual_objects.size():
		var entry: Dictionary=actual_objects[index];var original: Dictionary=old.map_layout.visual_objects[index]
		if original.id==M.BUILDING: office_entry=entry;old_entry=original;office_index=index
		elif not check(_same_visual_path(entry,original,["visual_objects",index],"Unchanged original visual storage "+String(original.id)),"Unchanged original visual storage "+String(original.id)): return false
		else: unchanged+=1
	if not check(unchanged==27 and not office_entry.is_empty(),"Exactly one office entry replaced"): return false
	for key: String in old_entry:
		if key not in M.VISUAL_KEYS and not check(_same_visual_path(office_entry.get(key),old_entry[key],["visual_objects",office_index,key],"Original physical/depth/foot retained "+key),"Original physical/depth/foot retained "+key): return false
	var sprite: Sprite2D=_prop(M.BUILDING)
	if not check(sprite!=null and sprite.texture.resource_path==office_author.office.texture and sprite.position==office_entry.pos*Vector2(3072,2048) and sprite.scale==office_entry.render_size_px/Vector2(sprite.texture.get_size()) and not sprite.centered,"Actual new office Sprite texture/source anchor projection"): return false
	var world: Node2D=field.get("world_container")
	var depth: float=world.to_global(Vector2(0,float(old_entry.depth_sort_foot_y)*2048)).y
	if not check(sprite.z_index==clampi(int(floor(depth/8.0)),0,255),"Office remains native original foot-depth sorted"): return false
	var body: StaticBody2D=field.get("_collision_layer").get_node_or_null("CityV3Physical_"+M.BUILDING)
	if not check(body!=null and body.position==Vector2.ZERO and body.collision_layer==1,"Original native office physical body retained"): return false
	var polygons: Array=[]
	for child: Node in body.get_children():
		if child is CollisionPolygon2D: polygons.append((child as CollisionPolygon2D).polygon)
	if not check(polygons.size()==old_entry.city_v3_solid_polygons_px.size(),"Actual original solid polygon count"): return false
	for index: int in polygons.size():
		if not check(polygons[index]==C._polygon(old_entry.city_v3_solid_polygons_px[index]),"Actual unchanged complete native office base"): return false
	var nodes: Dictionary={}
	for npc: Node2D in field.get("_npc_nodes"):
		if String(npc.get("npc_id")) in M.ROLE_IDS: nodes[String(npc.get("npc_id"))]=npc;crowd_refs.append(weakref(npc))
	if not check(nodes.size()==2,"Exactly two actual profession replacement nodes"): return false
	for id: String in M.ROLE_IDS:
		var npc: NPCNode=nodes[id];var role: Dictionary=office_author.roles[id]
		var row: Dictionary=_npc_frame(npc,true);records.append(row)
		var image: Image=npc.sprite.texture.get_image()
		if image.is_compressed() and not check(image.decompress()==OK,"Actual lossless actor image read"): return false
		var bounds: Rect2i=image.get_used_rect()
		var physical: StaticBody2D=npc.get("_body_collider")
		var query:=PhysicsPointQueryParameters2D.new();query.position=npc.global_position;query.collision_mask=1;query.collide_with_areas=false
		var hit:=false
		for item: Dictionary in npc.get_world_2d().direct_space_state.intersect_point(query,16):
			if item.collider==physical: hit=true
		if not check(npc.position==Vector2(role.expected_foot_px[0],role.expected_foot_px[1]) and npc.sprite_path==role.texture and image.get_size()==Vector2i(160,160) and npc.sprite.hframes==1 and npc.sprite.vframes==1 and npc.sprite.frame==0 and npc.movement_mode=="idle" and npc.sprite.scale==Vector2.ONE*(140.0/float(bounds.size.y)) and npc.z_index==clampi(int(floor(npc.get_depth_sort_y()/8.0)),0,255) and hit,"Actual160/1f/140-alpha/originalfoot/nativebodypoint/nativez",row): return false
	records.append({"kind":"ACTUAL_OFFICE_ROLES_FIELD","other27_storage_unchanged":true,"original_portals_tasks_preserved":true,"single_frame_not_animation":true,"office_texture":sprite.texture.resource_path,"office_position":sprite.position,"office_scale":sprite.scale,"office_depth_z":sprite.z_index})
	return failures==0
func _exercise() -> bool:
	var start:=Time.get_ticks_msec()
	var accepted: bool=root.get_node("SceneRouter").call("go_field_smart",StringName(scene_id),null,"",-1,C.VERSION)
	records.append({"kind":"REAL_DEFAULT_PUBLIC_DOCKS_BIRTH","accepted":accepted,"public_call_ms":Time.get_ticks_msec()-start,"no_near_spawn_or_private_setup":true})
	if not check(accepted,"Public default-null Docks entry") or not await _wait() or not _bind_actual() or not _office_actual(): return false
	var player: CharacterBody2D=field.get("_player")
	var target: Vector2=player.position+Vector2(32,0)
	if not check(_segment(player.position,target).get("clear",false) and _clear(target),"Original32px normal approach independently safe"): return false
	if not await _walk(PackedVector2Array([player.position,target])): return false
	var previous: Camera2D=field.get("_world_camera");var world: Node2D=field.get("world_container")
	var camera:=Camera2D.new();camera.position=Vector2(1536,1024);camera.zoom=Vector2(.5,.5)
	world.add_child(camera);camera.make_current();await process_frame
	var captured: bool=await _capture("h_actual_docks_office_roles_whole_field")
	previous.make_current();camera.queue_free();await process_frame
	return check(previous.is_current(),"QA overview camera removed, normal camera restored") and captured
func _run() -> void:
	var began:=Time.get_ticks_msec();deadline=began+SHARED_MS;district="docks";scene_id="ch4_s2_canal_docks"
	root.get_node("PlatformBridge").call("set_checkpoint_saves_suspended",true);players_before=saves()
	folder="res://build/luoyang_docks_office_actual_field_20261016h/%d_%d"%[OS.get_process_id(),began];DirAccess.make_dir_recursive_absolute(folder)
	var complete:=false
	if precheck():
		driver=INPUT.new();driver.configure(self)
		for singleton: String in ["GameState","Inventory","QuestManager","BountyManager","InvestigationState","SceneRouter"]: root.get_node(singleton).call("reset_for_new_game")
		complete=await _exercise()
		if not await _leave_actual_field(): complete=false
		root.get_node("SceneRouter").call("reset_for_new_game");await process_frame;await process_frame
	if driver!=null: driver.release();driver=null
	field=null;scene=null;oracle=null;frame_images.clear()
	for reference: WeakRef in crowd_refs: check(reference.get_ref()==null,"Own real two profession nodes released with Field tree exit")
	records.append({"kind":"SCOPE","shared_ms":SHARED_MS,"arrival_ms":ARRIVAL_MS,"captures":captures,"native_queries":native_queries,"whole_city_or_warm_or_rooms_claimed":false})
	finish(folder,began,complete,"ONLY_REAL_DEFAULT_DOCKS_H_VISUAL_ROLES_ONE32PX_INPUT_NOT_WARM_OR_ELEVEN_ROOMS")
