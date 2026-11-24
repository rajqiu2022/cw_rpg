extends "res://scripts/dev/world_map_v15_complete_v8_surface_proposal.gd"

## Independent visual proposal. Existing 18 CC0 scan channels, physical periods,
## full mips and raw bytes retained. Native colours/soil treatments are original
## project shader formulas, NOT newly licensed scans or displaced geometry.
const V9_MATERIAL_ID := "V9_FINITE_PARCELS_BROKEN_SNOW_DRY_SILT_PHYSICAL_PBR_PROPOSAL"
# Source-space centers/half-spans. Finite parcels, not a world-spanning phase.
const V9_PARCELS := [Vector4(3150,3000,220,170),Vector4(3690,3080,240,150),Vector4(4250,3250,195,210),Vector4(4810,3150,215,145),Vector4(5310,3480,230,190),Vector4(3260,3540,245,190),Vector4(3860,3750,210,145),Vector4(4490,3760,225,195),Vector4(4950,3970,210,175),Vector4(5570,4000,185,135),Vector4(6680,5670,205,160),Vector4(7230,5740,240,180),Vector4(7800,5790,185,210),Vector4(8380,5880,230,175),Vector4(6880,6240,235,165),Vector4(7480,6310,190,160),Vector4(8050,6410,235,180),Vector4(8660,6470,210,150)]
var v9_material_records: Array[Dictionary]=[]

func terrain_material(weights: Texture2D,roads: Texture2D,local_rect: Rect2) -> ShaderMaterial:
	var m: ShaderMaterial=super.terrain_material(weights,roads,local_rect)
	if m==null: return null
	var old: String=m.shader.code
	if old.count("void fragment(){")!=1 or old.count("void vertex(){xyz=VERTEX;geo=NORMAL;}")!=1:
		error="V9 exact inherited vertex/header anchors absent."
		return null
	# Preserve original vertex function and every actual sampler declaration.
	var header: String=old.substr(0,old.find("void fragment(){"))
	var code: String=header+_v9_fragment()
	code=code.replace("varying vec3 xyz;varying vec3 geo;","uniform vec4 finite_parcels[18];\nvarying vec3 xyz;varying vec3 geo;")
	_rich_install(m,code)
	var parcels: Array=[]
	for p: Vector4 in V9_PARCELS: parcels.append(p)
	m.set_shader_parameter("finite_parcels",parcels)
	# Retain parent records as provenance, but never advertise the replaced code
	# as the shader currently attached to the receiver.
	v7_material_records.back()["identity"]=V9_MATERIAL_ID
	v7_material_records.back()["shader_code_sha256"]=_v7_code_sha(m.shader.code)
	v8_material_records.back()["identity"]=V9_MATERIAL_ID
	v8_material_records.back()["actual_code_sha256"]=_v7_code_sha(m.shader.code)
	v9_material_records.append({"identity":V9_MATERIAL_ID,"kind":"terrain","actual_script_path":get_script().resource_path,"actual_script_sha256":FileAccess.get_sha256(get_script().resource_path),
		"inherited_actual_code_sha256":_v7_code_sha(old),"actual_code_sha256":_v7_code_sha(m.shader.code),"registered_binding":_v7_binding_evidence(m),
		"actual_parcel_uniform":m.get_shader_parameter("finite_parcels"),"parcel_uniform_variant_sha256":_v9_variant_sha(m.get_shader_parameter("finite_parcels")),
		"same_owners_for_ALBEDO_ARM_normal":true,"geometry_navigation_change":false,"production_approved":false,"visual_approved":false,
		"provenance":"existing CC0 physical scan detail plus declared project-original regional soil/snow/material treatment; no new scan/geometry"})
	return m

func _v9_variant_sha(value: Variant) -> String:
	var hash:=HashingContext.new()
	hash.start(HashingContext.HASH_SHA256)
	hash.update(var_to_bytes(value))
	return hash.finish().hex_encode()

func water_material(height_rf: Texture2D,grid_origin: Vector2i,grid_shape: Vector2i) -> ShaderMaterial:
	var material: ShaderMaterial=super.water_material(height_rf,grid_origin,grid_shape)
	if material==null: return null
	v9_material_records.append({"identity":"V9_UNCHANGED_V8_RF_WATER_DELEGATION","kind":"water","actual_script_path":get_script().resource_path,
		"actual_script_sha256":FileAccess.get_sha256(get_script().resource_path),"actual_code_sha256":_v7_code_sha(material.shader.code),
		"actual_RF_texture_bound":material.get_shader_parameter("actual_height_rf")==height_rf,
		"scope":"unchanged V8 water formula, RF/depth/discard/ALPHA/Y; not a water quality approval","production_approved":false,"visual_approved":false})
	return material

