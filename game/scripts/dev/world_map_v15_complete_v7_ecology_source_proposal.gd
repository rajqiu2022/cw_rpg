extends "res://scripts/dev/world_map_v15_complete_v5_source.gd"

# NEW SOURCE-ONLY PROPOSAL. No SceneTree, export, adoption or implicit execution.
# Inherits exact F812 geography/RF/selector/27 routes/16 targets unchanged.
# A future approved executor must bind this script rather than relabel v6 output.
const V7_PARENT_SOURCE := "res://scripts/dev/world_map_v15_complete_v5_source.gd"
const V7_PARENT_SHA := "f812bcd93efe93da54866c2d61287feaeaf6bc68543493b4b54a606d99769299"
const V7_REVISION := "ecology_v7_source_only_not_approved"
const VISUAL_MATERIAL_MAP_STEP_PX := 4
const V7_MAX_REGISTERED_SITES := 4600
const V7_STAND_BUCKET_PX := 512.0
const V7_SITE_BUCKET_PX := 96.0
const V7_FROZEN_RF := "res://art/maps/world_map_v15_complete_v5/terrain_height.rf"
const V7_FROZEN_RF_SHA := "b7210634cbc2d7a2809bfab608e47930d5717459b01dc42df33ae9e6919548b9"

# Each forest/bamboo acceptance rectangle spans at least two whole screens.
# >8% is an actual opaque-alpha union requirement, NOT inferred from stem count.
const V7_COVERAGE_REGIONS := [
	{"id":"northeastern_forest","rect":Rect2(8800,1400,3072,2048),"kinds":["tree"],"minimum_union_fraction":.08},
	{"id":"western_forest","rect":Rect2(300,3550,3072,2048),"kinds":["tree"],"minimum_union_fraction":.08},
	{"id":"southern_bamboo","rect":Rect2(2350,6100,3072,2048),"kinds":["bamboo"],"minimum_union_fraction":.08},
	{"id":"lingyue_bamboo","rect":Rect2(9750,4000,2048,2048),"kinds":["bamboo"],"minimum_union_fraction":.08}]

# Unequal contiguous copses with internal glades and irregular forest margins.
# These are real independent stems with three existing approved prototype poses.
# Count is a bounded authoring request; clearance rejection remains explicit.
const V7_STANDS := [
	{"id":"ne_west","center":Vector2(9470,1810),"radius":Vector2(540,390),"kind":"tree","count":116},
	{"id":"ne_south","center":Vector2(9970,2710),"radius":Vector2(540,350),"kind":"tree","count":110},
	{"id":"ne_east","center":Vector2(11340,2180),"radius":Vector2(470,480),"kind":"tree","count":108},
	{"id":"ne_low","center":Vector2(11130,2970),"radius":Vector2(610,310),"kind":"tree","count":112},
	{"id":"west_north","center":Vector2(980,3950),"radius":Vector2(520,410),"kind":"tree","count":116},
	{"id":"west_middle","center":Vector2(1620,4510),"radius":Vector2(570,370),"kind":"tree","count":114},
	{"id":"west_east","center":Vector2(2870,4770),"radius":Vector2(430,440),"kind":"tree","count":108},
	{"id":"west_low","center":Vector2(930,5130),"radius":Vector2(520,320),"kind":"tree","count":112},
	{"id":"south_west","center":Vector2(2840,7130),"radius":Vector2(480,360),"kind":"bamboo","count":345},
	{"id":"south_north","center":Vector2(3560,6360),"radius":Vector2(620,230),"kind":"bamboo","count":330},
	{"id":"south_middle","center":Vector2(3720,7580),"radius":Vector2(500,380),"kind":"bamboo","count":354},
	{"id":"south_east","center":Vector2(4810,7100),"radius":Vector2(490,470),"kind":"bamboo","count":360},
	{"id":"ling_north","center":Vector2(10270,4320),"radius":Vector2(440,300),"kind":"bamboo","count":216},
	{"id":"ling_west","center":Vector2(10090,5210),"radius":Vector2(310,490),"kind":"bamboo","count":224},
	{"id":"ling_middle","center":Vector2(10910,5540),"radius":Vector2(420,270),"kind":"bamboo","count":230},
	{"id":"ling_east","center":Vector2(11600,5360),"radius":Vector2(280,440),"kind":"bamboo","count":210},
	{"id":"marsh_north","center":Vector2(10720,5940),"radius":Vector2(540,170),"kind":"bamboo","count":124},
	{"id":"marsh_south","center":Vector2(11580,7310),"radius":Vector2(270,480),"kind":"bamboo","count":124}]

