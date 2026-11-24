extends RefCounted
const FINISH25I_ENABLED: bool=true
const FINISH25I_RUNTIME: String="res://build/luoyang_city_finish_20261025i_source01/runtime_READY01/finish8_runtime_READY.gd"
const FINISH25I_RUNTIME_SHA: String="6bf511258f2ab12e645762f85a4d55721633d7fb4a02fc7850929bc3b678a334"
const FINISH25I_ADAPTER: String="res://build/luoyang_city_finish_20261025i_source01/original_owner_receipts03_family_weak_snapshot_NOTREADY.gd"
const FINISH25I_ADAPTER_SHA: String="9ed1b1166bd1e7b700925e18a55337bb7d2fdb321b00cd3d6ae7cea685ae78d5"
static var _finish25i_handle: Variant=null
static var _finish25i_checking: bool=false
static var _finish25i_original_owners: Dictionary={}
static var _finish25i_active_scenes: Dictionary={}
static func _finish25i_runtime() -> Variant:
	if not FINISH25I_ENABLED: return null
	if _finish25i_handle!=null: return _finish25i_handle
	if FileAccess.get_sha256(FINISH25I_RUNTIME)!=FINISH25I_RUNTIME_SHA: return null
	var script: Variant=load(FINISH25I_RUNTIME)
	if not script is GDScript or script.resource_path!=FINISH25I_RUNTIME: return null
	_finish25i_handle=script;return script
static func original_receipt_for(scene: SceneScript) -> Dictionary:
	if not FINISH25I_ENABLED or scene==null or scene.map_layout==null: return {}
	var row: Dictionary=_finish25i_original_owners.get(scene.get_instance_id(),{})
	if row.is_empty() or row.scene.get_ref()!=scene or row.layout.get_ref()!=scene.map_layout: return {}
	return row.receipt.duplicate(true)
static func _finish25i_promote_original_final() -> void:
	if not FINISH25I_ENABLED: return
	var actual: Dictionary=validation_receipt()
	if actual.get("finalized")!=true or actual.get("full_source_hash_passes")!=2 or actual.get("source_first")!=actual.get("source_final"): return
	for key: int in _finish25i_original_owners.keys():
		var row: Dictionary=_finish25i_original_owners[key]
		if row.scene.get_ref()==null or row.layout.get_ref()==null:
			_finish25i_original_owners.erase(key);continue
		if row.receipt.get("serial")==actual.get("serial") and row.receipt.get("key")==actual.get("key") and row.receipt.get("source_first")==actual.get("source_first"):
			row.receipt=actual.duplicate(true)
static func _finish25i_ensure(scene: SceneScript) -> bool:
	if not FINISH25I_ENABLED: return true
	# Adapter recursively calls matches; its inner call still executes every old
	# whole-storage guard, but cannot recursively create or finalize a lease.
	if _finish25i_checking: return true
	var runtime: Variant=_finish25i_runtime()
	if runtime==null or scene==null or scene.map_layout==null: return false
	for key: int in _finish25i_original_owners.keys():
		var owner: Dictionary=_finish25i_original_owners[key]
		if owner.scene.get_ref()==null or owner.layout.get_ref()==null: _finish25i_original_owners.erase(key)
	if not _finish25i_original_owners.has(scene.get_instance_id()):
		var first: Dictionary=validation_receipt()
		if int(first.get("serial",0))<=0 or String(first.get("key",""))=="" or not first.get("source_first") is Dictionary or first.source_first.is_empty(): return false
		_finish25i_original_owners[scene.get_instance_id()]={"scene":weakref(scene),"layout":weakref(scene.map_layout),"receipt":first.duplicate(true)}
	if original_receipt_for(scene).is_empty() or FileAccess.get_sha256(FINISH25I_ADAPTER)!=FINISH25I_ADAPTER_SHA: return false
	var adapter: Variant=load(FINISH25I_ADAPTER)
	if not adapter is GDScript or adapter.resource_path!=FINISH25I_ADAPTER: return false
	_finish25i_checking=true
	var receipt: Dictionary=adapter.receipt(scene,null,false)
	_finish25i_checking=false
	if receipt.is_empty(): return false
	if not runtime.ensure(scene,receipt.original_native_navigation,receipt.original_parent_blockers,receipt): return false
	_finish25i_active_scenes[scene.scene_id]=weakref(scene)
	return true
static func _finish25i_safe(id: StringName,foot: Vector2) -> bool:
	var runtime: Variant=_finish25i_handle
	if runtime==null or not foot.is_finite(): return false
	var active: WeakRef=_finish25i_active_scenes.get(id) as WeakRef
	var scene: SceneScript=active.get_ref() as SceneScript if active!=null else null
	if scene==null or scene.scene_id!=id or scene.map_layout==null: return false
	var row: Dictionary=_finish25i_original_owners.get(scene.get_instance_id(),{})
	return not row.is_empty() and row.scene.get_ref()==scene and row.layout.get_ref()==scene.map_layout and runtime.safe_body(scene,foot)
