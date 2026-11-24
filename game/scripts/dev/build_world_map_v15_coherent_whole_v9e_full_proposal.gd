extends "res://scripts/dev/build_world_map_v15_coherent_whole_v9c_full_proposal.gd"

## NEW execution-only V9E surface revision. The inherited technical protocol,
## coordinate15, RF640, all18 samplers, 2687 sites, two worlds/five roles/two
## draws,64chunks/112seams/ROI96 and8404992 CPU pixels remain unchanged.
## ROOT must archive the completed ROOT234 art/source before the inherited
## absent-output guard can pass. This source never archives/publishes/approves.
const V9E_SURFACE := preload("res://scripts/dev/world_map_v15_v9e_material_refinement_surface.gd")
const V9E_FULL_PATH := "res://scripts/dev/build_world_map_v15_coherent_whole_v9e_full_proposal.gd"
const V9E_REGIONAL_PATH := "res://scripts/dev/build_world_map_v15_coherent_whole_v9e_regional_proposal.gd"
const V9E_SURFACE_PATH := "res://scripts/dev/world_map_v15_v9e_material_refinement_surface.gd"
const V9E_SURFACE_SHA := "3cb4f995cc800482fe859f0424a4839b70097721ec5f11f21e53a7d6ca3253b1"
const V9E_FIXED_PINS := {
 "res://scripts/dev/build_world_map_v15_coherent_whole_v9c_full_proposal.gd":"4d006169a3cc0f9dc347c467d4ab05204ee2f78be790e3c75c368d77e9b5abfb",
 "res://scripts/dev/build_world_map_v15_coherent_whole_v9c_regional_proposal.gd":"c843813232edc34d3393157d1285d1bae963abb723b09d65484be896a62d365b",
 "res://scripts/dev/build_world_map_v15_v9c_visual_quality_proposal_retry5.gd":"27a2826b93453dc4b4d139b775a6c907a048996f758f87b983769648ec3e5596",
 V9E_SURFACE_PATH:V9E_SURFACE_SHA
}
var v9e_factory_installed: bool = false
var v9e_repeated_catalog_reads_avoided: int = 0

func _full_register_paths(value: Variant) -> void:
	# The inherited exporter registers the same immutable PBR/model graph for
	# every vegetation instance. Reuse its already measured digest, not bytes
	# from another run. Every registered path is independently rehashed below,
	# and the inherited whole-run input recheck remains unchanged.
	if value is String and value.begins_with("res://") and full_catalog.has(value):
		if value.get_extension() in ["gd","gdshader","res","gltf","glb","obj","tga","jpg","png","json","bin"]:
			full_graph[value] = full_catalog[value]
		v9e_repeated_catalog_reads_avoided += 1
		return
	super._full_register_paths(value)

func _pilot_authorized(path: String) -> bool:
	# No const override: the same technical protocol is intentionally retained.
	# The root-signed current executor/SHA and this new dependency are distinct.
	for file: String in V9E_FIXED_PINS:
		if FileAccess.get_sha256(file).to_lower() != V9E_FIXED_PINS[file]:
			error = "Frozen V9E inherited input differs: " + file
			return false
	if not super._pilot_authorized(path): return false
	for file: String in [V9E_FULL_PATH, V9E_REGIONAL_PATH, V9E_SURFACE_PATH]:
		if not pilot_inputs.has(file) or String(pilot_inputs[file]).length() != 64 or String(pilot_inputs[file]).to_lower() != FileAccess.get_sha256(file).to_lower():
			error = "Exact V9E executor/surface missing from current signed closure: " + file
			return false
	for file: String in V9E_FIXED_PINS:
		if String(pilot_inputs.get(file, "")).to_lower() != V9E_FIXED_PINS[file]:
			error = "V9E signed closure does not bind exact inherited source: " + file
			return false
	return true

