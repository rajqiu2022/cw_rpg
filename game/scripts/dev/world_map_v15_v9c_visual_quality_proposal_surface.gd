extends "res://scripts/dev/world_map_v15_v9b_visual_quality_proposal_surface.gd"

## NEW source-only response to ROOT196. Actual CC0 diffuse is again the main
## surface signal, not converted to a luma-driven native two-colour lawn.
## Physical scans, raw bytes, normal/ARM triplets and mip chains remain intact.
const V9C_MATERIAL_ID := "V9C_ACTUAL_SCAN_LOCAL_EIGHT_PIXEL_CULTIVATION_OPAQUE_SOIL_PROPOSAL"
const V9C_ROW_PERIOD_PX := 8.0

func _v9b_parcel_branch(index: int,parcel: Vector4) -> String:
	# Eight projected logical pixels on flat farmland, not the prior .924m
	# period (67..95px). Slight irregularity is amplitude-limited below 1px.
	# The axis lives in source pixel coordinates, not anisotropic metre axes.
	return """ {
 vec4 parcel=vec4(%.9f,%.9f,%.9f,%.9f);vec2 delta=p-parcel.xy;
 float angle=sin(%.9f*2.17)*.61;vec2 axis=vec2(cos(angle),sin(angle));
 vec2 local=vec2(dot(delta,axis),dot(delta,vec2(-axis.y,axis.x)))/parcel.zw;
 float margin=max(abs(local.x),abs(local.y));
 float owner=1.-smoothstep(.980,1.014,margin);
 float phase=dot(delta,axis)*.785398163397+%.9f*1.73+(n2(xyz.xz/2.3)-.5)*.35;
 if(owner>field_owner){field_owner=owner;crop=.20+.35*smoothstep(.55,.88,.5+.5*sin(phase));furrow_n=cos(phase);}
 }
"""%[parcel.x,parcel.y,parcel.z,parcel.w,float(index),float(index)]

func terrain_material(weights: Texture2D,roads: Texture2D,local_rect: Rect2) -> ShaderMaterial:
	var material: ShaderMaterial=super.terrain_material(weights,roads,local_rect)
	if material==null: return null
	var old: String=material.shader.code
	if old.count("void fragment(){")!=1 or old.count("void vertex(){xyz=VERTEX;geo=NORMAL;}")!=1 or old.count("uniform float v9b_material_identity=1.;")!=1:
		error="V9C actual inherited vertex/sampler/header anchors absent."
		return null
	var header: String=old.substr(0,old.find("void fragment(){"))
	var code: String=header.replace("uniform float v9b_material_identity=1.;","uniform float v9c_material_identity=1.;")+_v9c_fragment()
	var bound: Dictionary={}
	for uniform: Dictionary in material.shader.get_shader_uniform_list():
		var name: String=String(uniform["name"])
		if name!="v9b_material_identity": bound[name]=material.get_shader_parameter(name)
	var shader:=Shader.new()
	shader.code=code
	material.shader=shader
	for name: String in bound: material.set_shader_parameter(name,bound[name])
	material.set_shader_parameter("v9c_material_identity",1.)
	v7_material_records.back()["identity"]=V9C_MATERIAL_ID
	v7_material_records.back()["shader_code_sha256"]=_v7_code_sha(code)
	v8_material_records.back()["identity"]=V9C_MATERIAL_ID
	v8_material_records.back()["actual_code_sha256"]=_v7_code_sha(code)
	for row: Dictionary in v9_material_records:
		if row.get("kind")=="terrain":
			row["kind"]="inherited_terrain_provenance_replaced"
			row["no_longer_attached_to_receiver"]=true
			row["actual_attached_code_sha256"]=_v7_code_sha(code)
	v9_material_records.append({"identity":V9C_MATERIAL_ID,"kind":"terrain","actual_script_path":get_script().resource_path,"actual_script_sha256":FileAccess.get_sha256(get_script().resource_path),"parent_actual_code_sha256":_v7_code_sha(old),"actual_code_sha256":_v7_code_sha(code),"registered_binding":_v7_binding_evidence(material),"finite_parcels":V9_PARCELS,"row_period_logical_px":V9C_ROW_PERIOD_PX,"finite_edge_source_px_range":[4.59,8.33],"actual_scan_ALBEDO_primary":true,"owner_debug_prior_actual_array_upload_works":true,"geometry_navigation_change_by_this_surface":false,"opaque_soil_pools_are_NOT_water_support":true,"visual_approved":false,"production_approved":false,"provenance":"unchanged18 official CC0 physical scan triplets plus declared native soil moisture, mineral weathering and snow material formulas; no new CC0 scan/no geometry displacement"})
	return material