func _v9_fragment() -> String:
	return """void fragment(){
 vec2 p=vec2(xyz.x*102.4+6144.,xyz.z*72.40773439+4096.);
 vec2 uv=(p-source_rect.xy)/source_rect.zw;
 vec4 eco=texture(biome_weights,uv);vec3 road=texture(road_weights,uv).rgb;
 vec3 gn=normalize(geo);vec3 w=pow(abs(gn),vec3(4.));w/=max(dot(w,vec3(1.)),.00001);
 float forest=clamp(eco.r,0.,1.),rock=clamp(eco.g,0.,1.),wet=clamp(eco.b,0.,1.),snow=clamp(eco.a,0.,1.);
 float route=clamp(road.r,0.,1.),sand=road.b*(1.-snow)*(1.-forest);
 // Continuous 2-11m growth/loam islands, never random per-pixel colour grains.
 float patch=n2(xyz.xz/3.7)*.55+n2(xyz.xz/10.9+vec2(7.,-3.))*.45;
 float growth=smoothstep(.29,.69,patch);
 float g=.18+.20*growth,l=.12+.25*forest,f=.10+.20*forest,r=rock*.82,b=wet*.10,a=.08;
 float total=max(g+l+f+r+b+a,.00001);g/=total;l/=total;f/=total;r/=total;b/=total;a/=total;
 vec3 col=scan(grass_ground_diff,2.51,w,1.)*g+scan(leafy_grass_diff,2.,w,1.)*l+scan(forest_ground_04_diff,3.2,w,.4)*f+scan(rock_01_diff,1.5,w,0.)*r+scan(brown_mud_03_diff,1.3,w,.5)*b+scan(aerial_grass_rock_diff,15.,w,0.)*a;
 vec3 arm=scan(grass_ground_arm,2.51,w,1.)*g+scan(leafy_grass_arm,2.,w,1.)*l+scan(forest_ground_04_arm,3.2,w,.4)*f+scan(rock_01_arm,1.5,w,0.)*r+scan(brown_mud_03_arm,1.3,w,.5)*b+scan(aerial_grass_rock_arm,15.,w,0.)*a;
 vec3 detail=scan(grass_ground_nor_gl,2.51,w,1.)*g+scan(leafy_grass_nor_gl,2.,w,1.)*l+scan(forest_ground_04_nor_gl,3.2,w,.4)*f+scan(rock_01_nor_gl,1.5,w,0.)*r+scan(brown_mud_03_nor_gl,1.3,w,.5)*b+scan(aerial_grass_rock_nor_gl,15.,w,0.)*a;
 // Regional base treatment supplies readable macro structure. Scan detail is
 // preserved at its real period; this native treatment is not claimed CC0.
 vec3 loam=mix(vec3(.245,.225,.165),vec3(.315,.300,.225),patch);
 vec3 turf=mix(vec3(.160,.230,.120),vec3(.235,.310,.175),patch);
 vec3 humus=mix(vec3(.130,.135,.105),vec3(.230,.215,.160),patch);
 vec3 floor_col=mix(mix(loam,turf,growth),humus,forest);
 float floor_owner=mix(.57,.82,forest)*(1.-rock*.9)*(1.-snow)*(1.-wet);
 col=mix(col,floor_col,floor_owner);arm=mix(arm,vec3(1.,.89,0.),floor_owner);
 detail=mix(detail,vec3(.5,.5,1.),floor_owner*.68);
 // Finite, unequal authored fields with local axes. .924m furrow period is
 // retained inside each parcel; no floor/step grid or full-region sine band.
 float field_owner=0.,crop=0.,furrow_n=0.;
 for(int i=0;i<18;i++){
  vec4 parcel=finite_parcels[i];vec2 delta=p-parcel.xy;
  float angle=sin(float(i)*2.17)*.61;
  vec2 axis=vec2(cos(angle),sin(angle));vec2 cross_axis=vec2(-axis.y,axis.x);
  vec2 local=vec2(dot(delta,axis),dot(delta,cross_axis))/parcel.zw;
  float rim=max(abs(local.x),abs(local.y));float owner=1.-smoothstep(.82,1.05,rim);
  float metres=dot(vec2(delta.x/102.4,delta.y/72.40773439),axis);
  float phase=metres*6.8+float(i)*1.73+(n2(xyz.xz/2.3)-.5)*.32;
  if(owner>field_owner){field_owner=owner;crop=.34+.18*smoothstep(.24,.76,.5+.5*sin(phase));furrow_n=sin(phase);}
 }
 field_owner*=.58*(1.-route)*(1.-forest)*(1.-wet)*(1.-rock)*(1.-snow)*(1.-sand);
 col=mix(col,mix(loam,scan(leafy_grass_diff,2.,w,1.),crop),field_owner);
 arm=mix(arm,mix(vec3(1.,.91,0.),scan(leafy_grass_arm,2.,w,1.),crop),field_owner);
 detail=mix(detail,mix(vec3(.5,.5,1.),scan(leafy_grass_nor_gl,2.,w,1.),crop),field_owner);
 // Dry silty soil only; the owner was excluded from actual RF water/roads.
 // Opaque sheen does not become a water body, walk support or ALPHA exception.
 float silt=n2(xyz.xz/1.9)*.35+n2(xyz.xz/7.1+vec2(4.,9.))*.65;
 vec3 silt_col=mix(vec3(.090,.100,.080),vec3(.220,.205,.150),silt);
 float moist=smoothstep(.35,.72,silt)*wet;
 float wet_owner=wet*.96*(1.-route);
 col=mix(col,mix(silt_col,scan(forest_ground_04_diff,3.2,w,.4),.10),wet_owner);
 arm=mix(arm,mix(vec3(1.,mix(.76,.34,moist),0.),scan(forest_ground_04_arm,3.2,w,.4),.10),wet_owner);
 detail=mix(detail,mix(vec3(.5,.5,1.),scan(forest_ground_04_nor_gl,3.2,w,.4),.14),wet_owner);
 float mineral_patch=smoothstep(.27,.72,n2(xyz.xz/2.9));
 vec3 rock_col=scan(rock_01_diff,1.5,w,0.);
 col=mix(col,mix(rock_col,loam,.17*(1.-mineral_patch)),rock*.86*(1.-snow));
 arm=mix(arm,scan(rock_01_arm,1.5,w,0.),rock*.86*(1.-snow));
 detail=mix(detail,scan(rock_01_nor_gl,1.5,w,0.),rock*.86*(1.-snow));
 vec3 sand_col=mix(vec3(.345,.300,.210),vec3(.475,.425,.315),patch);
 col=mix(col,mix(sand_col,scan(forest_ground_04_diff,3.2,w,0.),.19),sand*.9);
 arm=mix(arm,mix(vec3(1.,.92,0.),scan(forest_ground_04_arm,3.2,w,0.),.19),sand*.9);
 detail=mix(detail,mix(vec3(.5,.5,1.),scan(forest_ground_04_nor_gl,3.2,w,0.),.19),sand*.9);
 float grade=length(gn.xz)/max(abs(gn.y),.05);
 float deposit=snow*(.28+.66*smoothstep(.29,.70,n2(xyz.xz/1.4)*.55+n2(xyz.xz/4.6)*.45))*(1.-smoothstep(.30,1.1,grade)*.7);
 float snow_ground=snow*.85*(1.-deposit);
 col=mix(col,rock_col,snow_ground);arm=mix(arm,scan(rock_01_arm,1.5,w,0.),snow_ground);detail=mix(detail,scan(rock_01_nor_gl,1.5,w,0.),snow_ground);
 vec3 snow_col=mix(vec3(.51,.55,.56),vec3(.71,.75,.76),smoothstep(.27,.71,patch));
 col=mix(col,snow_col,deposit);arm=mix(arm,vec3(1.,.81,0.),deposit);detail=mix(detail,vec3(.5,.5,1.),deposit*.78);
 // Narrow original 4px road owner; compact earth + honest fine mineral detail.
 float compact=n2(xyz.xz/.56)*.34+n2(xyz.xz/2.1)*.66;
 vec3 earth=mix(vec3(.275,.240,.175),vec3(.380,.325,.245),compact);
 vec3 mineral=scan(forest_ground_04_diff,3.2,w,0.);float luma=dot(mineral,vec3(.2126,.7152,.0722));
 vec3 lane=mix(earth,vec3(luma),.19);
 float shoulder=clamp(road.g-route,0.,1.);
 col=mix(col,mix(floor_col,earth,.64),shoulder*.62*(1.-wet*.6));col=mix(col,lane,route);
 arm=mix(arm,mix(vec3(1.,.91,0.),scan(forest_ground_04_arm,3.2,w,0.),.19),route);
 detail=mix(detail,mix(vec3(.5,.5,1.),scan(forest_ground_04_nor_gl,3.2,w,0.),.23),route);
 ALBEDO=col;AO=mix(1.,arm.r,.18);ROUGHNESS=clamp(arm.g,.30,.98);SPECULAR=.18;METALLIC=0.;
 float strength=mix(.17,.12,route);vec3 wn=normalize(gn+vec3((detail.r-.5)*strength,0.,(detail.g-.5)*strength));
 wn=normalize(wn+vec3(furrow_n*.008*field_owner,0.,0.));NORMAL=normalize((VIEW_MATRIX*vec4(wn,0.)).xyz);
}
"""

func release() -> void:
	v9_material_records.clear()
	super.release()
