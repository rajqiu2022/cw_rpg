extends RefCounted
## Exact new-door compatibility only. No user save contents or nearest search.
const Core=preload("res://build/luoyang_regions_20261027d_source01/region_compiler.gd")
const REGION:="luoyang_estate_region_27d"
const LOGICAL:="luoyang_estate_riverside_20261021ai"
const SPEC:="res://build/luoyang_threshold_20261029o_system01/repair_definition_READY.json"
const OLD:="res://build/luoyang_regions_20261027d_source01/visual_finish04_BUILD/output/67124/luoyang_estate_region_27d.bin"
const OLD_SHA:="07d64efe26073bc666d04916d2539c7e3b63ed2d5526068f413f823f527a4e22"
const TARGET:=Vector2(1536,2060)
static func arrive(compiled: Dictionary,logical: String,extension: Dictionary,refused: Dictionary) -> Dictionary:
	if refused.get("error")!="REGION_SAVED_FOOT_BLOCKED" or compiled.get("id")!=REGION or compiled.get("revision")!=1 or logical!=LOGICAL:return refused
	if extension.get("region_id")!=REGION or extension.get("logical_id")!=LOGICAL or extension.get("revision")!=1:return refused
	var source: Dictionary=compiled.get("sources",{})
	if source.get(SPEC)!=FileAccess.get_sha256(SPEC) or source.get(OLD)!=OLD_SHA or FileAccess.get_sha256(OLD)!=OLD_SHA:return refused
	var declaration: Dictionary=compiled.get("threshold29o",{})
	if declaration.get("spec")!=SPEC or declaration.get("source_sha256")!=source[SPEC]:return refused
	var spec: Dictionary=JSON.parse_string(FileAccess.get_file_as_string(SPEC))
	if spec.get("region_id")!=REGION or spec.get("logical_id")!=LOGICAL or spec.get("owner_id")!="estate_ak_main_hall" or spec.get("portal_id")!="estate27d_hall_door":return refused
	var quad:=PackedVector2Array()
	for raw: Variant in spec.get("new_threshold_polygon_px",[]):quad.append(Core.vec(raw))
	if quad.size()!=4 or not compiled.solids.any(func(p: PackedVector2Array)->bool:return var_to_bytes(p)==var_to_bytes(quad)):return refused
	var point: Vector2=Core.vec(extension.get("global_foot_px"))
	if not point.is_finite() or Core.district_at(compiled,point)!=LOGICAL or Core.safe_body(compiled,point,Vector2(17,12)):return refused
	var body:=PackedVector2Array([point-Vector2(17,12),point+Vector2(17,-12),point+Vector2(17,12),point+Vector2(-17,12)])
	if Geometry2D.intersect_polygons(body,quad).is_empty():return refused
	var previous: Variant=bytes_to_var(FileAccess.get_file_as_bytes(OLD))
	if not previous is Dictionary or previous.get("id")!=REGION or previous.get("revision")!=1 or not Core.safe_body(previous,point,Vector2(17,12)):return refused
	var doors: Array=compiled.portals.filter(func(row: Dictionary)->bool:return row.get("id")=="estate27d_hall_door" and row.get("logical_id")==LOGICAL)
	if doors.size()!=1 or doors[0].get("return_foot")!=TARGET:return refused
	if not Core.safe_body(compiled,TARGET,Vector2(17,12)) or not Core.npc_route_clear(compiled,TARGET,TARGET,Vector2(17,12)):return refused
	return {"ok":true,"foot":TARGET,"reason":"estate29o_exact_old_door_gap_to_authored_approach","logical_id":LOGICAL}
