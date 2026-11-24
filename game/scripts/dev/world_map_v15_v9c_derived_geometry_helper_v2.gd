extends "res://scripts/dev/world_map_v15_v9c_derived_geometry_helper.gd"

## Independent SOURCE-ONLY protection-schema correction. The failed first helper
## remains immutable. Nonblocking low plants have visual/native support extents,
## not invented collision bodies. RF/mesh/selector derivation is the exact parent.
const ORIGINAL_HELPER_PATH := "res://scripts/dev/world_map_v15_v9c_derived_geometry_helper.gd"
const ORIGINAL_HELPER_SHA := "f4ae092bdfa6b09fe9e2cfa40e73508f5c0ff2d43d5956d1011287fc9d91d982"
const EXPECTED_FAMILIES := {
	"compound_measured_solids":16, "bridge_deck_actual_bounds":5,
	"bridge_post_actual_bounds":78, "bridge_rail_actual_bounds":10,
	"boulder_actual_fullxz":46, "tree_actual_collider":655,
	"bamboo_actual_collider":1517, "herb_nonblocking_render_and_native_support":360,
}
var _catalog_v2: Dictionary = {}
var _verified_paths_v2: Dictionary = {}
var _image_sizes_v2: Dictionary = {}
var _verified_geometry_v2: Dictionary = {}
var _family_counts_v2: Dictionary = {}
var _footprint_rows_v2: Array[Dictionary] = []

func derive(source: RefCounted, baseline_objects: Array, output_dir: String) -> Dictionary:
	_catalog_v2.clear()
	_verified_paths_v2.clear()
	_image_sizes_v2.clear()
	_verified_geometry_v2.clear()
	_family_counts_v2.clear()
	_footprint_rows_v2.clear()
	if FileAccess.get_sha256(ORIGINAL_HELPER_PATH).to_lower() != ORIGINAL_HELPER_SHA:
		return _failure("Immutable original derivation helper changed")
	if FileAccess.get_sha256(BASELINE_MANIFEST).to_lower() != BASELINE_PINS[BASELINE_MANIFEST]:
		return _failure("Frozen original body catalog changed")
	var manifest: Variant = JSON.parse_string(FileAccess.get_file_as_string(BASELINE_MANIFEST))
	if not manifest is Dictionary or not manifest.get("asset_sha256") is Dictionary:
		return _failure("Missing exact body asset catalog")
	_catalog_v2 = manifest.asset_sha256
	return super.derive(source,baseline_objects,output_dir)

