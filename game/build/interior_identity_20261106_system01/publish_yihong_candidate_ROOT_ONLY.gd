extends SceneTree
## Typed compile proof from the actual accepted room only. Publishes into the
## isolated task folder, never switches a live manifest or imports an image.
const HOME := "res://build/interior_identity_20261106_system01/"
const Layout = preload(HOME + "room_layout_candidate.gd")
const Core = preload("res://build/luoyang_regions_20261027d_source01/region_compiler.gd")
const MANIFEST := "res://build/luoyang_regions_20261027d_source01/region_runtime_manifest_BUILD.json"
const OLD_MANIFEST_SHA := "91533bb8714a613eb6534657e71a650f6d519b1fa73dd1d33ff9907dc28ddec5"
const OLD_PACK := "res://build/luoyang_yihongyuan_20261029n_system01/visual03/output/60160/yihongyuan27n_interior.bin"
const OLD_PACK_SHA := "4871b3e428bedd5c0c4c06882d5ebe36cc1660824100adb648027f82dec31d65"
const OLD_ENCLOSURE := "res://art/modules/luoyang_assembled_interiors_20261016g/shell_inn_hall_v1.png"
const ROOM := "yihongyuan27n_interior"
const LOGICAL := "ch4_s3_luoyang_market"
const OLD_PROP_KEYS := [
	"yihongyuan_backstage_desk", "yihongyuan_gallery_stair_visual", "yihongyuan_guest_chair",
	"yihongyuan_public_table", "yihongyuan_quiet_table", "yihongyuan_reception_counter", "yihongyuan_tea_shelf"
]
const DONOR_REMAP := {
	"inn_hall_inn_counter_0": "yihongyuan_reception_counter",
	"inn_hall_dining_table_2": "yihongyuan_public_table",
	"inn_hall_dining_table_4": "yihongyuan_quiet_table",
	"mansion_reception_wood_armchair_5": "yihongyuan_guest_chair",
	"mansion_reception_writing_desk_4": "yihongyuan_backstage_desk",
}
const CHANGED_KEYS := ["surfaces","render","solids","solid_cells","npcs","room_enclosure","sources","interior_identity_20261106_candidate"]
var _errors: Array[String] = []
var _checks: int = 0
var _output: String

func _initialize() -> void:
	call_deferred("_run")

func _check(value: bool, label: String) -> bool:
	_checks += 1
	if not value:
		_errors.append(label)
		push_error(label)
	return value

func _json(path: String, value: Dictionary) -> void:
	var out := FileAccess.open(path,FileAccess.WRITE)
	if out == null: return
	out.store_string(JSON.stringify(value,"  ")+"\n")
	out.close()

func _rect(p: Vector2,s: Vector2) -> PackedVector2Array:
	return PackedVector2Array([p,p+Vector2(s.x,0),p+s,p+Vector2(0,s.y)])

func _pin(room: Dictionary,path: String) -> bool:
	var value := FileAccess.get_sha256(path)
	if value.length() != 64 or (room.sources.has(path) and room.sources[path] != value):
		return false
	room.sources[path] = value
	return true

func _row(id: String,path: String,origin: Vector2,size: Vector2,ratio: float,depth: int) -> Dictionary:
	return {
		"id":id,"owner_id":id,"key":LOGICAL+"/"+id,"logical_id":LOGICAL,
		"texture":path,"texture_size_px":size,"position_px":origin,"scale":Vector2.ONE*ratio,
		"foot_px":Vector2.ZERO,"centered":false,"source_row":{"sort_by_feet":false,"z_index":depth},
	}