## Two new AP ordinary fields. The original city validation path remains owned
## by C/B; this family never claims a new field is one of those four cities.
const SELF="res://scripts/city/luoyang_quarters_family_20261022ap.gd"
const INDEX="res://scripts/city/luoyang_quarters_index_20261022ap.gd"
const ROOT="res://data/maps/luoyang_full_city_20261022ap/quarters/revision4/"
const IDS=[&"luoyang_artisan_residential_20261022ap",&"luoyang_riverside_garden_20261022ap"]
const SIZE=Vector2(3072,2048)
const B_PATH="res://scripts/city/luoyang_precomputed_bundle_20261018r.gd"
const COMPILER="res://build/luoyang_city_full_rollout_20261022ap_system01/quarters_compiler.gd"
static var _data: Dictionary={}
static var _key: String=""
static var _packets: Dictionary={}
static var _images: Dictionary={}
static var _sessions: Dictionary={}
static var _receipt: Dictionary={}
static var _serial: int=0
static var _connection_receipt: Dictionary={}
const A2_READY=true
const A2_BINDING="res://build/luoyang_city_full_rollout_20261022ap_source_finalize01/a2_production04/a2_binding_READY.json"
const A2_BINDING_SHA="cbc3f21f2e20391f9f1e598730f5f1c04a0953606a817114377cd0f5b9654851"
static var _a2_fixed_binding: Dictionary={}
static func _a2_spec() -> Dictionary:
	if not A2_READY or not b()._hash(A2_BINDING_SHA): return {}
	if not _a2_fixed_binding.is_empty(): return _a2_fixed_binding
	var bytes: PackedByteArray=FileAccess.get_file_as_bytes(A2_BINDING)
	if b().bytes_sha(bytes)!=A2_BINDING_SHA: return {}
	var value: Variant=JSON.parse_string(bytes.get_string_from_utf8())
	if not value is Dictionary or value.get("status")!="ROOT_FIXED_A2_ARTISAN_NATIVE_AND_ART_BINDING" or value.get("ready")!=true or value.get("scene_id")!=String(IDS[0]): return {}
	for key: String in ["child","parent"]:
		if not value.get(key) is Dictionary: return {}
		for suffix: String in ["scene.res","layout.res","packet.bin","walk.png"]:
			var leaf: Dictionary=value[key].get(suffix,{})
			if not leaf.get("path") is String or ".." in leaf.path or not leaf.path.begins_with("res://") or not b()._hash(leaf.get("sha256")): return {}
	for key: String in ["publisher_report","root_art_admission","independent_publication_review"]:
		var leaf: Dictionary=value.get(key,{})
		if not leaf.get("path") is String or not leaf.path.begins_with("res://build/") or ".." in leaf.path or not b()._hash(leaf.get("sha256")) or FileAccess.get_sha256(leaf.path)!=leaf.sha256: return {}
	var report: Variant=JSON.parse_string(FileAccess.get_file_as_string(value.publisher_report.path))
	var art: Variant=JSON.parse_string(FileAccess.get_file_as_string(value.root_art_admission.path))
	if not report is Dictionary or report.get("passed")!=true or report.get("published")!=true or not art is Dictionary or art.get("status")!="ROOT_VIEWED_A2_LOCAL_LAYOUT_AND_MATERIAL_SCOPE_ONLY" or art.get("approved_by_root")!=true or art.get("whole_district_ART_pass")!=false or art.get("Field_NPC_Player_Physics_or_loading_credit")!=false: return {}
	if not b().equal(art.get("publisher_report"),value.publisher_report) or not b().equal(art.get("independent_publication_review"),value.independent_publication_review): return {}
	if report.get("whole_packet_inverse")!=true or report.get("whole_scene_layout_inverse")!=true or not report.get("source_first") is Dictionary or report.source_first.size()!=139 or not b().equal(report.source_first,report.get("source_final")): return {}
	var proof: Dictionary=report.get("finite_proof",{})
	if not b().equal(proof,value.get("publication_finite_proof")) or proof.get("native_storage_inverse")!=true or proof.get("all_7_routes_all4NPC_all4portals_exact")!=true: return {}
	for key: String in ["old_visual_count","old_solid_count","new_visual_count","new_solid_count","new_ground_count","retained_opaque_props"]:
		var expected: Dictionary={"old_visual_count":106,"old_solid_count":33,"new_visual_count":132,"new_solid_count":27,"new_ground_count":118,"retained_opaque_props":14}
		if not proof.get(key) is float or proof[key]!=float(expected[key]): return {}
	var mask: Dictionary=proof.get("local_mask",{})
	if mask.get("whole_RGBA_inverse")!=true or mask.get("outside_eight_guarded_domains_exact")!=true or mask.get("child_rgba_sha256")!=value.get("child_rgba_sha256_from_fixed_independent_prior_and_Root_report") or mask.get("parent_rgba_sha256")!=value.get("parent_rgba_sha256"): return {}
	var contract: Dictionary=value.get("publication_admission_contract",{})
	if contract.get("runtime_inverse_replay")!=false or contract.get("fixed_publisher_inverse_inherited")!=true or contract.get("parent_packet_runtime_read_decode_clone_and_mask_domain_replay")!=false: return {}
	for suffix: String in value.child:
		if report.get("artifacts",{}).get(value.child[suffix].path)!=value.child[suffix].sha256: return {}
	if not value.get("source_sha256") is Dictionary or not value.get("local_domains_xywh") is Array or value.local_domains_xywh.size()!=8: return {}
	_a2_fixed_binding=value
	return _a2_fixed_binding
static func _a2_declared(data: Dictionary) -> bool: return data.has("a2_artisan_successor")
static func _a2_header_matches(data: Dictionary) -> bool:
	if not _a2_declared(data): return true
	var spec: Dictionary=_a2_spec()
	if spec.is_empty(): return false
	var declaration: Variant=data.get("a2_artisan_successor")
	if not declaration is Dictionary or declaration.size()!=2 or declaration.get("binding_path")!=A2_BINDING or declaration.get("binding_sha256")!=A2_BINDING_SHA or data.source_sha256.get(A2_BINDING)!=A2_BINDING_SHA: return false
	for path: String in spec.source_sha256:
		if not b()._hash(spec.source_sha256[path]) or data.source_sha256.get(path)!=spec.source_sha256[path]: return false
	for suffix: String in spec.child:
		if data.source_sha256.get(spec.child[suffix].path)!=spec.child[suffix].sha256: return false
	return true
static func _a2_artifact_path(data: Dictionary,id: StringName,suffix: String) -> String:
	if id==IDS[1] and _garden_river_declared(data):
		var river: Dictionary=garden_river_spec()
		return String(river.child[suffix].path) if not river.is_empty() and river.child.has(suffix) else ""
	if id==IDS[0] and _a2_declared(data):
		var spec: Dictionary=_a2_spec()
		return String(spec.child[suffix].path) if not spec.is_empty() and spec.child.has(suffix) else ""
	return ROOT+String(id)+"/"+suffix
