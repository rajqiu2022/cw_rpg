extends "res://scripts/dev/luoyang_modular_v3_source.gd"
## SOURCE ONLY note-placement revision. All original 73 city objects are retained.
## The low rolled scroll is independent RGBA, not a collider, table, or walk support.
const NOTE_REGION := "ch4_s3_luoyang_market"
const NOTE_ID := "xuantong_note_scroll"
const NOTE_ACTION := "discover_readable:xuantong_scale_weave_note:found_xuantong_scale_weave_note"
const NOTE_SOURCE := "res://art/props/interactive/expansion_v1/manual_supreme_scroll_v1.png"
const NOTE_SHA := "afd31fa91d7086c80a86bae0fdf7ac3afd1c716d39304cd864c8919c61c23e2f"
const NOTE_MEASUREMENT := "res://scripts/dev/luoyang_wall_v5_note_scroll_measurement.json"
const NOTE_MEASUREMENT_SHA := "32d09fb8433e5ec45fef990e5b16bed3edb163cc3b4a609cebdf62e19ebd6093"
const NOTE_OLD_SOURCE := "res://scripts/dev/luoyang_modular_v3_source.gd"
const NOTE_OLD_SOURCE_SHA := "3a6f96cd823eb5e3f6d3b4fb1801d5e90342ed020ab293d3a578ccac048dbad5"
const NOTE_ARCHIVE := "res://build/luoyang_wall_v5_market_before_note_fix_20261004_01/"
const NOTE_OLD_MANIFEST := NOTE_ARCHIVE+"inputs/game/art/maps/luoyang_modular_v3_wall_street_proposal/root_wall_v5/ch4_s3_luoyang_market/art_contract.json"
const NOTE_OLD_MANIFEST_SHA := "260a526e6232e4600c91653033c3a5f398c30a6c4f4bff882143124ffc945fc7"
const NOTE_STAND := Vector2(2440,1100)
const NOTE_FOOT := Vector2(2440,1060)
const NOTE_FOOT_UV := Vector2(126.0/512.0,439.0/512.0)
const NOTE_RENDER := Vector2(64,64)
const NOTE_POLYGON := [[2402,1080],[2478,1080],[2478,1120],[2402,1120]]
var note_revision: Dictionary = {}