var v7_stand_buckets: Dictionary={}
var v7_site_buckets: Dictionary={}
var v7_floor_patches: Array[Dictionary]=[]
var v7_placement_audit: Array[Dictionary]=[]
var v7_proposal_error := ""

func validate_v7_parent() -> bool:
	if FileAccess.get_sha256(V7_PARENT_SOURCE).to_lower()!=V7_PARENT_SHA:
		v7_proposal_error="Frozen authoring source changed; v7 proposal refuses inheritance."
		return false
	return true

func prepare_proposal_from_frozen_rf() -> bool:
	# Explicit call only. No export/default SceneTree and no RF reconstruction.
	# Readonly exact older authoring RF is disclosed as geometry cache input;
	# it is not a new capture or a v7 approval witness.
	if not validate_v7_parent(): return false
	if FileAccess.get_sha256(V7_FROZEN_RF).to_lower()!=V7_FROZEN_RF_SHA:
		v7_proposal_error="Exact frozen Float32 RF missing/changed; no fallback geometry."
		return false
	var bytes: PackedByteArray=FileAccess.get_file_as_bytes(V7_FROZEN_RF)
	if bytes.size()!=GRID_SIZE.x*GRID_SIZE.y*4:
		v7_proposal_error="Frozen RF byte count does not match1537x1025 Float32."
		return false
	heights=bytes.to_float32_array()
	prepare()
	return v7_proposal_error.is_empty()

func _prepare_ecology_sites() -> void:
	super._prepare_ecology_sites()
	v7_stand_buckets.clear()
	v7_site_buckets.clear()
	v7_floor_patches.clear()
	v7_placement_audit.clear()
	v7_proposal_error=""
	if not validate_v7_parent(): return
	# Original IDs, poses, coordinates and trunk/full-XZ rules remain registered.
	for site in vegetation_sites: _v7_index_site(site)
	for stand in occupied_stands:
		_v7_index_floor({"center":stand["center"],"radius":Vector2(240,185),"id":"original_occupied_stand","kind":stand["kind"]})
	for i in range(V7_STANDS.size()): _v7_append_stand(V7_STANDS[i],i)
	_v7_append_bank_cover()
	_v7_append_rock_aprons()
	if vegetation_sites.size()>V7_MAX_REGISTERED_SITES:
		v7_proposal_error="Actual site registration exceeded bounded proposal budget; no silent truncation."

func _v7_index_site(site: Dictionary) -> void:
	var p: Vector2=site["source_foot"]
	var key:=Vector2i((p/V7_SITE_BUCKET_PX).floor())
	if not v7_site_buckets.has(key): v7_site_buckets[key]=[]
	v7_site_buckets[key].append(site)

func _v7_stem_separated(p: Vector2,kind: String) -> bool:
	var key:=Vector2i((p/V7_SITE_BUCKET_PX).floor())
	for y in range(-1,2):
		for x in range(-1,2):
			for old in v7_site_buckets.get(key+Vector2i(x,y),[]):
				# No overlapping trunk solids. Crowns may form real layered canopies.
				var spacing: float=240. if kind=="boulder" or old["kind"]=="boulder" else 39. if kind=="tree" or old["kind"]=="tree" else 22.
				if p.distance_squared_to(old["source_foot"])<spacing*spacing: return false
	return true

func _v7_dry_stem_clear(p: Vector2,kind: String) -> bool:
	if not _ecology_clear(p) or not _v7_stem_separated(p,kind): return false
	# Uses the inherited exact entire-selector-cell triangle rule. Never white
	# water or steep RF to accommodate a plant. Compound polygons are additionally
	# required in the future FULL forecast, not replaced by these authoring guards.
	for offset in foot_offsets():
		if not bool(selector_cell_info(p+offset)["walk"]): return false
	return true