static func _a2_published_packet_valid(raw: Dictionary,data: Dictionary) -> bool:
	# Exact child bytes were hashed before decoding. The fixed publisher already
	# proved the complete parent inverse; runtime does NOT replay that operation.
	if not _a2_header_matches(data): return false
	var spec: Dictionary=_a2_spec()
	if spec.is_empty() or not raw.get("a2_finite_proof") is Dictionary: return false
	var native_proof: Dictionary=raw.a2_finite_proof
	if native_proof.get("native_storage_inverse")!=true or native_proof.get("all_7_routes_all4NPC_all4portals_exact")!=true: return false
	for key: String in ["old_visual_count","old_solid_count","new_visual_count","new_solid_count","new_ground_count","retained_opaque_props"]:
		var expected: Dictionary={"old_visual_count":106,"old_solid_count":33,"new_visual_count":132,"new_solid_count":27,"new_ground_count":118,"retained_opaque_props":14}
		if not native_proof.get(key) is int or native_proof[key]!=expected[key]: return false
	if raw.get("parent_packet_sha256")!=spec.parent["packet.bin"].sha256 or raw.get("author_path")!=spec.author.path or raw.get("author_sha256")!=spec.author.sha256: return false
	if raw.get("mask_sha256")!=spec.child_rgba_sha256_from_fixed_independent_prior_and_Root_report or not raw.get("solids") is Array or raw.solids.size()!=27: return false
	for key: String in ["scene_storage","layout_storage"]:
		if not raw.get(key) is Dictionary or not raw[key].get("fields") is Dictionary: return false
	for key: String in ["visual_objects","blockers"]:
		if not raw.layout_storage.fields.get(key) is Dictionary or not raw.layout_storage.fields[key].get("array_values") is Array: return false
	return raw.layout_storage.fields.visual_objects.array_values.size()==132 and raw.layout_storage.fields.blockers.array_values.size()==27 and raw.layout_storage.fields.walkable_mask_path==spec.child["walk.png"].path
static func a2_source_bound_scene(scene: SceneScript) -> bool:
	return A2_READY and scene!=null and scene.scene_id==IDS[0] and _a2_declared(manifest()) and matches(scene)
const GARDEN_RIVER_READY=true
const GARDEN_RIVER_BINDING="res://build/luoyang_garden_river_20261025h_source01/runtime02_READY/garden_river_binding_READY.json"
const GARDEN_RIVER_BINDING_SHA="7ecb31c6adde123f7b365ba6596dc1eed3b1e795c3b4a6baa3162992e3bf5cdf"
static var _garden_river_fixed_binding: Dictionary={}
static func _garden_river_declared(data: Dictionary) -> bool: return data.has("garden_river_successor")
static func garden_river_spec() -> Dictionary:
	if not GARDEN_RIVER_READY or not b()._hash(GARDEN_RIVER_BINDING_SHA): return {}
	if not _garden_river_fixed_binding.is_empty(): return _garden_river_fixed_binding
	var bytes: PackedByteArray=FileAccess.get_file_as_bytes(GARDEN_RIVER_BINDING)
	if b().bytes_sha(bytes)!=GARDEN_RIVER_BINDING_SHA: return {}
	var value: Variant=JSON.parse_string(bytes.get_string_from_utf8())
	if not value is Dictionary or value.get("ready")!=true or value.get("status")!="ROOT_READY_GARDEN_RIVER_NATIVE_BINDING" or value.get("scene_id")!=String(IDS[1]) or not value.get("required_sources") is Dictionary or not value.get("child") is Dictionary: return {}
	for suffix: String in ["scene.res","layout.res","packet.bin","walk.png"]:
		var leaf: Dictionary=value.child.get(suffix,{})
		if not leaf.get("path") is String or not leaf.path.begins_with("res://build/luoyang_garden_river_20261025h_source01/") or ".." in leaf.path or not b()._hash(leaf.get("sha256")) or value.required_sources.get(leaf.path)!=leaf.sha256: return {}
	for path: String in value.required_sources:
		if not path.begins_with("res://") or ".." in path or not b()._hash(value.required_sources[path]): return {}
	if value.get("expected_visual_count")!=56 or value.get("expected_solid_count")!=16 or value.get("expected_portal_count")!=2 or value.get("child_rgba_sha256")!="d552010ef7108d37c38ee472106b244bdc5145ea3ef41748cbd103cfaeb6c456" or not value.get("mask_import_and_direct_ctex") is Dictionary or not value.get("limited_Field_trial_admission") is Dictionary: return {}
	_garden_river_fixed_binding=value;return value
static func _garden_river_header_matches(data: Dictionary) -> bool:
	if not _garden_river_declared(data): return true
	var spec: Dictionary=garden_river_spec()
	if spec.is_empty(): return false
	var declaration: Variant=data.garden_river_successor
	if not declaration is Dictionary or declaration.size()!=2 or declaration.get("binding_path")!=GARDEN_RIVER_BINDING or declaration.get("binding_sha256")!=GARDEN_RIVER_BINDING_SHA or data.source_sha256.get(GARDEN_RIVER_BINDING)!=GARDEN_RIVER_BINDING_SHA: return false
	for path: String in spec.required_sources:
		if data.source_sha256.get(path)!=spec.required_sources[path]: return false
	return true
static func garden_river_source_bound_scene(scene: SceneScript) -> bool:
	return scene!=null and scene.scene_id==IDS[1] and _garden_river_declared(manifest()) and _garden_river_header_matches(manifest()) and matches(scene)
