extends "res://tests/helpers/v15_field_raw_oracle.gd"
## NEW joint sibling. Legacy fields retain the exact original PNG/polygon
## sampler. New city solids come independently from the current frozen raw
## manifest, never from Field clearance or its scoped rendering dictionaries.
const CITY_ROOT: String = "res://art/maps/luoyang_modular_v3_street_detail_proposal/root_material_v1/"
const CITY_IDS: Array[String] = ["ch4_s0_luoyang_gate","ch4_s1_luoyang_yamen","ch4_s2_canal_docks","ch4_s3_luoyang_market"]
var source_record: Dictionary = {}
var source_manifest_path: String = ""
var source_manifest_sha256: String = ""

func configure_city(scene: SceneScript, candidate: bool) -> bool:
	release()
	errors.clear()
	source_record.clear()
	if scene==null or scene.map_layout==null or String(scene.scene_id) not in CITY_IDS:
		errors.append("not an exact joint city identity")
		return false
	source_manifest_path=CITY_ROOT+String(scene.scene_id)+"/art_contract.json"
	source_manifest_sha256=FileAccess.get_sha256(source_manifest_path)
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(source_manifest_path)) if FileAccess.file_exists(source_manifest_path) else null
	if not parsed is Dictionary or parsed.get("canonical_scene_id")!=String(scene.scene_id) or parsed.get("status") not in ["ART_CANDIDATE_REQUIRES_FIELD_VISUAL_QA","PRODUCTION_APPROVED"]:
		errors.append("new city source NOT_READY or wrong identity")
		return false
	var record: Dictionary = parsed
	var catalog: Variant = record.get("asset_sha256")
	if not catalog is Dictionary or catalog.is_empty():
		errors.append("new city has no independently readable asset catalog")
		return false
	for path: Variant in catalog:
		if not path is String or not path.begins_with("res://") or ".." in path or not catalog[path] is String or catalog[path].length()!=64 or not FileAccess.file_exists(path) or FileAccess.get_sha256(path).to_lower()!=String(catalog[path]).to_lower():
			errors.append("new city current source bytes mismatch: "+str(path))
	var ordinary_size: Vector2 = Vector2(scene.map_layout.design_size)
	if ordinary_size!=Vector2(3072,2048) or scene.map_layout.schema_version!=3 or record.get("pixel_sampling")!="round_world_pixel" or float(record.get("physical_navigation_margin_px",-1))!=0:
		errors.append("new city must explicitly declare ordinary3072/full-body/direct-round/margin0")
	var expected_scene: String = "res://data/scenes/%s.tres"%scene.scene_id
	var expected_candidate: String = "res://data/scenes/luoyang_v3_candidates/%s.tres"%scene.scene_id
	var materialized: bool = candidate and scene.resource_path.is_empty() and scene.get_meta("luoyang_layered_revision",0)==3 and scene.get_meta("city_manifest_sha","")==source_manifest_sha256
	if scene.resource_path!=expected_scene and not (candidate and scene.resource_path==expected_candidate) and not materialized:
		errors.append("new city scene is neither exact formal/candidate path nor SHA-bound explicit candidate clone")
	if scene.background_path!=record.get("ground_path") or scene.map_layout.walkable_mask_path!=record.get("walk_path"):
		errors.append("actual city background/nav differ from frozen current manifest")
	var objects: Variant = record.get("objects")
	if not objects is Array or objects.is_empty():
		errors.append("new city independent solids missing")
		return false
	var declarations: Array[Dictionary] = []
	var ids: Dictionary = {}
	for raw_object: Variant in objects:
		if not raw_object is Dictionary:
			errors.append("invalid source object")
			continue
		var object: Dictionary = raw_object
		var id: String = String(object.get("id",""))
		var polygons: Variant = object.get("solid_polygons_px")
		var extent: Vector2 = _pair(object.get("collision_size_px"))
		var center: Vector2 = _pair(object.get("physical_center_px"))
		if id.is_empty() or ids.has(id) or typeof(object.get("blocking"))!=TYPE_BOOL or not polygons is Array or not extent.is_finite() or not center.is_finite() or extent.x<0 or extent.y<0 or (extent.x==0)!=(extent.y==0):
			errors.append("malformed/duplicate source physical object: "+id)
			continue
		ids[id]=true
		var has_rectangle: bool = extent.x>0
		if bool(object.blocking)!=(has_rectangle or not polygons.is_empty()) or (has_rectangle and not polygons.is_empty()):
			errors.append("source blocking identity mismatch or double collider: "+id)
			continue
		if not bool(object.blocking): continue
		if has_rectangle:
			declarations.append({"id":id,"pos":center/ordinary_size,"collision_size":extent/ordinary_size,"collision_offset":Vector2.ZERO})
		else:
			var actual_polygons: Array[PackedVector2Array] = []
			for value: Variant in polygons:
				var polygon: PackedVector2Array = PackedVector2Array()
				if value is Array:
					for vertex: Variant in value: polygon.append(_pair(vertex))
				actual_polygons.append(polygon)
			declarations.append({"id":id,"solid_polygons_px":actual_polygons})
	if not errors.is_empty(): return false
	var owned_layout: Resource = scene.map_layout.duplicate(true)
	owned_layout.set("visual_objects",declarations)
	# Legacy blockers are forbidden here, not silently inherited or removed.
	if not (owned_layout.get("blockers") as Array).is_empty():
		errors.append("new city inherited old source blockers")
		return false
	var good: bool = super.configure(owned_layout,"round_world_pixel",0.0)
	owned_layout=null
	if good: source_record=record.duplicate(true)
	return good

func _pair(value: Variant) -> Vector2:
	if value is Vector2: return value
	if value is Array and value.size()==2 and typeof(value[0]) in [TYPE_INT,TYPE_FLOAT] and typeof(value[1]) in [TYPE_INT,TYPE_FLOAT]: return Vector2(float(value[0]),float(value[1]))
	return Vector2(INF,INF)