func _prepare_protection(record: Dictionary, objects: Array) -> bool:
	var compounds: Dictionary = {}
	var ids: Dictionary = {}
	for portal: Dictionary in record.portals:
		var p: Vector2 = _v2(portal.get("source_XZ_foot_px"))
		if not p.is_finite(): error="Missing measured source door"; return false
		compounds[portal.compound_id] = p
		_add_rect("door_"+String(portal.id),Rect2(p-Vector2(64,64),Vector2(128,208)))
	for object: Dictionary in objects:
		var oid: String = String(object.get("id",""))
		if oid.is_empty() or ids.has(oid): error="Missing/duplicate original body ID"; return false
		ids[oid]=true
		var foot: Vector2 = _v2(object.get("source_XZ_foot_px"))
		var family := ""
		var row: Dictionary = {"id":oid,"physical_collision":false}
		if object.get("role") == "independent_generated_compound":
			family="compound_measured_solids"
			if not compounds.has(oid): error="Compound has no exact source portal"; return false
			foot = compounds[oid]
			var world: Vector2 = _v2(object.get("world_foot_px"))
			if not object.get("solid_polygons_px") is Array or not world.is_finite(): error="Missing measured compound solids"; return false
			for raw: Array in object.solid_polygons_px:
				if raw.size()<3: error="Missing compound polygon"; return false
				var rect := Rect2(_v2(raw[0])+Vector2(0,foot.y-world.y),Vector2.ZERO)
				for point: Variant in raw:
					var p: Vector2 = _v2(point)+Vector2(0,foot.y-world.y)
					if not p.is_finite(): error="Nonfinite compound polygon"; return false
					rect=rect.expand(p)
				_add_rect(oid,rect)
			row.physical_collision=true
		elif String(object.get("role","")).begins_with("bridge_"):
			family=String(object.role)+"_actual_bounds"
			if not EXPECTED_FAMILIES.has(family): error="Unknown bridge protection role"; return false
			var bounds: Variant = object.get("actual_used_world_bounds_m")
			if not bounds is Array or bounds.size()!=2 or float(object.get("deck_height_m",INF))!=0.: error="Missing actual deck/post world bounds"; return false
			var low: Vector3 = _v3(bounds[0])
			var high: Vector3 = _v3(bounds[1])
			if not low.is_finite() or not high.is_finite(): error="Invalid bridge support bounds"; return false
			var start := Vector2(low.x*BASE.PPM+BASE.SIZE.x*.5,low.z*BASE.Z_PPM+BASE.SIZE.y*.5)
			var finish := Vector2(high.x*BASE.PPM+BASE.SIZE.x*.5,high.z*BASE.Z_PPM+BASE.SIZE.y*.5)
			_add_rect(oid,Rect2(start,finish-start))
			foot=_v2(object.get("world_foot_px"))
			row.physical_collision=object.get("blocking") == true
		else:
			if not foot.is_finite(): error="Missing original native instance source foot: "+oid; return false
			if object.get("kind") == "herb":
				family="herb_nonblocking_render_and_native_support"
				var cover: Dictionary = _low_cover_protection(object,foot)
				if not bool(cover.get("passed",false)): return false
				_add_rect(oid+"_visual_guard",cover.render_rect)
				_add_rect(oid+"_native_support_guard",cover.native_rect)
				row.merge(cover.audit)
			elif object.get("kind") == "boulder" and object.has("source_fullxz_rect_px"):
				family="boulder_actual_fullxz"
				if typeof(object.get("blocking"))!=TYPE_BOOL or not object.blocking: error="Boulder blocking contract changed"; return false
				var raw: Variant=object.source_fullxz_rect_px
				if not raw is Array or raw.size()!=4: error="Missing real fullXZ footprint"; return false
				for component: Variant in raw:
					if typeof(component) not in [TYPE_INT,TYPE_FLOAT] or not is_finite(float(component)): error="Invalid actual fullXZ footprint"; return false
				var size:=Vector2(raw[2],raw[3])
				if size.x<=0. or size.y<=0.: error="Empty actual fullXZ footprint"; return false
				_add_rect(oid,Rect2(Vector2(raw[0],raw[1]),size))
				row.physical_collision=true
			elif object.get("kind") in ["tree","bamboo"]:
				family=String(object.kind)+"_actual_collider"
				if typeof(object.get("blocking"))!=TYPE_BOOL or not object.blocking: error="Tree/bamboo blocking contract changed"; return false
				var size: Vector2=_v2(object.get("collision_size_px"))
				var center: Vector2=_v2(object.get("collision_center_world_px",object.get("world_foot_px")))
				var world: Vector2=_v2(object.get("world_foot_px"))
				if not size.is_finite() or size.x<=0. or size.y<=0. or not center.is_finite() or not world.is_finite(): error="Missing measured native physical footprint: "+oid; return false
				_add_rect(oid,Rect2(center+Vector2(0,foot.y-world.y)-size*.5,size))
				row.physical_collision=true
			else:
				error="Unclassified original native protection schema: "+oid; return false
		if not foot.is_finite(): error="Missing original entity support foot"; return false
		_family_counts_v2[family]=int(_family_counts_v2.get(family,0))+1
		row["protection_family"]=family
		row["source_foot_px"]=[foot.x,foot.y]
		row["four_native_RF_lattice_corners_frozen"]=true
		_footprint_rows_v2.append(row)
		# Same real 10x6 foot ellipse and lattice halo as the original helper.
		_add_rect(oid+"_shoe",Rect2(foot-Vector2(18,14),Vector2(36,28)))
		var cell:=Vector2i((foot/BASE.GRID_STEP).floor()).clamp(Vector2i.ZERO,BASE.GRID_SIZE-Vector2i(2,2))
		_feet.append({"id":oid,"source_foot_px":[foot.x,foot.y],"indices":[cell.y*BASE.GRID_SIZE.x+cell.x,cell.y*BASE.GRID_SIZE.x+cell.x+1,(cell.y+1)*BASE.GRID_SIZE.x+cell.x,(cell.y+1)*BASE.GRID_SIZE.x+cell.x+1]})
	if not _same_value(_family_counts_v2,EXPECTED_FAMILIES) or ids.size()!=2687:
		error="Original 2687 protection families/counts changed"; return false
	return true