func _v7_append_stand(spec: Dictionary,index: int) -> void:
	var center: Vector2=spec["center"]
	var radius: Vector2=spec["radius"]
	var kind: String=spec["kind"]
	var accepted := 0
	var rejected := 0
	var count: int=int(spec["count"])
	var actual_bounds:=Rect2()
	for stem in range(count):
		var angle: float=float(stem)*2.399963229728653+index*.713
		var reach: float=sqrt((stem+.5)/float(count))
		var irregular: float=.83+.12*sin(angle*2.31+index)+.05*cos(angle*5.13)
		var local:=Vector2(cos(angle),sin(angle))*reach*irregular
		# Two unequal glades; not repetitive radial holes in every copse.
		if local.distance_to(Vector2(.19*sin(index*.71),-.14))<(.13+.03*(index%3)):
			rejected+=1
			continue
		var p: Vector2=center+local*radius+Vector2(sin(stem*1.43),cos(stem*.91))*9.
		if not _v7_dry_stem_clear(p,kind):
			rejected+=1
			continue
		var site: Dictionary={"id":"v7_%s_stem_%04d"%[spec["id"],stem],"kind":kind,"source_foot":p,"pose":(stem+index)%3,"collision_size_px":Vector2(18,14) if kind=="tree" else Vector2(12,10),"blocking":true,"stand_id":"v7_"+String(spec["id"]),"source_attribution":"verified CC0 TreeSmall02 native hybrid sourcebody; original three scales/yaws" if kind=="tree" else "verified CC0 Yughues original1440tri OBJ/3TGA native sourcebody; original three scales/yaws","v7_caster_recipe":"PENDING_V7_ACTUAL_PROTOTYPE_RGBA_CAMERA_PLANE_REGIONAL_GPU_APPROVAL","v7_geometry_recipe":"reuse exact original kind/pose RGBA and measured sprite foot. New cheap caster is a disclosed2.5D alpha plane, NOT original native GLTF tree; own RF footY and original separate trunk collider"}
		vegetation_sites.append(site)
		_v7_index_site(site)
		actual_bounds=Rect2(p,Vector2.ZERO) if accepted==0 else actual_bounds.expand(p)
		accepted+=1
	if accepted>=12:
		# Floor ownership derived from actual accepted stems; separate from the
		# required visible-alpha union proof. Not a forest-painted empty ellipse.
		var footprint: Rect2=actual_bounds.grow(55.)
		_v7_index_floor({"id":"v7_"+String(spec["id"]),"center":footprint.get_center(),"radius":footprint.size*.52,"kind":kind,"actual_stem_count":accepted})
		occupied_stands.append({"center":footprint.get_center(),"stem_count":accepted,"kind":kind,"v7_floor_extent_px":footprint})
	v7_placement_audit.append({"id":spec["id"],"kind":kind,"requested":count,"accepted":accepted,"rejected":rejected,"actual_source_foot_bounds":actual_bounds,"coverage":"PENDING_ACTUAL_RENDERED_ALPHA_UNION_NOT_COUNT"})

func _v7_append_bank_cover() -> void:
	# Real unchanged Shrub03 low broadleaf vegetation, explicitly NOT reeds.
	# Broken elongated dry-bank colonies follow physical river distance.
	var count := 0
	for y in range(5740,7970,46):
		for x in range(9140,12030,57):
			var p:=Vector2(x,y)+Vector2(sin(x*.047+y*.023)*17.,cos(y*.039-x*.017)*14.)
			var margin: float=bank(p)
			var road: Vector2=road_distance(p)
			if margin<36. or margin>210. or road.x<road.y+100.: continue
			if sin(p.x/133.+.8*sin(p.y/271.))+.43*cos(p.y/91.)<-.30: continue
			if not _v7_dry_stem_clear(p,"herb"): continue
			var site: Dictionary={"id":"v7_bank_cover_%04d"%count,"kind":"herb","source_foot":p,"pose":count%3,"collision_size_px":Vector2.ZERO,"blocking":false,"stand_id":"v7_dry_sediment_colonies","source_attribution":"registered CC0 Shrub03 unchanged low broadleaf model; NOT reed, not enlarged or stretched","v7_same_sourcebody_and_caster":true}
			vegetation_sites.append(site)
			_v7_index_site(site)
			count+=1
	v7_placement_audit.append({"id":"dry_bank_cover","accepted":count,"geometry":"same RF actual dry bank; no water support or nav repaint"})

