extends RefCounted
## Only old-valid feet hit by this garden's newly authored solids may relocate.
const Core=preload("res://build/luoyang_regions_20261027d_source01/region_compiler.gd")
const REGION:="luoyang_estate_region_27d"
const LOGICAL:="luoyang_estate_riverside_20261021ai"
const SPEC:="res://build/luoyang_estate_garden_20261029q_system01/garden_definition_READY.json"
const OLD:="res://build/luoyang_threshold_20261029o_system01/output/118016/luoyang_estate_region_27d.bin"
const OLD_SHA:="a3a1af2a473809638fd15ed2788c0a477a1ac17c65672856003cd2c4b0540561"
const TARGET:=Vector2(1536,1450)
static func arrive(compiled: Dictionary,logical: String,extension: Dictionary,refused: Dictionary) -> Dictionary:
	if refused.get("error")!="REGION_SAVED_FOOT_BLOCKED" or compiled.get("id")!=REGION or compiled.get("revision")!=1 or logical!=LOGICAL:return refused
	if extension.get("region_id")!=REGION or extension.get("logical_id")!=LOGICAL or extension.get("revision")!=1:return refused
	var pins: Dictionary=compiled.get("sources",{})
	if pins.get(SPEC)!=FileAccess.get_sha256(SPEC) or pins.get(OLD)!=OLD_SHA or FileAccess.get_sha256(OLD)!=OLD_SHA:return refused
	var declaration: Dictionary=compiled.get("garden29q_restore",{})
	if declaration.get("spec")!=SPEC or declaration.get("source_sha256")!=pins[SPEC] or declaration.get("target")!=TARGET:return refused
	var point: Vector2=Core.vec(extension.get("global_foot_px"))
	if not point.is_finite() or not Rect2(430,128,2212,1336).has_point(point) or Core.district_at(compiled,point)!=LOGICAL or Core.safe_body(compiled,point,Vector2(17,12)):return refused
	var indices: Variant=declaration.get("new_solid_indices")
	if not indices is Array or indices.is_empty():return refused
	var body:=PackedVector2Array([point-Vector2(17,12),point+Vector2(17,-12),point+Vector2(17,12),point+Vector2(-17,12)])
	var touches: bool=false
	for raw: Variant in indices:
		if not raw is int or raw<0 or raw>=compiled.solids.size():return refused
		if not Geometry2D.intersect_polygons(body,compiled.solids[raw]).is_empty():touches=true
	if not touches:return refused
	var previous: Variant=bytes_to_var(FileAccess.get_file_as_bytes(OLD))
	if not previous is Dictionary or previous.get("id")!=REGION or previous.get("revision")!=1 or not Core.safe_body(previous,point,Vector2(17,12)):return refused
	var doors: Array=compiled.portals.filter(func(row: Dictionary)->bool:return row.get("id")=="estate27q_hall_rear_door" and row.get("logical_id")==LOGICAL)
	if doors.size()!=1 or doors[0].get("return_foot")!=TARGET:return refused
	if not Core.safe_body(compiled,TARGET,Vector2(17,12)) or not Core.npc_route_clear(compiled,TARGET,TARGET,Vector2(17,12)):return refused
	return {"ok":true,"foot":TARGET,"reason":"estate29q_new_garden_solid_to_authored_rear_approach","logical_id":LOGICAL}