static func _garden_river_packet_valid(raw: Dictionary,data: Dictionary) -> bool:
	var spec: Dictionary=garden_river_spec()
	if spec.is_empty() or not _garden_river_header_matches(data) or raw.get("author_path")!=spec.author.path or raw.get("author_sha256")!=spec.author.sha256 or raw.get("mask_sha256")!=spec.child_rgba_sha256 or not raw.get("solids") is Array or raw.solids.size()!=16 or not raw.get("river_bridge25h") is Dictionary: return false
	if raw.river_bridge25h.get("whole_parent_outside_domains_inverse")!=true or not raw.river_bridge25h.get("water_physics_pieces") is Array or raw.river_bridge25h.water_physics_pieces.size()!=2 or not raw.river_bridge25h.get("deck") is Rect2 or raw.river_bridge25h.deck.size.y-24<128: return false
	for key: String in ["scene_storage","layout_storage"]:
		if not raw.get(key) is Dictionary or not raw[key].get("fields") is Dictionary: return false
	var fields: Dictionary=raw.layout_storage.fields
	return fields.get("visual_objects",{}).get("array_values",[]).size()==56 and fields.get("blockers",{}).get("array_values",[]).size()==16 and fields.get("walkable_mask_path")==spec.child["walk.png"].path
static func b() -> Variant: return load(B_PATH)
static func requested() -> bool:
	if not FileAccess.file_exists(INDEX): return false
	var authority: Variant=load(INDEX)
	return authority is GDScript and authority.resource_path==INDEX and authority.formal_enabled()==true
static func source_header() -> Dictionary:
	if not requested(): return {}
	var entry: Dictionary=load(INDEX).entry()
	if entry.size()!=2 or entry.get("path")!=ROOT+"manifest.json" or not b()._hash(entry.get("sha256")) or FileAccess.get_sha256(entry.path)!=entry.sha256: return {}
	var raw: Variant=JSON.parse_string(FileAccess.get_file_as_string(entry.path))
	if not raw is Dictionary or raw.get("status")!="ROOT_ADMITTED_AP_TWO_QUARTERS" or not raw.get("scenes") is Dictionary or raw.scenes.size()!=2 or not raw.get("source_sha256") is Dictionary or raw.source_sha256.is_empty() or raw.source_sha256.has(INDEX): return {}
	if not _a2_header_matches(raw): return {}
	if not _life_header_matches(raw): return {}
	if not _garden_river_header_matches(raw): return {}
	for id: StringName in IDS:
		var row: Dictionary=raw.scenes.get(String(id),{})
		if row.get("scene_path")!=_life_artifact_path(raw,id,"scene.res") or row.get("layout_path")!=_life_artifact_path(raw,id,"layout.res") or row.get("packet_path")!=_life_artifact_path(raw,id,"packet.bin"): return {}
		for p: String in [row.scene_path,row.layout_path,row.packet_path,_life_artifact_path(raw,id,"walk.png"),COMPILER,SELF]:
			if not raw.source_sha256.has(p): return {}
	for p: String in raw.source_sha256:
		if not p.begins_with("res://") or ".." in p or not b()._hash(raw.source_sha256[p]): return {}
	return raw
static func manifest() -> Dictionary:
	var header: Dictionary=source_header()
	if header.is_empty(): return {}
	var key: String=FileAccess.get_sha256(INDEX)+":"+load(INDEX).entry().sha256
	if key==_key and not _data.is_empty(): return _data
	_data={};_packets={};_images={};_sessions={};_key=""
	var began: int=Time.get_ticks_usec()
	for p: String in header.source_sha256:
		if FileAccess.get_sha256(p)!=header.source_sha256[p]: return {}
	_data=header;_key=key
	_receipt={"serial":_serial,"key":key,"source_first":header.source_sha256.duplicate(true),"source_final":{},"full_source_hash_passes":1,"first_hash_elapsed_us":Time.get_ticks_usec()-began,"finalized":false}
	return _data
static func validation_begin() -> bool:
	_serial+=1;_data={};_key="";_packets={};_images={};_sessions={};_receipt={}
	return not manifest().is_empty()
static func validation_finish() -> bool:
	if _data.is_empty() or _receipt.get("serial")!=_serial or _receipt.get("key")!=_key or source_header().is_empty(): return false
	if FileAccess.get_sha256(INDEX)+":"+load(INDEX).entry().sha256!=_key: return false
	if _receipt.get("finalized")==true:
		_finish25i_promote_original_final();return true
	var began: int=Time.get_ticks_usec();var final: Dictionary={}
	for p: String in _receipt.source_first:
		final[p]=FileAccess.get_sha256(p)
		if final[p]!=_receipt.source_first[p]: _data={};_packets={};_images={};_sessions={};return false
	_receipt.source_final=final;_receipt.full_source_hash_passes=2;_receipt.final_hash_elapsed_us=Time.get_ticks_usec()-began;_receipt.finalized=true;_finish25i_promote_original_final();return true
static func validation_receipt() -> Dictionary: return _receipt.duplicate(true)
static func source_paths() -> Dictionary:
	var data: Dictionary=source_header()
	if data.is_empty(): return {}
	var out: Dictionary={SELF:true,INDEX:true,ROOT+"manifest.json":true}
	for p: String in data.source_sha256: out[p]=true
	if FINISH25I_ENABLED:
		var runtime: Variant=_finish25i_runtime()
		if runtime==null: return {}
		for id: StringName in IDS:
			var extra: Dictionary=runtime.source_paths_for(id)
			if extra.is_empty(): return {}
			out.merge(extra,true)
		out[FINISH25I_ADAPTER]=true
	return out
static func scene_path(id: StringName) -> String:
	var data: Dictionary=manifest()
	return String(data.scenes[String(id)].scene_path) if id in IDS and not data.is_empty() else ""