func prepare(value: String = NOTE_REGION) -> void:
	note_revision.clear()
	if FileAccess.get_sha256(NOTE_OLD_SOURCE)!=NOTE_OLD_SOURCE_SHA or FileAccess.get_sha256(NOTE_OLD_MANIFEST)!=NOTE_OLD_MANIFEST_SHA or FileAccess.get_sha256(NOTE_MEASUREMENT)!=NOTE_MEASUREMENT_SHA or FileAccess.get_sha256(NOTE_SOURCE)!=NOTE_SHA:
		preparation_error="Frozen note authoring/archive/measurement changed"
		return
	super.prepare(value)
	if preparation_error!="" or value!=NOTE_REGION:
		preparation_error="This independent source is ONLY the market note revision"
		return
	var measurement: Variant=JSON.parse_string(FileAccess.get_file_as_string(NOTE_MEASUREMENT))
	var image: Image=Image.load_from_file(NOTE_SOURCE)
	if not measurement is Dictionary or image==null or image.get_size()!=Vector2i(512,512) or measurement.get("source_sha256")!=NOTE_SHA or measurement.get("source_bytes_modified")!=false or measurement.get("foot_source_px")!=[126.0,439.0] or measurement.get("click_source_px")!=[250.0,320.0]:
		preparation_error="Measured scroll source identity/foot/click missing"
		return
	var contact: Color=image.get_pixel(126,439)
	var click: Color=image.get_pixel(250,320)
	if contact.to_rgba32()!=0x3c4326ff or click.to_rgba32()!=0x786e61ff:
		preparation_error="Actual scroll contact/click RGBA differs"
		return
	var old_count: int=objects.size()
	var changed: int=0
	for slot: Dictionary in gameplay_slots.interactions:
		if slot.get("source_id")!="xuantong_note": continue
		if slot.get("object_id")!="shop" or Vector2(slot.stand_px[0],slot.stand_px[1])!=Vector2(2440,950):
			preparation_error="Original exact note slot differs"
			return
		slot.object_id=NOTE_ID
		slot.stand_px=[NOTE_STAND.x,NOTE_STAND.y]
		slot.interaction_polygon_px=NOTE_POLYGON.duplicate(true)
		changed+=1
	var anchor_count: int=0
	for anchor: Dictionary in anchors:
		if anchor.get("id")=="xuantong_note":
			anchor.point_px=[NOTE_STAND.x,NOTE_STAND.y]
			anchor_count+=1
	if changed!=1 or anchor_count!=1:
		preparation_error="Original note slot/anchor not unique"
		return
	objects.append({"id":NOTE_ID,"prototype":"","texture":NOTE_SOURCE,"source":NOTE_SOURCE,"original_source":NOTE_SOURCE,"original_source_sha256":NOTE_SHA,"source_sha256":NOTE_SHA,"source_size_px":[512,512],"render_size_px":[64,64],"foot_uv":[NOTE_FOOT_UV.x,NOTE_FOOT_UV.y],"world_foot_px":[2440,1060],"depth_foot_y":1060,"physical_center_px":[2440,1060],"collision_size_px":[0,0],"solid_polygons_px":[],"blocking":false,"ghost_occlusion":true,"sort_by_feet":true,"walk_support":false,"nature":"project_existing_original_independent_low_scroll","source_semantics":measurement.duplicate(true),"note_provenance_document":NOTE_MEASUREMENT,"source_attribution":"Existing project-authored original; generator provenance not independently recovered; NOT CC0. Byte-exact PNG with no alpha cropping.","doorstep_visual_review_status":"PENDING_FIELD_REVIEW"})
	_compile_solids()
	note_revision={"identity":"EXACT_XUANTONG_NOTE_SCROLL_PLACEMENT_V1","scope":"ONLY_MARKET_NOTE_SPATIAL_BINDING_AND_ONE_INDEPENDENT_RGBA_PROP_NOT_GAMEPLAY_OR_FORMAL_APPROVAL","previous_manifest":{"path":NOTE_OLD_MANIFEST,"sha256":NOTE_OLD_MANIFEST_SHA},"old_source":{"path":NOTE_OLD_SOURCE,"sha256":NOTE_OLD_SOURCE_SHA},"source_id":"xuantong_note","original_action":NOTE_ACTION,"previous_object_id":"shop","previous_stand_px":[2440,950],"object_id":NOTE_ID,"stand_px":[2440,1100],"interaction_polygon_px":NOTE_POLYGON.duplicate(true),"world_foot_px":[2440,1060],"measurement":{"path":NOTE_MEASUREMENT,"sha256":NOTE_MEASUREMENT_SHA},"source":{"path":NOTE_SOURCE,"sha256":NOTE_SHA},"old_objects":old_count,"new_objects":objects.size(),"npc_positions_unchanged":true,"routes_solids_navigation_unchanged":true,"original_actions_flags_unchanged":true,"physical_scope":"Nonblocking small scroll; zero collision remains zero, independent actor-foot/Y/actual-alpha still require actual Field QA","visual_approved":false,"field_executed":false,"production_approved":false}
	if not _note_clearance_forecast():
		preparation_error="New note approach violates original solids/NPC interaction clearance"
		return

func _note_clearance_forecast() -> bool:
	# All corners and inclusive 77x41 approach centres: full17 + full34x24.
	# NPC separation uses the existing 160x160 Area and 118px normal interaction,
	# NOT a smaller body or increased range. Source forecast is NOT Physics proof.
	for x in range(2402,2479):
		for y in range(1080,1121):
			var p:=Vector2(x,y)
			if not foot_clear(p) or not physical_clear(p): return false
			for npc: Dictionary in gameplay_slots.npcs:
				var n:=Vector2(npc.foot_px[0],npc.foot_px[1])
				if p.distance_to(n)<=118.0 or Rect2(p-Vector2(17,12),Vector2(34,24)).intersects(Rect2(n-Vector2(80,80),Vector2(160,160)),true): return false
	# Existing continuous east-west route joins the authored stand by <=4px probes.
	for y in range(1060,1101,4):
		if not foot_clear(Vector2(2440,y)) or not physical_clear(Vector2(2440,y)): return false
	return true

func snapshot() -> Dictionary:
	var result: Dictionary=super.snapshot()
	result["note_placement_revision"]=note_revision.duplicate(true)
	return result

func forecast() -> Dictionary:
	var result: Dictionary=super.forecast()
	var clear: bool=preparation_error=="" and not note_revision.is_empty() and _note_clearance_forecast()
	if not clear: result.failures.append({"note_placement":preparation_error if preparation_error!="" else "approach/NPC clearance"})
	result.passed=result.failures.is_empty()
	result["note_placement_revision"]=note_revision.duplicate(true)
	result["note_source_and_npc_clearance_only_not_actual_physics"]=clear
	return result