func _v9c_fragment() -> String:
	return """void fragment(){
 vec2 p=vec2(xyz.x*102.4+6144.,xyz.z*72.40773439+4096.);
 vec2 uv=(p-source_rect.xy)/source_rect.zw;
 vec4 eco=texture(biome_weights,uv);vec3 road=texture(road_weights,uv).rgb;
 vec3 gn=normalize(geo);vec3 w=pow(abs(gn),vec3(4.));w/=max(dot(w,vec3(1.)),.00001);
 float forest=clamp(eco.r,0.,1.),rock=clamp(eco.g,0.,1.),wet=clamp(eco.b,0.,1.),snow=clamp(eco.a,0.,1.);
 float route=clamp(road.r,0.,1.),sand=road.b*(1.-snow)*(1.-forest);
 float patch=n2(xyz.xz/1.9)*.38+n2(xyz.xz/5.8+vec2(7.,-3.))*.62;
 float growth=smoothstep(.34,.67,patch);
 // Registered diffuse stays in RGB. Native pigment correction is a small
 // multiplier, not replacement by two flat colours or a luma-only field.
 vec3 gd=scan(grass_ground_diff,2.51,w,.25),ld=scan(leafy_grass_diff,2.,w,.25);
 vec3 fd=scan(forest_ground_04_diff,3.2,w,0.),rd=scan(rock_01_diff,1.5,w,0.);
 vec3 bd=scan(brown_mud_03_diff,1.3,w,.25),ad=scan(aerial_grass_rock_diff,15.,w,0.);
 vec3 ga=scan(grass_ground_arm,2.51,w,.25),la=scan(leafy_grass_arm,2.,w,.25);
 vec3 fa=scan(forest_ground_04_arm,3.2,w,0.),ra=scan(rock_01_arm,1.5,w,0.);
 vec3 ba=scan(brown_mud_03_arm,1.3,w,.25),aa=scan(aerial_grass_rock_arm,15.,w,0.);
 vec3 gnscan=scan(grass_ground_nor_gl,2.51,w,.25),ln=scan(leafy_grass_nor_gl,2.,w,.25);
 vec3 fn=scan(forest_ground_04_nor_gl,3.2,w,0.),rn=scan(rock_01_nor_gl,1.5,w,0.);
 vec3 bn=scan(brown_mud_03_nor_gl,1.3,w,.25),an=scan(aerial_grass_rock_nor_gl,15.,w,0.);
 vec3 turf=(gd*.62+ld*.30+ad*.08)*vec3(.97,1.04,.94);
 vec3 turf_a=ga*.62+la*.30+aa*.08,turf_n=gnscan*.62+ln*.30+an*.08;
 vec3 loam=fd*.50+rd*.38+bd*.12;
 vec3 loam_a=fa*.50+ra*.38+ba*.12,loam_n=fn*.50+rn*.38+bn*.12;
 float dry_island=.12+.34*(1.-growth);
 vec3 col=mix(turf,loam,dry_island),arm=mix(turf_a,loam_a,dry_island),detail=mix(turf_n,loam_n,dry_island);
 // Real litter/soil detail at roots, not a flat black forest disk.
 vec3 litter=ld*.48+fd*.40+rd*.12;
 col=mix(col,litter*vec3(.69,.72,.66),forest*.80);
 arm=mix(arm,la*.48+fa*.40+ra*.12,forest*.80);detail=mix(detail,ln*.48+fn*.40+rn*.12,forest*.80);
 """+_v9b_literal_parcels()+"""
 field_owner*=.88*(1.-route)*(1.-forest)*(1.-wet)*(1.-rock)*(1.-snow)*(1.-sand);
 // Narrow ridges between actual granular earth and actual low grass scans.
 // No full-region high-contrast green/brown ALBEDO sine bands.
 col=mix(col,mix(loam,turf,crop)*(.97+.035*furrow_n),field_owner);
 arm=mix(arm,mix(loam_a,turf_a,crop),field_owner);
 detail=mix(detail,mix(loam_n,turf_n,crop),field_owner);
 // Mineral patches retain RGB scan grains at the real1.5/3.2/15m periods.
 float plate=smoothstep(.29,.67,n2(xyz.xz/1.3)*.40+n2(xyz.xz/4.4)*.60);
 vec3 mineral=rd*.72+fd*.20+ad*.08;
 mineral=mix(mineral,mineral*vec3(.98,1.01,1.02),.35);
 float exposed=rock*.95*(1.-snow);
 col=mix(col,mix(mineral,loam,plate*.22),exposed);
 arm=mix(arm,ra*.72+fa*.20+aa*.08,exposed);detail=mix(detail,rn*.72+fn*.20+an*.08,exposed);
 // Existing native sand owner, explicitly not a licensed sand photograph.
 float sand_owner=sand*.90;
 col=mix(col,mix(fd*.43+rd*.57,vec3(.38,.34,.25),.20),sand_owner);
 arm=mix(arm,fa*.43+ra*.57,sand_owner);detail=mix(detail,fn*.43+rn*.57,sand_owner);
 // Irregular opaque wet-soil films/pools on already legal RF soil. They
 // never alter ALPHA/discard/waterY/land/navigation or become walk support.
 float pool=smoothstep(.43,.64,n2(xyz.xz/1.2)*.30+n2(xyz.xz/3.4+vec2(4.,9.))*.70);
 float wet_owner=wet*.97*(1.-route);
 vec3 silt=fd*.43+rd*.34+bd*.23;
 vec3 wet_col=mix(silt*vec3(.76,.78,.72),silt*vec3(.36,.43,.39),pool);
 col=mix(col,wet_col,wet_owner);
 vec3 wet_a=fa*.43+ra*.34+ba*.23;wet_a.g=mix(wet_a.g*.82,.15,pool*.86);
 arm=mix(arm,wet_a,wet_owner);detail=mix(detail,fn*.43+rn*.34+bn*.23,wet_owner*(1.-pool*.30));
 // Material snow coverage is irregular; it cannot certify that a cached
 // shelf mesh has been repaired. A derived-RF executor must say so honestly.
 float grade=length(gn.xz)/max(abs(gn.y),.05);
 float deposit=snow*smoothstep(.22,.60,n2(xyz.xz/1.1)*.38+n2(xyz.xz/2.7+vec2(-3.,5.))*.62)*(1.-smoothstep(.36,1.12,grade)*.72);
 float snow_bed=snow*(1.-deposit);
 col=mix(col,mineral,snow_bed);arm=mix(arm,ra*.72+fa*.20+aa*.08,snow_bed);detail=mix(detail,rn*.72+fn*.20+an*.08,snow_bed);
 vec3 snow_col=mix(vec3(.68,.71,.70),vec3(.85,.87,.86),clamp(rd.r*.80+patch*.45,0.,1.));
 col=mix(col,snow_col,deposit);arm=mix(arm,vec3(1.,.78,0.),deposit);
 detail=mix(detail,mix(vec3(.5,.5,1.),rn,.28),deposit);
 // Coherent compact earth with real mineral ALBEDO/ARM/normal, not a blurred
 // whole brown colour replacement and not the cracked mud scan as a road.
 float compact=n2(xyz.xz/.56)*.34+n2(xyz.xz/2.1)*.66;
 vec3 earth=mix(vec3(.25,.23,.18),vec3(.34,.30,.24),compact);
 vec3 aggregate=fd*.40+rd*.60;
 vec3 lane=mix(earth,aggregate,.48);
 float shoulder=clamp(road.g-route,0.,1.);
 col=mix(col,mix(loam,lane,.65),shoulder*.64);col=mix(col,lane,route);
 arm=mix(arm,mix(vec3(1.,.90,0.),fa*.40+ra*.60,.48),route);
 detail=mix(detail,mix(vec3(.5,.5,1.),fn*.40+rn*.60,.48),route);
 ALBEDO=col;AO=mix(1.,arm.r,.24);ROUGHNESS=clamp(arm.g,.14,.98);SPECULAR=mix(.18,.34,pool*wet_owner);METALLIC=0.;
 float strength=mix(.26,.20,route);vec3 wn=normalize(gn+vec3((detail.r-.5)*strength,0.,(detail.g-.5)*strength));
 wn=normalize(wn+vec3(furrow_n*.07*field_owner,0.,0.));NORMAL=normalize((VIEW_MATRIX*vec4(wn,0.)).xyz);
}
"""