func _v7_append_rock_aprons() -> void:
	# Genuine licensed volumetric objects provide rock mass on unchanged RF.
	# No shader peak/displacement or pass-through terrain-baked rock silhouette.
	var accepted := 0
	for group in range(ROCK_SHOULDERS.size()):
		var center: Vector2=ROCK_SHOULDERS[group]["center"]
		for piece in range(8):
			var angle: float=piece*2.399963+group*.83
			var reach: float=230.+sqrt(piece+.4)*100.
			var p: Vector2=center+Vector2(cos(angle)*reach,sin(angle)*reach*.72+180.)
			var road: Vector2=road_distance(p)
			if road.x<road.y+310. or not _v7_dry_stem_clear(p,"boulder"): continue
			var site: Dictionary={"id":"v7_rock_apron_%d_%d"%[group,piece],"kind":"boulder","source_foot":p,"pose":(group+piece)%3,"blocking":true,"collision_size_px":Vector2.ZERO,"collision_recipe":"PENDING actual transformed used-index fullXZ bounds from unchanged three prototypes; zero placeholder is NOT a passable blocker","source_attribution":"registered Poly Haven boulder_01 original raw GLTF/model UV atlas; original three prototype scales/yaws","v7_same_sourcebody_and_caster":true}
			vegetation_sites.append(site)
			_v7_index_site(site)
			accepted+=1
	v7_placement_audit.append({"id":"north_west_snow_rock_aprons","accepted":accepted,"support":"own actual RF altitude and unchanged used-index minY; real fullXZ blocker required at export","scope":"volumetric independent boulder addition, inherited terrain mesh still byte unchanged"})

func _v7_index_floor(patch: Dictionary) -> void:
	v7_floor_patches.append(patch)
	var radius: Vector2=patch["radius"]
	var rect:=Rect2(Vector2(patch["center"])-radius*1.25,radius*2.5)
	var a:=Vector2i((rect.position/V7_STAND_BUCKET_PX).floor())
	var b:=Vector2i((rect.end/V7_STAND_BUCKET_PX).floor())
	for y in range(a.y,b.y+1):
		for x in range(a.x,b.x+1):
			var key:=Vector2i(x,y)
			if not v7_stand_buckets.has(key): v7_stand_buckets[key]=[]
			v7_stand_buckets[key].append(patch)

func habitat(p: Vector2) -> Vector4:
	# Finite spatially indexed occupied floors, not O(pixel_count*all_stands).
	var weights:=Vector4.ZERO
	for region in HABITATS:
		var q: Vector2=(p-Vector2(region["center"]))/Vector2(region["radius"])
		var owner: float=1.-smoothstep(.52,1.10,q.length())
		weights.y=maxf(weights.y,owner*float(region["rock"]))
		weights.z=maxf(weights.z,owner*float(region["wet"]))
		weights.w=maxf(weights.w,owner*float(region["snow"]))
	for patch in v7_stand_buckets.get(Vector2i((p/V7_STAND_BUCKET_PX).floor()),[]):
		var q: Vector2=(p-Vector2(patch["center"]))/Vector2(patch["radius"])
		weights.x=maxf(weights.x,(1.-smoothstep(.67,1.20,q.length()))*.96)
	# Exposed rock/snow follow exact inherited relief, never a new RF or mask.
	var h: float=triangle_height(p)
	weights.y*=smoothstep(.15,1.10,h)
	var scoured: float=.5+.22*sin(p.x/367.+.6*sin(p.y/571.))+.18*cos(p.y/293.)
	weights.w*=smoothstep(.24,.65,scoured)*smoothstep(1.2,3.0,h)
	weights.z*=1.-smoothstep(90.,340.,maxf(0.,bank(p)))
	var tea: float=((p-Vector2(11100,7900))/Vector2(700,650)).length()
	weights.z*=smoothstep(.3,1.1,tea)
	return weights