func _low_cover_protection(object: Dictionary, foot: Vector2) -> Dictionary:
	var oid: String=String(object.id)
	if typeof(object.get("blocking"))!=TYPE_BOOL or object.blocking or _v2(object.get("collision_size_px"))!=Vector2.ZERO:
		error="Low cover must have the explicit original zero collider: "+oid; return {"passed":false}
	var size: Vector2=_v2(object.get("render_size_px"))
	var uv: Vector2=_v2(object.get("foot_uv"))
	var world: Vector2=_v2(object.get("world_foot_px"))
	var proto: Variant=object.get("prototype_actual_sourcebody_evidence")
	if not size.is_finite() or size.x<=0. or size.y<=0. or not uv.is_finite() or uv.x<0. or uv.y<0. or uv.x>1. or uv.y>1. or not world.is_finite() or not proto is Dictionary:
		error="Missing actual low cover render footprint: "+oid; return {"passed":false}
	if proto.get("kind")!="herb" or proto.get("sourcebody_exact")!=true or _v2(proto.get("render_size_px"))!=size:
		error="Low cover sourcebody/render identity changed: "+oid; return {"passed":false}
	var texture: String=String(object.get("texture",""))
	var prototype: String=String(proto.get("texture",""))
	if not _catalog_asset_v2(texture) or not _catalog_asset_v2(prototype) or not _catalog_asset_v2(String(object.get("metadata_path",""))) or not _catalog_asset_v2(String(proto.get("metadata_path",""))): return {"passed":false}
	if _verified_paths_v2[texture]!=_verified_paths_v2[prototype]:
		error="Independent low cover PNG differs from actual pose: "+oid; return {"passed":false}
	if not _image_sizes_v2.has(prototype):
		var image: Image=Image.load_from_file(prototype)
		if image==null or image.is_empty(): error="Cannot decode actual low cover PNG: "+oid; return {"passed":false}
		_image_sizes_v2[prototype]=Vector2(image.get_size())
	if _image_sizes_v2[prototype]!=size: error="Actual low cover PNG canvas mismatch: "+oid; return {"passed":false}
	var mesh_path: String=String(proto.get("actual_draw_mesh_path",""))
	if not _catalog_asset_v2(mesh_path) or _verified_paths_v2.get(mesh_path)!=proto.get("actual_draw_mesh_sha256"):
		error="Unbound actual low cover native mesh: "+oid; return {"passed":false}
	if not _low_native_geometry_v2(proto,object): return {"passed":false}
	var bounds: Variant=proto.get("used_vertex_bounds_m")
	var support: Vector3=_v3(proto.get("support_m"))
	if not bounds is Array or bounds.size()!=2 or not support.is_finite(): error="Missing measured low cover native bounds: "+oid; return {"passed":false}
	var low: Vector3=_v3(bounds[0])
	var high: Vector3=_v3(bounds[1])
	if not low.is_finite() or not high.is_finite() or high.x<=low.x or high.y<=low.y or high.z<=low.z:
		error="Invalid actual low cover native bounds: "+oid; return {"passed":false}
	# These bounds already include the measured model basis; do not rotate or
	# scale them a second time. This is the actual boulder/sourcebody XZ formula.
	var native_origin: Vector2=foot+Vector2((low.x-support.x)*BASE.PPM,(low.z-support.z)*BASE.Z_PPM)
	var native_size:=Vector2((high.x-low.x)*BASE.PPM,(high.z-low.z)*BASE.Z_PPM)
	var native_rect:=Rect2(native_origin,native_size)
	# Translate the actual projected PNG frame into the frozen source-foot plane.
	# It is a conservative visual guard, explicitly NOT a physical collision box.
	var render_rect:=Rect2(foot-uv*size,size)
	return {"passed":true,"render_rect":render_rect,"native_rect":native_rect,"audit":{
		"texture":texture,"texture_sha256":_verified_paths_v2[texture],
		"prototype_texture":prototype,"actual_draw_mesh_path":mesh_path,"actual_draw_mesh_sha256":_verified_paths_v2[mesh_path],
		"render_size_px":[size.x,size.y],"foot_uv":[uv.x,uv.y],
		"render_guard_source_rect_px":[render_rect.position.x,render_rect.position.y,render_rect.size.x,render_rect.size.y],
		"native_support_source_rect_px":[native_rect.position.x,native_rect.position.y,native_rect.size.x,native_rect.size.y],
		"protection_scope":"ACTUAL_RENDER_AND_USED_INDEX_NATIVE_SUPPORT_ONLY_NOT_PHYSICAL_COLLISION",
		"physical_collision":false,"original_collision_size_px":[0,0]}}