func _material_maps(rect: Rect2) -> Dictionary:
	# retry5 constructs its historical surface, but calls this dynamic method
	# BEFORE any terrain_material/shader/World3D exists. Replace the actual
	# factory instance here; never recolour an already captured image.
	if not v9e_factory_installed:
		if v9c_plan_only or not v9c_installed or source == null or surface == null or not source.v9c_derived_rf_installed:
			error = "V9E requires the existing approved derived RF, not a new plan."
			return {}
		if FileAccess.get_sha256(V9E_SURFACE_PATH).to_lower() != V9E_SURFACE_SHA or String(pilot_inputs.get(V9E_SURFACE_PATH, "")).to_lower() != V9E_SURFACE_SHA:
			error = "Exact actual V9E surface is not approved in the input closure."
			return {}
		surface.release()
		surface = V9E_SURFACE.new()
		if not surface.load_sources() or surface.evidence.size() != 18:
			error = "V9E actual18 sampler loader refused: " + String(surface.error)
			return {}
		# The parent validated the old factory before this hook. Validate every
		# actual NEW sampler again; the old validation is not new object credit.
		for entry: Dictionary in surface.evidence:
			for key: String in ["path", "source_path"]:
				var file: String = String(entry.get(key, ""))
				if file.is_empty() or not pilot_inputs.has(file) or FileAccess.get_sha256(file).to_lower() != String(pilot_inputs[file]).to_lower():
					error = "Unbound actual V9E PBR input: " + file
					return {}
		v9e_factory_installed = true
	return super._material_maps(rect)

func _load_pilot_inputs() -> bool:
	if not super._load_pilot_inputs(): return false
	if not v9e_factory_installed or not surface is V9E_SURFACE or surface.get_script().resource_path != V9E_SURFACE_PATH or source.heights.to_byte_array() != FileAccess.get_file_as_bytes(_v9c_artifact_path("height_rf")):
		error = "Actual V9E instance or original approved derived RF differs."
		return false
	if pilot_result.get("original_site_preparation", {}).get("baseline_objects") != 2687 or v9c_attached_material_creations.size() != 1:
		error = "The original2687 body preparation/initial material contract differs."
		return false
	var initial: Dictionary = surface.v9_material_records.back()
	if initial.get("identity") != V9E_SURFACE.V9D_SURFACE_ID or initial.get("material_revision_identity") != V9E_SURFACE.V9E_ID or initial.get("actual_script_path") != V9E_SURFACE_PATH or String(initial.get("actual_script_sha256", "")).to_lower() != V9E_SURFACE_SHA or initial.get("actual_code_sha256") != _bytes_sha(pilot_shader.code.to_utf8_buffer()):
		error = "V9E actual material identity/code must differ from ancestral lineage."
		return false
	if initial.get("opaque_damp_soil_triplet_weights", {}) != {"forest":.60, "leafy":.05, "mud":.35} or initial.get("snow_deposit_actual_grade_fade", []) != [.22, .54] or initial.get("snow_pigment_range", []) != [[.48,.52,.51],[.70,.73,.72]]:
		error = "V9E material records do not describe the actual current shader."
		return false
	v9c_attached_material_creations[0]["actual_revision_creation"] = surface.v9e_records[0].duplicate(true)
	pilot_result["material_revision_identity"] = V9E_SURFACE.V9E_ID
	pilot_result["actual_surface_factory"] = {"path":V9E_SURFACE_PATH, "sha256":V9E_SURFACE_SHA, "installed_before_initial_shader":true, "no_material_or_pixel_post_correction":true}
	return true

func _v9e_material_record(material: ShaderMaterial, kind: String) -> Dictionary:
	if material == null or material.shader == null or not surface is V9E_SURFACE: return {}
	var sha: String = _bytes_sha(material.shader.code.to_utf8_buffer())
	for index in range(surface.v9e_records.size()-1, -1, -1):
		var row: Dictionary = surface.v9e_records[index]
		if row.get("kind") == kind and row.get("identity") == V9E_SURFACE.V9E_ID and row.get("source_path") == V9E_SURFACE_PATH and String(row.get("source_sha256", "")).to_lower() == V9E_SURFACE_SHA and row.get("code_sha256") == sha:
			return row
	return {}

func _v9c_record_live_material(material: ShaderMaterial, kind: String, path: String) -> bool:
	var record: Dictionary = _v9e_material_record(material, kind)
	if record.is_empty():
		error = "The actual attached V9E material/code has no exact creation record."
		return false
	if kind == "terrain" and material.get_shader_parameter("v9e_material_identity") != 1.:
		error = "Actual attached terrain is not the V9E fragment."
		return false
	if kind == "water" and (record.get("actual_RF_texture_bound") != true or record.get("depth_discard_alpha_water_Y_unchanged") != true):
		error = "Actual V9E water must retain original RF/discard/support."
		return false
	if not super._v9c_record_live_material(material, kind, path): return false
	# Parent serializes actual current uniforms/all texture mips and hashes.
	v9c_attached_material_creations.back()["material_revision_identity"] = V9E_SURFACE.V9E_ID
	v9c_attached_material_creations.back()["actual_revision_creation"] = record.duplicate(true)
	return true