static func packet(id: StringName) -> Dictionary:
	var data: Dictionary=manifest()
	if id not in IDS or data.is_empty(): return {}
	if _packets.has(id): return _packets[id]
	var row: Dictionary=data.scenes[String(id)]
	var packet_bytes: PackedByteArray=FileAccess.get_file_as_bytes(row.packet_path)
	if id==IDS[0] and _life_declared(data):
		var life: Dictionary=_life_packet_from_bytes(packet_bytes,data)
		if life.is_empty(): return {}
		_packets[id]=life;return life
	if id==IDS[0] and _a2_declared(data):
		var spec: Dictionary=_a2_spec()
		if spec.is_empty() or b().bytes_sha(packet_bytes)!=spec.child["packet.bin"].sha256: return {}
	if id==IDS[1] and _garden_river_declared(data):
		var river: Dictionary=garden_river_spec()
		if river.is_empty() or b().bytes_sha(packet_bytes)!=river.child["packet.bin"].sha256: return {}
	var raw: Variant=bytes_to_var(packet_bytes)
	if not raw is Dictionary or not b()._plain(raw) or raw.get("kind")!="AP_SOURCE_BOUND_NEW_ORDINARY_QUARTER" or raw.get("scene_id")!=String(id) or not raw.get("walk_bytes") is PackedByteArray or b().bytes_sha(raw.walk_bytes)!=raw.get("mask_sha256"): return {}
	if id==IDS[0] and _a2_declared(data):
		if not _a2_published_packet_valid(raw,data): return {}
	elif raw.has("a2_finite_proof"): return {}
	if id==IDS[1] and _garden_river_declared(data) and not _garden_river_packet_valid(raw,data): return {}
	if id==IDS[1] and not _garden_river_declared(data) and raw.has("river_bridge25h"): return {}
	_packets[id]=raw;return raw
static func matches(scene: SceneScript) -> bool:
	if scene==null or scene.scene_id not in IDS or scene.map_layout==null or not scene.actor_positions_are_feet: return false
	var data: Dictionary=manifest();var value: Dictionary=packet(scene.scene_id)
	if data.is_empty() or value.is_empty(): return false
	var row: Dictionary=data.scenes[String(scene.scene_id)]
	if scene.resource_path!=row.scene_path or scene.map_layout.resource_path!=row.layout_path or scene.get_meta("luoyang_full_city_AP","")!=value.author_sha256: return false
	if not b().equal(b().storage(scene),value.scene_storage) or not b().equal(b().storage(scene.map_layout),value.layout_storage): return false
	for old: int in _sessions.keys():
		if _sessions[old].scene.get_ref()==null or _sessions[old].layout.get_ref()==null: _sessions.erase(old)
	if _sessions.size()>=8 and not _sessions.has(scene.get_instance_id()): return false
	_sessions[scene.get_instance_id()]={"scene":weakref(scene),"layout":weakref(scene.map_layout)};return _finish25i_ensure(scene)
static func safe_body(id: StringName,foot: Vector2) -> bool:
	if FINISH25I_ENABLED and id in IDS: return _finish25i_safe(id,foot)
	var value: Dictionary=packet(id)
	if value.is_empty(): return false
	if not _images.has(id):
		var image: Image=Image.load_from_file(_life_artifact_path(_data,id,"walk.png"))
		if image==null: return false
		image.convert(Image.FORMAT_RGBA8)
		if image.get_size()!=Vector2i(3072,2048) or image.get_data()!=value.walk_bytes: return false
		_images[id]=image
	return load(COMPILER).safe_body(foot,_images[id],value.solids)
static func owns_route(source: StringName,target: StringName) -> bool:
	if FINISH25I_ENABLED and _finish25i_new_pair(source,target): return _finish25i_runtime()!=null
	if source not in IDS and target not in IDS: return false
	var data: Dictionary=source_header()
	if data.is_empty(): return false
	var found: int=0
	for row: Dictionary in data.get("connections",[]):
		if row.get("source")==String(source) and row.get("target")==String(target): found+=1
	return found==1
static func project_connections(scene: SceneScript,original: Array) -> Dictionary:
	if scene==null: return {"ok":false,"error":"AP_CONNECTION_SCENE_NULL","portals":[]}
	var data: Dictionary=source_header()
	if data.is_empty(): return {"ok":false,"error":"AP_CONNECTION_HEADER_NOT_READY","portals":[]}
	var selected: Array=[]
	for row: Dictionary in data.get("connections",[]):
		if row.get("source")==String(scene.scene_id) and row.get("target") in [String(IDS[0]),String(IDS[1])] and row.get("kind")=="PUBLIC_QUARTER_LINK": selected.append(row)
	if selected.is_empty(): return {"ok":true,"portals":original.duplicate(true),"AP_connection_delta":0}
	# Existing fields load only this control header and projection executable,
	# not future Garden/Artisan media. Their own parent family/C lease owns the
	# actual native resources. Keep this composed source domain cycle-free.
	var header_first: Dictionary={INDEX:FileAccess.get_sha256(INDEX),ROOT+"manifest.json":load(INDEX).entry().sha256}
	for path: String in [SELF,COMPILER]:
		if not data.source_sha256.has(path) or FileAccess.get_sha256(path)!=data.source_sha256[path]: return {"ok":false,"error":"AP_CONNECTION_HEADER_EXECUTABLE_CHANGED","portals":[]}
		header_first[path]=data.source_sha256[path]
	var parent_ok: bool=false
	if scene.scene_id in IDS: parent_ok=matches(scene)
	elif scene.scene_id==&"luoyang_estate_riverside_20261021ai": parent_ok=load("res://scripts/city/luoyang_estate_family_20261021am.gd").matches(scene)
	else:
		var city: Variant=load("res://scripts/city/luoyang_enclosure_v11_candidate_contract.gd")
		parent_ok=city.is_v3(scene) and b().whole_bound(scene)
	if not parent_ok: return {"ok":false,"error":"AP_CONNECTION_REAL_PARENT_OWNER","portals":[]}
	var out: Array=original.duplicate(true)
	for row: Dictionary in selected:
		if not load(COMPILER).pair(row.get("source_foot")) or not load(COMPILER).pair(row.get("target_foot")) or not owns_route(scene.scene_id,StringName(row.target)): return {"ok":false,"error":"AP_CONNECTION_EXACT_COORDINATES","portals":[]}
		var foot: Vector2=load(COMPILER).v(row.source_foot)
		for offset: float in [0.0,10.0,24.0]:
			var point: Vector2=foot+Vector2(0,offset)
			var safe: bool=false
			if scene.scene_id in IDS: safe=safe_body(scene.scene_id,point)
			elif scene.scene_id==&"luoyang_estate_riverside_20261021ai": safe=load("res://scripts/city/luoyang_estate_family_20261021am.gd").safe_body(point)
			else: safe=load("res://scripts/city/luoyang_enclosure_v11_candidate_contract.gd").safe_body(scene.scene_id,point)
			if not safe: return {"ok":false,"error":"AP_CONNECTION_NATIVE_BODY_PLUS24:"+String(row.id),"portals":[]}
		for prior: Dictionary in out:
			if prior.get("id")==row.id or String(prior.get("target_scene",""))==row.target: return {"ok":false,"error":"AP_CONNECTION_DUPLICATE_TARGET","portals":[]}
		out.append({"id":row.id,"pos":foot/SIZE,"size":Vector2(40,32)/SIZE,"target_scene":row.target,"target_scene_path":_life_artifact_path(data,StringName(row.target),"scene.res"),"target_pos":load(COMPILER).v(row.target_foot)/SIZE,"auto_trigger":false,"label":row.label,"interaction_polygon_px":PackedVector2Array([foot+Vector2(-20,-16),foot+Vector2(20,-16),foot+Vector2(20,16),foot+Vector2(-20,16)])})
	var header_final: Dictionary={}
	for path: String in header_first:
		header_final[path]=FileAccess.get_sha256(path)
		if header_final[path]!=header_first[path]: return {"ok":false,"error":"AP_CONNECTION_HEADER_SOURCE_FINAL_CHANGED","portals":[]}
	_connection_receipt={"scene_id":String(scene.scene_id),"source_first":header_first,"source_final":header_final,"scope":"AP_PUBLIC_LINK_HEADER_ONLY_PARENT_NATIVE_LEASE_SEPARATE","future_quarter_media_loaded":false,"source_hash_passes":2}
	return {"ok":true,"portals":out,"AP_connection_delta":selected.size(),"native_parent_portals_unchanged_prefix":true,"source_receipt":_connection_receipt.duplicate(true)}