func _low_native_geometry_v2(proto: Dictionary, object: Dictionary) -> bool:
	var oid: String=String(object.id)
	var columns: Variant=proto.get("basis_columns")
	var transform: Variant=object.get("actual_model_transform")
	if not columns is Array or columns.size()!=3 or not transform is Dictionary or not transform.get("basis_columns") is Array or transform.basis_columns.size()!=3:
		error="Actual low cover instance/prototype basis mismatch: "+oid; return false
	var bx: Vector3=_v3(columns[0])
	var by: Vector3=_v3(columns[1])
	var bz: Vector3=_v3(columns[2])
	if not bx.is_finite() or not by.is_finite() or not bz.is_finite(): error="Nonfinite low cover basis"; return false
	# Both JSON encodings describe native Float32 Basis columns. Compare the
	# actual typed geometry exactly, not different decimal spellings; no epsilon.
	if bx!=_v3(transform.basis_columns[0]) or by!=_v3(transform.basis_columns[1]) or bz!=_v3(transform.basis_columns[2]):
		error="Actual low cover native Basis differs: "+oid; return false
	var basis:=Basis(bx,by,bz)
	if basis.determinant()==0.: error="Degenerate low cover basis"; return false
	var mesh_path: String=String(proto.actual_draw_mesh_path)
	var key: String=mesh_path+JSON.stringify(columns)
	if not _verified_geometry_v2.has(key):
		var mesh: ArrayMesh=ResourceLoader.load(mesh_path,"",ResourceLoader.CACHE_MODE_IGNORE) as ArrayMesh
		var surfaces: Variant=proto.get("actual_surfaces")
		if mesh==null or mesh.get_surface_count()==0 or not surfaces is Array or mesh.get_surface_count()!=surfaces.size():
			error="Missing actual low cover drawn surfaces: "+oid; return false
		var minimum:=Vector3(INF,INF,INF)
		var maximum:=Vector3(-INF,-INF,-INF)
		var points:=PackedVector3Array()
		for surface_id in mesh.get_surface_count():
			var row: Variant=surfaces[surface_id]
			if not row is Dictionary or row.get("surface_index")!=surface_id or not row.get("draw_arrays_sha256") is Dictionary or mesh.surface_get_primitive_type(surface_id)!=Mesh.PRIMITIVE_TRIANGLES:
				error="Invalid actual low cover surface evidence: "+oid; return false
			var arrays: Array=mesh.surface_get_arrays(surface_id)
			for slot: Variant in row.draw_arrays_sha256:
				var index: int=String(slot).to_int()
				if str(index)!=String(slot) or index<0 or index>=Mesh.ARRAY_MAX or arrays[index]==null or _sha(arrays[index].to_byte_array())!=row.draw_arrays_sha256[slot]:
					error="Actual low cover source geometry arrays differ: "+oid; return false
			var vertices: PackedVector3Array=arrays[Mesh.ARRAY_VERTEX]
			var indices: PackedInt32Array=arrays[Mesh.ARRAY_INDEX]
			if vertices.is_empty() or indices.is_empty() or indices.size()%3!=0: error="Empty actual low cover indexed geometry"; return false
			var seen: Dictionary={}
			for index: int in indices:
				if index<0 or index>=vertices.size(): error="Invalid low cover source index"; return false
				if seen.has(index): continue
				seen[index]=true
				var point: Vector3=basis*vertices[index]
				if not point.is_finite(): error="Nonfinite actual low cover drawn vertex"; return false
				points.append(point)
				minimum=minimum.min(point)
				maximum=maximum.max(point)
		var sum_x:=0.0
		var front: float=-INF
		var support_count:=0
		for point: Vector3 in points:
			if point.y<=minimum.y+(maximum.y-minimum.y)*.02:
				sum_x+=point.x
				front=maxf(front,point.z)
				support_count+=1
		if support_count==0: error="Actual low cover source has no measured drawn support"; return false
		_verified_geometry_v2[key]={"minimum":minimum,"maximum":maximum,"support":Vector3(sum_x/support_count,minimum.y,front)}
	var measured: Dictionary=_verified_geometry_v2[key]
	var bounds: Variant=proto.get("used_vertex_bounds_m")
	if not bounds is Array or bounds.size()!=2 or measured.minimum!=_v3(bounds[0]) or measured.maximum!=_v3(bounds[1]) or measured.support!=_v3(proto.get("support_m")):
		error="Actual low cover used-index XYZ/support differs from measured evidence: "+oid; return false
	return true

func _catalog_asset_v2(path: String) -> bool:
	if _verified_paths_v2.has(path): return true
	var expected: Variant=_catalog_v2.get(path)
	if path.is_empty() or not expected is String or expected.length()!=64 or FileAccess.get_sha256(path).to_lower()!=expected.to_lower():
		error="Missing/changed measured body catalog asset: "+path; return false
	_verified_paths_v2[path]=expected.to_lower()
	return true

func _support_audit(before: PackedByteArray, after: PackedByteArray) -> Dictionary:
	var audit: Dictionary=super._support_audit(before,after)
	if not bool(audit.get("passed",false)): return audit
	audit["protection_schema_revision"]="EXPLICIT_NONBLOCKING_LOW_COVER_VISUAL_AND_NATIVE_SUPPORT_V2"
	audit["immutable_parent_helper"]={"path":ORIGINAL_HELPER_PATH,"sha256":ORIGINAL_HELPER_SHA}
	audit["protection_family_counts"]=_family_counts_v2.duplicate(true)
	audit["protection_footprint_rows"]=_footprint_rows_v2.duplicate(true)
	audit["nonblocking_low_cover_physical_collision_invented"]=false
	return audit
