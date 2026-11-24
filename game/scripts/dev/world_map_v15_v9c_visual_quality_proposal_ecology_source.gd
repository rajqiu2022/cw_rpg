extends "res://scripts/dev/world_map_v15_v9b_visual_quality_proposal_ecology_source.gd"

## NEW source facade. Height derivation is explicit and must be installed by the
## NEW bounded loader before material maps or any GPU allocation. Merely loading
## this script does not repair the cached northern shelves or inherit NAV PASS.
const V9C_SOURCE_ID := "V9C_NEW_CONTINUOUS_NORTHERN_SHOULDERS_ACTUAL_RF_OWNER_SOURCE_PROPOSAL"
var v9c_geometry_artifacts: Dictionary={}
var v9c_geometry_audit: Dictionary={}
var v9c_derived_rf_installed: bool=false

func bind_derived_geometry(result: Dictionary) -> bool:
	if result.get("passed",false)!=true or not result.get("heights") is PackedFloat32Array or not result.get("artifacts") is Dictionary or not result.get("audit") is Dictionary:
		v7_proposal_error="V9C derived RF/mesh/selector/audit binding absent; cached geometry is not a fallback."
		return false
	var candidate: PackedFloat32Array=result["heights"]
	if candidate.size()!=GRID_SIZE.x*GRID_SIZE.y:
		v7_proposal_error="V9C actual derived Float32 grid shape differs."
		return false
	for role: String in ["height_rf","terrain_mesh","source_topology","derivation_report"]:
		var entry: Dictionary=result["artifacts"].get(role,{})
		var path: String=entry.get("path","")
		if path.is_empty() or not path.begins_with("res://build/world_map_v15_v9c_visual_quality_proposal/") or String(entry.get("sha256","")).length()!=64 or FileAccess.get_sha256(path).to_lower()!=String(entry["sha256"]).to_lower():
			v7_proposal_error="V9C actual NEW geometry artifact invalid/unbound: "+role
			return false
	var actual_rf: PackedByteArray=FileAccess.get_file_as_bytes(result["artifacts"]["height_rf"]["path"])
	if actual_rf!=candidate.to_byte_array():
		v7_proposal_error="V9C actual saved RF bytes differ from installed source heights."
		return false
	heights=candidate
	vertex_cache.clear()
	v9c_geometry_artifacts=result["artifacts"].duplicate(true)
	v9c_geometry_audit=result["audit"].duplicate(true)
	v9c_derived_rf_installed=true
	return true

func v9_execution_contract() -> Dictionary:
	var record: Dictionary=super.v9_execution_contract()
	record["identity"]=V9C_SOURCE_ID
	record["actual_script"]={"path":get_script().resource_path,"sha256":FileAccess.get_sha256(get_script().resource_path)}
	record["derived_RF_installed"]=v9c_derived_rf_installed
	record["actual_geometry_artifacts"]=v9c_geometry_artifacts.duplicate(true)
	record["actual_geometry_audit"]=v9c_geometry_audit.duplicate(true)
	record["navigation_authority_unchanged"]=false
	record["navigation_scope"]="same authored route/door/bridge/instance IDs and protected height nodes; NEW unprotected terrain gradients/projected pixels may change. NEW saved selector/mesh/RF must agree, not cached NAV reuse or Field acceptance."
	record["limitations"]="bounded source proposal, not FULL64/112/Field; opaque moist soil is not a new navigable water body or credible complete wetland claim"
	return record