func _shell(spec: Dictionary) -> Dictionary:
	var size := Vector2(1664,1152)
	var row := _row("yihongyuan_identity_native_shell",spec.shell,spec.shell_origin,size,1.0,-1000)
	# These source rectangles exactly partition the padded canvas. Lower floor
	# and front rails draw once each, avoiding duplicated semi-transparent RGB.
	var declarations := [
		[Rect2(0,0,1664,887),-1000], [Rect2(0,1082,1664,70),-1000],
		[Rect2(0,887,80,195),-1000], [Rect2(714,887,235,195),-1000],
		[Rect2(1584,887,80,195),-1000],
		[Rect2(80,887,634,195),300], [Rect2(949,887,635,195),300],
	]
	var layers: Array[Dictionary] = []
	var area := 0.0
	for i: int in range(declarations.size()):
		var rect: Rect2 = declarations[i][0]
		var poly := _rect(rect.position,rect.size)
		area += rect.get_area()
		layers.append({"id":"YihongNativePartition"+str(i),"polygon":poly,"uv":poly.duplicate(),"z_index":declarations[i][1]})
	_check(area == size.x*size.y,"NATIVE_SHELL_LAYER_PARTITION_AREA")
	row["yihongyuan_native_layers"] = layers
	return row

func _wall_bands(floor: PackedVector2Array) -> Array[PackedVector2Array]:
	return [
		_rect(Vector2.ZERO,Vector2(1536,floor[0].y)),
		PackedVector2Array([Vector2(0,floor[0].y),floor[0],floor[7],Vector2(0,floor[7].y)]),
		PackedVector2Array([floor[1],Vector2(1536,floor[1].y),Vector2(1536,floor[2].y),floor[2]]),
		_rect(Vector2(0,floor[6].y),Vector2(floor[6].x,1024-floor[6].y)),
		_rect(floor[3],Vector2(1536-floor[3].x,1024-floor[3].y)),
		_rect(floor[5],Vector2(floor[4].x-floor[5].x,1024-floor[5].y)),
	]

func _verify_input(room: Dictionary) -> bool:
	if not _check(Core.plain(room) and room.get("id")==ROOM and room.get("size")==Vector2(1536,1024) and room.get("schema")==Core.SCHEMA and room.get("ok")==true,"OLD_ROOM_BIN_IDENTITY"): return false
	if not _check(room.get("navigation_kind")=="AUTHORED_INTERIOR" and room.room_enclosure.get("native_complete_shell")==OLD_ENCLOSURE and room.surfaces.size()==1 and room.surfaces[0].texture==OLD_ENCLOSURE,"OLD_NATIVE_ENCLOSURE_SURFACE"): return false
	if not _check(room.portals.size()==1 and room.portals[0].foot==Vector2(768,920) and Core.vec(room.portals[0].data.get("region27d_target",{}).get("foot_px"))==Vector2(5206.18,4280),"EXACT_OLD_DOOR_AND_RETURN"): return false
	if not _check(room.npcs.size()==6 and room.yihongyuan_daily.size()==4 and room.future_story_anchors.size()==3,"OLD_ROOM_DECLARED_BUSINESS"): return false
	for anchor: Dictionary in room.future_story_anchors:
		if not _check(anchor.get("enabled")==false,"OLD_STORY_ANCHOR_INACTIVE"): return false
	var keys: Array = []
	for row: Dictionary in room.render: keys.append(row.get("owner_id",""))
	keys.sort()
	return _check(keys==OLD_PROP_KEYS,"EXACT_SEVEN_OLD_PROP_OWNERS")