func _shader_gate(material: ShaderMaterial, required: Array[String]) -> bool:
	if not super._shader_gate(material, required): return false
	if required.has("v9d_material_identity"):
		return material.get_shader_parameter("v9e_material_identity") == 1. and not _v9e_material_record(material, "terrain").is_empty()
	if required.has("actual_height_rf"):
		return material.get_shader_parameter("actual_height_rf") == full_rf and not _v9e_material_record(material, "water").is_empty()
	return true

func _v9c_final_revision_evidence() -> bool:
	# Actual all-path terminal verification, never a borrowed old capture/hash.
	for path: String in full_catalog:
		if FileAccess.get_sha256(path).to_lower() != String(full_catalog[path]).to_lower():
			error = "Actual registered asset changed during V9E capture: " + path
			return false
	if not super._v9c_final_revision_evidence(): return false
	if full_objects.size() != 2687 or surface.v9e_records.size() != 5 or v9c_attached_material_creations.size() != 5:
		error = "V9E requires original2687 objects and actual initial + two-world materials."
		return false
	var kinds: Array[String] = ["terrain", "terrain", "water", "terrain", "water"]
	for index in 5:
		var row: Dictionary = surface.v9e_records[index]
		var creation: Dictionary = v9c_attached_material_creations[index]
		if row.get("kind") != kinds[index] or row.get("identity") != V9E_SURFACE.V9E_ID or row.get("source_path") != V9E_SURFACE_PATH or String(row.get("source_sha256", "")).to_lower() != V9E_SURFACE_SHA or String(row.get("code_sha256", "")).length() != 64 or row.get("code_sha256") != creation.get("actual_code_sha256") or creation.get("actual_revision_creation") != row:
			# Initial construction stores shader-code SHA as actual_code_sha256;
			# attached materials store that same raw UTF8-code identity.
			error = "V9E five actual creation records/attached code differ."
			return false
	var execution: Dictionary = pilot_result["v9c_revision_evidence"]["actual_execution"]
	execution["full"] = {"path":V9E_FULL_PATH, "sha256":FileAccess.get_sha256(V9E_FULL_PATH), "role":"INHERITED_FULL_METHODS_NOT_REGIONAL_EXECUTOR" if v9c_regional_mode else "ACTUAL_FULL_EXECUTOR"}
	execution["regional"] = {"path":V9E_REGIONAL_PATH, "sha256":FileAccess.get_sha256(V9E_REGIONAL_PATH), "role":"ACTUAL_REGIONAL_EXECUTOR" if v9c_regional_mode else "ROOT_REVIEWED_PRIOR_REGIONAL_EXECUTOR"}
	execution["inherited_full"] = {"path":"res://scripts/dev/build_world_map_v15_coherent_whole_v9c_full_proposal.gd", "sha256":V9E_FIXED_PINS["res://scripts/dev/build_world_map_v15_coherent_whole_v9c_full_proposal.gd"], "role":"ACTUAL_INHERITED_CAPTURE_METHODS_NOT_CURRENT_ENTRY"}
	pilot_result["v9e_revision_evidence"] = {"material_revision_identity":V9E_SURFACE.V9E_ID, "surface":{"path":V9E_SURFACE_PATH,"sha256":V9E_SURFACE_SHA}, "actual_material_creations":surface.v9e_records.duplicate(true), "actual_attached_material_creations":v9c_attached_material_creations.duplicate(true), "actual_execution":execution.duplicate(true), "technical_capture_protocol_unchanged":V9C_FULL_PROTOCOL, "original_derived_geometry_inputs_unchanged":v9c_geometry_result["artifacts"].duplicate(true), "geometry_RF_NAV_body_coordinates_changed_by_revision":false, "visual_approved":false, "production_approved":false}
	pilot_result["actual_catalog_hashing"] = {"method":"CURRENT_RUN_REGISTER_ONCE_THEN_ALL_REGISTERED_PATHS_REHASHED", "terminal_actual_paths_rehashed":full_catalog.size(), "repeated_reads_avoided":v9e_repeated_catalog_reads_avoided, "original_input_before_after_guard_unchanged":true, "geometry_material_capture_changed":false}
	return true

