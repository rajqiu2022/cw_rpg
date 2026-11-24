extends "res://scripts/dev/world_map_v15_complete_v8_ecology_source_proposal.gd"

## Independent visual-owner candidate. Inherits every original site unchanged.
## No RF/mesh/selector/water/route/door/native-solid authoring override.
const RICH_ECOLOGY_ID := "V8_REGIONAL_LOW_DRY_RF_SEDIMENT_SNOW_GRADE_OWNER_V2_CANDIDATE"
var expanded_dry_marsh_candidate_enabled: bool=true
var snow_rock_candidate_enabled: bool=true

func habitat(p: Vector2) -> Vector4:
	var original: Vector4=super.habitat(p)
	# Use actual cached Float32 native-triangle interpolation, not a painted
	# wet/nav mask. Water and elevated terrain cannot acquire this dry owner.
	var bed_height: float=triangle_height(p)
	var q: Vector2=p.clamp(Vector2.ZERO,Vector2(SIZE))/float(GRID_STEP)
	var cell:=Vector2i(mini(floori(q.x),GRID_SIZE.x-2),mini(floori(q.y),GRID_SIZE.y-2))
	var local: Vector2=q-Vector2(cell)
	var native_grade: float=triangle_gradient(cell,local.x+local.y>1.)
	if snow_rock_candidate_enabled:
		var north_region: float=1.-smoothstep(.52,1.1,((p-Vector2(5000,430))/Vector2(4600,860)).length())
		var high_ground: float=smoothstep(.85,1.6,bed_height)
		var sheltered_grade: float=1.-smoothstep(.38,1.15,native_grade)
		var snow_deposit: float=.90*high_ground*sheltered_grade
		# Real steep native triangles shed snow; gently graded upper shoulders
		# retain it. Only visual owners change, never height/steep navigation.
		original.w=lerpf(original.w,snow_deposit,north_region)
		var bare_ridge: float=north_region*smoothstep(.65,2.2,bed_height)*smoothstep(.22,.85,native_grade)
		original.y=maxf(original.y,bare_ridge*.92)
	if not expanded_dry_marsh_candidate_enabled: return original
	if bed_height<=WATER_Y: return original
	var dry_edge: float=smoothstep(WATER_Y,WATER_Y+.035,bed_height)
	var low_ground: float=1.-smoothstep(.18,.65,bed_height)
	var low_grade: float=1.-smoothstep(.12,.48,native_grade)
	var region: float=1.-smoothstep(.55,1.1,((p-Vector2(10920,6850))/Vector2(1650,1500)).length())
	var tea_distance: float=((p-Vector2(11100,7900))/Vector2(700,650)).length()
	var tea_clear: float=smoothstep(.3,1.1,tea_distance)
	var lane: Vector2=road_distance(p)
	# Road widths/selector are unchanged; only this new visual owner fades out
	# over its own 28px dry shoulder. The existing bank owner remains inherited.
	var road_clear: float=smoothstep(lane.y,lane.y+28.,lane.x)
	var organization: float=.78+.22*(.5+.5*sin(p.x*.0021+p.y*.0037+sin(p.y*.008)*1.2))
	var dry_owner: float=.85*region*dry_edge*low_ground*low_grade*tea_clear*road_clear*organization
	original.z=maxf(original.z,dry_owner)
	return original

func rich_candidate_contract() -> Dictionary:
	return {"identity":RICH_ECOLOGY_ID,
		"candidate_script_path":get_script().resource_path,
		"candidate_script_sha256":FileAccess.get_sha256(get_script().resource_path),
		"parent_script_path":"res://scripts/dev/world_map_v15_complete_v8_ecology_source_proposal.gd",
		"parent_script_sha256":FileAccess.get_sha256("res://scripts/dev/world_map_v15_complete_v8_ecology_source_proposal.gd"),
		"expanded_dry_marsh_candidate_enabled":expanded_dry_marsh_candidate_enabled,
		"snow_rock_candidate_enabled":snow_rock_candidate_enabled,
		"authority":"inherited triangle_height actual RF; bed<=WATER_Y excluded; source4px visual weights only",
		"low_ground_height_m":[.18,.65],"region_center_source_px":[10920,6850],"region_radius_source_px":[1650,1500],
		"maximum_new_owner":.85,"road_shoulder_fade_px":28.,
		"dry_ground_gradient_fade":[.12,.48],
		"snow_deposit_height_fade_m":[.85,1.6],"snow_deposit_gradient_fade":[.38,1.15],
		"bare_ridge_height_fade_m":[.65,2.2],"bare_ridge_gradient_fade":[.22,.85],
		"unchanged":"RF/native mesh/selector/27 roads/16 doors/native body/solids/registered sites/18 CC0 channels/metres/mips",
		"limitations":"dry sediment and native height/gradient snow-rock owners only; no new reeds, water, landforms or walk support",
		"status":"CANDIDATE_CODE_CREATED_NOT_ENGINE_VALIDATED",
		"visual_approved":false,"production_approved":false}
