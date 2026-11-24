extends "res://scripts/dev/world_map_v15_v9c_visual_quality_proposal_surface.gd"

## NEW surface-only response to ROOT213 actual visual FAIL. The unchanged18
## verified CC0 RGB/normal/ARM sources remain the actual samplers/full mips.
## Native pigment/moisture/snow formulas are project-original, NOT new scans.
## This does not create reed geometry/water, displace vertices or certify art.
const V9D_SURFACE_ID := "V9D_RGB_GRASS_DAMP_SILT_PALE_MINERAL_STEEP_SNOW_EXCLUSION_PROPOSAL"
const V9D_PARENT_SURFACE_PATH := "res://scripts/dev/world_map_v15_v9c_visual_quality_proposal_surface.gd"
const V9D_PARENT_SURFACE_SHA := "d14e792202263186423751b030151eb2238cfa82ff00e2080ce859206f9f9627"

func terrain_material(weights: Texture2D,roads: Texture2D,local_rect: Rect2) -> ShaderMaterial:
	if FileAccess.get_sha256(V9D_PARENT_SURFACE_PATH).to_lower()!=V9D_PARENT_SURFACE_SHA:
		error="Frozen V9C surface differs; no material fallback."
		return null
	var material: ShaderMaterial=super.terrain_material(weights,roads,local_rect)
	if material==null or material.shader.code.count("uniform float v9d_material_identity=1.;")!=1:
		error="Actual V9D fragment was not dynamically installed."
		return null
	material.set_shader_parameter("v9d_material_identity",1.)
	for records: Array in [v7_material_records,v8_material_records,v9_material_records]:
		for row: Dictionary in records:
			if row.get("kind","terrain")=="terrain" and row.get("no_longer_attached_to_receiver",false)!=true:
				row["identity"]=V9D_SURFACE_ID
				row["actual_script_path"]=get_script().resource_path
				row["actual_script_sha256"]=FileAccess.get_sha256(get_script().resource_path)
	var row: Dictionary=v9_material_records.back()
	row["actual_code_sha256"]=_v7_code_sha(material.shader.code)
	row["registered_binding"]=_v7_binding_evidence(material)
	row["grass_RGB_triplet_weights"]={"grass":.80,"leafy":.20,"default_soil_patch_min":.015,"default_soil_patch_max":.10}
	row["forest_RGB_triplet_weights"]={"leafy":.74,"forest":.26}
	row["mineral_RGB_triplet_weights"]={"rock":.93,"aerial":.07}
	row["opaque_damp_soil_triplet_weights"]={"forest":.76,"leafy":.20,"mud":.04}
	row["snow_deposit_actual_grade_fade"]=[.30,.68]
	row["native_pigment_formulas_declared"]=true
	row["lighting_geometry_water_navigation_changed_by_surface"]=false
	row["wet_soil_is_NOT_water_or_reed_geometry"]=true
	row["protected_RF_flat_tops_not_claimed_removed"]=true
	row["visual_approved"]=false
	row["production_approved"]=false
	return material