func _write_json(path: String, data: Dictionary) -> bool:
	# Keep the established output/protocol contract, but never let that label
	# misidentify the active surface. Hashes are computed AFTER this exact save.
	if path in [V9C_FULL_SOURCE_JSON, V9C_FULL_ROOT+"art_contract.json"] and data.get("status", "") in ["ART_ASSETS_READY", "ART_CANDIDATE_REQUIRES_FIELD_VISUAL_QA"]:
		if not pilot_result.has("v9e_revision_evidence"):
			error = "Cannot emit READY source/manifest without actual V9E evidence."
			return false
		var enriched: Dictionary = data.duplicate(true)
		enriched["material_revision_identity"] = V9E_SURFACE.V9E_ID
		enriched["material_revision_script"] = {"path":V9E_SURFACE_PATH, "sha256":V9E_SURFACE_SHA}
		enriched["v9e_revision_evidence"] = pilot_result["v9e_revision_evidence"].duplicate(true)
		return super._write_json(path, enriched)
	return super._write_json(path, data)

func _v9c_regional_approval_error() -> String:
	var review: Variant=pilot_auth.get("regional_visual_review")
	if not review is Dictionary or review.get("approved_by")!="root" or review.get("approved")!=true or review.get("scope")!=V9C_REGIONAL_SCOPE:
		error="NEW FULL requires separate actual current V9C regional root review."
		return error
	var target: Dictionary=review.get("candidate_full_builder",{})
	if target.get("path")!=get_script().resource_path or String(target.get("sha256","")).to_lower()!=FileAccess.get_sha256(get_script().resource_path).to_lower():
		error="Independent regional review must bind this exact FULL target."
		return error
	var path: String=review.get("result_path","")
	if not path.begins_with(V9C_REGIONAL_ROOT) or String(review.get("result_sha256","")).length()!=64 or FileAccess.get_sha256(path).to_lower()!=String(review["result_sha256"]).to_lower() or String(pilot_inputs.get(path,"")).to_lower()!=String(review["result_sha256"]).to_lower():
		error="Actual current NEW regional result is not bound."
		return error
	var actual: Variant=JSON.parse_string(FileAccess.get_file_as_string(path))
	if not actual is Dictionary or actual.get("scope")!=V9C_REGIONAL_SCOPE or actual.get("status")!=V9C_REGIONAL_STATUS or actual.get("input_hashes_unchanged_after")!=true:
		error="Actual current V9C regional technical evidence incomplete."
		return error
	var executor: Dictionary=actual.get("executed_builder",{})
	if executor.get("path")!=V9E_REGIONAL_PATH or String(executor.get("sha256","")).to_lower()!=FileAccess.get_sha256(V9E_REGIONAL_PATH).to_lower() or String(pilot_inputs.get(V9E_REGIONAL_PATH,"")).to_lower()!=FileAccess.get_sha256(V9E_REGIONAL_PATH).to_lower():
		error="Actual regional executor differs from current input catalog."
		return error
	var recorded: Dictionary=actual.get("cached_inputs_sha256",{})
	for dependency: String in V9C_FULL_PINS:
		if String(recorded.get(dependency,"")).to_lower()!=V9C_FULL_PINS[dependency]:
			error="Regional current V9C source/material/helper dependency differs "+dependency
			return error
	for dependency: String in [V9E_FULL_PATH, V9E_SURFACE_PATH]:
		if String(recorded.get(dependency, "")).to_lower() != FileAccess.get_sha256(dependency).to_lower():
			error = "Regional current V9E executor/surface dependency differs " + dependency
			return error
	if actual.get("material_revision_identity") != V9E_SURFACE.V9E_ID or actual.get("v9e_revision_evidence", {}).get("surface", {}).get("path") != V9E_SURFACE_PATH or String(actual.get("v9e_revision_evidence", {}).get("surface", {}).get("sha256", "")).to_lower() != V9E_SURFACE_SHA or actual.get("v9e_revision_evidence", {}).get("actual_material_creations", []).size() != 5:
		error = "Regional current V9E actual material evidence is missing."
		return error
	var revision: Dictionary = actual["v9e_revision_evidence"]
	var attached: Array = actual.get("v9c_revision_evidence", {}).get("attached_material_creations", [])
	if attached.size() != 5 or revision.get("actual_attached_material_creations") != attached:
		error = "Regional V9E creation records must bind the five actual attached materials."
		return error
	var kinds: Array[String] = ["terrain", "terrain", "water", "terrain", "water"]
	for index in 5:
		var record: Variant = revision["actual_material_creations"][index]
		var creation: Variant = attached[index]
		if not record is Dictionary or not creation is Dictionary:
			error = "Regional actual V9E creation record type differs."
			return error
		if record.get("kind") != kinds[index] or record.get("identity") != V9E_SURFACE.V9E_ID or record.get("source_path") != V9E_SURFACE_PATH or String(record.get("source_sha256", "")).to_lower() != V9E_SURFACE_SHA or String(record.get("code_sha256", "")).length() != 64 or record.get("code_sha256") != creation.get("actual_code_sha256") or creation.get("actual_revision_creation") != record:
			error = "Regional actual V9E source/code/attached material identities differ."
			return error
	var actual_derived: Dictionary=actual.get("derived_geometry_inputs",{})
	if actual_derived!=pilot_auth.get("derived_geometry_inputs",{}):
		error="Regional and FULL derived geometry roles differ."
		return error
	for role: String in ["height_rf","terrain_mesh","source_topology","derivation_report"]:
		var entry: Dictionary=actual_derived.get(role,{})
		if String(entry.get("sha256","")).length()!=64 or FileAccess.get_sha256(entry.get("path","")).to_lower()!=String(entry["sha256"]).to_lower():
			error="Actual regional derived geometry changed "+role
			return error
	var worlds: Dictionary=actual.get("worlds",{})
	if worlds.size()!=2 or worlds.get("primary",{}).get("world_node_instance_id")==worlds.get("reference",{}).get("world_node_instance_id") or worlds.get("primary",{}).get("world_3d_instance_id")==worlds.get("reference",{}).get("world_3d_instance_id"):
		error="Two truly independent regional worlds not proven."
		return error
	var ids: Array[String]=["farmland","marsh","snow","limestone","meadow_river","northern_river_bailu_junction"]
	for identity: String in ["primary","reference"]:
		var world: Dictionary=worlds.get(identity,{})
		if world.get("actual_world_released_before_next")!=true or world.get("coverage",{}).get("passed")!=true:
			error="Actual regional coverage/release missing."
			return error
		for role: String in ROLE_NAMES:
			var row: Dictionary=world.get("roles",{}).get(role,{})
			var windows: Dictionary=row.get("windows",{})
			if row.get("passes",[]).size()!=2 or windows.size()!=6:
				error="Regional two draws/all5 roles/all6 exact ROIs incomplete."
				return error
			for id: String in ids:
				var window: Dictionary=windows.get(id,{})
				var repeat: Dictionary=window.get("repeat_transfer_evidence",{})
				if window.get("actual_repeat_raw",{}).get("byte_exact")!=true or window.get("actual_repeat_logical",{}).get("byte_exact")!=true:
					error="Actual regional repeat failed."
					return error
				for record: Dictionary in [window,repeat]:
					for key: String in ["path","raw_path"]:
						var file: String=record.get(key,"")
						var sha_key: String="sha256" if key=="path" else "raw_sha256"
						if not file.begins_with(V9C_REGIONAL_ROOT) or String(record.get(sha_key,"")).length()!=64 or FileAccess.get_sha256(file).to_lower()!=String(record[sha_key]).to_lower():
							error="Actual original/repeat regional image binding failed."
							return error
	for role: String in ROLE_NAMES:
		var compared: Dictionary=actual.get("comparisons",{}).get(role,{}).get("independent_worlds_same_global_coordinates",{})
		for id: String in ids:
			if compared.get(id,{}).get("byte_exact")!=true or compared.get(id,{}).get("independent_raw_RGBA",{}).get("byte_exact")!=true:
				error="Actual independent regional RGBA equality missing."
				return error
	if actual.get("alpha_union",{}).get("passed")!=true or actual.get("v9c_revision_evidence",{}).get("attached_material_creations",[]).size()!=5:
		error="Regional actual canopy/material evidence incomplete."
		return error
	return ""
