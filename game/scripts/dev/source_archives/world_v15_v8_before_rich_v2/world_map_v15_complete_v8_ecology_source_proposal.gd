extends "res://scripts/dev/world_map_v15_complete_v7_ecology_source_proposal.gd"

## New visual ownership and honest original Shrub03 dry-bank instances only.
## All added objects nonblocking. Never call them reeds or stretch the model.
var v8_bank_sites: Array[Dictionary]=[]

func _prepare_ecology_sites() -> void:
	super._prepare_ecology_sites()
	v8_bank_sites.clear()
	if not v7_proposal_error.is_empty(): return
	for row in range(32):
		for column in range(44):
			var p:=Vector2(9510.+column*57.+sin(row*2.13+column*.73)*19.,5650.+row*71.+cos(column*1.37+row*.57)*25.)
			var bank_margin: float=bank(p)
			var patch: float=.5+.5*sin(p.x*.0031+p.y*.0067+sin(p.y*.013)*1.8)
			if bank_margin<36. or bank_margin>260. or patch<.48 or road_distance(p).x<road_distance(p).y+100.: continue
			if not _v7_dry_stem_clear(p,"herb") or triangle_height(p)<=WATER_Y: continue
			var site: Dictionary={"id":"v8_marsh_lowgrass_%02d_%02d"%[row,column],"kind":"herb","pose":(row+column)%3,"source_foot":p,"blocking":false,"collision_size_px":Vector2.ZERO,"nature":"official CC0 Shrub03 unchanged source/pose, dry-bank lowgrass NOT reed"}
			vegetation_sites.append(site)
			_v7_index_site(site)
			v8_bank_sites.append(site.duplicate(true))
	if vegetation_sites.size()>V7_MAX_REGISTERED_SITES: v7_proposal_error="V8 bounded original+bank-site budget exceeded; no truncation."

func habitat(p: Vector2) -> Vector4:
	var original: Vector4=super.habitat(p)
	var bank_margin: float=bank(p)
	var region: float=1.-smoothstep(.55,1.1,((p-Vector2(10920,6850))/Vector2(1650,1500)).length())
	var edge: float=(1.-smoothstep(45.,310.,maxf(bank_margin,0.)))*smoothstep(8.,36.,bank_margin)
	var irregular: float=.7+.3*(.5+.5*sin(p.x*.0021+p.y*.0037+sin(p.y*.008)*1.2))
	# Visual dry sediment ownership only: water still actual RF, never this weight.
	original.z=maxf(original.z,region*edge*irregular)
	return original

func v8_proposal_contract() -> Dictionary:
	return {"identity":"V8_DRY_BANK_OWNERSHIP_AND_ORIGINAL_SHRUB_CLUSTER","added_sites":v8_bank_sites,"all_new_blocking":false,"original_RF_mesh_selector_routes_doors_unchanged":true,"profile":"wet sediment/lowgrass; no authorized real reed asset, no fake species attribution","visual_approved":false,"production_approved":false}