func _v9c_fragment() -> String:
	return """uniform float v9d_material_identity=1.;
void fragment(){
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
 vec3 turf=(gd*.80+ld*.20)*vec3(.86,1.10,.80);
 vec3 turf_a=ga*.80+la*.20,turf_n=gnscan*.80+ln*.20;
 vec3 loam=fd*.75+rd*.20+bd*.05;
 vec3 loam_a=fa*.75+ra*.20+ba*.05,loam_n=fn*.75+rn*.20+bn*.05;
 float dry_island=.015+.085*(1.-growth);
 vec3 col=mix(turf,loam,dry_island),arm=mix(turf_a,loam_a,dry_island),detail=mix(turf_n,loam_n,dry_island);
 // Real litter/soil detail at roots, not a flat black forest disk.
 vec3 litter=ld*.74+fd*.26;
 col=mix(col,litter*vec3(.74,.94,.69),forest*.80);
 arm=mix(arm,la*.74+fa*.26,forest*.80);detail=mix(detail,ln*.74+fn*.26,forest*.80);
 """+_v9b_literal_parcels()+"""
 field_owner*=.88*(1.-route)*(1.-forest)*(1.-wet)*(1.-rock)*(1.-snow)*(1.-sand);
 // Narrow ridges between actual granular earth and actual low grass scans.
 // No full-region high-contrast green/brown ALBEDO sine bands.
 col=mix(col,mix(loam,turf,crop)*(.97+.035*furrow_n),field_owner);
 arm=mix(arm,mix(loam_a,turf_a,crop),field_owner);
 detail=mix(detail,mix(loam_n,turf_n,crop),field_owner);
 // Mineral patches retain RGB scan grains at the real1.5/3.2/15m periods.
 float plate=smoothstep(.29,.67,n2(xyz.xz/1.3)*.40+n2(xyz.xz/4.4)*.60);
 vec3 mineral=rd*.93+ad*.07;
 mineral*=vec3(1.07,1.08,1.06);
 float exposed=rock*.95*(1.-snow);
 col=mix(col,mix(mineral,loam,plate*.08),exposed);
 arm=mix(arm,ra*.93+aa*.07,exposed);detail=mix(detail,rn*.93+an*.07,exposed);
 // Existing native sand owner, explicitly not a licensed sand photograph.
 float sand_owner=sand*.90;
 col=mix(col,mix(fd*.43+rd*.57,vec3(.38,.34,.25),.20),sand_owner);
 arm=mix(arm,fa*.43+ra*.57,sand_owner);detail=mix(detail,fn*.43+rn*.57,sand_owner);
 // Irregular opaque wet-soil films/pools on already legal RF soil. They
 // never alter ALPHA/discard/waterY/land/navigation or become walk support.
 float pool=smoothstep(.43,.64,n2(xyz.xz/1.2)*.30+n2(xyz.xz/3.4+vec2(4.,9.))*.70);
 float wet_owner=wet*.97*(1.-route)*(1.-snow);
 float bank_film=1.-smoothstep(.04,.25,xyz.y);

 vec3 silt=fd*.76+ld*.20+bd*.04;
 vec3 wet_col=mix(silt*vec3(.47,.58,.44),silt*vec3(.24,.34,.29),pool*.68+bank_film*.20);
 col=mix(col,wet_col,wet_owner);
 vec3 wet_a=fa*.76+la*.20+ba*.04;wet_a.g=mix(wet_a.g*.55,.18,clamp(pool*.66+bank_film*.28,0.,1.));
 arm=mix(arm,wet_a,wet_owner);detail=mix(detail,fn*.76+ln*.20+bn*.04,wet_owner*(1.-pool*.25));
 // Material snow coverage is irregular; it cannot certify that a cached
 // shelf mesh has been repaired. A derived-RF executor must say so honestly.
 float grade=length(gn.xz)/max(abs(gn.y),.05);
 float deposit=snow*smoothstep(.22,.60,n2(xyz.xz/1.8)*.38+n2(xyz.xz/4.7+vec2(-3.,5.))*.62)*(1.-smoothstep(.30,.68,grade));
 float snow_bed=snow*(1.-deposit);
 col=mix(col,mineral,snow_bed);arm=mix(arm,ra*.93+aa*.07,snow_bed);detail=mix(detail,rn*.93+an*.07,snow_bed);
 vec3 snow_col=mix(vec3(.68,.71,.70),vec3(.85,.87,.86),clamp(rd.r*.80+patch*.45,0.,1.));
 col=mix(col,snow_col,deposit);arm=mix(arm,vec3(1.,.78,0.),deposit);
 detail=mix(detail,mix(vec3(.5,.5,1.),rn,.28),deposit);
 // Coherent compact earth with real mineral ALBEDO/ARM/normal, not a blurred
 // whole brown colour replacement and not the cracked mud scan as a road.
 float compact=n2(xyz.xz/.56)*.34+n2(xyz.xz/2.1)*.66;
 vec3 earth=mix(vec3(.25,.23,.18),vec3(.34,.30,.24),compact);
 vec3 aggregate=fd*.70+rd*.30;
 vec3 lane=mix(earth,aggregate,.62);
 float shoulder=clamp(road.g-route,0.,1.);
 col=mix(col,mix(loam,lane,.65),shoulder*.64);col=mix(col,lane,route);
 arm=mix(arm,mix(vec3(1.,.90,0.),fa*.70+ra*.30,.62),route);
 detail=mix(detail,mix(vec3(.5,.5,1.),fn*.70+rn*.30,.62),route);
 ALBEDO=col;AO=mix(1.,arm.r,.24);ROUGHNESS=clamp(arm.g,.14,.98);SPECULAR=mix(.18,.38,clamp((pool*.70+bank_film*.30)*wet_owner,0.,1.));METALLIC=0.;
 float strength=mix(.26,.20,route);vec3 wn=normalize(gn+vec3((detail.r-.5)*strength,0.,(detail.g-.5)*strength));
 wn=normalize(wn+vec3(furrow_n*.07*field_owner,0.,0.));NORMAL=normalize((VIEW_MATRIX*vec4(wn,0.)).xyz);
}
"""