static func connection_receipt() -> Dictionary: return _connection_receipt.duplicate(true)
static func _finish25i_new_pair(source: StringName,target: StringName) -> bool:
	return (source==&"ch4_s1_luoyang_yamen" and target==IDS[0]) or (source==IDS[0] and target==&"ch4_s1_luoyang_yamen")
static func _finish25i_new_arrival(source: StringName,target: StringName,authored: Variant,remembered: Variant,destination: SceneScript) -> Dictionary:
	if not authored is Vector2 or destination==null or destination.scene_id!=target or (remembered!=null and not remembered is Vector2): return {}
	if target in IDS and not matches(destination): return {}
	var runtime: Variant=_finish25i_runtime()
	if runtime==null: return {}
	var authority: Dictionary=runtime.authored_arrival(source,target,authored)
	if authority.get("matched")!=true or authority.get("ok")!=true or authority.get("kind")!="ORIGINAL_FIRST_COLD_LEASE": return {}
	var arrival: Vector2=remembered if remembered is Vector2 else authored
	if not arrival.is_finite() or ((arrival-authored)*SIZE).length()>180.0 or not runtime.safe_body(destination,arrival*SIZE): return {}
	return {"spawn":arrival,"source_version":3,"target_version":3,"reason":"finish25i_exact_original_owner_public_pair"}
static func prepare_arrival(source: StringName,target: StringName,authored: Variant,remembered: Variant,destination: SceneScript) -> Dictionary:
	if FINISH25I_ENABLED and _finish25i_new_pair(source,target): return _finish25i_new_arrival(source,target,authored,remembered,destination)
	if not authored is Vector2 or not owns_route(source,target) or manifest().is_empty(): return {}
	var route: Dictionary={}
	for row: Dictionary in _data.connections:
		if row.source==String(source) and row.target==String(target): route=row
	if route.is_empty() or not load(COMPILER).pair(route.get("target_foot")): return {}
	var target_size: Vector2=load(COMPILER).v(route.target_size) if load(COMPILER).pair(route.get("target_size")) else SIZE
	if authored!=load(COMPILER).v(route.target_foot)/target_size or (remembered!=null and not remembered is Vector2): return {}
	var arrival: Vector2=remembered if remembered is Vector2 else authored
	if not arrival.is_finite() or ((arrival-authored)*target_size).length()>180.0: return {}
	if target in IDS:
		if not matches(destination) or not safe_body(target,arrival*SIZE): return {}
	elif target==&"luoyang_estate_riverside_20261021ai":
		var estate: Variant=load("res://scripts/city/luoyang_estate_family_20261021am.gd")
		if not estate.matches(destination) or not estate.safe_body(arrival*SIZE): return {}
	elif route.get("target_kind")=="EXISTING_ROOM_RETURN_ONLY":
		var rooms: Variant=load("res://scripts/city/luoyang_assembled_interiors_20261016g.gd")
		if not rooms.matches(destination,target) or target_size!=Vector2(1536,1024): return {}
		var geometry: Dictionary=rooms.compile_geometry(rooms.author_for_id(target).get("geometry",{}),target_size)
		if geometry.is_empty() or not rooms.safe_foot(geometry,arrival*target_size,target_size,true): return {}
	else:
		# A legacy field must already have passed its OWN arrival/identity path.
		# Revalidate its original full body rather than claiming our new mask.
		var old_city: Variant=load("res://scripts/city/luoyang_enclosure_v11_candidate_contract.gd")
		if destination==null or destination.scene_id!=target or not old_city.safe_body(target,arrival*SIZE): return {}
	return {"spawn":arrival,"source_version":3,"target_version":3,"reason":"source_bound_AP_quarter_pair"}


## Independent exact life-child admission; the original A2 implementation above is unchanged.
const LIFE_READY=true
const LIFE_BINDING="res://build/luoyang_city_full_rollout_20261022ap_source_finalize01/life_production100_READY/life_binding_READY.json"
const LIFE_BINDING_SHA="ff97c27d2660bc45bcd7f526dca4c1d7aca9329510de24e1fe767c959a433333"
const LIFE_IDS=["ap_life_dye_rinse_tub_a","ap_life_dye_rinse_tub_b","ap_life_well_tea_table","ap_life_well_wait_bench"]
static var _life_fixed_binding: Dictionary={}
static func _life_fixed_leaf(row: Variant) -> bool:
	return row is Dictionary and row.get("path") is String and row.path.begins_with("res://build/") and not ".." in row.path and b()._hash(row.get("sha256"))