func _assemble(before: Dictionary,spec: Dictionary) -> Dictionary:
	var room: Dictionary = before.duplicate(true)
	room.surfaces = []
	room.render = [_shell(spec)]
	room.solids = []
	room.solid_cells = {}
	var walls: Array[PackedVector2Array] = _wall_bands(spec.floor)
	for wall: PackedVector2Array in walls: Core._append_solid(room,wall)
	room.room_enclosure["wall_ground_polygons_px"] = walls
	room.room_enclosure["native_complete_shell"] = spec.shell
	room["interior_identity_20261106_candidate"] = {"room_id":ROOM,"candidate_only":true,"retired_prop_ids":["yihongyuan_gallery_stair_visual","yihongyuan_tea_shelf"]}
	for path: String in [spec.shell,Layout.RUG,HOME+"room_layout_candidate.gd",Layout.ART+"shell_processing_receipt.json",Layout.ART+"women_processing_receipt.json"]:
		if not _check(_pin(room,path),"PIN_CANDIDATE_MEDIA_OR_AUTHOR:"+path): return {}
	for item: Dictionary in spec.furniture:
		if not _check(DONOR_REMAP.has(item.get("donor_id")) and _pin(room,item.texture),"PIN_EXACT_PROP_DONOR"): return {}
		var id: String = DONOR_REMAP[item.donor_id]
		var original: Array = before.render.filter(func(row: Dictionary) -> bool: return row.owner_id==id and row.texture==item.texture)
		if not _check(original.size()==1,"ONE_ORIGINAL_PROP_ROLE:"+id): return {}
		var row: Dictionary = original[0].duplicate(true)
		row.position_px=item.origin;row.foot_px=item.foot;row.scale=Vector2.ONE*float(item.scale)
		room.render.append(row)
		for solid: PackedVector2Array in item.solids: Core._append_solid(room,solid)
	var rect: Rect2 = spec.flat_rug
	var content := Rect2(108,190,1687,646)
	var ratio := minf(rect.size.x/content.size.x,rect.size.y/content.size.y)
	var top := rect.get_center()-content.size*ratio*0.5-content.position*ratio
	room.render.append(_row("yihongyuan_performance_rug",Layout.RUG,top,Vector2(1902,1015),ratio,-985))
	var matched: int = 0
	for actor: Dictionary in spec.actors:
		if not _check(not actor.is_empty(),"EXPLICIT_ACTOR"): return {}
		var previous: Array = room.npcs.filter(func(row: Dictionary) -> bool: return row.data.npc_id==actor.id)
		if previous.size()==1:
			previous[0].foot = actor.foot
			matched += 1
		elif previous.is_empty() and actor.has("cell") and actor.has("native_height"):
			if not _check(_pin(room,actor.texture),"PIN_EXACT_NEW_ACTOR:"+actor.id): return {}
			var scale: float = float(actor.height)/float(actor.native_height)
			var data: Dictionary = {"npc_id":actor.id,"npc_name":actor.name,"sprite_path":actor.texture,"portrait_path":"","dialog_id":"","interaction_action":"","scale":scale,"movement_mode":actor.movement_mode,"idle_frame_seconds":actor.idle_frame_seconds,"conversation_base_facing":"front","dialog_variants":[]}
			room.npcs.append({"data":data,"foot":actor.foot,"logical_id":LOGICAL,"slot_key":LOGICAL+"/"+actor.id,"ground_anchored":true,"body_offset_px":Vector2.ZERO,"half_body":actor.cell*Vector2(0.07,0.09)*scale,"default_active":true})
		else:
			_check(false,"ACTOR_SLOT_NOT_UNIQUE_OR_AUTHORED"); return {}
	if not _check(matched==6 and room.npcs.size()==10,"OLD_SIX_PLUS_FOUR"): return {}
	return room