func visual_material_maps(rect: Rect2) -> Dictionary:
	# Opt-in replacement for a future NEW builder's old 8px _material_maps.
	# Does not alter source_topology, selector texture, RF or authority nav.
	var shape:=Vector2i(ceili(rect.size.x/VISUAL_MATERIAL_MAP_STEP_PX),ceili(rect.size.y/VISUAL_MATERIAL_MAP_STEP_PX))
	var biome:=Image.create(shape.x,shape.y,false,Image.FORMAT_RGBA8)
	var roads_image:=Image.create(shape.x,shape.y,false,Image.FORMAT_RGB8)
	for y in range(shape.y):
		for x in range(shape.x):
			var p: Vector2=rect.position+Vector2(x+.5,y+.5)*VISUAL_MATERIAL_MAP_STEP_PX
			var owner: Vector4=habitat(p)
			biome.set_pixel(x,y,Color(owner.x,owner.y,owner.z,owner.w))
			var road: Vector2=road_distance(p)
			# Core to shoulder transition is 6 physical source pixels, not a
			# nested 50px smoothstep. Shoulder ownership stays a distinct G channel.
			var core: float=1.-smoothstep(road.y*.75-3.,road.y*.75+3.,road.x)
			var shoulder: float=1.-smoothstep(road.y*.82,road.y+22.,road.x)
			roads_image.set_pixel(x,y,Color(core,shoulder,sand_weight(p)))
	return {"biome":biome,"roads":roads_image,"step_px":VISUAL_MATERIAL_MAP_STEP_PX,"logical_source_rect_px":rect,"sampling":"source pixel centres; no mip on ownership maps; linear sampling; RF/nav unchanged"}

func v7_navigation_recheck_scope() -> Dictionary:
	return {"RF_global_mesh_selector_binary_raster":"must remain original byte SHA; visual ownership maps are separate","final_walk_mask":"retain original ground/deck raster; may change only if existing FULL export explicitly subtracts new physical solids; cannot promise unchanged final walk until actual inspection","physical_navigation":"new blocking tree/bamboo/boulder solids change physical layout even when binary ground/deck raster is unchanged; every mandatory road/door full17 plus actual Field bypass/depth must be reverified","added_caster_options":[{"id":"actual_RGBA_camera_plane","status":"NEW_HELPER_SOURCE_ONLY_PENDING_REGIONAL_GPU_APPROVAL","helper":"res://scripts/dev/world_map_v15_complete_v7_billboard_caster_proposal.gd","body":"same exact verified original kind/pose native RGBA at original scale/foot_uv","caster":"new2triangle project plane with same original PNG alpha and exact fixed-camera mapping, newly rendered shadow; not claimed GLTF geometry/minY proof","required_proof":"actual plane/sourcebody mapping, silhouette, ownfoot, shadowON/OFF, native arrays and regional GPU frame cost"},{"id":"original_draw_geometry","status":"fallback ONLY by explicit approval, expensive","body":"same exact original kind/pose alpha","caster":"same selected original draw indices/support/material","required_proof":"actual whole/region GPU triangles and frame time"}]}

