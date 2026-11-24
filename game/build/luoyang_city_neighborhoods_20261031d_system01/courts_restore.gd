extends RefCounted
## Only old-valid Market feet hit by a new31d annex/house may move to its court.
const Core=preload("res://build/luoyang_regions_20261027d_source01/region_compiler.gd")
const SPEC="res://build/city_neighborhoods_20261031d/luoyang_courts.json"
const OLD="res://build/luoyang_yihongyuan_20261029n_system01/visual03/output/60160/luoyang_civic_market_region_27d.bin"
const OLD_SHA="c0a84079257b5bb2e5f8001144b5fbdf1067b2463c705eb0d4d8badfcb67d4a4"
const REGION="luoyang_civic_market_region_27d"
const LOGICAL="ch4_s3_luoyang_market"
static func arrive(compiled: Dictionary,logical: String,extension: Dictionary,refused: Dictionary) -> Dictionary:
	if refused.get("error")!="REGION_SAVED_FOOT_BLOCKED" or compiled.get("id")!=REGION or compiled.get("revision")!=1 or logical!=LOGICAL:return refused
	if extension.get("region_id")!=REGION or extension.get("logical_id")!=LOGICAL or extension.get("revision")!=1:return refused
	var pins: Dictionary=compiled.get("sources",{})
	if pins.get(SPEC)!=FileAccess.get_sha256(SPEC) or pins.get(OLD)!=OLD_SHA or FileAccess.get_sha256(OLD)!=OLD_SHA:return refused
	var declaration: Dictionary=compiled.get("courts31d_restore",{})
	var indices: Variant=declaration.get("new_solid_indices")
	var rows: Variant=declaration.get("rows")
	if declaration.get("spec")!=SPEC or declaration.get("source_sha256")!=pins[SPEC] or declaration.get("parent")!=OLD or declaration.get("parent_sha256")!=OLD_SHA:return refused
	if not indices is Array or not rows is Array or indices.size()!=4 or rows.size()!=4:return refused
	var point: Vector2=Core.vec(extension.get("global_foot_px"))
	if not point.is_finite() or Core.district_at(compiled,point)!=LOGICAL or Core.safe_body(compiled,point,Vector2(17,12)):return refused
	var previous: Variant=bytes_to_var(FileAccess.get_file_as_bytes(OLD))
	if not previous is Dictionary or previous.get("id")!=REGION or previous.get("revision")!=1 or not Core.safe_body(previous,point,Vector2(17,12)) or not Core.npc_route_clear(previous,point,point,Vector2(17,12)):return refused
	var body:=PackedVector2Array([point-Vector2(17,12),point+Vector2(17,-12),point+Vector2(17,12),point+Vector2(-17,12)])
	for i: int in range(4):
		var index: Variant=indices[i]
		if not index is int or index<0 or index>=compiled.solids.size() or not rows[i] is Dictionary:return refused
		var row: Dictionary=rows[i]
		if not row.get("polygon") is PackedVector2Array or var_to_bytes(row.polygon)!=var_to_bytes(compiled.solids[index]):return refused
		if Geometry2D.intersect_polygons(body,row.polygon).is_empty():continue
		var target: Variant=row.get("restore")
		if not target is Vector2 or Core.district_at(compiled,target)!=LOGICAL or not Core.safe_body(compiled,target,Vector2(17,12)) or not Core.npc_route_clear(compiled,target,target,Vector2(17,12)):return refused
		return {"ok":true,"foot":target,"reason":"market31d_new_complete_building_to_its_authored_workcourt","logical_id":LOGICAL}
	return refused