func _verify_output(before: Dictionary,room: Dictionary,spec: Dictionary) -> bool:
	var inverse: Dictionary = room.duplicate(true)
	for key: String in CHANGED_KEYS:
		if before.has(key): inverse[key] = before[key]
		else: inverse.erase(key)
	_check(var_to_bytes(inverse)==var_to_bytes(before),"ALL_UNOWNED_FIELDS_TYPED_IDENTICAL")
	for i: int in range(6):
		var actor: Dictionary = room.npcs[i].duplicate(true)
		actor.foot=before.npcs[i].foot
		_check(var_to_bytes(actor)==var_to_bytes(before.npcs[i]),"OLD_ACTOR_ONLY_FOOT_MAY_CHANGE:"+actor.data.npc_id)
	for actor: Dictionary in room.npcs:
		_check(Core.safe_body(room,actor.foot,actor.half_body),"ACTOR_CLEAR_COMPILED_FOOT:"+actor.data.npc_id)
	var steps: Array[Vector2] = [spec.exit,spec.entry,Vector2(spec.entry.x,spec.counter_approach.y),spec.counter_approach]
	for i: int in range(steps.size()-1):
		_check(Core.safe_segment(room,steps[i],steps[i+1],Layout.BODY_HALF) and Core.npc_route_clear(room,steps[i],steps[i+1],Layout.BODY_HALF),"COMPILED_PLAYER_ROUTE_SEGMENT:"+str(i))
	_check(Core.plain(room),"ONLY_PLAIN_TYPED_DATA")
	return _errors.is_empty()

func _run() -> void:
	_output = HOME+"publish_candidate_actual/"+str(OS.get_process_id())+"/"
	DirAccess.make_dir_recursive_absolute(_output)
	if not _check(FileAccess.get_sha256(MANIFEST)==OLD_MANIFEST_SHA,"EXACT_CURRENT_REGION_MANIFEST"):
		_finish(); return
	var manifest: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(MANIFEST))
	var current: Dictionary = manifest.compiled_bindings.get(ROOM,{})
	if not _check(current.get("path")==OLD_PACK and current.get("sha256")==OLD_PACK_SHA and FileAccess.get_sha256(OLD_PACK)==OLD_PACK_SHA,"EXACT_CURRENT_ROOM_BINDING"):
		_finish(); return
	var raw := FileAccess.get_file_as_bytes(OLD_PACK)
	var before: Variant = bytes_to_var(raw)
	if not _check(raw.size()==int(current.get("bytes",-1)) and before is Dictionary,"EXACT_OLD_PACK_LENGTH_AND_TYPE") or not _verify_input(before):
		_finish(); return
	var spec: Dictionary = Layout.compose_room(ROOM)
	if not _check(not spec.is_empty(),"AUTHOR_DATA_COMPOSE"):
		_finish(); return
	var room := _assemble(before,spec)
	if room.is_empty() or not _verify_output(before,room,spec):
		_finish(); return
	var path := _output+"payload_CANDIDATE.bin"
	var data := var_to_bytes(room)
	var output := FileAccess.open(path,FileAccess.WRITE)
	if not _check(output!=null,"ISOLATED_OUTPUT_OPEN"):
		_finish(); return
	output.store_buffer(data);output.close()
	_check(var_to_bytes(bytes_to_var(FileAccess.get_file_as_bytes(path)))==data,"CANDIDATE_TYPED_DISK_ROUNDTRIP")
	# This is an inert manifest specimen; no consumer points to it and its
	# adoption flag is explicitly false. It preserves all nine unrelated bins.
	var shadow := manifest.duplicate(true)
	shadow.adoption_enabled = false
	shadow.compiled_bindings[ROOM]={"path":path,"bytes":data.size(),"sha256":FileAccess.get_sha256(path)}
	for id: String in manifest.compiled_bindings:
		if id==ROOM: continue
		_check(var_to_bytes(shadow.compiled_bindings[id])==var_to_bytes(manifest.compiled_bindings[id]),"OTHER_ROOM_BINDING_EXACT:"+id)
	_json(_output+"manifest_INERT.json",shadow)
	_finish({"candidate_bin":path,"candidate_sha256":FileAccess.get_sha256(path),"typed_candidate":true,"imported_media":false})

func _finish(extra: Dictionary = {}) -> void:
	var report: Dictionary = {"checks":_checks,"failures":_errors,"candidate_only":true,"production_writes":0,"real_field":false,"real_save_content_access":false}
	report.merge(extra,true)
	_json(_output+"result.json",report)
	print(JSON.stringify(report))
	quit(0 if _errors.is_empty() else 1)