func measure_v7_alpha_union(actual_objects: Array[Dictionary]) -> Dictionary:
	# Consume actual captured/copied PNGs, actual world foot and exact foot_uv.
	# Bounded one regional L8 occupancy array at a time, never a whole CPU image.
	# No alpha scaling, artificial dilation, shadow contribution or count proxy.
	var results: Array[Dictionary]=[]
	var all_passed := true
	for region in V7_COVERAGE_REGIONS:
		var rect: Rect2=region["rect"]
		var size:=Vector2i(rect.size)
		var occupied:=PackedByteArray()
		occupied.resize(size.x*size.y)
		occupied.fill(0)
		var included := 0
		var sources: Dictionary={}
		var errors: Array[String]=[]
		for object in actual_objects:
			if not String(object.get("kind","")) in region["kinds"]: continue
			if not object.has("world_foot_px") or not object.has("foot_uv") or not object.has("render_size_px"):
				errors.append("Missing actual image/foot geometry: "+String(object.get("id","")))
				continue
			var footprint: Array=object["world_foot_px"]
			var uv_values: Array=object["foot_uv"]
			var render_values: Array=object["render_size_px"]
			var render:=Vector2(render_values[0],render_values[1])
			var origin:=Vector2(footprint[0],footprint[1])-Vector2(uv_values[0],uv_values[1])*render
			if not Rect2(origin,render).intersects(rect): continue
			var path: String=object.get("texture","")
			var image: Image=Image.load_from_file(path)
			if image==null or image.is_empty() or Vector2(image.get_size())!=render:
				errors.append("No exact original-size sourcebody for coverage: "+path)
				continue
			included+=1
			sources[path]=FileAccess.get_sha256(path)
			for y in range(image.get_height()):
				for x in range(image.get_width()):
					if image.get_pixel(x,y).a<=30./255.: continue
					var world: Vector2=origin+Vector2(x+.5,y+.5)
					var local:=Vector2i((world-rect.position).floor())
					if local.x>=0 and local.y>=0 and local.x<size.x and local.y<size.y: occupied[local.y*size.x+local.x]=1
		var total := 0
		for byte in occupied: total+=byte
		var fraction: float=float(total)/float(size.x*size.y)
		var passed: bool=errors.is_empty() and fraction>float(region["minimum_union_fraction"])
		all_passed=all_passed and passed
		results.append({"id":region["id"],"logical_rect_px":[rect.position.x,rect.position.y,rect.size.x,rect.size.y],"alpha_threshold_byte":30,"actual_union_pixels":total,"actual_union_fraction":fraction,"minimum_exclusive":region["minimum_union_fraction"],"actual_intersecting_instances":included,"actual_sourcebody_sha256":sources,"errors":errors,"passed":passed,"scope":"native sourcebody alpha union at unchanged 1:1 logical size; independent body union, not terrain-baked crowns or cast shadows"})
	return {"status":"ACTUAL_COVERAGE_MEASUREMENT_NOT_VISUAL_APPROVAL","passed":all_passed,"regions":results}

func v7_proposal_contract() -> Dictionary:
	var counts: Dictionary={}
	for site in vegetation_sites:
		var kind: String=site["kind"]
		counts[kind]=int(counts.get(kind,0))+1
	return {"status":"SOURCE_ONLY_PROPOSAL_NOT_EXECUTED_OR_APPROVED","coordinate_version":15,"revision":V7_REVISION,"authoring_parent":{"path":V7_PARENT_SOURCE,"sha256":V7_PARENT_SHA},"geometry_cache_input":{"path":V7_FROZEN_RF,"sha256":V7_FROZEN_RF_SHA,"scope":"readonly exact original geometry cache, NOT new capture proof"},"unchanged_authorities":["Float32 RF","global native mesh arrays","entire-2px-cell selector","27 route IDs/points","16 source door/target/solid contracts","9 core center/door spacing","5 actual bridge supports"],"visual_material_map_step_px":VISUAL_MATERIAL_MAP_STEP_PX,"navigation_step_px":SELECTOR_STEP,"actual_registered_counts":counts,"placement_audit":v7_placement_audit,"error":v7_proposal_error,"coverage_status":"PENDING_ACTUAL_ALPHA_UNION_REQUIRED_GT_8_PERCENT","coverage_regions":V7_COVERAGE_REGIONS,"navigation_recheck_scope":v7_navigation_recheck_scope(),"performance_scope":"original394 source models retain their existing recipe. Added tree/bamboo sourcebody may be byte-reused, with proposed newly rendered2triangle actual-alpha plane caster rather than silently drawing1.95Mtri for each additional tree. Plane/foot/shadow recipe must pass bounded regional GPU before FULL","required_rechecks":["27 full17 road routes and 16 actual door passages vs all new trunk/fullXZ solids","actual RF ground/support/Y for every new instance","all actual alpha/crop/material/mesh sourcegraph and caster binding","per-region alpha union >8% and actual 1:1 visual review","new visual/shadow_off exact repeats and independent whole captures","nav/land/RF/mesh byte equality; new physical-object layout must be independently tested"]}