static func _life_spec() -> Dictionary:
	if not LIFE_READY or not b()._hash(LIFE_BINDING_SHA): return {}
	if not _life_fixed_binding.is_empty(): return _life_fixed_binding
	var bytes: PackedByteArray=FileAccess.get_file_as_bytes(LIFE_BINDING)
	if b().bytes_sha(bytes)!=LIFE_BINDING_SHA: return {}
	var value: Variant=JSON.parse_string(bytes.get_string_from_utf8())
	if not value is Dictionary or value.get("status")!="ROOT_FIXED_ARTISAN_LIFE_FOUR_PROP_NATIVE_AND_LOCAL_ART_BINDING" or value.get("ready")!=true or value.get("scene_id")!=String(IDS[0]): return {}
	var parent: Dictionary=_a2_spec()
	if parent.is_empty() or not b().equal(value.get("a2_binding"),{"path":A2_BINDING,"sha256":A2_BINDING_SHA}) or not b().equal(value.get("parent"),parent.child) or not b().equal(value.get("author"),parent.author): return {}
	if not value.get("child") is Dictionary or value.child.size()!=4: return {}
	for suffix: String in ["scene.res","layout.res","packet.bin","walk.png"]:
		if not _life_fixed_leaf(value.get("child",{}).get(suffix)): return {}
	for key: String in ["author_delta","publisher_report","independent_pixel_prior","native_visual_report","root_art_admission"]:
		var leaf: Variant=value.get(key)
		if not _life_fixed_leaf(leaf) or FileAccess.get_sha256(leaf.path)!=leaf.sha256: return {}
	var report: Variant=JSON.parse_string(FileAccess.get_file_as_string(value.publisher_report.path))
	var art: Variant=JSON.parse_string(FileAccess.get_file_as_string(value.root_art_admission.path))
	if not report is Dictionary or report.get("passed")!=true or report.get("published")!=true or report.get("whole_packet_inverse")!=true or report.get("whole_scene_layout_inverse")!=true: return {}
	if not report.get("source_first") is Dictionary or report.source_first.size()!=20 or not b().equal(report.source_first,report.get("source_final")) or not b().equal(report.source_first,value.get("publication_source_first")): return {}
	# Exact ART8A9C schema is source-bound; it grants only four native prop visuals,
	# never Root deployment, Field, ghost, loading or whole-district approval.
	var art_fields: Variant=value.get("root_art_expected_fields")
	if not art is Dictionary or art.get("status")!="LIMITED_NATIVE_FOUR_LOW_PROP_VISUAL_ADMISSION_NOT_DISTRICT_ART" or art.get("approved_local_four_prop_delta_by_ART")!=true or art.get("eligible_for_Root_finite_geometry_source_integration_decision")!=true or not art_fields is Dictionary or art_fields.size()!=3: return {}
	if not art.get("actual_image_viewed") is Dictionary or art.actual_image_viewed.get("result_sha256_reported_by_Root")!=value.native_visual_report.sha256: return {}
	for key: String in art_fields:
		if not b().equal(art.get(key),art_fields[key]): return {}
	var proof: Dictionary=report.get("finite_proof",{})
	if not b().equal(proof,value.get("publication_finite_proof")) or proof.get("whole_scene_layout_inverse")!=true or proof.get("original_a2_finite_proof_wholetyped_retained")!=true or proof.get("Physics_Field_ART_or_runtime_credit")!=false: return {}
	if proof.get("parent_packet_sha256")!=parent.child["packet.bin"].sha256 or not b().equal(proof.get("author_delta"),value.author_delta) or not b().equal(proof.get("independent_prior"),value.independent_pixel_prior): return {}
	var counts: Dictionary={"old_visual_count":132,"old_solid_count":27,"new_visual_count":136,"new_solid_count":31,"ground_count_unchanged":118,"low_opaque_props":18}
	for key: String in counts:
		if not proof.get(key) is float or proof[key]!=float(counts[key]): return {}
	if not b().equal(value.get("inherited_a2_finite_proof"),parent.publication_finite_proof): return {}
	if not value.get("new_visual_ids") is Array or value.new_visual_ids.size()!=4 or not value.get("new_visual_rows") is Array or value.new_visual_rows.size()!=4: return {}
	var art_items: Variant=art.get("exact_admitted_items")
	if not art_items is Array or art_items.size()!=4: return {}
	for i: int in 4:
		if String(value.new_visual_ids[i])!=LIFE_IDS[i] or String(value.new_visual_rows[i].id)!=LIFE_IDS[i]: return {}
		var visual: Dictionary=value.new_visual_rows[i]
		if not b().equal(art_items[i],{"id":visual.id,"foot_px":visual.foot_px,"uniform_scale":visual.uniform_scale,"texture":visual.texture}): return {}
	var mask: Dictionary=proof.get("local_mask",{})
	if mask.get("whole_RGBA_inverse")!=true or mask.get("outside_all4_domains_exact")!=true or mask.get("domain_count")!=4.0 or mask.get("changed_pixels")!=6735.0 or mask.get("visited_pixels")!=8714.0: return {}
	if mask.get("child_rgba_sha256")!=value.get("child_rgba_sha256") or mask.get("parent_rgba_sha256")!=value.get("parent_rgba_sha256") or value.parent_rgba_sha256!=parent.child_rgba_sha256_from_fixed_independent_prior_and_Root_report: return {}
	var contract: Dictionary=value.get("publication_admission_contract",{})
	if contract.get("runtime_parent_packet_read_decode_clone")!=false or contract.get("runtime_mask_domain_or_875_replay")!=false or contract.get("fixed_Root59_whole_inverse_inherited")!=true or contract.get("exact_child_packet_SHA_then_existing_plain_kind_scene_whole_mask_SHA")!=true or contract.get("existing_whole_Scene_and_Layout_storage_equality")!=true or contract.get("existing_complete_shared_Quarter_FIRST_FINAL_unchanged")!=true or contract.get("whole_district_ART_Field_loading_or_ghost_credit")!=false: return {}
	for suffix: String in value.child:
		if report.get("artifacts",{}).get(value.child[suffix].path)!=value.child[suffix].sha256: return {}
	var imports: Variant=value.get("mask_import_source_sha256")
	var walk: String=String(value.child["walk.png"].path)
	var compiled: String="res://.godot/imported/walk.png-"+walk.md5_text()+".ctex"
	if not imports is Dictionary or imports.size()!=2 or not b()._hash(imports.get(walk+".import")) or not b()._hash(imports.get(compiled)): return {}
	if not value.get("source_sha256") is Dictionary or value.source_sha256.has(SELF) or value.source_sha256.has(LIFE_BINDING): return {}
	for path: String in value.source_sha256:
		if not path.begins_with("res://") or ".." in path or not b()._hash(value.source_sha256[path]): return {}
	_life_fixed_binding=value
	return _life_fixed_binding
