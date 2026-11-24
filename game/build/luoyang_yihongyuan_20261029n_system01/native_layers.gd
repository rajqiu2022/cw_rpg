extends RefCounted
## Source-UV layers under the original Region lease. Never edits an image or physics.
static func complete_room_enclosure(field: Node,owner: RefCounted,region: Dictionary) -> bool:
	const SHELL := "res://art/modules/luoyang_assembled_interiors_20261016g/shell_inn_hall_v1.png"
	if region.get("id")!="yihongyuan27n_interior" or region.get("size")!=Vector2(1536,1024):return false
	if owner==null or not owner.matches(field,field.get("_current_scene")):return false
	if region.get("room_enclosure",{}).get("native_complete_shell")!=SHELL:return false
	return owner.receipt().get("source_first",{}).get(SHELL)==FileAccess.get_sha256(SHELL)
static func install(field: Node,owner: RefCounted,row: Dictionary,parent: Sprite2D) -> bool:
	var layers: Variant=row.get("yihongyuan_native_layers",[])
	if not layers is Array:return false
	if layers.is_empty():return true
	if not is_instance_valid(parent) or owner==null or not owner.matches(field,field.get("_current_scene")):return false
	var original: Dictionary=owner.get("_compiled")
	var selected: Array=original.get("render",[]).filter(func(candidate: Dictionary) -> bool:return candidate.get("key")==row.get("key"))
	if selected.size()!=1 or var_to_bytes(selected[0])!=var_to_bytes(row):return false
	var sources: Dictionary=owner.receipt().get("source_first",{})
	if sources.get(row.texture)!=FileAccess.get_sha256(row.texture) or parent.texture!=load(row.texture):return false
	if parent.position!=row.position_px or parent.scale!=row.scale or parent.centered:return false
	for descriptor: Dictionary in layers:
		if not descriptor.get("polygon") is PackedVector2Array or not descriptor.get("uv") is PackedVector2Array:return false
		if descriptor.polygon.size()<3 or descriptor.polygon.size()!=descriptor.uv.size():return false
		var polygon:=Polygon2D.new()
		polygon.name=String(descriptor.id)
		polygon.texture=parent.texture
		polygon.polygon=descriptor.polygon
		polygon.uv=descriptor.uv
		polygon.z_as_relative=false
		polygon.z_index=int(descriptor.z_index)
		parent.add_child(polygon)
	parent.self_modulate.a=0.0
	return true