static func _life_declared(data: Dictionary) -> bool: return data.has("artisan_life_successor")
static func _life_header_matches(data: Dictionary) -> bool:
	if not _life_declared(data): return true
	if not _a2_declared(data): return false
	var spec: Dictionary=_life_spec()
	if spec.is_empty(): return false
	var declaration: Variant=data.get("artisan_life_successor")
	if not declaration is Dictionary or declaration.size()!=2 or declaration.get("binding_path")!=LIFE_BINDING or declaration.get("binding_sha256")!=LIFE_BINDING_SHA or data.source_sha256.get(LIFE_BINDING)!=LIFE_BINDING_SHA: return false
	for path: String in spec.source_sha256:
		if data.source_sha256.get(path)!=spec.source_sha256[path]: return false
	for path: String in spec.mask_import_source_sha256:
		if data.source_sha256.get(path)!=spec.mask_import_source_sha256[path]: return false
	for key: String in ["root_art_admission"]:
		if data.source_sha256.get(spec[key].path)!=spec[key].sha256: return false
	for suffix: String in spec.child:
		if data.source_sha256.get(spec.child[suffix].path)!=spec.child[suffix].sha256: return false
	return true
static func _life_artifact_path(data: Dictionary,id: StringName,suffix: String) -> String:
	if id==IDS[0] and _life_declared(data):
		var spec: Dictionary=_life_spec()
		return String(spec.child[suffix].path) if not spec.is_empty() and spec.child.has(suffix) else ""
	return _a2_artifact_path(data,id,suffix)
static func _life_published_packet_valid(raw: Dictionary,data: Dictionary) -> bool:
	if not _life_header_matches(data): return false
	var spec: Dictionary=_life_spec();var parent: Dictionary=_a2_spec()
	if spec.is_empty() or parent.is_empty() or not raw.get("life_cluster_finite_proof") is Dictionary or not raw.get("a2_finite_proof") is Dictionary: return false
	# Only the small already-published finite proofs use their original JSON wire
	# representation. No parent packet or layout/mask inverse is replayed here.
	if not b().equal(b()._wire(raw.life_cluster_finite_proof),b()._wire(spec.publication_finite_proof)) or not b().equal(b()._wire(raw.a2_finite_proof),b()._wire(spec.inherited_a2_finite_proof)): return false
	var counts: Dictionary={"old_visual_count":132,"old_solid_count":27,"new_visual_count":136,"new_solid_count":31,"ground_count_unchanged":118,"low_opaque_props":18}
	for key: String in counts:
		if not raw.life_cluster_finite_proof.get(key) is int or raw.life_cluster_finite_proof[key]!=counts[key]: return false
	if raw.get("life_parent_packet_sha256")!=spec.parent["packet.bin"].sha256 or not b().equal(raw.get("life_author_delta"),spec.author_delta): return false
	if raw.get("parent_packet_sha256")!=parent.parent["packet.bin"].sha256 or raw.get("author_path")!=parent.author.path or raw.get("author_sha256")!=parent.author.sha256: return false
	if raw.get("mask_sha256")!=spec.child_rgba_sha256 or not raw.get("solids") is Array or raw.solids.size()!=31: return false
	for key: String in ["scene_storage","layout_storage"]:
		if not raw.get(key) is Dictionary or not raw[key].get("fields") is Dictionary: return false
	for key: String in ["visual_objects","blockers"]:
		if not raw.layout_storage.fields.get(key) is Dictionary or not raw.layout_storage.fields[key].get("array_values") is Array: return false
	return raw.layout_storage.fields.visual_objects.array_values.size()==136 and raw.layout_storage.fields.blockers.array_values.size()==31 and raw.layout_storage.fields.walkable_mask_path==spec.child["walk.png"].path and raw.scene_storage.fields.get("metadata/luoyang_artisan_life_delta")==spec.author_delta.sha256
static func _life_packet_from_bytes(bytes: PackedByteArray,data: Dictionary) -> Dictionary:
	var spec: Dictionary=_life_spec()
	if spec.is_empty() or b().bytes_sha(bytes)!=spec.child["packet.bin"].sha256: return {}
	var raw: Variant=bytes_to_var(bytes)
	if not raw is Dictionary or not b()._plain(raw) or raw.get("kind")!="AP_SOURCE_BOUND_NEW_ORDINARY_QUARTER" or raw.get("scene_id")!=String(IDS[0]) or not raw.get("walk_bytes") is PackedByteArray or b().bytes_sha(raw.walk_bytes)!=raw.get("mask_sha256"): return {}
	return raw if _life_published_packet_valid(raw,data) else {}
static func life_requested_scene(scene: SceneScript) -> bool:
	# Selection only; material install must still call life_source_bound_scene.
	return LIFE_READY and scene!=null and scene.scene_id==IDS[0] and _life_declared(source_header())
static func life_source_bound_scene(scene: SceneScript) -> bool:
	return life_requested_scene(scene) and matches(scene)
